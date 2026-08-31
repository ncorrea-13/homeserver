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
NTFY_TOKEN="${NTFY_TOKEN:?NTFY_TOKEN not set in $ENV_FILE}"

if ! curl -sf "$GATEWAY_CHECK_URL" >/dev/null; then
  curl -H "Authorization: Bearer $NTFY_TOKEN" \
    -d "⚠ Pi (gateway) caída - sin DNS ni Caddy" \
    -H "Tags: warning" \
    -H "Priority: high" \
    "$NTFY_PUSH_URL"
fi
