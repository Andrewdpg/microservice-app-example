# Patrones de Nube Implementados

## **Patrones Seleccionados**

Implementamos **3 patrones**:

1. **Circuit Breaker** - Resiliencia
2. **Cache-Aside** - Performance
3. **Autoscaling** - Escalabilidad

---

## **1. Circuit Breaker**

### **¿Qué es?**

Patrón que previene cascadas de fallos al "abrir" el circuito cuando un servicio falla repetidamente.

### **Estados del Circuito**

- **CLOSED**: Funcionamiento normal
- **OPEN**: Circuito abierto, falla rápido
- **HALF-OPEN**: Probando si el servicio se recuperó

### **Implementación**

#### **Auth API (Go) - gobreaker**

```go
// Configuración del circuit breaker
var cb = gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "users-api",
    MaxRequests: 3,           // Máximo 3 requests en half-open
    Interval:    30 * time.Second,  // Ventana de tiempo
    Timeout:     10 * time.Second,  // Timeout por request
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures >= 5  // 5 fallos → abrir
    },
    OnStateChange: func(name string, from gobreaker.State, to gobreaker.State) {
        log.Printf("Circuit breaker %s changed from %s to %s", name, from, to)
    },
})

// Uso en el código
func (s *UserService) Login(ctx context.Context, username, password string) (*User, error) {
    result, err := cb.Execute(func() (interface{}, error) {
        return s.callUsersAPI(ctx, username, password)
    })
  
    if err != nil {
        return nil, err
    }
  
    return result.(*User), nil
}
```

#### **TODOs API (Node.js) - opossum**

```javascript
const CircuitBreaker = require('opossum');

// Configuración del circuit breaker
const options = {
    timeout: 3000,        // 3 segundos timeout
    errorThresholdPercentage: 50,  // 50% errores → abrir
    resetTimeout: 30000,  // 30 segundos antes de half-open
    rollingCountTimeout: 10000,    // Ventana de 10 segundos
    rollingCountBuckets: 10,       // 10 buckets en la ventana
    name: 'users-api-cb'
};

const usersApiBreaker = new CircuitBreaker(callUsersAPI, options);

// Eventos del circuit breaker
usersApiBreaker.on('open', () => {
    console.log('Circuit breaker opened - Users API is down');
});

usersApiBreaker.on('halfOpen', () => {
    console.log('Circuit breaker half-open - Testing Users API');
});

usersApiBreaker.on('close', () => {
    console.log('Circuit breaker closed - Users API is healthy');
});

// Uso en el código
async function validateUser(token) {
    try {
        return await usersApiBreaker.fire(token);
    } catch (error) {
        if (error.code === 'ECIRCUITOPEN') {
            // Circuito abierto - usar datos en caché o fallback
            return getCachedUser(token);
        }
        throw error;
    }
}
```

### **Beneficios**

- **Previene cascadas**: Un servicio caído no tumba todo el sistema
- **Recuperación rápida**: Detecta cuando el servicio se recupera
- **Fallback graceful**: Puede usar datos en caché o respuestas por defecto

---

## **2. Cache-Aside**

### **¿Qué es?**

Patrón donde la aplicación es responsable de cargar y actualizar datos en caché.

### **Flujo del Patrón**

1. **Read**: App consulta caché primero
2. **Cache Miss**: Si no está, consulta BD y guarda en caché
3. **Cache Hit**: Si está, devuelve datos del caché
4. **Write**: App actualiza BD y invalida caché

### **Implementación**

#### **Users API (Spring Boot) - @Cacheable**

