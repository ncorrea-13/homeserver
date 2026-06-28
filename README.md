# My Personal Homeserver

Personal home server configuration built around privacy, modularity, and low maintenance overhead. Runs on a Lenovo ThinkCentre (i3-6100T, 8GB RAM) on Debian Trixie (amd64), using rootless Podman with systemd user services.

Remote access is handled exclusively through [Tailscale](https://tailscale.com/) — no ports exposed to the public internet.

---

## Architecture

Each stack is an independent Podman Compose project managed as a systemd user service. This keeps concerns isolated: restarting or updating one pod doesn't affect the others.

| Pod | Services |
|---|---|
| `core` | Vaultwarden, Radicale |
| `gateway` | Pi-hole, Unbound |
| `immich` | Immich Server, Machine Learning, Redis, Postgres |
| `miniflux` | Miniflux, Postgres |
| `storage` | Syncthing, Filebrowser, Kavita |
| `suwayomi` | Suwayomi (Tachidesk), FlareSolverr |
| `utils` | Homepage, Uptime Kuma, Ntfy |

### Core

- **Vaultwarden** — Self-hosted Bitwarden-compatible password manager.
- **Radicale** — Lightweight CalDAV/CardDAV server for calendars and contacts.

### Gateway

- **Pi-hole** — Network-wide DNS-based ad and tracker blocking.
- **Unbound** — Local recursive DNS resolver, used as Pi-hole's upstream.

### Immich

- **Immich** — Self-hosted photo and video management with ML-powered search and face recognition.

### Miniflux

- **Miniflux** — Minimalist RSS reader with a built-in Postgres backend.

### Storage

- **Syncthing** — Continuous file synchronization across devices.
- **Filebrowser** — Web-based file manager for NAS access.
- **Kavita** — Self-hosted digital library for ebooks, manga, and comics.

### Suwayomi

- **Suwayomi (Tachidesk)** — Self-hosted manga server compatible with Tachiyomi clients.
- **FlareSolverr** — Cloudflare bypass proxy used by Suwayomi extensions.

### Utils

- **Homepage** — Service dashboard with real-time status widgets.
- **Uptime Kuma** — Lightweight uptime monitoring and alerting.
- **Ntfy** — Self-hosted push notification server.

---

## Hardware & Software Stack

- **Hardware**: Lenovo ThinkCentre M700 (i3-6100T, 8GB RAM)
- **OS**: Debian Trixie (amd64)
- **Container engine**: Rootless Podman with `podman-compose`
- **Service management**: systemd user services (`podman-compose@.service` template)
- **VPN**: Tailscale (MagicDNS for internal service routing)
- **Admin**: Cockpit (system and container monitoring)
- **Storage monitoring**: `smartmontools` + `smartd` with Ntfy alerts

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/ncorrea-13/homeserver
cd homeserver
```

### 2. Configure each pod

Every pod has its own `.env.example`. Copy and fill in your values:

```bash
for pod in core gateway immich miniflux storage suwayomi utils; do
  cp $pod/.env.example $pod/.env
  $EDITOR $pod/.env
done
```

### 3. Create Podman secrets

Sensitive credentials (Pi-hole web password, Miniflux admin password) are stored as Podman secrets and never written to `.env` files:

```bash
echo "your_pihole_password"     | podman secret create pi_password -
echo "your_miniflux_password"   | podman secret create miniflux_admin_password -
```

Verify they exist:

```bash
podman secret ls
```

> **Note**: DB passwords for Immich and Miniflux live in each pod's `.env` file. These are excluded from version control via `.gitignore`.

### 4. Deploy

Each pod is managed as a systemd user service. Assuming the `podman-compose@.service` template is in place:

```bash
for pod in core gateway immich miniflux storage suwayomi utils; do
  systemctl --user enable --now podman-compose@$pod
done
```

Or bring up a single pod manually:

```bash
cd gateway && podman-compose up -d
```

Recommended startup order: `gateway` → `core` → rest.

---

## Security Notes

- All services are accessed exclusively over Tailscale. No ports are forwarded on the router.
- `.env` files are excluded from version control. See `.gitignore`.
- Podman secrets are used for credentials that support `_FILE`-style env vars.
- Pi-hole runs with `network_mode: host` and `NET_BIND_SERVICE` to bind to port 53.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

*Mendoza, Argentina — Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))*## License
