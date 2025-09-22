#!/usr/bin/env bash
set -euo pipefail

REGISTRY=${1:?"Usage: $0 <registry> [tag]"}
TAG=${2:-local-$(date +%Y%m%d%H%M%S)}

echo "Using REGISTRY=$REGISTRY TAG=$TAG"

docker build -t "$REGISTRY/todos-api:$TAG" ./todos-api
docker build -t "$REGISTRY/frontend:$TAG" ./frontend
docker build -t "$REGISTRY/users-api:$TAG" ./users-api
docker build -t "$REGISTRY/auth-api:$TAG" ./auth-api
docker build -t "$REGISTRY/log-message-processor:$TAG" ./log-message-processor

docker push "$REGISTRY/todos-api:$TAG"
docker push "$REGISTRY/frontend:$TAG"
docker push "$REGISTRY/users-api:$TAG"
docker push "$REGISTRY/auth-api:$TAG"
docker push "$REGISTRY/log-message-processor:$TAG"

echo "Done. Images pushed with tag $TAG"


