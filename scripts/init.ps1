param(
  [string]$ClusterName = "ci",
  [string]$Namespace = "micro",
  [switch]$ConnectJenkinsToKindNet
)

Write-Host "1) Instalando herramientas (kubectl/kind)..." -ForegroundColor Yellow
.\scripts\install.ps1

Write-Host "2) Creando/Inicializando cluster kind..." -ForegroundColor Yellow
.\scripts\init-kind.ps1 -ClusterName $ClusterName

Write-Host "3) Generando kubeconfig para Jenkins..." -ForegroundColor Yellow
.\scripts\gen-jenkins-config.ps1 -ClusterName $ClusterName -Namespace $Namespace -ConnectJenkinsToKindNet:$ConnectJenkinsToKindNet

Write-Host "Listo. Archivo generado: jenkins-kubeconfig.yaml" -ForegroundColor Green
Write-Host "Puedes usarlo en Jenkins para desplegar con kubectl." -ForegroundColor Green