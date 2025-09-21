# Build stage
FROM maven:3.8.6-openjdk-11-slim AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

# Build de la aplicación
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:11-jre-slim

WORKDIR /app

# Copiar el JAR desde el stage de build
COPY --from=builder /app/target/*.jar app.jar

# Exponer puerto
EXPOSE 8083

# Variables de entorno por defecto
ENV SERVER_PORT=8083

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8083/users/health || exit 1

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]