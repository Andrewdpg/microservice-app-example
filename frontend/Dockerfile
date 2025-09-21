# Build stage
# Node8.17.0
FROM node:8.17.0-alpine AS builder

WORKDIR /app
COPY package*.json ./

# Instalar dependencias
RUN npm ci

# Copiar código fuente
COPY . .

# Build de la aplicación
RUN npm run build

# Runtime stage
FROM nginx:alpine

# Copiar archivos buildados
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuración de nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer puerto
EXPOSE 8080

# Variables de entorno por defecto
ENV AUTH_API_URL=http://auth-api:8081
ENV TODOS_API_URL=http://todos-api:8082

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

# Comando para ejecutar nginx
CMD ["nginx", "-g", "daemon off;"]
