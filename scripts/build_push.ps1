Param(
  [Parameter(Mandatory=$true)][string]$Registry,
  [Parameter()][string]$Tag = "local-$(Get-Date -Format yyyyMMddHHmmss)"
)

$ErrorActionPreference = 'Stop'
Write-Host "Using REGISTRY=$Registry, TAG=$Tag"

docker build -t "$Registry/todos-api:$Tag" ./todos-api
docker build -t "$Registry/frontend:$Tag" ./frontend
docker build -t "$Registry/users-api:$Tag" ./users-api
docker build -t "$Registry/auth-api:$Tag" ./auth-api
docker build -t "$Registry/log-message-processor:$Tag" ./log-message-processor

docker push "$Registry/todos-api:$Tag"
docker push "$Registry/frontend:$Tag"
docker push "$Registry/users-api:$Tag"
docker push "$Registry/auth-api:$Tag"
docker push "$Registry/log-message-processor:$Tag"

Write-Host "Done. Images pushed with tag $Tag"


