#!/bin/bash

if [ -f "$(dirname "$0")/.env" ]; then
  export $(grep -v '^#' "$(dirname "$0")/.env" | xargs)
fi

ORIGEN="${NAS_ROOT_PATH:-/ruta/origen/}"
DESTINO_BASE="${BACKUP_DEST_PATH:-/ruta/destino/}"
LOG_HISTORIAL="${LOG_PATH:-./backup_history.log}"
CARPETA_SQL="${DESTINO_BASE}db_backups/"

USUARIO_PODMAN="${USER_NAME:-ncserver}"
ID_USUARIO_PODMAN="${PUID:-1000}"

mkdir -p "$DESTINO_BASE"
mkdir -p "$CARPETA_SQL"

# Verificación de Voltaje (Específico para Raspberry Pi)
if command -v vcgencmd &>/dev/null; then
  THROTTLED=$(vcgencmd get_throttled)
  if [ "$THROTTLED" != "throttled=0x0" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [ADVERTENCIA] Sistema throttled ($THROTTLED). Voltaje inestable." >>"$LOG_HISTORIAL"
  fi
fi

FECHA=$(date +%Y-%m-%d_%H-%M)
FICHERO_SQL="immich_backup_${FECHA}.sql.gz"

echo "Iniciando dump de base de datos..."
if sudo -u "$USUARIO_PODMAN" HOME=/home/$USUARIO_PODMAN XDG_RUNTIME_DIR=/run/user/$ID_USUARIO_PODMAN DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID_USUARIO_PODMAN/bus /usr/bin/podman exec immich_postgres pg_dumpall -c -U postgres | gzip >"${CARPETA_SQL}${FICHERO_SQL}"; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [OK] DB Guardada en $CARPETA_SQL" >>"$LOG_HISTORIAL"
  find "$CARPETA_SQL" -name "immich_backup_*.sql.gz" -mtime +15 -delete
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] Falló el dump de la DB." >>"$LOG_HISTORIAL"
fi

FICHERO_VW="vaultwarden_backup_${FECHA}.sqlite3"

echo "Iniciando backup binario de Vaultwarden..."
# Ajustamos la ruta al volumen de Vaultwarden usando la variable de origen
if sudo -u "$USUARIO_PODMAN" HOME=/home/$USUARIO_PODMAN XDG_RUNTIME_DIR=/run/user/$ID_USUARIO_PODMAN DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID_USUARIO_PODMAN/bus /usr/bin/podman run --rm --entrypoint sh -v "${VAULTWARDEN_DATA_PATH}:/data:Z" docker.io/keinos/sqlite3 -c "sqlite3 /data/db.sqlite3 '.backup /tmp/ok.sqlite3' && cat /tmp/ok.sqlite3" >"${CARPETA_SQL}${FICHERO_VW}"; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [OK] Vaultwarden DB Guardada (Binario Atómico)" >>"$LOG_HISTORIAL"
  find "$CARPETA_SQL" -name "vaultwarden_backup_*.sqlite3" -mtime +15 -delete
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] Falló el backup binario de Vaultwarden." >>"$LOG_HISTORIAL"
fi

echo "Iniciando rsync de $ORIGEN..."

rsync -av --delete --omit-dir-times --inplace \
  --exclude="db_backups/" \
  --exclude="aquota.*" \
  --exclude="/lost+found" \
  --exclude="*.db-shm" \
  --exclude="**/*.sqlite3-shm" \
  --exclude="**/*.sqlite3-wal" \
  --exclude="*.db-wal" \
  --exclude="vaultwarden/tmp/" \
  --exclude="syncthing/config/index-v0.14.0.db*" \
  --exclude="**/postgress/**" \
  --exclude="immich_db_backup.sql" \
  --exclude="**/db.sqlite3" \
  "$ORIGEN" "$DESTINO_BASE"

ESTADO=$?
if [ $ESTADO -eq 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [ÉXITO] Backup completado correctamente." >>"$LOG_HISTORIAL"
elif [ $ESTADO -eq 23 ] || [ $ESTADO -eq 24 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [AVISO] Backup completado (archivos temporales saltados)." >>"$LOG_HISTORIAL"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] Falló la sincronización. Código: $ESTADO" >>"$LOG_HISTORIAL"
fi
