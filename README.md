# My personal homeserver

This repository contains the configuration and architecture of my personal home server, a project built to centralize my digital life. Designed to run on a Raspberry Pi 4, this setup focuses on privacy, modularity, and security, leveraging containerized services and high-performance tools like Tailscale, OpenMediaVault, and Cockpit.

## Architecture & Services

The infrastructure is divided into independent stacks to simplify management and backups:

#### Core

- **Vaultwarden**: Self-hosted Bitwarden-compatible password manager (no cloud leaks).
- Radicale: A lightweight CalDAV/CardDAV server to host calendars and contacts, compatible with most clients.

#### Gateway

- Unbound: A DNS resolver that provides additional privacy and performance for your network, running as a local recursive DNS server.
- **Pi-hole**: Network-wide DNS filtering for ads and trackers, directly on your LAN.

#### Storage

- Syncthing: Continuous file synchronization across devices.
- Filebrowser: Web-based file manager with SMB/NFS support.
- Kavita: A self-hosted digital library manager for ebooks, comics, and manga.

#### Utils

- Homepage: Modern dashboard for quick access to all your services in one place.
- Uptime Kuma: Simple status page monitoring for your main services.

#### Immich

- Immich: High-performance self-hosted photo and video management with AI-powered recognition.

## Hardware & Software Stack

- Hardware: Raspberry Pi 4B (4GB+ RAM recommended).
- OS: Debian / Raspberry Pi OS Lite.
- Container Engine: Podman (or Docker) with Compose support.
- Storage: [OpenMediaVault](https://www.openmediavault.org/) for RAID and share management.
- VPN: [Tailscale](https://tailscale.com/) for zero-config secure remote access.
- Admin: [Cockpit](https://cockpit-project.org/) for low-level container and system monitoring.
- Backup scripts (with logging), for your home files and Immich database.

## Quick Start

1. Clone & Configure:

```bash
git clone https://github.com/ncorrea-13/homeserver
cp .env.example .env
# Edit .env with your specific paths and credentials
```

1. Storage: Set up your drives and shared folders in OpenMediaVault.

2. Deploy Stacks:

```bash
# Deploying with podman-compose or docker-compose
podman-compose -f gateway/compose.yaml up -d
podman-compose -f immich/compose.yaml up -d
podman-compose -f utils/compose.yaml up -d
```

1. Access: Open your browser at your Pi's IP to access the Homepage dashboard.

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*Mendoza, Argentina — Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))*
