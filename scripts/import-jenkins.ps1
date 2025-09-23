# scripts/import-jenkins-secure.ps1
Write-Host "Importando configuracion de Jenkins de forma segura..." -ForegroundColor Yellow

$configDir = ".\jenkins-config"
if (-not (Test-Path $configDir)) {
    Write-Host "No se encontro el directorio de configuracion: $configDir" -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts\export-jenkins-secure.ps1" -ForegroundColor Yellow
    exit 1
}

# Verificar que Jenkins esta ejecutandose
$jenkinsContainer = docker ps --filter "name=jenkins" --format "{{.Names}}"
if (-not $jenkinsContainer) {
    Write-Host "Jenkins no esta ejecutandose. Ejecuta: docker-compose up -d" -ForegroundColor Red
    exit 1
}

Write-Host "Jenkins encontrado: $jenkinsContainer" -ForegroundColor Green

# Función para cargar variables de entorno desde .env
function Load-EnvFile {
    param([string]$EnvFile)
    
    if (-not (Test-Path $EnvFile)) {
        Write-Host "No se encontro el archivo .env" -ForegroundColor Yellow
        return @{}
    }
    
    $envVars = @{}
    Get-Content $EnvFile | Where-Object { $_ -notlike "#*" -and $_ -ne "" } | ForEach-Object {
        if ($_ -match "^(.+?)=(.*)$") {
            $envVars[$matches[1]] = $matches[2]
        }
    }
    
    return $envVars
}

