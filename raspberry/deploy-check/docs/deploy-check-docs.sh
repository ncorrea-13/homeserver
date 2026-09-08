#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
source "$SCRIPT_DIR/.env"
set +a

LATEST=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/commits/$GITHUB_BRANCH" | jq -r '.sha')
CURRENT=$(cat "$TARGET_DIR/.deployed-sha" 2>/dev/null || echo "none")

if [ "$LATEST" != "$CURRENT" ]; then
  echo "$(date -Iseconds) Nuevo commit $LATEST, sincronizando"
  for f in index.html style.css diagrama-arquitectura-claro.svg diagrama-arquitectura-oscuro.svg; do
    curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/$SUBDIR/$f" \
      -o "$TARGET_DIR/$f"
  done
  echo "$LATEST" >"$TARGET_DIR/.deployed-sha"
  echo "$(date -Iseconds) Deploy OK: $LATEST"
else
  echo "$(date -Iseconds) Sin cambios"
fi
