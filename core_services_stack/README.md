# Core Services stack overview

This stack provides foundational services that support other stacks in the homelab. It should be able to run independently of other stacks, however other stacks may rely on it.

It consists of the following services:
- **Swag:** Reverse proxy with automatic SSL certificates and dynamic DNS updates
- **Cloudflared:** Cloudflare tunnel for secure external access without public IP
- **AdGuard Home:** DNS service for ad blocking and internal service naming
- **Homarr:** Configurable dashboard for all homelab services
- **Notifiarr:** Notification aggregator for Discord and other platforms
- **Wyze-bridge:** Wyze camera feed aggregator for local RTSP streams

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Swag | 443 | HTTPS reverse proxy |
| | 81 | Swag dashboard |
| AdGuard Home | 53 | DNS |
| | 80 | WebUI |
| | 853 | DNS over TLS |
| | 3000 | Initial setup |
| | 4443 | WebUI (alternate) |
| | 5443 | WebUI (alternate) |
| Homarr | 7575 | WebUI |
| Notifiarr | 5454 | WebUI |
| Wyze Bridge | 5000 | WebUI |
| | 8554 | RTSP streams |
| | 8888 | HLS streams |
| | 8189 | WebRTC/ICE streams |

## Data Flow
1. **Swag** acts as the main entry point, providing reverse proxy and SSL termination
2. **Cloudflared** provides an alternative tunnel-based access method
3. **AdGuard Home** handles DNS resolution and ad blocking for the entire network
4. **Homarr** provides a unified dashboard for accessing all services
5. **Notifiarr** aggregates notifications from various services
6. **Wyze-bridge** converts Wyze cameras to standard RTSP streams

## Security Considerations
- SSL certificates automatically managed by Let's Encrypt
- DNS challenge validation for wildcard certificates
- Cloudflare tunnel provides secure access without exposing ports
- AdGuard Home blocks malicious domains at DNS level
- Wyze-bridge runs as root (required for camera access)

## Network Architecture
The stack creates and manages several Docker networks:
- `core_services_net`: Core infrastructure services
- `media_net`: Media-related services
- `download_net`: Download and torrent services
- `ebooks_net`: E-book management services

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `HOST_IP`: IP address of the Docker host
- `SWAG_UID`/`SWAG_GID`: User/group for Swag
- `SWAG_URL`: Your domain name for SSL certificates
- `CLOUDFLARE_UID`/`CLOUDFLARE_GID`: User/group for Cloudflared
- `ADGUARD_UID`/`ADGUARD_GID`: User/group for AdGuard Home
- `HOMARR_UID`/`HOMARR_GID`: User/group for Homarr
- `NOTIFIARR_UID`/`NOTIFIARR_GID`: User/group for Notifiarr
- `CONFIG_DIR`: Directory for application configurations
- `SECRETS`: Directory for Docker secrets
- `TZ`: Timezone (default: Australia/Melbourne)

## Service Details

### Swag 
### Swag
Swag acts as a reverse proxy for services, meaning we don't need to expose loads of ports on our home network - we simply expose `443`, set up the services with DNS names, and access the services via DNS requests. Swag will also generate SSL certificates for everything.

- Uses nginx proxy-confs to proxy services
- Uses nginx site-confs to configure what the default homepage is
- Using DNS challenge to get an SSL certificate from Let's Encrypt
  - [DNS-01 challenge documentation](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
  - [DuckDNS validation setup](https://docs.linuxserver.io/general/swag/#create-container-via-duckdns-validation-with-a-wildcard-cert)

#### Swag Mods
Linuxserver images often have mods you can configure for their containers. [Available Swag mods](https://mods.linuxserver.io/?mod=swag)

We are using:
- **Auto-reload**: Allows us to make edits to the underlying config files that nginx uses, and they'll be reloaded on the fly
- **Dashboard**: Gives live overview of what services are running, what's proxied/exposed, and if there are updates