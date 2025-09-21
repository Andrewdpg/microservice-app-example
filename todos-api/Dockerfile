# Build stage
FROM node:16-alpine AS builder

WORKDIR /app
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Runtime stage
FROM node:16-alpine

WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

# Copiar dependencias y código
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Exponer puerto
EXPOSE 8082

# Variables de entorno por defecto
ENV TODO_API_PORT=8082
ENV JWT_SECRET=myfancysecret
ENV REDIS_HOST=redis-queue
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel
ENV USERS_API_ADDRESS=http://users-api:8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8082/health || exit 1

# Comando para ejecutar la aplicación
CMD ["npm", "start"]