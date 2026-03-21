# Infraestructura Modular Home Server en Raspberry Pi 4

Este proyecto describe una arquitectura de home server robusta, modular y segura, diseñada para Raspberry Pi 4. Convierte tu Pi en el núcleo de servicios domésticos esenciales aprovechando contenedores y herramientas punteras como Tailscale, OpenMediaVault y Homepage, con soporte técnico avanzado usando Cocktail.

---

## Tabla de Contenidos

- [Visión General](#visión-general)
- [Requisitos de Hardware y Software](#requisitos-de-hardware-y-software)
- [Arquitectura de Servicios](#arquitectura-de-servicios)
  - [Gateway](#gateway)
  - [Utils](#utils)
  - [Immich](#immich)
- [Integración con herramientas clave](#integración-con-herramientas-clave)
  - [Tailscale](#tailscale-seguridad-remota)
  - [OpenMediaVault](#openmediavault-almacenamiento)
  - [Homepage](#homepage-dashboard-central)
  - [Cocktail](#cocktail-gestion-tecnica-avanzada)
- [Automatización y Respaldo](#automatización-y-respaldo)
- [Configuración mediante Variables de Entorno](#configuración-mediante-variables-de-entorno)
- [Puesta en Marcha](#puesta-en-marcha)
- [Buenas Prácticas y Mantenimiento](#buenas-prácticas-y-mantenimiento)
- [Extensión y Soporte](#extensión-y-soporte)
- [Referencias y Recursos](#referencias-y-recursos)

---

## Visión General

Esta solución consolida en una sola plataforma los servicios clave para una red doméstica moderna: bloqueo de publicidad, gestión de contraseñas, almacenamiento multimedia, backups y sincronización de archivos. El diseño prioriza seguridad, resiliencia y facilidad de gestión, utilizando tecnologías open source consolidadas.

### Diagrama de alto nivel

```
 Internet
    │
  Tailscale (VPN)
    │
[ Pi-hole | Vaultwarden | Unbound ] ─── stack "gateway"
[ Immich (fotos + AI) ]              ─── stack "immich"
[ Syncthing | Filebrowser | ... ]    ─── stack "utils"
    │
 OpenMediaVault (almacenamiento y dashboard de discos)
    │
 Homepage (dashboard general)
    │
Cocktail (opcional: monitoreo técnico de contenedores)
```

*Nota: Homepage y OMV son los dashboards principales. Cocktail es opcional y útil para visualizar detalles técnicos de pods/containers.*

---

## Requisitos de Hardware y Software

- **Raspberry Pi 4** (mínimo 4 GB de RAM recomendado)
- Almacenamiento externo confiable (SSD/NAS)
- Sistema base: Debian/Raspberry Pi OS/Armbian
- [OpenMediaVault](https://www.openmediavault.org/) instalado y operativo
- Docker o Podman con soporte para Compose

---

## Arquitectura de Servicios

El sistema separa funcionalidades en tres grandes pilas para simplificar la administración y los backups:

### Gateway

Servicio crítico de red y seguridad:

- **Pi-hole**: Filtro avanzando de publicidad y rastreadores para toda la LAN
- **Vaultwarden**: Password manager self-hosted compatible con Bitwarden Apps
- **Unbound**: DNS recursivo privado para mejorar privacidad y velocidad

### Utils

Herramientas de productividad y monitoreo:

- **Homepage**: Dashboard centralizado para enlaces, estados y accesos rápidos
- **Syncthing**: Sincronización automática de archivos y dispositivos
- **Uptime-Kuma**: Monitor de salud y disponibilidad de servicios
- **Filebrowser**: Gestor de archivos web amigable, con soporte SMB/NFS

### Immich

Solución de fotos y videos autoalojada, tipo Google Photos:

- **Immich**: IA para reconocimiento, gestión multimedia y subida automática
- **Machine Learning, Redis, Postgres**: Backend optimizado especialmente para Raspberry Pi

Cada stack se despliega de manera aislada mediante archivos `compose.yaml`, facilitando actualización y troubleshooting independiente.

---

## Integración con herramientas clave

### Tailscale (seguridad remota)

Despliega una red VPN wireguard con configuración mínima, ideal para acceder a tu servidor de manera segura desde cualquier parte sin exponer puertos.

**Instalación base:**

```
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey tu-key
```

Más información en la [documentación oficial](https://tailscale.com/kb/).

### OpenMediaVault (almacenamiento y dashboard)

Gestiona discos, raids, cuotas y comparticiones (NFS/SMB) mediante una interfaz web intuitiva (dashboard de almacenamiento principal). Esencial para estructurar el almacenamiento consumido por los contenedores.

### Homepage (dashboard central)

Dashboard web principal para monitorizar el estado global, acceder a servicios y enlaces rápidos de tu home server.

### Cocktail (gestión técnica avanzada)

Herramienta opcional ideal para visualizar, monitorear y gestionar contenedores y pods a bajo nivel. Útil para debugging, reinicio manual o ajustes avanzados de los stacks.

---

## Automatización y Respaldo

El script `/scripts/backup_nas.sh` automatiza los backups:

- Dump SQL de Immich y respaldo binario atómico de Vaultwarden
- Sincronización incremental de carpetas críticas vía `rsync`
- Rotación automática manteniendo backups por 15 días
- Logging detallado y chequeo básico de salud (voltaje, integridad)

Se recomienda agendar este script en `cron` o `anacron` según la criticidad de tus datos.

---

## Configuración mediante Variables de Entorno

Toda la parametrización (credenciales, rutas, parámetros de red, tokens) se centraliza en `.env`. Renombrá y editá `.env.example` antes de iniciar los servicios.

Aspectos clave:

- Token de admin de Vaultwarden y claves de servicios
- Rutas de discos, ubicaciones de backups, etc.
- Hosts confiables y dominio de Tailscale para integración LAN/VPN

---

## Puesta en Marcha

1. Cloná el repositorio y copiate `.env.example` a `.env`, completando los valores necesarios para tu entorno
2. Configurá discos y comparticiones en OpenMediaVault
3. Deploy de cada stack de servicios (adaptá a tu motor preferido):

   ```bash
   docker compose -f gateway/compose.yaml up -d
   docker compose -f immich/compose.yaml up -d
   docker compose -f utils/compose.yaml up -d
   # o podman-compose si administrás rootless
   ```

4. Verificá que los endpoints estén activos y funcionando (Homepage, OMV, Pi-hole, etc.)
5. Activá Tailscale y accedé de forma remota y segura
6. Agendá backup automatizado y monitoreá periódicamente

---

## Buenas Prácticas y Mantenimiento

- Actualizá imágenes y dependencias periódicamente (`docker compose pull && up -d`)
- Restringí acceso externo vía VPN y limitá exposición de servicios públicos
- Guardá las contraseñas y tokens sólo en `.env` (no versionar)
- Monitoreá activamente logs, recursos y alertas de backup
- Chequeá temperatura y uso de almacenamiento de tu Pi4 regularmente
- Revisá integridad de backups y ejecutá restauraciones de validación cada cierto tiempo

---

## Extensión y Soporte

La estructura de stacks independientes permite adicionar servicios, testear upgrades o integrar nuevas herramientas sin afectar el resto de la infraestructura. El stack puede ser adaptado a otras plataformas ARM o incluso trasladado a equipos más potentes manteniendo la misma lógica modular.

---

## Referencias y Recursos

- [OpenMediaVault](https://www.openmediavault.org/)
- [Tailscale](https://tailscale.com/kb/)
- [Cocktail](https://cocktail.tools/docs/)
- [Immich](https://immich.app/docs/)
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Pi-hole](https://docs.pi-hole.net/)
- [Homepage](https://gethomepage.dev)

---

Proyecto diseñado para usuarios avanzados y entusiastas del autohosting: seguro, resiliente y flexible. Para consultas, mejoras o contribuciones, usá las issues o mandá PR.
