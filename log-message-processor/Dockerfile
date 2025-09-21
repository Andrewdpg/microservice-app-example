# Build stage
FROM python:3.9-alpine AS builder

WORKDIR /app
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.9-alpine

WORKDIR /app

# Instalar dependencias del sistema
RUN apk add --no-cache curl

# Copiar dependencias y código
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY . .

# Variables de entorno por defecto
ENV REDIS_HOST=redis-queue
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import redis; r=redis.Redis(host='${REDIS_HOST}', port=${REDIS_PORT}); r.ping()" || exit 1

# Comando para ejecutar la aplicación
CMD ["python", "main.py"]