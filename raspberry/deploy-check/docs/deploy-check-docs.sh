#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
source "$SCRIPT_DIR/.env"
set +a

LATEST=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/commits/$GITHUB_BRANCH" | jq -r '.sha')
CURRENT=$(cat "$TARGET_DIR/.deployed-sha" 2>/dev/null || echo "none")

if [ "$LATEST" = "$CURRENT" ]; then
  echo "$(date -Iseconds) Sin cambios"
  exit 0
fi

echo "$(date -Iseconds) Nuevo commit $LATEST, sincronizando"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FILES=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/contents/$SUBDIR?ref=$GITHUB_BRANCH" |
  jq -r '.[] | select(.type == "file") | .name')

if [ -z "$FILES" ]; then
  echo "$(date -Iseconds) ERROR: no pude listar archivos de $SUBDIR" >&2
  exit 1
fi

for f in $FILES; do
  curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/$SUBDIR/$f" \
    -o "$TMP_DIR/$f"
done

mv "$TMP_DIR"/* "$TARGET_DIR/"
echo "$LATEST" >"$TARGET_DIR/.deployed-sha"
echo "$(date -Iseconds) Deploy OK: $LATEST"
