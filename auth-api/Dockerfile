# Build stage
FROM golang:1.19-alpine AS builder

WORKDIR /app
COPY . .

# Instalar dependencias
RUN apk add --no-cache git
RUN go mod download
RUN go mod verify

# Build de la aplicación
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Runtime stage
FROM alpine:latest

# Instalar ca-certificates para HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copiar el binario desde el stage de build
COPY --from=builder /app/main .

# Exponer puerto
EXPOSE 8081

# Variables de entorno por defecto
ENV AUTH_API_PORT=8081
ENV JWT_SECRET=myfancysecret
ENV USERS_API_ADDRESS=http://users-api:8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

# Comando para ejecutar la aplicación
CMD ["./main"]