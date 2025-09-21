package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
	"github.com/sony/gobreaker"
)

var allowedUserHashes = map[string]interface{}{
	"admin_admin": nil,
	"johnd_foo":   nil,
	"janed_ddd":   nil,
}

type User struct {
	Username  string `json:"username"`
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
	Role      string `json:"role"`
}

type HTTPDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
	Client            HTTPDoer
	UserAPIAddress    string
	AllowedUserHashes map[string]interface{}
	CircuitBreaker    *gobreaker.CircuitBreaker
}

// Configuración del Circuit Breaker
func NewUserService(client HTTPDoer, userAPIAddress string) *UserService {
	cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
		Name:        "users-api",
		MaxRequests: 3,                    // Máximo 3 requests en half-open
		Interval:    30 * time.Second,     // Ventana de tiempo
		Timeout:     10 * time.Second,     // Timeout por request
		ReadyToTrip: func(counts gobreaker.Counts) bool {
			return counts.ConsecutiveFailures >= 5 // 5 fallos → abrir
		},
		OnStateChange: func(name string, from gobreaker.State, to gobreaker.State) {
			log.Printf("Circuit breaker %s changed from %s to %s", name, from, to)
		},
	})

	return &UserService{
		Client:            client,
		UserAPIAddress:    userAPIAddress,
		AllowedUserHashes: allowedUserHashes,
		CircuitBreaker:    cb,
	}
}

func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
	user, err := h.getUser(ctx, username)
	if err != nil {
		return user, err
	}

	userKey := fmt.Sprintf("%s_%s", username, password)

	if _, ok := h.AllowedUserHashes[userKey]; !ok {
		return user, ErrWrongCredentials
	}

	return user, nil
}

func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
	var user User

	// Usar Circuit Breaker para la llamada a Users API
	result, err := h.CircuitBreaker.Execute(func() (interface{}, error) {
		return h.callUsersAPI(ctx, username)
	})

	if err != nil {
		// Si el circuito está abierto, usar datos de fallback
		if err == gobreaker.ErrOpenState {
			log.Printf("Circuit breaker is open, using fallback data for user %s", username)
			return h.getFallbackUser(username), nil
		}
		return user, err
	}

	return result.(User), nil
}

func (h *UserService) callUsersAPI(ctx context.Context, username string) (User, error) {
	var user User

	token, err := h.getUserAPIToken(username)
	if err != nil {
		return user, err
	}

	url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", "Bearer "+token)
	req = req.WithContext(ctx)

	resp, err := h.Client.Do(req)
	if err != nil {
		return user, err
	}

	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, err
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return user, fmt.Errorf("could not get user data: %s", string(bodyBytes))
	}

	err = json.Unmarshal(bodyBytes, &user)
	return user, err
}

// Datos de fallback cuando el circuito está abierto
func (h *UserService) getFallbackUser(username string) User {
	// Datos básicos de fallback para usuarios conocidos
	fallbackUsers := map[string]User{
		"admin": {
			Username:  "admin",
			FirstName: "Admin",
			LastName:  "User",
			Role:      "admin",
		},
		"johnd": {
			Username:  "johnd",
			FirstName: "John",
			LastName:  "Doe",
			Role:      "user",
		},
		"janed": {
			Username:  "janed",
			FirstName: "Jane",
			LastName:  "Doe",
			Role:      "user",
		},
	}

	if user, exists := fallbackUsers[username]; exists {
		return user
	}

	// Usuario genérico si no se encuentra
	return User{
		Username:  username,
		FirstName: "Unknown",
		LastName:  "User",
		Role:      "user",
	}
}

func (h *UserService) getUserAPIToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["scope"] = "read"
	return token.SignedString([]byte(jwtSecret))
}