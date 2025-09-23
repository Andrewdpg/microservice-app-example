# scripts/export-jenkins-secure.ps1
Write-Host "Exportando configuracion de Jenkins de forma segura..." -ForegroundColor Yellow

# Crear directorio para la configuracion
$configDir = ".\jenkins-config"
if (Test-Path $configDir) {
    Remove-Item -Path $configDir -Recurse -Force
}
New-Item -ItemType Directory -Path $configDir

# Verificar que Jenkins esta ejecutandose
$jenkinsContainer = docker ps --filter "name=jenkins" --format "{{.Names}}"
if (-not $jenkinsContainer) {
    Write-Host "Jenkins no esta ejecutandose. Ejecuta: docker-compose up -d" -ForegroundColor Red
    exit 1
}

Write-Host "Jenkins encontrado: $jenkinsContainer" -ForegroundColor Green

# Exportar configuracion esencial
Write-Host "Exportando jobs..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/jobs $configDir\

# Limpiar builds y logs
Write-Host "Limpiando builds y logs..." -ForegroundColor Yellow
Get-ChildItem -Path "$configDir\jobs" -Recurse -Directory -Name "builds" | ForEach-Object {
    $buildsPath = "$configDir\jobs\$_"
    if (Test-Path $buildsPath) {
        Remove-Item -Path $buildsPath -Recurse -Force
    }
}

Get-ChildItem -Path "$configDir\jobs" -Recurse -Directory -Name "logs" | ForEach-Object {
    $logsPath = "$configDir\jobs\$_"
    if (Test-Path $logsPath) {
        Remove-Item -Path $logsPath -Recurse -Force
    }
}

# Exportar configuracion del sistema
Write-Host "Exportando configuracion del sistema..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/config.xml $configDir\

# Exportar usuarios
Write-Host "Exportando usuarios..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/users $configDir\

# Exportar plugins
Write-Host "Exportando plugins..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/plugins $configDir\

# Exportar claves de encriptacion
Write-Host "Exportando claves de encriptacion..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/secrets $configDir\

# Exportar credentials.xml y reemplazar contraseñas con placeholders
Write-Host "Exportando credentials.xml con placeholders..." -ForegroundColor Yellow
docker cp jenkins:/var/jenkins_home/credentials.xml $configDir\

# Función para extraer credenciales y crear placeholders
function Extract-CredentialsAndCreatePlaceholders {
    param([string]$CredentialsFile, [string]$EnvFile)
    
    if (-not (Test-Path $CredentialsFile)) {
        Write-Host "No se encontro el archivo de credenciales" -ForegroundColor Yellow
        return
    }
    
    try {
        # Leer el archivo como texto
        $xmlContent = Get-Content $CredentialsFile -Raw
        
        $envContent = @()
        $envContent += "# Credenciales de Jenkins - NO SUBIR A REPOSITORIO"
        $envContent += "# Este archivo contiene credenciales sensibles"
        $envContent += ""
        
        $credentialCount = 0
        
        # Extraer todas las credenciales y crear placeholders
        $credentials = @()
        $currentCredential = @{}
        
        # Dividir el XML en secciones de credenciales
        $credentialSections = $xmlContent -split '<com\.cloudbees\.plugins\.credentials\.impl\.|<org\.jenkinsci\.plugins\.plaincredentials\.impl\.'
        
        foreach ($section in $credentialSections) {
            if ($section -match 'UsernamePasswordCredentialsImpl|StringCredentialsImpl|FileCredentialsImpl') {
                $currentCredential = @{}
                
                # Extraer ID
                if ($section -match '<id>([^<]+)</id>') {
                    $currentCredential.ID = $matches[1]
                }
                
                # Extraer descripción
                if ($section -match '<description>([^<]*)</description>') {
                    $currentCredential.DESCRIPTION = $matches[1]
                }
                
                # Extraer username
                if ($section -match '<username>([^<]+)</username>') {
                    $currentCredential.USERNAME = $matches[1]
                }
                
                # Extraer password encriptada
                if ($section -match '<password>\{([^}]+)\}</password>') {
                    $currentCredential.PASSWORD = $matches[1]
                }
                
                # Extraer secret encriptado
                if ($section -match '<secret>\{([^}]+)\}</secret>') {
                    $currentCredential.SECRET = $matches[1]
                }
                
                # Extraer filename
                if ($section -match '<fileName>([^<]+)</fileName>') {
                    $currentCredential.FILENAME = $matches[1]
                }
                
                # Extraer secretBytes encriptado
                if ($section -match '<secretBytes>\{([^}]+)\}</secretBytes>') {
                    $currentCredential.SECRET_BYTES = $matches[1]
                }
                
                # Determinar tipo de credencial
                if ($section -match 'UsernamePasswordCredentialsImpl') {
                    $currentCredential.CLASS = "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
                } elseif ($section -match 'StringCredentialsImpl') {
                    $currentCredential.CLASS = "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
                } elseif ($section -match 'FileCredentialsImpl') {
                    $currentCredential.CLASS = "org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl"
                }
                
                if ($currentCredential.ID) {
                    $credentials += $currentCredential
                }
            }
        }
        
        # Crear archivo .env con las credenciales
        $credentialCount = 0
        foreach ($cred in $credentials) {
            $credentialCount++
            
            $envContent += "# Credencial ${credentialCount}: $($cred.DESCRIPTION)"
            $envContent += "JENKINS_CRED_${credentialCount}_ID=$($cred.ID)"
            $envContent += "JENKINS_CRED_${credentialCount}_DESCRIPTION=$($cred.DESCRIPTION)"
            $envContent += "JENKINS_CRED_${credentialCount}_CLASS=$($cred.CLASS)"
            
            if ($cred.USERNAME) {
                $envContent += "JENKINS_CRED_${credentialCount}_USERNAME=$($cred.USERNAME)"
            }
            
            if ($cred.PASSWORD) {
                $envContent += "JENKINS_CRED_${credentialCount}_PASSWORD=$($cred.PASSWORD)"
            }
            
            if ($cred.SECRET) {
                $envContent += "JENKINS_CRED_${credentialCount}_SECRET=$($cred.SECRET)"
            }
            
            if ($cred.FILENAME) {
                $envContent += "JENKINS_CRED_${credentialCount}_FILENAME=$($cred.FILENAME)"
            }
            
            if ($cred.SECRET_BYTES) {
                $envContent += "JENKINS_CRED_${credentialCount}_SECRET_BYTES=$($cred.SECRET_BYTES)"
            }
            
            $envContent += ""
        }
        
        $envContent | Out-File -FilePath $EnvFile -Encoding UTF8
        Write-Host "Credenciales extraidas a: $EnvFile" -ForegroundColor Green
        Write-Host "Total de credenciales: $credentialCount" -ForegroundColor Cyan
        
        # Ahora reemplazar las contraseñas encriptadas por placeholders en el XML
        Write-Host "Creando placeholders en credentials.xml..." -ForegroundColor Yellow
        $modifiedXmlContent = $xmlContent
        
        $credentialCount = 0
        foreach ($cred in $credentials) {
            $credentialCount++
            
            # Reemplazar password encriptada por placeholder
            if ($cred.PASSWORD) {
                $placeholder = "{{PASSWORD_${credentialCount}}}"
                $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($cred.PASSWORD), $placeholder
            }
            
            # Reemplazar secret encriptado por placeholder
            if ($cred.SECRET) {
                $placeholder = "{{SECRET_${credentialCount}}}"
                $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($cred.SECRET), $placeholder
            }
            
            # Reemplazar secretBytes encriptado por placeholder
            if ($cred.SECRET_BYTES) {
                $placeholder = "{{SECRET_BYTES_${credentialCount}}}"
                $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($cred.SECRET_BYTES), $placeholder
            }
        }
        
        # Guardar el XML modificado con placeholders
        $modifiedXmlContent | Out-File -FilePath $CredentialsFile -Encoding UTF8
        Write-Host "Credentials.xml modificado con placeholders" -ForegroundColor Green
        
    } catch {
        Write-Host "Error procesando credenciales: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Contenido del archivo:" -ForegroundColor Gray
        Get-Content $CredentialsFile | Select-Object -First 10
    }
}

