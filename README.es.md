# Mi Homelab Personal

> (aka Home Server)

> [!Note]
> [Versión web](https://homeserver.ncorrea.com.ar)

Este es mi homelab personal.

## Dispositivos

| Hardware                   | Rol                                            |
| -------------------------- | ---------------------------------------------- |
| `Lenovo ThinkCentre M710q` | Servicios principales (fotos, archivos, media) |
| `Raspberry-pi 4B`          | Gateway de red (DNS, proxy inverso)            |
| `Samsung Galaxy s9+`       | Relay de notificaciones push                   |

Cada dispositivo posee su propia carpeta en este repo, con sus propios pods y sus propios archivos `.env`.

## Arquitectura

### thinkcentre

Cada stack es un proyecto de Podman Compose independiente, manejado como servicio de systemd a nivel usuario. Así, si reinicio o actualizo un pod, no afecta a los demás.

| Pod             | Servicios                                                                         |
| --------------- | --------------------------------------------------------------------------------- |
| `core`          | Vaultwarden (gestor de contraseñas), Radicale (CalDAV/CardDAV)                    |
| `immich`        | Immich (fotos y video), Redis, Postgres                                           |
| `entertainment` | Miniflux (RSS) + Postgres, Suwayomi (manga), Kavita (ebooks/comics), FlareSolverr |
| `storage`       | Syncthing (sincronización de archivos), Filebrowser (interfaz web para el NAS)    |
| `utils`         | Homepage (panel de inicio)                                                        |

### raspberry

| Pod       | Servicios                                                                                                    |
| --------- | ------------------------------------------------------------------------------------------------------------ |
| `gateway` | Pi-hole (bloqueo de ads por DNS), Caddy (proxy inverso, TLS con Cloudflare DNS), Unbound (resolver upstream) |
| `utils`   | Uptime Kuma (monitoreo)                                                                                      |

### s9+

Corre dentro de un rootfs de Debian con proot-distro sobre Termux, arrancado al iniciar el teléfono:

- `ntfy-start.sh` levanta el servidor Ntfy, usado para las notificaciones push de todas las máquinas.
- `check-pi.sh` chequea si el gateway de raspberry está online y manda una alerta push si se cae.

## Página pública de inicio

La versión web linkeada arriba no forma parte de este repositorio. Vive en la carpeta `servidor` de [ncorrea-13/portfolio](https://github.com/ncorrea-13/portfolio), y se expone a través de un Cloudflare Tunnel, no del pod gateway. Sin embargo, corre en la Raspberry Pi.

## Instalación

### 1. Cloná el repositorio

```bash
git clone https://github.com/ncorrea-13/homelab
cd homelab
```

### 2. Configurá cada pod

Cada pod tiene su propio `.env.example`. Copialo y completá tus valores.

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

### 3. Creá los secrets de Podman

Las credenciales sensibles se guardan como secrets de Podman y nunca se escriben en los archivos `.env`.

```bash
echo "tu_contraseña_pihole" | podman secret create pi_password -
podman secret ls
```

> **Nota**: las contraseñas de las bases de datos de Immich y Miniflux quedan en el `.env` de cada pod, en vez de un secret de Podman.

### 4. Desplegá

Cada pod se maneja como servicio de systemd a nivel usuario. Con el template `podman-compose@.service` ya configurado, corré esto en la máquina correspondiente:

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

O levantá un solo pod a mano:

```bash
cd thinkcentre/pods/immich && podman-compose up -d
```

En el teléfono s9+, ntfy arranca solo al bootear, a través del `start-all.sh` de Termux.

### 5. Configurá el s9+

El teléfono no usa systemd, así que esta parte es manual.

1. Instalá Termux y el add-on Termux:Boot (los dos desde F-Droid). Termux:Boot es necesario para que `start-all.sh` corra al bootear.
2. Dentro de Termux, instalá openssh y proot-distro:

   ```bash
   pkg install openssh proot-distro
   proot-distro install debian
   ```

3. Entrá al rootfs de Debian e instalá cron y ntfy:

   ```bash
   proot-distro login debian
   apt install cron
   # instalar ntfy: ver https://docs.ntfy.sh/install/
   ```

4. Copiá `s9+/proot-distro/*.sh` y el `.env` a `/root/` dentro del rootfs de Debian, y dales permiso de ejecución.
5. Agregá un cron job dentro del rootfs de Debian para correr `check-pi.sh` cada 5 minutos:

   ```bash
   crontab -e
   # */5 * * * * /root/check-pi.sh
   ```

6. Copiá `s9+/.termux/boot/start-all.sh` a `~/.termux/boot/` en Termux, y dale permiso de ejecución.

## Licencia

Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

_Mendoza, Argentina. Nicolás Correa ([ncorrea-13](https://github.com/ncorrea-13))_
