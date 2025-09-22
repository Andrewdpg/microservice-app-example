Param(
  [Parameter(Mandatory=$true)][string]$Registry,
  [Parameter(Mandatory=$true)][string]$Tag,
  [Parameter()][string]$Kubeconfig = "$HOME\.kube\config"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Kubeconfig)) { throw "Kubeconfig not found at $Kubeconfig" }

Write-Host "Rendering manifests with REGISTRY=$Registry TAG=$Tag"
$renderDir = "infra/k8s/_render"
New-Item -ItemType Directory -Force -Path $renderDir | Out-Null

Get-ChildItem -Path infra/k8s -Filter *.yaml -Recurse | Where-Object { $_.FullName -notmatch "_render" } | ForEach-Object {
  $content = Get-Content $_.FullName -Raw
  $rendered = $content.Replace('${REGISTRY}', $Registry).Replace('${IMAGE_TAG}', $Tag)
  $outPath = Join-Path $renderDir $_.Name
  $rendered | Out-File -FilePath $outPath -Encoding utf8
}

$env:KUBECONFIG = $Kubeconfig
kubectl apply -f $renderDir --recursive

Write-Host "Applied manifests from $renderDir"