# Extraer credenciales y crear placeholders
Extract-CredentialsAndCreatePlaceholders -CredentialsFile "$configDir\credentials.xml" -EnvFile "$configDir\.env"

# Crear archivo .gitignore para la configuracion
Write-Host "Creando .gitignore..." -ForegroundColor Yellow
$gitignoreContent = @"
# Jenkins Configuration - NO SUBIR A REPOSITORIO
jenkins-config/
*.env
secrets/
credentials.xml
users/
"@
$gitignoreContent | Out-File -FilePath "$configDir\.gitignore" -Encoding UTF8

# Crear README de seguridad
Write-Host "Creando README de seguridad..." -ForegroundColor Yellow
$readmeContent = @"
# Configuracion de Jenkins

## ADVERTENCIA DE SEGURIDAD

Este directorio contiene configuracion sensible de Jenkins:

- **NO SUBIR A REPOSITORIO PUBLICO**
- **NO COMPARTIR EN CHAT/EMAIL**
- **MANTENER EN LUGAR SEGURO**

## Contenido

- `jobs/` - Configuracion de jobs (sin builds)
- `plugins/` - Plugins instalados
- `secrets/` - Claves de encriptacion
- `users/` - Usuarios y permisos
- `config.xml` - Configuracion del sistema
- `credentials.xml` - Archivo de credenciales con placeholders
- `.env` - Credenciales encriptadas extraidas

## Credenciales

Las credenciales estan en el archivo `.env` en formato:

JENKINS_CRED_1_ID=docker-hub-credentials
JENKINS_CRED_1_DESCRIPTION=Docker Hub credentials (GitHub linked)
JENKINS_CRED_1_USERNAME=andrewdpg
JENKINS_CRED_1_PASSWORD={AQAAABAAAAAw/JabHhGen3PfScTMQ5U4suC9CtoY9wxZFJcEw/xQ3gTO/WoPkgM5S18yT3ORdKxXxp/wNceFKBWc/GLMpl40AQ==}
JENKINS_CRED_1_CLASS=com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

## Uso

1. Importar configuracion: `.\scripts\import-jenkins-secure.ps1`
2. Las credenciales se importaran automaticamente desde `.env`
"@
$readmeContent | Out-File -FilePath "$configDir\README.md" -Encoding UTF8

Write-Host "Configuracion exportada de forma segura!" -ForegroundColor Green
Write-Host "Archivos creados:" -ForegroundColor Cyan
Get-ChildItem -Path $configDir | Select-Object Name, Length
Write-Host "NO SUBIR A REPOSITORIO PUBLICO" -ForegroundColor Red