```java
@Service
@EnableCaching
public class UserService {
  
    @Autowired
    private UserRepository userRepository;
  
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
  
    // Configuración de caché
    @Bean
    public CacheManager cacheManager() {
        RedisCacheManager.Builder builder = RedisCacheManager
            .RedisCacheManagerBuilder
            .fromConnectionFactory(redisTemplate.getConnectionFactory())
            .cacheDefaults(cacheConfiguration(Duration.ofMinutes(1)));
        return builder.build();
    }
  
    private RedisCacheConfiguration cacheConfiguration(Duration ttl) {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(ttl)
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));
    }
  
    // Método con caché
    @Cacheable(value = "users", key = "#id")
    public User getUserById(Long id) {
        log.info("Fetching user {} from database", id);
        return userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException("User not found"));
    }
  
    @Cacheable(value = "users", key = "'all'")
    public List<User> getAllUsers() {
        log.info("Fetching all users from database");
        return userRepository.findAll();
    }
  
    // Invalidar caché al actualizar
    @CacheEvict(value = "users", allEntries = true)
    public User updateUser(User user) {
        log.info("Updating user {} and evicting cache", user.getId());
        return userRepository.save(user);
    }
}
```

#### **Configuración Redis**

```yaml
# application.yml
spring:
  redis:
    host: redis-cache
    port: 6379
    database: 1  # Base de datos separada para caché
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
        max-wait: -1ms

# Configuración de caché
cache:
  redis:
    time-to-live: 60000  # 60 segundos TTL
    cache-null-values: false
```

### **Beneficios**

- **Performance**: Respuestas más rápidas para datos frecuentemente consultados
- **Reducción de carga**: Menos consultas a la base de datos
- **Escalabilidad**: Mejor throughput del sistema

---

## **3. Autoscaling**

### **¿Qué es?**

Patrón que ajusta automáticamente los recursos según la demanda.

### **Tipos de Autoscaling**

#### **A. Horizontal Pod Autoscaler (HPA) - TODOs API**

```yaml
# hpa-todos-api.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: todos-api-hpa
  namespace: microservices-staging
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: todos-api
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

#### **B. KEDA - Log Message Processor**

```yaml
# keda-scaler.yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: log-processor-scaler
  namespace: microservices-staging
spec:
  scaleTargetRef:
    name: log-processor
  minReplicaCount: 0
  maxReplicaCount: 5
  triggers:
  - type: redis
    metadata:
      address: redis-queue:6379
      listName: log_channel
      listLength: '10'  # Escalar cuando hay 10+ mensajes
      databaseIndex: '0'
  cooldownPeriod: 30
  pollingInterval: 10
```

### **Configuración de Recursos**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todos-api
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: todos-api
        image: microservice-app/todos-api:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /health
            port: 8082
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8082
          initialDelaySeconds: 30
          periodSeconds: 10
```

### **Beneficios**

- **Eficiencia de costos**: Solo paga por recursos que usa
- **Disponibilidad**: Escala automáticamente ante picos de tráfico
- **Performance**: Mantiene tiempos de respuesta consistentes

---

## **Configuración de Monitoreo**

### **Métricas para Circuit Breaker**

```yaml
# Prometheus metrics
circuit_breaker_state{name="users-api",state="closed"} 1
circuit_breaker_requests_total{name="users-api",result="success"} 100
circuit_breaker_requests_total{name="users-api",result="failure"} 5
```

### **Métricas para Cache**

```yaml
# Cache hit/miss ratio
cache_hits_total{cache="users",operation="getUserById"} 150
cache_misses_total{cache="users",operation="getUserById"} 25
cache_hit_ratio{cache="users"} 0.857  # 85.7% hit ratio
```

### **Métricas para Autoscaling**

```yaml
# HPA metrics
kube_horizontalpodautoscaler_status_current_replicas{name="todos-api-hpa"} 3
kube_horizontalpodautoscaler_status_desired_replicas{name="todos-api-hpa"} 5
kube_pod_resource_requests{resource="cpu",pod="todos-api-xxx"} 0.1
```

---

## 🎯 **Resumen de Beneficios**

| Patrón                   | Problema que Resuelve         | Beneficio Principal |
| ------------------------- | ----------------------------- | ------------------- |
| **Circuit Breaker** | Cascadas de fallos            | Resiliencia         |
| **Cache-Aside**     | Consultas lentas              | Performance         |
| **Autoscaling**     | Recursos sub/sobre utilizados | Eficiencia          |

Estos patrones trabajan juntos para crear un sistema robusto, rápido y eficiente. 🚀
