# Estrategia de Branching - Trunk-Based Development

## **Decisión de Estrategia**

**Elegida**: **Trunk-Based Development con ramas efímeras**

### **Alternativas consideradas:**

- **GitFlow**: Demasiado complejo para microservicios, ramas largas
- **GitHub Flow**: Simple pero sin separación de entornos
- **GitLab Flow**: Bueno pero con overhead innecesario
- **Trunk-Based**: Óptimo para equipos pequeños y deploys frecuentes

### **¿Por qué Trunk-Based Development?**

**Ventajas:**

- **Ramas cortas**: Máximo 2 días de duración
- **Integración continua**: Merge frecuente a `main`
- **Menos conflictos**: Evita divergencia de código
- **Feedback rápido**: Detección temprana de problemas
- **Simplicidad**: Menos overhead de gestión de ramas

**Contexto del proyecto:**

- **Equipo pequeño**: 2-4 desarrolladores
- **Microservicios**: Deploys independientes
- **Desarrollo ágil**: Iteraciones de 2 semanas

## **Estructura de Ramas**

### **Desarrollo (Código Fuente)**

**Estructura de ramas:**

```
main (siempre estable)
├── feature/nombre-corto (máximo 2 días)
├── hotfix/incidente-crítico (merge directo a main)
└── tags/v1.0.0 (versiones estables)
```

### **Operaciones (Infraestructura)**

**Estructura:**

```
infra/main (staging)
└── infra/prod (producción, requiere aprobación)
```

## **Reglas Detalladas**

### **Rama `main`**

- **Estado**: Siempre estable y desplegable
- **Protección**: Requiere PR + 1 aprobación
- **Deploy**: Automático a staging tras merge
- **Historial**: Commits lineales, no merge commits
- **Política**: Nunca hacer commit directo a `main`

### **Ramas `feature/*`**

- **Nomenclatura**: `feature/descripcion-corta` (ej: `feature/user-auth`)
- **Duración máxima**: 2 días de trabajo
- **Razón**: Evita conflictos de merge y mantiene integración continua
- **Proceso**:
  1. Crear desde `main` actualizado
  2. Desarrollar y hacer commits frecuentes
  3. Crear PR cuando esté listo
  4. Merge directo a `main` (no squash, no rebase)
  5. Eliminar rama inmediatamente

**Ejemplos de nomenclatura:**

- `feature/user-authentication`
- `feature/payment-integration`
- `feature/email-notifications`
- `feature/api-rate-limiting`

### **Ramas `hotfix/*`**

- **Nomenclatura**: `hotfix/descripcion-incidente` (ej: `hotfix/auth-token-expiry`)
- **Uso**: Solo para bugs críticos en producción
- **Proceso**:
  1. Crear desde `main`
  2. Fix rápido (máximo 4 horas)
  3. Merge directo a `main` (bypass review si es crítico)
  4. Deploy inmediato a producción
  5. Eliminar rama

**Ejemplos de hotfix:**

- `hotfix/database-connection-pool`
- `hotfix/memory-leak-fix`
- `hotfix/security-patch`

### **Tags de versión**

- **Formato**: `v{major}.{minor}.{patch}` (ej: `v1.2.3`)
- **Cuándo**: Al final de cada iteración exitosa
- **Propósito**: Puntos de rollback y releases formales
- **Semantic Versioning**:
  - **MAJOR**: Cambios incompatibles en API
  - **MINOR**: Nueva funcionalidad compatible
  - **PATCH**: Bug fixes compatibles

## **Flujo de Trabajo Detallado**

### **Desarrollo de Feature**

**Paso a paso:**

1. **Sync con main**:

   ```bash
   git checkout main
   git pull origin main
   ```
2. **Crear rama feature**:

   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. **Desarrollar**:

   - Commits frecuentes con mensajes claros
   - Usar conventional commits: `feat:`, `fix:`, `docs:`, etc.
   - Ejemplo: `git commit -m "feat: add user authentication endpoint"`
4. **Push de la rama**:

   ```bash
   git push origin feature/nueva-funcionalidad
   ```
5. **Crear Pull Request**:

   - Título descriptivo
   - Descripción detallada de cambios
   - Asignar reviewers
6. **Review**:

   - Esperar aprobación (máximo 4 horas)
   - Resolver comentarios si los hay
   - Actualizar rama si es necesario
7. **Merge**:

   - Merge directo a `main`
   - No usar squash o rebase
   - Mantener historial de commits
8. **Cleanup**:

   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/nueva-funcionalidad
   git push origin --delete feature/nueva-funcionalidad
   ```

### **Hotfix de Emergencia**

**Paso a paso:**

1. **Crear rama hotfix**:

   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/descripcion-bug
   ```
2. **Implementar fix**:

   - Solución mínima y directa
   - No agregar funcionalidad nueva
   - Commits claros y concisos
3. **Testing**:

   - Verificar que el fix funciona
   - Ejecutar tests relevantes
   - Validar en entorno local
4. **Merge inmediato**:

   ```bash
   git checkout main
   git merge hotfix/descripcion-bug
   git push origin main
   ```
5. **Deploy de emergencia**:

   - Deploy inmediato a producción
   - Monitorear que todo funcione
   - Notificar al equipo
6. **Cleanup**:

   ```bash
   git branch -d hotfix/descripcion-bug
   git push origin --delete hotfix/descripcion-bug
   ```

## **Operaciones de Infraestructura**

### **Rama `infra/main`**

- **Propósito**: Infraestructura de staging
- **Deploy**: Automático tras merge
- **Validación**: Tests de infraestructura pasando
- **Proceso**: Similar a desarrollo de features

### **Rama `infra/prod`**

- **Propósito**: Infraestructura de producción
- **Proceso**: Merge desde `infra/main` + aprobación de 2 personas
- **Deploy**: Manual tras aprobación
- **Rollback**: Inmediato si hay problemas

**Flujo de infraestructura:**

1. Cambios en `infra/main`
2. Deploy automático a staging
3. Validación en staging
4. PR de `infra/main` a `infra/prod`
5. Aprobación de 2 personas
6. Deploy manual a producción
