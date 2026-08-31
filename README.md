<div align="center">

# My Personal Homelab

**Self-hosted infra across three machines, managed as Podman Compose pods and systemd user services**

</div>

---

[Español](README.es.md)

> [!Note]
> [Web version](https://homelab.ncorrea.com.ar)

## Machines

| Hardware                 | Role                                 |
| ------------------------ | ------------------------------------ |
| Lenovo ThinkCentre M710q | Main services (photos, files, media) |
| Raspberry Pi 4B          | Network gateway (DNS, reverse proxy) |
| Samsung Galaxy S9+       | Push notifications relay             |

Each machine has its own folder in this repo, with its own pods and its own `.env` files.

## Stack

| Layer                | Tech                                                  |
| -------------------- | ----------------------------------------------------- |
| Orchestration        | Podman Compose, systemd user services                 |
| Reverse proxy / TLS  | Caddy                                                 |
| DNS                  | Pi-hole, Unbound                                      |
| Photos / video       | Immich, PostgreSQL, Redis                             |
| Password manager     | Vaultwarden                                           |
| CalDAV/CardDAV       | Radicale                                              |
| File sync / browser  | Syncthing, Filebrowser                                |
| RSS / manga / ebooks | Miniflux + PostgreSQL, Suwayomi, Kavita, FlareSolverr |
| Dashboard            | Homepage                                              |
| Monitoring           | Uptime Kuma                                           |
| Push notifications   | ntfy                                                  |
| Networking mesh      | Tailscale                                             |

## Quick Start

```bash
git clone https://github.com/ncorrea-13/homelab
cd homelab
```

Copy each pod's `.env.example` and fill in real values (see [Environment variables](#environment-variables)):

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

Sensitive credentials go in Podman secrets, never in `.env` (see [Secrets](#secrets)):

```bash
echo "your_pihole_password" | podman secret create pi_password -
```

Bring up a single pod manually (container-only path, no systemd needed):

```bash
cd thinkcentre/pods/immich && podman-compose up -d
```

Or, once the `podman-compose@.service` template is set up, run each pod as a systemd user service:

```bash
# on thinkcentre
for pod in core immich entertainment storage utils; do
  systemctl --user enable --now podman-compose@$pod
done

# on raspberry
for pod in gateway utils; do
  systemctl --user enable --now podman-compose@$pod
done
```

### Termux

When deploying to a phone, note it has no init process, but does have an add-on substitute.

Install Termux and the Termux:Boot add-on from their repos or from F-Droid (never from the Play Store), then inside Termux:

```bash
pkg install openssh proot-distro
proot-distro install debian
proot-distro login debian
apt install cron
# install ntfy: see https://docs.ntfy.sh/install/
```

Then, still inside the Debian rootfs:

```bash
# copy s9+/proot-distro/*.sh and .env into /root/, make the scripts executable

crontab -e
# */5 * * * * /root/check-pi.sh
```

Finally, back in Termux, copy `s9+/.termux/boot/start-all.sh` into `~/.termux/boot/` and make it executable. Now, on boot and opening the Termux:Boot app, it starts `sshd`, `ntfy-start.sh`, and `check-pi.sh`.

## Environment variables

| Pod                       | Variable                                                                                                                                   | Required | Description                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------- | --------------------------------------------------------------------- |
| thinkcentre/core          | `TZ`                                                                                                                                       | No       | Container timezone (default `America/Argentina/Buenos_Aires`)         |
| thinkcentre/core          | `VAULTWARDEN_SIGNUPS_ALLOWED`                                                                                                              | No       | Allow new account signups                                             |
| thinkcentre/core          | `VAULTWARDEN_PORT`                                                                                                                         | Yes      | Vaultwarden host port                                                 |
| thinkcentre/core          | `RADICALE_PORT`                                                                                                                            | Yes      | Radicale host port                                                    |
| thinkcentre/immich        | `IMMICH_VERSION`                                                                                                                           | Yes      | Immich image tag                                                      |
| thinkcentre/immich        | `IMMICH_PORT`                                                                                                                              | Yes      | Immich host port                                                      |
| thinkcentre/immich        | `IMMICH_DB_USER` / `IMMICH_DB_NAME`                                                                                                        | Yes      | Immich PostgreSQL user/database name                                  |
| thinkcentre/immich        | `IMMICH_DB_LOCATION`                                                                                                                       | Yes      | Host path for Postgres data                                           |
| thinkcentre/immich        | `IMMICH_UPLOAD_LOCATION`                                                                                                                   | Yes      | Host path for uploaded media                                          |
| thinkcentre/entertainment | `SUWAYOMI_PORT`, `FLARESOLVERR_PORT`, `FLARESOLVERR_LOG_LEVEL`                                                                             | Yes/No   | Suwayomi and FlareSolverr host ports/log level                        |
| thinkcentre/entertainment | `MINIFLUX_PORT`, `MINIFLUX_ADMIN_USER`                                                                                                     | Yes      | Miniflux port and admin login                                         |
| thinkcentre/entertainment | `MINIFLUX_DB_USER`, `MINIFLUX_DB_NAME`                                                                                                     | Yes      | Miniflux PostgreSQL user/database name                                |
| thinkcentre/entertainment | `KAVITA_PORT`, `KAVITA_CALIBRE_PATH`, `KAVITA_COMIC_PATH`, `KAVITA_MANGA_PATH`                                                             | Yes      | Kavita port and library host paths                                    |
| thinkcentre/storage       | `SYNCTHING_UI_PORT`, `SYNCTHING_DATA_PATH`                                                                                                 | Yes      | Syncthing web UI port and data path                                   |
| thinkcentre/storage       | `FILEBROWSER_PORT`, `FILEBROWSER_ROOT`                                                                                                     | Yes      | Filebrowser port and served root path                                 |
| thinkcentre/utils         | `TS_DOMAIN`                                                                                                                                | Yes      | Tailscale domain used for service URLs                                |
| thinkcentre/utils         | `HOMEPAGE_PORT`, `HOMEPAGE_DOMAIN`, `HOMEPAGE_ALLOWED_HOSTS`                                                                               | Yes      | Homepage dashboard port/domain/allowed hosts                          |
| thinkcentre/utils         | `HOMEPAGE_VAR_OPENWEATHER_KEY`                                                                                                             | No       | OpenWeather API key for the weather widget                            |
| thinkcentre/scripts       | `BACKUP_SOURCE`, `BACKUP_PODMAN_USER`, `BACKUP_PODMAN_UID`                                                                                 | Yes      | Backup script source path and Podman user/UID                         |
| thinkcentre/scripts       | `BACKUP_NTFY_URL`, `BACKUP_NTFY_USER`, `BACKUP_NTFY_PASS`                                                                                  | Yes      | ntfy endpoint used for backup notifications                           |
| raspberry/gateway         | `TZ`                                                                                                                                       | No       | Container timezone                                                    |
| raspberry/gateway         | `PIHOLE_WEB_PORT`, `PIHOLE_TRUSTED_HOSTS`                                                                                                  | Yes      | Pi-hole web UI port and trusted host list                             |
| raspberry/gateway         | `LANDING`                                                                                                                                  | Yes      | Caddy landing page target                                             |
| raspberry/gateway/caddy   | `ACME_EMAIL`                                                                                                                               | Yes      | Let's Encrypt email                                                   |
| raspberry/gateway/caddy   | `TS_DOMAIN`, `BIND_IP`, `S9_IP`, `TC_IP`                                                                                                   | Yes      | Tailscale domain and machine IPs used in routing                      |
| raspberry/gateway/caddy   | `PORT_*` (HOME, IMMICH, WEBHOOK, NTFY, UPTIME, FILEBROWSER, SUWAYOMI, KAVITA, RADICALE, MINIFLUX, SYNCTHING, PIHOLE, COCKPIT, VAULTWARDEN) | Yes      | Upstream ports Caddy reverse-proxies to                               |
| raspberry/utils           | `UPTIME_KUMA_PORT`                                                                                                                         | Yes      | Uptime Kuma web UI port                                               |
| raspberry/utils           | `PODMAN_SOCKET`                                                                                                                            | No       | Podman socket path monitored by Uptime Kuma                           |
| raspberry/utils           | `STATUS_PORT`, `ALLOWED_ORIGIN`                                                                                                            | Yes      | homelab-status-api host port and allowed CORS origin                  |
| s9+/proot-distro          | `TZ`                                                                                                                                       | No       | Timezone inside the proot-distro Debian rootfs                        |
| s9+/proot-distro          | `NTFY_BASE_URL`, `NTFY_LISTEN_HTTP`, `NTFY_CACHE_FILE`, `NTFY_AUTH_FILE`, `NTFY_AUTH_DEFAULT_ACCESS`                                       | Yes      | ntfy server bind address, cache/auth file paths                       |
| s9+/proot-distro          | `GATEWAY_CHECK_URL`, `NTFY_PUSH_URL`                                                                                                       | Yes      | URL polled to check the gateway and where to push alerts if it's down |

## Secrets

Every credential below is an external Podman secret, created once before bringing up its pod, never written to `.env`:

```bash
echo "value" | podman secret create <name> -
```

| Secret                     | Pod                       | Purpose                                |
| -------------------------- | -------------------------- | --------------------------------------- |
| `pi_password`               | raspberry/gateway          | Pi-hole web UI password                 |
| `cf_api_token`               | raspberry/gateway/caddy    | Cloudflare DNS API token for ACME       |
| `webhook_secret`             | raspberry/utils            | homelab-status-api webhook auth         |
| `vaultwarden_admin_token`    | thinkcentre/core           | Vaultwarden admin panel token           |
| `miniflux_db_password`       | thinkcentre/entertainment  | Miniflux PostgreSQL password            |
| `miniflux_admin_password`    | thinkcentre/entertainment  | Miniflux admin login password           |
| `miniflux_db_url`            | thinkcentre/entertainment  | Miniflux PostgreSQL connection URL      |
| `immich_db_password`         | thinkcentre/immich         | Immich PostgreSQL password              |

## Architecture

Each pod maps to separate containers, orchestrated as Pods to share infrastructure between them, organizing them both at the file level and by capability. Restarting or updating one does not affect the others.

## Backups

Only the data server has periodic backups, since it holds the most and the most relevant data. thinkcentre/scripts/backup.sh runs via cron, taking the destination directory as its only argument:

1. Dumps the Immich Postgres database and prunes anything older than 15 days.
2. Backs up the Vaultwarden SQLite file through a throwaway sqlite3 container, same pruning rule.
3. Syncs the source to the destination with rsync, skipping what's already covered above. Daily runs also skip the NAS archive and the Immich photo library; weekly runs take everything.
4. Logs each step and sends an ntfy notification on success, partial success, or failure.

## Public Landing Page

The web version linked above isn't part of this repository. It's an extension of my [portfolio](https://github.com/ncorrea-13/portfolio/tree/main/servidor) and reaches the internet through a Cloudflare Tunnel.

Its data comes from a status API at <https://status.ncorrea.com.ar>, a separate FastAPI project in this [repo](https://github.com/ncorrea-13/homelab-status) that stores Uptime Kuma's webhook notifications in SQLite and serves them back for the dashboard to read.

## Project Structure

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
    └── backup.sh           # Backup job

s9+/
├── .termux/boot/
│   └── start-all.sh        # Boot entrypoint on Termux
└── proot-distro/
    ├── ntfy-start.sh
    └── check-pi.sh
```

## License

MIT License. See [LICENSE](LICENSE) for details.

_Mendoza, Argentina. Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))_
</content>
</invoke>
