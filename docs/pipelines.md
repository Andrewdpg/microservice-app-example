# Pipelines de CI/CD

## Pipeline de Microservicios

El pipeline de microservicios se ejecuta automáticamente cuando se realizan cambios en el repositorio de código fuente. Este pipeline se encarga de construir, probar y desplegar las aplicaciones de microservicios en los entornos correspondientes.

### Triggers del Pipeline

El pipeline se activa de manera diferente según la rama en la que se realicen los cambios:

- **Push a `dev`**: Deploy automático a staging
- **Push a `release`**: Deploy automático a staging y producción
- **Push a `feature/*`**: Solo build y test (sin deploy)

Esta estrategia de branching permite un flujo de trabajo controlado donde los cambios se validan primero en staging antes de llegar a producción.

### Proceso de Construcción y Pruebas

La primera etapa del pipeline consiste en obtener el código fuente del repositorio Git. El sistema genera automáticamente etiquetas de imagen Docker basadas en el nombre de la rama y el hash del commit, lo que permite un seguimiento preciso de las versiones desplegadas.

Posteriormente, se ejecutan las pruebas de manera paralela para cada microservicio:

- **Auth API**: Pruebas unitarias en Go
- **Users API**: Pruebas con Maven en Java Spring Boot
- **TODOs API**: Pruebas con npm en Node.js
- **Frontend**: Pruebas con npm en Vue.js
- **Log Processor**: Pruebas con pytest en Python

Este enfoque paralelo optimiza el tiempo de ejecución del pipeline y permite la detección temprana de problemas en cualquier microservicio.

### Construcción de Imágenes Docker

Una vez completadas las pruebas, el pipeline procede a construir las imágenes Docker para cada microservicio. Este proceso se ejecuta de manera paralela para optimizar el tiempo de construcción. Cada imagen se etiqueta con dos versiones: una específica que incluye el nombre de la rama y el hash del commit, y otra con la etiqueta `latest` para facilitar las referencias. Las imágenes se construyen utilizando los Dockerfiles específicos de cada servicio, que incluyen las dependencias y configuraciones necesarias para el funcionamiento en contenedores.

### Publicación de Imágenes

Después de la construcción exitosa, las imágenes Docker se publican en Docker Hub utilizando las credenciales configuradas en Jenkins. El proceso de publicación incluye todas las imágenes construidas, asegurando que estén disponibles para su despliegue en los entornos de Kubernetes. La publicación se realiza de manera secuencial para evitar conflictos de red y garantizar la integridad de las imágenes.

### Activación del Pipeline de Infraestructura

Una vez completada la publicación de las imágenes, el pipeline de microservicios activa el pipeline de infraestructura correspondiente. Para cambios en la rama `dev`, se activa el despliegue al entorno de staging, mientras que para la rama `release` se activa el despliegue a producción. Esta activación se realiza mediante una llamada HTTP a Jenkins, incluyendo todos los parámetros necesarios como la etiqueta de la imagen, el registro de Docker, el commit de Git y el entorno de destino.

## Pipeline de Infraestructura

El pipeline de infraestructura se encarga de desplegar y gestionar los recursos de Kubernetes necesarios para el funcionamiento de los microservicios. Este pipeline puede ser activado manualmente o automáticamente por el pipeline de microservicios.

### Validación de Manifiestos

La primera etapa del pipeline de infraestructura consiste en validar la sintaxis y estructura de todos los manifiestos de Kubernetes. El sistema utiliza `kubectl` en modo `dry-run` para verificar que los archivos YAML estén correctamente formateados y sean válidos antes de intentar aplicarlos al cluster. Esta validación previene errores de despliegue y asegura la integridad de la configuración.

### Procesamiento de Variables de Entorno

Antes del despliegue, el sistema procesa los archivos de configuración para reemplazar las variables de entorno específicas de cada namespace. Los archivos `configmap.yaml` y `secret.yaml` se procesan para incluir los valores correctos según el entorno de destino, ya sea staging o producción. Este procesamiento asegura que cada entorno tenga su configuración específica.

### Despliegue a Staging

El despliegue al entorno de staging se caracteriza por su simplicidad y rapidez. El sistema aplica primero los recursos base como namespaces, configmaps y secrets, seguido de los manifiestos específicos de staging. Cada servicio se despliega con una sola réplica, sin load balancers internos, lo que resulta en una arquitectura más simple y fácil de depurar. El proceso incluye la verificación del estado de los deployments para asegurar que todos los servicios estén funcionando correctamente.

