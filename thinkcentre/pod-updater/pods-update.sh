#!/bin/bash
set -uo pipefail
shopt -s nullglob

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

PODS_DIR="${UPDATE_PODS_DIR:?UPDATE_PODS_DIR not set in $ENV_FILE}"
SKIP="${UPDATE_SKIP:-}"

for f in "$PODS_DIR"/*/compose.yaml; do
  dir="$(dirname "$f")"
  [[ " $SKIP " == *" $(basename "$dir") "* ]] && continue
  cd "$dir" || continue
  podman compose pull && podman compose up -d || echo "FAIL: $dir" >&2
done
podman image prune -f
