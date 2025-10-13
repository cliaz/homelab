# Download stack overview

This stack is purely for download (content acquisition) and torrent management. It may break if the Core Services stack is not present.

It consists of the following services:
- **Gluetun:** VPN client to provide containers secure outbound connectivity with port forwarding
- **qBittorrent:** Torrent client with built-in RSS support. Relies on Gluetun for VPN connectivity
- **Prowlarr:** Torrent indexers proxy and management
- **FlareSolverr:** Proxy to allow Prowlarr to bypass Cloudflare and DDoS-GUARD protection

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Gluetun | 8080 | qBittorrent WebUI (via VPN) |
| qBittorrent | - | exposed via Gluetun network |
| Prowlarr | 9696 | WebUI |
| FlareSolverr | 8191 | Captcha solver requests |

## Data Flow
1. **Prowlarr**: used by Radarr / Sonarr / Readarr to get torrents
2. **FlareSolverr**: helps Prowlarr bypass protection on sites to get torrents
3. **qBittorrent**: downloads those torrents through the VPN tunnel with optimized port forwarding
4. **Gluetun**: provides VPN connectivity for secure torrenting with automatic port forwarding

## Security Considerations
- All torrent traffic routed through VPN (Gluetun)
- FlareSolverr runs without host volume access
- VPN credentials stored as Docker secrets
- Watchtower monitoring disabled for Gluetun to prevent connection loss

## Installation & Configuration
Below are environment variables to configure. 
For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `HOST_IP`: IP address of the Docker host
- `GLUETUN_UID`/`GLUETUN_GID`: User/group for Gluetun
- `QBITTORRENT_UID`/`MEDIA_GID`: User/group for qBittorrent
- `PROWLARR_UID`/`MEDIA_GID`: User/group for Prowlarr
- `CONFIG_DIR`: Directory for application configurations
- `DATA_DIR`: Directory for downloaded content
- `VPN_SERVICE_PROVIDER`: Your VPN provider
- `SERVER_COUNTRIES`: VPN server countries
- `QBIT_WEBUI_PORT`: qBittorrent WebUI port (optional, default: 8080)