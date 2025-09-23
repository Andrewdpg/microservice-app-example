# Configuracion de Jenkins


## Contenido

- jobs/ - Configuracion de jobs (sin builds)
- plugins/ - Plugins instalados
- secrets/ - Claves de encriptacion
- users/ - Usuarios y permisos
- config.xml - Configuracion del sistema
- credentials.xml - Archivo de credenciales con placeholders
- .env - Credenciales encriptadas extraidas

## Credenciales

Las credenciales estan en el archivo .env en formato:

JENKINS_CRED_1_ID=docker-hub-credentials
JENKINS_CRED_1_DESCRIPTION=Docker Hub credentials (GitHub linked)
JENKINS_CRED_1_USERNAME=andrewdpg
JENKINS_CRED_1_PASSWORD={AQAAABAAAAAw/JabHhGen3PfScTMQ5U4suC9CtoY9wxZFJcEw/xQ3gTO/WoPkgM5S18yT3ORdKxXxp/wNceFKBWc/GLMpl40AQ==}
JENKINS_CRED_1_CLASS=com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

## Uso

1. Importar configuracion: .\scripts\import-jenkins-secure.ps1
2. Las credenciales se importaran automaticamente desde .env
