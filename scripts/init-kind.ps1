param([string]$ClusterName="ci")
Write-Host "Creando/verificando cluster kind '$ClusterName'..."
$exists = kind get clusters | Select-String -SimpleMatch $ClusterName
if (-not $exists) {
  kind create cluster --name $ClusterName --config infra/k8s/config/kind.yaml
} else {
  Write-Host "Cluster ya existe."
}
kubectl cluster-info

Write-Host "Aplicando namespaces + RBAC..."
kubectl apply -f infra/k8s/namespaces.yaml
kubectl apply -f infra/k8s/rbac-jenkins.yaml
Write-Host "Aplicando config (ConfigMap/Secret)..."
kubectl apply -f infra/k8s/config/configmap.yaml
kubectl apply -f infra/k8s/config/secret.yaml