<div align="center">

# Mi Homelab Personal

**Infraestructura self-hosted en tres máquinas, manejada como pods de Podman Compose y servicios de systemd a nivel usuario**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Podman](https://img.shields.io/badge/Podman-Compose-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![systemd](https://img.shields.io/badge/systemd-user%20services-1793D1?logo=linux&logoColor=white)](https://www.freedesktop.org/wiki/Software/systemd/)

</div>

---

[English](README.md)

> [!Note]
> [Versión web](https://homelab.ncorrea.com.ar)

Este es mi homelab personal. Corre fotos, archivos, media, DNS/proxy inverso y notificaciones push para uso personal, repartido entre una mini-PC, una Raspberry Pi y un teléfono viejo. Sin CI, sin pipeline de deploy — cada máquina clona este repo y corre sus propios pods localmente.

## Dispositivos

| Hardware                | Rol                                            |
| ------------------------ | ---------------------------------------------- |
| Lenovo ThinkCentre M710q | Servicios principales (fotos, archivos, media) |
| Raspberry Pi 4B          | Gateway de red (DNS, proxy inverso)            |
| Samsung Galaxy S9+       | Relay de notificaciones push                   |

Cada dispositivo tiene su propia carpeta en este repo, con sus propios pods y sus propios archivos `.env`.

## Stack

| Capa                  | Tecnología                                               |
| ---------------------- | --------------------------------------------------------- |
| Orquestación            | Podman Compose, servicios systemd a nivel usuario         |
| Proxy inverso / TLS     | Caddy (desafío DNS de Cloudflare)                          |
| DNS                     | Pi-hole, Unbound                                           |
| Fotos / video           | Immich, PostgreSQL, Redis                                  |
| Gestor de contraseñas   | Vaultwarden                                                |
| CalDAV/CardDAV          | Radicale                                                   |
| Sync / navegador de archivos | Syncthing, Filebrowser                               |
| RSS / manga / ebooks    | Miniflux + PostgreSQL, Suwayomi, Kavita, FlareSolverr       |
| Panel de inicio         | Homepage                                                   |
| Monitoreo               | Uptime Kuma                                                |
| Notificaciones push     | ntfy (en el s9+, sobre Termux + proot-distro Debian)       |
| Red mesh                | Tailscale                                                  |

## Instalación rápida

```bash
git clone https://github.com/ncorrea-13/homelab
cd homelab
```

Copiá el `.env.example` de cada pod y completá los valores reales (ver [Variables de entorno](#variables-de-entorno)):

```bash
# thinkcentre
for pod in core immich entertainment storage utils; do
  cp thinkcentre/pods/$pod/.env.example thinkcentre/pods/$pod/.env
done

# raspberry
for pod in gateway utils; do
  cp raspberry/pods/$pod/.env.example raspberry/pods/$pod/.env
done
cp raspberry/pods/gateway/caddy/caddy.env.example raspberry/pods/gateway/caddy/caddy.env

# s9+
cp s9+/proot-distro/.env.example s9+/proot-distro/.env
```

Las credenciales sensibles van en secrets de Podman, nunca en `.env`:

```bash
echo "tu_contraseña_pihole" | podman secret create pi_password -
```

Levantá un solo pod a mano (solo contenedor, sin systemd):

```bash
cd thinkcentre/pods/immich && podman-compose up -d
```

O, con el template `podman-compose@.service` ya configurado, corré cada pod como servicio de systemd a nivel usuario:

```bash
# en thinkcentre
for pod in core immich entertainment storage utils; do
  systemctl --user enable --now podman-compose@$pod
done

# en raspberry
for pod in gateway utils; do
  systemctl --user enable --now podman-compose@$pod
done
```

### Implementación del celular (s9+)

El s9+ no tiene systemd, así que se configura a mano. Instalá Termux y el add-on Termux:Boot (los dos desde F-Droid), y después, dentro de Termux:

```bash
pkg install openssh proot-distro
proot-distro install debian
proot-distro login debian
apt install cron
# instalar ntfy: ver https://docs.ntfy.sh/install/
```

Después, todavía dentro del rootfs de Debian:

```bash
# copiá s9+/proot-distro/*.sh y el .env a /root/, dales permiso de ejecución

crontab -e
# */5 * * * * /root/check-pi.sh
```

Por último, de vuelta en Termux, copiá `s9+/.termux/boot/start-all.sh` a `~/.termux/boot/` y dale permiso de ejecución — arranca `ntfy-start.sh` (el servidor ntfy) y `check-pi.sh` (chequea el gateway de raspberry, manda una alerta si se cae) al bootear.

## Variables de entorno

| Pod                        | Variable                                                                 | Requerida | Descripción                                        |
| --------------------------- | ------------------------------------------------------------------------- | --------- | --------------------------------------------------- |
| thinkcentre/core         | `TZ`                                                                     | No        | Timezone del contenedor (default `America/Argentina/Buenos_Aires`) |
| thinkcentre/core         | `VAULTWARDEN_ADMIN_TOKEN`                                                | Sí        | Token del panel admin de Vaultwarden                |
| thinkcentre/core         | `VAULTWARDEN_SIGNUPS_ALLOWED`                                            | No        | Permitir registro de nuevas cuentas                 |
| thinkcentre/core         | `VAULTWARDEN_PORT`                                                       | Sí        | Puerto host de Vaultwarden                          |
| thinkcentre/core         | `RADICALE_PORT`                                                          | Sí        | Puerto host de Radicale                             |
| thinkcentre/immich       | `IMMICH_VERSION`                                                         | Sí        | Tag de imagen de Immich                             |
| thinkcentre/immich       | `IMMICH_PORT`                                                            | No        | Puerto host de Immich (default `2283`)              |
| thinkcentre/immich       | `DB_USERNAME` / `DB_PASSWORD` / `DB_DATABASE_NAME`                       | Sí        | Credenciales PostgreSQL de Immich                   |
| thinkcentre/immich       | `DB_DATA_LOCATION`                                                       | Sí        | Path host para datos de Postgres                    |
| thinkcentre/immich       | `UPLOAD_LOCATION`                                                        | Sí        | Path host para media subida                         |
| thinkcentre/entertainment| `SUWAYOMI_PORT`, `FLARESOLVERR_PORT`, `FLARESOLVERR_LOG_LEVEL`           | Sí/No     | Puertos y log level de Suwayomi y FlareSolverr      |
| thinkcentre/entertainment| `MINIFLUX_PORT`, `MINIFLUX_ADMIN_USER`, `MINIFLUX_ADMIN_PASSWORD`        | Sí        | Puerto y login admin de Miniflux                    |
| thinkcentre/entertainment| `MINIFLUX_DB_USER`, `MINIFLUX_DB_NAME`, `MINIFLUX_DB_PASSWORD`, `DATABASE_URL` | Sí   | Credenciales PostgreSQL y URL de conexión de Miniflux |
| thinkcentre/entertainment| `KAVITA_PORT`, `KAVITA_CALIBRE_PATH`, `KAVITA_COMIC_PATH`, `KAVITA_MANGA_PATH` | Sí   | Puerto y paths de bibliotecas de Kavita             |
| thinkcentre/storage      | `SYNCTHING_UI_PORT`, `SYNCTHING_DATA_PATH`                               | Sí        | Puerto de UI y path de datos de Syncthing           |
| thinkcentre/storage      | `FILEBROWSER_PORT`, `FILEBROWSER_ROOT`                                   | Sí        | Puerto y root servido por Filebrowser               |
| thinkcentre/utils        | `TS_DOMAIN`                                                              | Sí        | Dominio de Tailscale usado en las URLs de servicios |
| thinkcentre/utils        | `HOMEPAGE_PORT`, `HOMEPAGE_DOMAIN`, `HOMEPAGE_ALLOWED_HOSTS`             | Sí        | Puerto/dominio/hosts permitidos del dashboard Homepage |
| thinkcentre/utils        | `HOMEPAGE_VAR_OPENWEATHER_KEY`                                           | No        | API key de OpenWeather para el widget del clima     |
| thinkcentre/scripts      | `BACKUP_SOURCE`, `BACKUP_PODMAN_USER`, `BACKUP_PODMAN_UID`               | Sí        | Path fuente del backup y usuario/UID de Podman      |
| thinkcentre/scripts      | `BACKUP_NTFY_URL`, `BACKUP_NTFY_USER`, `BACKUP_NTFY_PASS`                | Sí        | Endpoint de ntfy usado para notificar backups       |
| raspberry/gateway        | `TZ`                                                                     | No        | Timezone del contenedor                             |
| raspberry/gateway        | `PIHOLE_WEB_PORT`, `PIHOLE_TRUSTED_HOSTS`                                | Sí        | Puerto de UI web y hosts confiables de Pi-hole      |
| raspberry/gateway        | `LANDING`                                                                | Sí        | Target de la landing page en Caddy                  |
| raspberry/gateway/caddy  | `ACME_EMAIL`, `CF_API_TOKEN`                                             | Sí        | Email de Let's Encrypt y token API de Cloudflare DNS |
| raspberry/gateway/caddy  | `TS_DOMAIN`, `BIND_IP`, `S9_IP`, `TC_IP`                                 | Sí        | Dominio de Tailscale e IPs de máquinas para el ruteo |
| raspberry/gateway/caddy  | `PORT_*` (HOME, IMMICH, WEBHOOK, NTFY, UPTIME, FILEBROWSER, SUWAYOMI, KAVITA, RADICALE, MINIFLUX, SYNCTHING, PIHOLE, COCKPIT, VAULTWARDEN) | Sí | Puertos upstream a los que Caddy hace proxy inverso |
| raspberry/utils         | `UPTIME_KUMA_PORT`                                                       | Sí        | Puerto de UI web de Uptime Kuma                     |
| raspberry/utils         | `PODMAN_SOCKET`                                                          | No        | Path del socket de Podman monitoreado por Uptime Kuma |
| s9+/proot-distro        | `TZ`                                                                     | No        | Timezone dentro del rootfs Debian de proot-distro   |
| s9+/proot-distro        | `NTFY_BASE_URL`, `NTFY_LISTEN_HTTP`, `NTFY_CACHE_FILE`, `NTFY_AUTH_FILE`, `NTFY_AUTH_DEFAULT_ACCESS` | Sí | Bind, cache y paths de auth del server ntfy |
| s9+/proot-distro        | `GATEWAY_CHECK_URL`, `NTFY_PUSH_URL`                                     | Sí        | URL chequeada del gateway y a dónde mandar la alerta si se cae |

> Las contraseñas de las bases de datos de Immich y Miniflux quedan en el `.env` de cada pod, en vez de un secret de Podman.

## Arquitectura

Cada pod es un proyecto de Podman Compose independiente — reiniciar o actualizar uno no afecta a los demás. El mapeo pod-servicio está en [Estructura del proyecto](#estructura-del-proyecto); qué hace cada servicio está en [Stack](#stack).

## Backups

thinkcentre/scripts/backup.sh corre por cron, recibiendo el directorio destino como único argumento (un path semanal dispara una corrida completa, cualquier otro una incremental diaria):

1. Vuelca la base Postgres de Immich y borra lo que tenga más de 15 días.
2. Respalda el SQLite de Vaultwarden vía un contenedor descartable de sqlite3, mismo criterio de borrado.
3. Sincroniza el origen al destino con rsync, salteando lo ya cubierto arriba. Las corridas diarias también saltean el archivo del NAS y la biblioteca de fotos de Immich; las semanales llevan todo.
4. Loguea cada paso y manda una notificación por ntfy en éxito, éxito parcial o falla.

Ambos pasos de base de datos bajan al usuario Podman rootless para llegar a su socket.

## Página pública de inicio

La versión web linkeada arriba no forma parte de este repositorio — vive en el proyecto portfolio (ncorrea-13/portfolio, carpeta servidor) y sale a internet por un Cloudflare Tunnel en vez del pod gateway, aunque sigue corriendo en la Raspberry Pi.

Sus datos salen de una API de estado en status.ncorrea.com.ar, un proyecto FastAPI separado (ncorrea-13/homelab-status) que guarda las notificaciones webhook de Uptime Kuma en SQLite y las sirve de vuelta para que el dashboard las lea.

## Estructura del proyecto

```
raspberry/
└── pods/
    ├── gateway/            # Pi-hole, Caddy, Unbound
    │   └── caddy/          # Caddyfile, caddy.env.example
    └── utils/              # Uptime Kuma

thinkcentre/
├── pods/
│   ├── core/               # Vaultwarden, Radicale
│   ├── immich/             # Immich, Postgres, Redis
│   ├── entertainment/      # Miniflux, Suwayomi, Kavita, FlareSolverr
│   ├── storage/            # Syncthing, Filebrowser
│   └── utils/              # Homepage
└── scripts/
    └── backup.sh           # Job de backup, notifica vía ntfy

s9+/
├── .termux/boot/
│   └── start-all.sh        # Entrypoint de boot en Termux
└── proot-distro/
    ├── ntfy-start.sh
    └── check-pi.sh
```

## Licencia

Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

_Mendoza, Argentina. Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))_
</content>
</invoke>
