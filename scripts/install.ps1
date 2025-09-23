param([switch]$Force)

function Ensure-Tool {
  param([string]$Name,[string]$CheckCmd,[scriptblock]$InstallChoco,[scriptblock]$InstallWinget)
  Write-Host "Verificando $Name..."
  $exists = Invoke-Expression $CheckCmd 2>$null
  if ($LASTEXITCODE -eq 0 -and -not $Force) { Write-Host "$Name OK"; return }
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Instalando $Name via choco..."
    & $InstallChoco
  } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Instalando $Name via winget..."
    & $InstallWinget
  } else {
    Write-Host "Instala Chocolatey (https://chocolatey.org/install) o Winget y reintenta." -ForegroundColor Red
    exit 1
  }
}

Ensure-Tool -Name "kubectl" -CheckCmd "kubectl version --client --output=yaml | Out-Null" `
  -InstallChoco { choco install kubernetes-cli -y } `
  -InstallWinget { winget install -e --id Kubernetes.kubectl }

Ensure-Tool -Name "kind" -CheckCmd "kind --version | Out-Null" `
  -InstallChoco { choco install kind -y } `
  -InstallWinget { winget install -e --id Kubernetes.kind }

Write-Host "Herramientas listas." -ForegroundColor Green