#!/bin/bash
# seal_secret.sh - Helper to generate a SealedSecret YAML for GitOps
# Usage: seal_secret.sh <app-name> <key1=val1> [<key2=val2> ...]

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <app-name> <key=value> [<key=value> ...]"
  exit 1
fi

APP_NAME=$1
shift

# Build kubectl command with --from-literal args
SECRET_ARGS=()
for kv in "$@"; do
  SECRET_ARGS+=(--from-literal="$kv")
done

# Create a temporary plain Secret YAML
kubectl create secret generic "$APP_NAME-secret" \
  "${SECRET_ARGS[@]}" \
  --dry-run=client -o yaml > /tmp/${APP_NAME}-secret.yaml

# Seal it with cluster's public key
kubeseal \
  --controller-namespace kube-system \
  --controller-name sealed-secret \
  --format yaml \
  < /tmp/${APP_NAME}-secret.yaml \
  > ${APP_NAME}-sealed-secret.yaml

echo "✅ Created ${APP_NAME}-sealed-secret.yaml"
echo "→ Commit this file to the appropriate Git repo (e.g. apps/${APP_NAME}/secrets/)"
