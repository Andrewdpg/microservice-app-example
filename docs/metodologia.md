# Metodología Ágil - Scrumban + Trunk-Based Development

## **Decisión de Metodología**

**Elegida**: **Scrumban**

### ¿Por qué esta combinación?

**Alternativas consideradas:**

- **Scrum puro**: Demasiado rígido para un equipo pequeño, muchas ceremonias
- **Kanban puro**: Falta de planificación y visibilidad a largo plazo

**Decisión final: Scrumban**

1. **Scrumban**: Combina lo mejor de Scrum (planificación, demos, retrospectivas) con Kanban (flujo continuo, WIP limitado)

   - **Ventaja**: Flexibilidad del flujo continuo + estructura de Scrum
   - **Beneficio**: Adaptable al tamaño del equipo y complejidad del proyecto
2. **Perfecto para equipos pequeños**: Reduce complejidad de merge y acelera el feedback

   - **Equipo actual**: 2-4 desarrolladores
   - **Contexto**: Microservicios con deploys independientes

## **Cadencia y Rituales**

### **Iteraciones Quincenales**

**Decisión**: 2 semanas (no 1 ni 3)

**Razones:**

- **1 semana**: Demasiado corta para features complejas, mucha overhead de planificación
- **3 semanas**: Demasiado larga para feedback rápido, riesgo de desviación
- **2 semanas**: Balance óptimo entre planificación y flexibilidad

**Características:**

- **Duración**: 2 semanas
- **Objetivos claros**: Cada iteración tiene metas específicas y medibles
- **Flexibilidad**: Permite ajustes rápidos según feedback
- **Planificación**: 1 hora de planning por iteración
- **Capacidad**: 80% del tiempo disponible (20% para imprevistos)

### **Daily Standup (15 min)**

**Decisión**: 15 minutos máximo, no 30

**Razones:**

- **30 min**: Demasiado tiempo, se convierte en reunión técnica
- **10 min**: Muy poco para identificar bloqueos reales
- **15 min**: Tiempo suficiente para sincronización sin perder productividad

**Estructura:**

- ¿Qué hice ayer?
- ¿Qué haré hoy?
- ¿Qué impedimentos tengo?
- **Foco**: Bloqueos y dependencias, no detalles técnicos
- **Regla**: Si necesitas discutir detalles técnicos, agenda una reunión separada

### **Demo y Retrospectiva**

**Decisión**: Combinar demo y retrospectiva en una sola sesión

**Razones:**

- **Separadas**: Demasiadas reuniones, pérdida de contexto
- **Solo demo**: Falta de mejora continua
- **Solo retrospectiva**: Sin validación de lo entregado
- **Combinadas**: Eficiencia + contexto completo

**Estructura (1.5 horas total):**

- **Demo (45 min)**: Mostrar funcionalidad terminada al final de cada iteración
  - Cada desarrollador presenta su trabajo
  - Feedback inmediato de stakeholders
- **Retrospectiva (45 min)**: Mejoras en proceso, herramientas y comunicación
  - ¿Qué funcionó bien?
  - ¿Qué podemos mejorar?
  - ¿Qué acciones tomaremos?

## **Definition of Done (DoD)**

**Decisión**: DoD estricto para mantener calidad en desarrollo rápido

**Razones:**

- **Sin DoD**: Código inconsistente, bugs en producción
- **DoD muy laxo**: Calidad baja, deuda técnica
- **DoD muy estricto**: Lentitud en desarrollo
- **DoD balanceado**: Calidad + velocidad óptima

**Criterios para que una tarea se considere "terminada":**

1. **Código revisado**: PR aprobado por al menos un compañero

   - **Razón**: Detección temprana de bugs y mejora de calidad
   - **Tiempo**: Máximo 4 horas para review
2. **Tests pasando**: Unit tests y integration tests exitosos

   - **Cobertura mínima**: 80% para código nuevo
   - **Razón**: Confianza en cambios, detección de regresiones
3. **Build exitoso**: Pipeline CI/CD sin errores

   - **Razón**: Garantiza que el código se puede desplegar
   - **Tiempo máximo**: 10 minutos para build completo
4. **Imagen Docker**: Publicada en registry con tag semántico

   - **Formato**: `servicio:version` (ej: `auth-api:v1.2.3`)
   - **Razón**: Reproducibilidad y rollback fácil
5. **Deploy en staging**: Funcionando correctamente

   - **Validación**: Smoke tests pasando
   - **Razón**: Validación en entorno similar a producción
6. **Documentación**: README actualizado si es necesario

   - **Criterio**: Cambios que afecten configuración o uso
   - **Razón**: Mantenibilidad a largo plazo

## **Métricas Clave**

- **Lead Time**: Tiempo desde idea hasta producción
- **Cycle Time**: Tiempo desde desarrollo hasta deploy
- **Deployment Frequency**: Frecuencia de deploys a producción
- **Mean Time to Recovery**: Tiempo promedio para resolver incidentes
