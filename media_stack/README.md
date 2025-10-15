# Media Stack overview

This stack is purely for media management and streaming. It may break if the Core Services stack is not present.

It consists of the following services:
- **Plex:** Main media server for streaming movies and TV shows
- **Radarr:** Automated movie management and acquisition
- **Sonarr:** Automated TV show management and acquisition  
- **Overseerr:** Media request management for both Sonarr and Radarr
- **Tautulli:** Plex media server monitoring and statistics

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Plex | 32400 | WebUI |
| Radarr | 7878 | WebUI |
| Sonarr | 8989 | WebUI |
| Overseerr | 5055 | WebUI |
| Tautulli | 8181 | WebUI |

## Data Flow
1. **Overseerr** provides a user-friendly interface for requesting movies and TV shows
2. **Radarr** and **Sonarr** automatically search, download, and organize content
3. **Plex** serves the organized media to clients
4. **Tautulli** monitors Plex usage and provides statistics

## Dependencies
- Requires the **Download Stack** for content acquisition (Prowlarr, qBittorrent, etc.)
- Uses `media_net` and `download_net` Docker networks
- Requires shared storage with the download stack for seamless file management

## Security Considerations
- Plex uses host networking for better performance and device discovery
- GPU transcoding support via `/dev/dri` device mapping
- Proper user/group permissions for media file access

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `PLEX_UID`/`MEDIA_GID`: User/group for Plex
- `RADARR_UID`/`MEDIA_GID`: User/group for Radarr
- `SONARR_UID`/`MEDIA_GID`: User/group for Sonarr
- `TAUTULLI_UID`/`MEDIA_GID`: User/group for Tautulli
- `OVERSEERR_UID` / `OVERSEERR_GID`: User/group for Overseerr
- `CONFIG_DIR`: Directory for application configurations
- `DATA_DIR`: Directory for media files
- `TRANSCODE_DIR`: Directory for Plex transcoding
- `TZ`: Timezone (default: Australia/Melbourne)



