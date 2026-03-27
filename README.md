# My personal homeserver

This repository contains the configuration and architecture of my personal home server, a project built to centralize my digital life. Designed to run on a Raspberry Pi 4, this setup focuses on privacy, modularity, and security, leveraging containerized services and high-performance tools like Tailscale, OpenMediaVault, and Cockpit.

## Architecture & Services

The infrastructure is divided into independent stacks to simplify management and backups:

#### Gateway (Core Networking)
- Pi-hole: Network-wide ad and tracker blocking.
- Unbound: Recursive DNS resolver for enhanced privacy.
- Vaultwarden: Lightweight, self-hosted Bitwarden-compatible password manager.

#### Utils (Productivity)
- Homepage: A sleek, centralized dashboard for all services.
- Syncthing: Continuous file synchronization across devices.
- Uptime-Kuma: Self-hosted uptime monitoring.
- Filebrowser: Web-based file manager with SMB/NFS support.

#### Immich
- Immich: High-performance self-hosted photo and video management (Google Photos alternative) with AI-powered recognition.

## Hardware & Software Stack
- Hardware: Raspberry Pi 4B (4GB+ RAM recommended).
- OS: Debian / Raspberry Pi OS Lite.
- Container Engine: Podman (or Docker) with Compose support.
- Storage: [OpenMediaVault](https://www.openmediavault.org/) for RAID and share management.
- VPN: [Tailscale](https://tailscale.com/) for zero-config secure remote access.
- Admin: [Cockpit](https://cockpit-project.org/) for low-level container and system monitoring.

## Quick Start

1. Clone & Configure:
```bash
git clone https://github.com/ncorrea-13/homeserver
cp .env.example .env
# Edit .env with your specific paths and credentials
```

2. Storage: Set up your drives and shared folders in OpenMediaVault.

3. Deploy Stacks:
```bash
# Deploying with podman-compose or docker-compose
podman-compose -f gateway/compose.yaml up -d
podman-compose -f immich/compose.yaml up -d
podman-compose -f utils/compose.yaml up -d
```
4. Access: Open your browser at your Pi's IP to access the Homepage dashboard.

## Automation & Backup

The included scripts/backup_nas.sh handles data integrity:

- Database Dumps: Atomic backups for Immich (Postgres) and Vaultwarden.
- Incremental Sync: Uses rsync for critical data folders.
- Retention: 15-day automatic rotation.
- Health Checks: Monitors system voltage and backup logs.
> Tip: Schedule this via cron to ensure your data is always safe.

## Best Practices
- Security: Access services via Tailscale VPN; avoid exposing ports to the public internet.
- Maintenance: Regularly run podman-compose pull to keep images updated.
- Environment: Never commit your .env file to version control.
- Monitoring: Periodically check Pi temperature and disk health via Cockpit.

## Sources
## Sources

- [OpenMediaVault](https://www.openmediavault.org/) | [Tailscale](https://tailscale.com/kb/) | [Cockpit](https://cockpit-project.org/)
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden) | [Pi-hole](https://docs.pi-hole.net/) | [Unbound](https://nlnetlabs.nl/projects/unbound/about/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma) | [Homepage](https://gethomepage.dev) | [Syncthing](https://syncthing.net/) | [Filebrowser](https://filebrowser.org/)
- [Immich](https://immich.app/docs/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*Mendoza, Argentina — Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))*
