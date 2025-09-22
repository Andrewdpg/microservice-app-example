#!/usr/bin/env bash
set -euo pipefail

REGISTRY=${1:?"Usage: $0 <registry> <tag> [kubeconfig]"}
TAG=${2:?"Usage: $0 <registry> <tag> [kubeconfig]"}
KUBECONFIG_PATH=${3:-$HOME/.kube/config}

if [ ! -f "$KUBECONFIG_PATH" ]; then
  echo "Kubeconfig not found at $KUBECONFIG_PATH" >&2
  exit 1
fi

echo "Rendering manifests with REGISTRY=$REGISTRY TAG=$TAG"
render_dir="infra/k8s/_render"
mkdir -p "$render_dir"

for f in $(ls infra/k8s/*.yaml 2>/dev/null) $(ls infra/k8s/*/*.yaml 2>/dev/null); do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  sed -e "s|\\${REGISTRY}|${REGISTRY}|g" \
      -e "s|\\${IMAGE_TAG}|${TAG}|g" "$f" > "$render_dir/$name"
done

export KUBECONFIG="$KUBECONFIG_PATH"
kubectl apply -f "$render_dir" --recursive

echo "Applied manifests from $render_dir"