# Función para crear una copia de credentials.xml con placeholders reemplazados
function Create-CredentialsWithReplacements {
    param([string]$OriginalCredentialsFile, [hashtable]$EnvVars)
    
    if (-not (Test-Path $OriginalCredentialsFile)) {
        Write-Host "No se encontro el archivo credentials.xml original" -ForegroundColor Yellow
        return $null
    }
    
    try {
        # Leer el archivo credentials.xml original
        $xmlContent = Get-Content $OriginalCredentialsFile -Raw
        
        Write-Host "Contenido original del XML:" -ForegroundColor Gray
        Write-Host $xmlContent.Substring(0, [Math]::Min(500, $xmlContent.Length)) -ForegroundColor Gray
        
        # Crear una copia del contenido para modificar
        $modifiedXmlContent = $xmlContent
        
        # Buscar y reemplazar cada placeholder
        $credentialCount = 1
        $replacements = 0
        
        while ($EnvVars.ContainsKey("JENKINS_CRED_${credentialCount}_ID")) {
            $credId = $EnvVars["JENKINS_CRED_${credentialCount}_ID"]
            $credDescription = $EnvVars["JENKINS_CRED_${credentialCount}_DESCRIPTION"]
            
            Write-Host "Procesando credencial ${credentialCount}: $credDescription" -ForegroundColor Gray
            
            # Reemplazar placeholder de password
            if ($EnvVars.ContainsKey("JENKINS_CRED_${credentialCount}_PASSWORD")) {
                $credPassword = $EnvVars["JENKINS_CRED_${credentialCount}_PASSWORD"]
                $placeholder = "{{PASSWORD_${credentialCount}}}"
                
                Write-Host "Buscando placeholder: $placeholder" -ForegroundColor Gray
                Write-Host "Reemplazando con: $($credPassword.Substring(0, [Math]::Min(20, $credPassword.Length)))..." -ForegroundColor Gray
                
                if ($modifiedXmlContent -match [regex]::Escape($placeholder)) {
                    $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($placeholder), $credPassword
                    $replacements++
                    Write-Host "Placeholder de password reemplazado" -ForegroundColor Green
                } else {
                    Write-Host "Placeholder de password no encontrado" -ForegroundColor Yellow
                }
            }
            
            # Reemplazar placeholder de secret
            if ($EnvVars.ContainsKey("JENKINS_CRED_${credentialCount}_SECRET")) {
                $credSecret = $EnvVars["JENKINS_CRED_${credentialCount}_SECRET"]
                $placeholder = "{{SECRET_${credentialCount}}}"
                
                Write-Host "Buscando placeholder: $placeholder" -ForegroundColor Gray
                Write-Host "Reemplazando con: $($credSecret.Substring(0, [Math]::Min(20, $credSecret.Length)))..." -ForegroundColor Gray
                
                if ($modifiedXmlContent -match [regex]::Escape($placeholder)) {
                    $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($placeholder), $credSecret
                    $replacements++
                    Write-Host "Placeholder de secret reemplazado" -ForegroundColor Green
                } else {
                    Write-Host "Placeholder de secret no encontrado" -ForegroundColor Yellow
                }
            }
            
            # Reemplazar placeholder de secretBytes
            if ($EnvVars.ContainsKey("JENKINS_CRED_${credentialCount}_SECRET_BYTES")) {
                $credSecretBytes = $EnvVars["JENKINS_CRED_${credentialCount}_SECRET_BYTES"]
                $placeholder = "{{SECRET_BYTES_${credentialCount}}}"
                
                Write-Host "Buscando placeholder: $placeholder" -ForegroundColor Gray
                Write-Host "Reemplazando con: $($credSecretBytes.Substring(0, [Math]::Min(20, $credSecretBytes.Length)))..." -ForegroundColor Gray
                
                if ($modifiedXmlContent -match [regex]::Escape($placeholder)) {
                    $modifiedXmlContent = $modifiedXmlContent -replace [regex]::Escape($placeholder), $credSecretBytes
                    $replacements++
                    Write-Host "Placeholder de secretBytes reemplazado" -ForegroundColor Green
                } else {
                    Write-Host "Placeholder de secretBytes no encontrado" -ForegroundColor Yellow
                }
            }
            
            $credentialCount++
        }
        
        Write-Host "Total de reemplazos realizados: $replacements" -ForegroundColor Cyan
        
        # Crear archivo temporal con las credenciales reemplazadas
        $tempCredentialsFile = "$configDir\credentials-temp.xml"
        $modifiedXmlContent | Out-File -FilePath $tempCredentialsFile -Encoding UTF8
        Write-Host "Archivo temporal creado: $tempCredentialsFile" -ForegroundColor Green
        
        # Mostrar contenido modificado
        Write-Host "Contenido modificado del XML:" -ForegroundColor Gray
        Write-Host $modifiedXmlContent.Substring(0, [Math]::Min(500, $modifiedXmlContent.Length)) -ForegroundColor Gray
        
        return $tempCredentialsFile
        
    } catch {
        Write-Host "Error creando archivo temporal de credenciales: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Detener Jenkins antes de importar
Write-Host "Deteniendo Jenkins..." -ForegroundColor Yellow
docker stop jenkins

# Importar claves de encriptacion PRIMERO
Write-Host "Importando claves de encriptacion..." -ForegroundColor Yellow
docker cp $configDir/secrets jenkins:/var/jenkins_home/

# Importar configuracion del sistema
Write-Host "Importando configuracion del sistema..." -ForegroundColor Yellow
docker cp $configDir/config.xml jenkins:/var/jenkins_home/

# Importar usuarios
Write-Host "Importando usuarios..." -ForegroundColor Yellow
docker cp $configDir/users jenkins:/var/jenkins_home/

# Importar jobs
Write-Host "Importando jobs..." -ForegroundColor Yellow
docker cp $configDir/jobs jenkins:/var/jenkins_home/

# Importar plugins
Write-Host "Importando plugins..." -ForegroundColor Yellow
docker cp $configDir/plugins jenkins:/var/jenkins_home/

# Crear archivo temporal de credenciales con reemplazos
Write-Host "Creando archivo temporal de credenciales con reemplazos..." -ForegroundColor Yellow
$envFile = "$configDir\.env"
$tempCredentialsFile = $null

if (Test-Path $envFile) {
    $envVars = Load-EnvFile -EnvFile $envFile
    Write-Host "Variables de entorno cargadas: $($envVars.Count)" -ForegroundColor Gray
    
    # Mostrar las credenciales encontradas
    $credentialCount = 1
    while ($envVars.ContainsKey("JENKINS_CRED_${credentialCount}_ID")) {
        $credId = $envVars["JENKINS_CRED_${credentialCount}_ID"]
        $credDescription = $envVars["JENKINS_CRED_${credentialCount}_DESCRIPTION"]
        Write-Host "Credencial ${credentialCount}: $credId - $credDescription" -ForegroundColor Gray
        $credentialCount++
    }
    
    $tempCredentialsFile = Create-CredentialsWithReplacements -OriginalCredentialsFile "$configDir\credentials.xml" -EnvVars $envVars
} else {
    Write-Host "No se encontro el archivo .env, usando credentials.xml original" -ForegroundColor Yellow
    $tempCredentialsFile = "$configDir\credentials.xml"
}

# Importar credentials.xml (temporal o original)
if ($tempCredentialsFile -and (Test-Path $tempCredentialsFile)) {
    Write-Host "Importando credentials.xml..." -ForegroundColor Yellow
    docker cp $tempCredentialsFile jenkins:/var/jenkins_home/credentials.xml
    
    # Limpiar archivo temporal si se creó
    if ($tempCredentialsFile -ne "$configDir\credentials.xml") {
        Write-Host "Limpiando archivo temporal..." -ForegroundColor Gray
        Remove-Item $tempCredentialsFile -Force
    }
} else {
    Write-Host "Error: No se pudo crear o encontrar el archivo de credenciales" -ForegroundColor Red
}

# Ajustar permisos
Write-Host "Ajustando permisos..." -ForegroundColor Yellow
docker exec jenkins chown -R jenkins:jenkins /var/jenkins_home/

# Iniciar Jenkins
Write-Host "Iniciando Jenkins..." -ForegroundColor Yellow
docker start jenkins

# Esperar a que Jenkins este listo
Write-Host "Esperando a que Jenkins este listo..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
do {
    $attempt++
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8079" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "Jenkins esta listo!" -ForegroundColor Green
            break
        }
    } catch {
        # Continuar esperando
    }
} while ($attempt -lt $maxAttempts)

Write-Host "Configuracion importada de forma segura!" -ForegroundColor Green
Write-Host "Jenkins disponible en: http://localhost:8079" -ForegroundColor Cyan