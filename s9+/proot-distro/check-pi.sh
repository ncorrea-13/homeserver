#!/bin/bash
set -uo pipefail

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

GATEWAY_CHECK_URL="${GATEWAY_CHECK_URL:?GATEWAY_CHECK_URL not set in $ENV_FILE}"
NTFY_PUSH_URL="${NTFY_PUSH_URL:?NTFY_PUSH_URL not set in $ENV_FILE}"

if ! curl -sf "$GATEWAY_CHECK_URL" >/dev/null; then
  curl -d "⚠ Pi (gateway) caída - sin DNS ni Caddy" "$NTFY_PUSH_URL"
fi
