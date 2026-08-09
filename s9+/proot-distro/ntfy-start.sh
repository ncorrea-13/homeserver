#!/bin/bash
set -uo pipefail

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

export TZ="${TZ:?TZ not set in $ENV_FILE}"
export NTFY_BASE_URL="${NTFY_BASE_URL:?NTFY_BASE_URL not set in $ENV_FILE}"
export NTFY_LISTEN_HTTP="${NTFY_LISTEN_HTTP:?NTFY_LISTEN_HTTP not set in $ENV_FILE}"
export NTFY_CACHE_FILE="${NTFY_CACHE_FILE:?NTFY_CACHE_FILE not set in $ENV_FILE}"
export NTFY_AUTH_FILE="${NTFY_AUTH_FILE:?NTFY_AUTH_FILE not set in $ENV_FILE}"
export NTFY_AUTH_DEFAULT_ACCESS="${NTFY_AUTH_DEFAULT_ACCESS:?NTFY_AUTH_DEFAULT_ACCESS not set in $ENV_FILE}"

ntfy serve
