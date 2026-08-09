# My Personal Homeserver

> [!Note]
> [Web version](https://homeserver.ncorrea.com.ar)

This is my personal home server. It runs on three machines, and every service stays inside a Tailscale network with no ports open to the public internet.

---

## Machines

| Machine      | Role                                    | Hardware                            |
| ------------ | ---------------------------------------- | ------------------------------------ |
| `thinkcenter` | Main services (photos, files, media)    | Lenovo ThinkCentre M710q (i3-6100T, 8GB RAM), Debian Trixie |
| `raspberry`   | Network gateway (DNS, reverse proxy)    | Raspberry Pi                        |
| `s9+`         | Push notifications relay                 | Old Samsung Galaxy S9+, Termux, proot-distro (Debian) |

Each machine has its own folder in this repository, with its own pods and its own `.env` files.

---

## Architecture

### thinkcenter

Each stack is a separate Podman Compose project, managed as a systemd user service. This keeps things separate, so restarting or updating one pod does not affect the others.

| Pod             | Services                                                                        |
| ---------------- | -------------------------------------------------------------------------------- |
| `core`           | Vaultwarden (password manager), Radicale (CalDAV/CardDAV)                      |
| `immich`         | Immich (photos and video, ML search), Redis, Postgres                          |
| `entertainment`  | Miniflux (RSS) + Postgres, Suwayomi (manga), Kavita (ebooks/comics), FlareSolverr |
| `storage`        | Syncthing (file sync), Filebrowser (NAS web UI)                                |
| `utils`          | Homepage (dashboard)                                                           |

### raspberry

| Pod       | Services                                                       |
| ---------- | ---------------------------------------------------------------- |
| `gateway` | Pi-hole (DNS ad-block), Caddy (reverse proxy, TLS via Cloudflare DNS), Unbound (upstream resolver) |
| `utils`   | Uptime Kuma (monitoring)                                        |

### s9+

Runs inside a proot-distro Debian rootfs on Termux, started at boot:

- `ntfy-start.sh` starts the Ntfy server, used for push notifications from every machine.
- `check-pi.sh` checks if the raspberry gateway is online and sends a push alert if it is down.

---

## Public Landing Page

The web version linked at the top of this page (`homeserver.ncorrea.com.ar`) is not part of this repository. It lives in the `servidor` folder of [ncorrea-13/portfolio](https://github.com/ncorrea-13/portfolio), and it is exposed through a Cloudflare Tunnel, not through the gateway pod.

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/ncorrea-13/homeserver
cd homeserver
```

### 2. Configure each pod

Every pod has its own `.env.example`. Copy it and fill in your values.

```bash
# thinkcenter
for pod in core immich entertainment storage utils; do
  cp thinkcenter/pods/$pod/.env.example thinkcenter/pods/$pod/.env
  $EDITOR thinkcenter/pods/$pod/.env
done

# raspberry
for pod in gateway utils; do
  cp raspberry/pods/$pod/.env.example raspberry/pods/$pod/.env
  $EDITOR raspberry/pods/$pod/.env
done
cp raspberry/pods/gateway/caddy/caddy.env.example raspberry/pods/gateway/caddy/caddy.env

# s9+
cp s9+/proot-distro/.env.example s9+/proot-distro/.env
$EDITOR s9+/proot-distro/.env
```

### 3. Create Podman secrets

Sensitive credentials (Pi-hole web password) are stored as Podman secrets and never written to `.env` files.

```bash
echo "your_pihole_password" | podman secret create pi_password -
```

Verify it exists:

```bash
podman secret ls
```

> **Note**: DB passwords for Immich and Miniflux live in each pod's `.env` file instead of a Podman secret.

### 4. Deploy

Each pod is managed as a systemd user service. If the `podman-compose@.service` template is set up, run this on the right machine:

```bash
# on thinkcenter
for pod in core immich entertainment storage utils; do
  systemctl --user enable --now podman-compose@$pod
done

# on raspberry
for pod in gateway utils; do
  systemctl --user enable --now podman-compose@$pod
done
```

Or bring up a single pod manually:

```bash
cd thinkcenter/pods/immich && podman-compose up -d
```

On the s9+ phone, ntfy starts automatically at boot through Termux's `start-all.sh`.

### 5. Set up s9+

The phone does not use systemd, so this part is manual.

1. Install Termux and the Termux:Boot add-on (both from F-Droid). Termux:Boot is required for `start-all.sh` to run at boot.
2. Inside Termux, install openssh and proot-distro:
   ```bash
   pkg install openssh proot-distro
   proot-distro install debian
   ```
3. Log into the Debian rootfs and install cron and ntfy:
   ```bash
   proot-distro login debian
   apt install cron
   # install ntfy: see https://docs.ntfy.sh/install/
   ```
4. Copy `s9+/proot-distro/*.sh` and `.env` into `/root/` inside the Debian rootfs, and make the scripts executable.
5. Add a cron job inside the Debian rootfs to run `check-pi.sh` every 5 minutes:
   ```bash
   crontab -e
   # */5 * * * * /root/check-pi.sh
   ```
6. Copy `s9+/.termux/boot/start-all.sh` into `~/.termux/boot/` in Termux, and make it executable.

---

## Security Notes

- `.env` files are not tracked in version control. See `.gitignore`.
- Podman secrets are used for credentials that support `_FILE` style env vars.
- Pi-hole runs with `network_mode: host` and `NET_BIND_SERVICE` to bind to port 53.
- Scripts on s9+ read values from `.env` and stop with an error if a value is missing, instead of using a fixed value in the code.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

_Mendoza, Argentina. Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))_
