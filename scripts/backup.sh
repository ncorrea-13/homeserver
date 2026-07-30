#!/bin/bash
# no -e: sync_data's rsync exit code (23/24 = partial success) is handled below
set -uo pipefail

DEST_BASE="$1"

if [ -z "$DEST_BASE" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] Missing destination directory."
  exit 1
fi

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

SOURCE="${BACKUP_SOURCE:?BACKUP_SOURCE not set in $ENV_FILE}"
PODMAN_USER="${BACKUP_PODMAN_USER:?BACKUP_PODMAN_USER not set in $ENV_FILE}"
PODMAN_UID="${BACKUP_PODMAN_UID:?BACKUP_PODMAN_UID not set in $ENV_FILE}"
NTFY_URL="${BACKUP_NTFY_URL:?BACKUP_NTFY_URL not set in $ENV_FILE}"
NTFY_USER="${BACKUP_NTFY_USER:-}"
NTFY_PASS="${BACKUP_NTFY_PASS:-}"

FULL_BACKUP=false
[[ "$DEST_BASE" == *semanal* ]] && FULL_BACKUP=true

LOG_FILE="${DEST_BASE}backup_history.log"
SQL_DIR="${DEST_BASE}NAS_2/db_backups/"
RSYNC_DEST="${DEST_BASE}NAS_2/"
DATE_TAG=$(date +%Y-%m-%d_%H-%M)

mkdir -p "$RSYNC_DEST" "$SQL_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

notify() {
  [ -z "$NTFY_USER" ] && return 0
  curl -s -u "${NTFY_USER}:${NTFY_PASS}" -d "$1" -H "Tags: $2" "$NTFY_URL"
}

as_podman_user() {
  sudo -u "$PODMAN_USER" \
    HOME="/home/$PODMAN_USER" \
    XDG_RUNTIME_DIR="/run/user/$PODMAN_UID" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$PODMAN_UID/bus" \
    "$@"
}

backup_immich_db() {
  local file="immich_backup_${DATE_TAG}.sql.gz"
  echo "Starting Immich database dump..."
  if as_podman_user /usr/bin/podman exec immich_postgres pg_dumpall -c -U postgres | gzip >"${SQL_DIR}${file}"; then
    log "[OK] Immich DB saved to $SQL_DIR"
    find "$SQL_DIR" -name "immich_backup_*.sql.gz" -mtime +15 -delete
  else
    log "[ERROR] Immich DB dump failed."
    exit 1
  fi
}

backup_vaultwarden_db() {
  local file="vaultwarden_backup_${DATE_TAG}.sqlite3"
  echo "Starting Vaultwarden binary backup..."
  if as_podman_user /usr/bin/podman run --rm --entrypoint sh \
    -v "${SOURCE}Docker_Config/gateway/vaultwarden:/data:Z" \
    docker.io/keinos/sqlite3 -c "sqlite3 /data/db.sqlite3 '.backup /tmp/ok.sqlite3' && cat /tmp/ok.sqlite3" \
    >"${SQL_DIR}${file}"; then
    log "[OK] Vaultwarden DB saved"
    find "$SQL_DIR" -name "vaultwarden_backup_*.sqlite3" -mtime +15 -delete
  else
    log "[ERROR] Vaultwarden binary backup failed."
  fi
}

sync_data() {
  local exclude=(
    --exclude="db_backups/"
    --exclude="aquota.*"
    --exclude="/lost+found"
    --exclude="*.db-shm"
    --exclude="**/*.sqlite3-shm"
    --exclude="**/*.sqlite3-wal"
    --exclude="*.db-wal"
    --exclude="vaultwarden/tmp/"
    --exclude="syncthing/config/index-v0.14.0.db*"
    --exclude="**/postgress/**"
    --exclude="immich_db_backup.sql"
    --exclude="**/db.sqlite3"
  )

  if [ "$FULL_BACKUP" = true ]; then
    echo "Running FULL (weekly) backup, including photo library..."
  else
    echo "Running DAILY backup, active data only..."
    exclude+=(--exclude="NAS_1/" --exclude="Docker_Config/immich/library/")
  fi

  rsync -av --delete --omit-dir-times --inplace "${exclude[@]}" "$SOURCE" "$RSYNC_DEST"
}

backup_immich_db
backup_vaultwarden_db
sync_data
STATUS=$?

BACKUP_TYPE=$([ "$FULL_BACKUP" = true ] && echo "weekly" || echo "daily")

case $STATUS in
0)
  log "[SUCCESS] Backup completed successfully."
  notify "Backup $BACKUP_TYPE completed OK" "white_check_mark"
  ;;
23 | 24)
  log "[WARNING] Backup completed (temporary files skipped)."
  notify "Backup $BACKUP_TYPE completed (temporary files skipped) OK" "white_check_mark"
  ;;
*)
  log "[ERROR] Sync failed. Exit code: $STATUS"
  notify "Backup $BACKUP_TYPE FAILED" "rotating_light,Priority: high"
  ;;
esac