### Despliegue a Producción

El despliegue a producción implementa una arquitectura más robusta con múltiples réplicas y load balancers internos. Cada servicio se despliega con al menos dos réplicas para garantizar alta disponibilidad. Los servicios de Kubernetes actúan como load balancers internos, distribuyendo la carga entre las múltiples instancias de cada microservicio. El proceso incluye verificaciones exhaustivas del estado de los deployments y la validación de que todos los servicios estén respondiendo correctamente.

### Gestión de Recursos de Datos

Los servicios de Redis, tanto para caché como para cola de mensajes, se despliegan de manera diferente según el entorno. En staging, se utiliza una sola instancia de cada servicio para simplificar la configuración. En producción, aunque se mantiene una sola instancia de Redis, se implementan servicios de Kubernetes para facilitar la comunicación entre los microservicios y los recursos de datos.

## Configuración de Jenkins

### Gestión de Credenciales

Jenkins está configurado con las credenciales necesarias para interactuar con los diferentes servicios externos:

- **Docker Hub**: Usuario y contraseña para publicación de imágenes
- **GitHub**: Usuario, contraseña y token para acceso a repositorios
- **Jenkins API Token**: Para comunicación entre pipelines
- **Kubernetes Kubeconfig**: Para acceso seguro al cluster

Estas credenciales se almacenan de forma segura en Jenkins y se utilizan automáticamente durante la ejecución de los pipelines.

### Configuración de Jobs

Los jobs de Jenkins están configurados como pipelines que utilizan los archivos `Jenkinsfile` ubicados en la raíz de cada repositorio. La configuración incluye la especificación del repositorio Git, la rama principal y los parámetros necesarios para la ejecución. Cada job está configurado para ejecutarse automáticamente cuando se detectan cambios en el repositorio correspondiente.

### Integración con Kubernetes

La integración con Kubernetes se realiza a través del plugin de Kubernetes de Jenkins, que permite la ejecución de pipelines en pods dinámicos. El sistema utiliza el kubeconfig configurado para autenticarse con el cluster y ejecutar comandos `kubectl` necesarios para el despliegue y gestión de recursos.

## Monitoreo y Observabilidad

### Métricas de Pipeline

El sistema recopila métricas importantes sobre el rendimiento de los pipelines:

- **Build Time**: Tiempo total de construcción
- **Success Rate**: Porcentaje de builds exitosos
- **Deploy Frequency**: Frecuencia de despliegues
- **Lead Time**: Tiempo desde commit hasta producción

Estas métricas permiten identificar cuellos de botella y optimizar el proceso de CI/CD.

### Alertas y Notificaciones

El sistema está configurado para enviar alertas cuando ocurren fallos en los builds o despliegues:

- **Build fallido**: Notificación inmediata al equipo de desarrollo
- **Deploy fallido**: Alerta con detalles del error y acciones recomendadas
- **Rollback automático**: Si health check falla en producción

Las alertas incluyen información detallada sobre el error y las acciones recomendadas para su resolución.

### Health Checks

Después de cada despliegue, el sistema ejecuta verificaciones de salud para asegurar que todos los servicios estén funcionando correctamente:

- **Validación de endpoints**: Verificación de endpoints de salud de cada servicio
- **Estado de pods**: Confirmación de que todos los pods estén en estado "Running"
- **Verificación de rollouts**: Confirmación de que los deployments se completaron exitosamente

Estas verificaciones garantizan la estabilidad del sistema después de cada despliegue.

## Estrategia de Despliegue

### Despliegue por Etapas

El sistema implementa una estrategia de despliegue por etapas, donde los cambios primero se despliegan en staging para pruebas y validación, y posteriormente se promueven a producción. Esta estrategia reduce el riesgo de introducir errores en el entorno de producción y permite la validación exhaustiva de los cambios antes de su liberación.

### Gestión de Versiones

El sistema utiliza un esquema de versionado basado en ramas Git y hashes de commit para el seguimiento de versiones. Cada imagen Docker incluye metadatos que permiten rastrear exactamente qué código se está ejecutando en cada entorno, facilitando la depuración y el mantenimiento.
