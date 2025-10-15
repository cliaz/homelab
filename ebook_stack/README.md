# E-Book Stack overview

This stack is purely for management of e-books. It may break if the Core Services and Download stacks are not present.

It consists of the following services:
- **Calibre:** E-book management desktop software for organizing and converting e-books. Amongst other things, it can convert and email eBooks to your devices
- **Calibre-Web:** Web frontend for Calibre with user management and device integration
- **Readarr:** Automated e-book acquisition and management

## Dependencies
It uses the following services from other stacks:
- **Download Stack:** Gluetun (VPN), qBittorrent (torrent client), Prowlarr (indexers)
- **Core Services:** Notifiarr (notifications)

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Calibre | 8080 | KasmVNC WebUI |
| | 8081 | Calibre Content Server |
| Calibre-Web | 8083 | WebUI |
| Readarr | 8787 | WebUI |

## Data Flow
1. **Readarr** searches for and downloads e-books via Prowlarr and qBittorrent
2. **Calibre** stores and organizes the e-book library database
3. **Calibre-Web** provides user-friendly web access to the library
4. **Integration:** Readarr manages the Calibre database automatically

## Important Notes
- **Readarr controls Calibre's database** - Do not manually add/edit books in Calibre
- **No hardlinks recommended** - Readarr is tag-based, changing metadata breaks seeding
- **Separate copies** - Keep download and library copies separate due to metadata changes

## Security Considerations
- Calibre runs with KasmVNC for desktop access
- Calibre-Web provides user authentication and permissions
- All torrent traffic routed through VPN via Download Stack
- Content server integration allows device synchronization

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `CALIBRE_UID`/`MEDIA_GID`: User/group for Calibre
- `CALIBRE_WEB_UID`/`MEDIA_GID`: User/group for Calibre-Web
- `READARR_UID`/`MEDIA_GID`: User/group for Readarr
- `CONFIG_DIR`: Directory for application configurations
- `DATA_DIR`: Directory for e-book library and downloads
- `CALIBRE_VNC_PORT`: VNC port for Calibre (default: 8080)
- `CALIBRE_WEBUI_PORT`: Calibre-Web port (default: 8083)
- `TZ`: Timezone (default: Australia/Melbourne)