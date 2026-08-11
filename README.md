# My Personal Homelab

> (aka Home Server)

> [!Note]
> [Web version](https://homelab.ncorrea.com.ar)

This is my personal homelab.

## Machines

| Hardware                   | Role                                 |
| -------------------------- | ------------------------------------ |
| `Lenovo ThinkCentre M710q` | Main services (photos, files, media) |
| `Raspberry-pi 4B`          | Network gateway (DNS, reverse proxy) |
| `Samsung Galaxy s9+`       | Push notifications relay             |

Each machine has its own folder in this repository, with its own pods and its own `.env` files.

## Architecture

### thinkcentre

Each stack is a separate Podman Compose project, managed as a systemd user service. This keeps things separate, so restarting or updating one pod does not affect the others.

| Pod             | Services                                                                          |
| --------------- | --------------------------------------------------------------------------------- |
| `core`          | Vaultwarden (password manager), Radicale (CalDAV/CardDAV)                         |
| `immich`        | Immich (photos and video), Redis, Postgres                                        |
| `entertainment` | Miniflux (RSS) + Postgres, Suwayomi (manga), Kavita (ebooks/comics), FlareSolverr |
| `storage`       | Syncthing (file sync), Filebrowser (NAS web UI)                                   |
| `utils`         | Homepage (dashboard)                                                              |

### raspberry

| Pod       | Services                                                                                           |
| --------- | -------------------------------------------------------------------------------------------------- |
| `gateway` | Pi-hole (DNS ad-block), Caddy (reverse proxy, TLS via Cloudflare DNS), Unbound (upstream resolver) |
| `utils`   | Uptime Kuma (monitoring)                                                                           |

### s9+

Runs inside a proot-distro Debian rootfs on Termux, started at boot:

- `ntfy-start.sh` starts the Ntfy server, used for push notifications from every machine.
- `check-pi.sh` checks if the raspberry gateway is online and sends a push alert if it is down.

## Public Landing Page

The web version linked at the top of this page is not part of this repository. It lives in the `servidor` directory of [ncorrea-13/portfolio](https://github.com/ncorrea-13/portfolio), and it is exposed through a Cloudflare Tunnel, not through the gateway pod. However, it runs on the Raspberry Pi.

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/ncorrea-13/homelab
cd homelab
```

### 2. Configure each pod

Every pod has its own `.env.example`. Copy it and fill in your values.

```bash
# thinkcentre
for pod in core immich entertainment storage utils; do
  cp thinkcentre/pods/$pod/.env.example thinkcentre/pods/$pod/.env
  vim thinkcentre/pods/$pod/.env
done

# raspberry
for pod in gateway utils; do
  cp raspberry/pods/$pod/.env.example raspberry/pods/$pod/.env
  vim raspberry/pods/$pod/.env
done
cp raspberry/pods/gateway/caddy/caddy.env.example raspberry/pods/gateway/caddy/caddy.env

# s9+
cp s9+/proot-distro/.env.example s9+/proot-distro/.env
vim s9+/proot-distro/.env
```

### 3. Create Podman secrets

Sensitive credentials are stored as Podman secrets and never written to `.env` files.

```bash
echo "your_pihole_password" | podman secret create pi_password -
podman secret ls
```

> **Note**: DB passwords for Immich and Miniflux live in each pod's `.env` file instead of a Podman secret.

### 4. Deploy

Each pod is managed as a systemd user service. If the `podman-compose@.service` template is set up, run this on the right machine:

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

Or bring up a single pod manually:

```bash
cd thinkcentre/pods/immich && podman-compose up -d
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

## License

MIT License. See [LICENSE](LICENSE) for details.

_Mendoza, Argentina. Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))_
