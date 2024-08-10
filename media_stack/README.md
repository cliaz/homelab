## Media stack
This stack is purely for media management. It may break if the Home Services stack is not present

It consists of the following services:
- Plex: Main media server
- Tautulli: Plex media server monitoring service
- Gluetun: VPN client to provide containers secure outbound connectivity
- Deluge: torrent client. Relies on Gluetun
- Radarr: Automated movie management and integration with torrent client
- Sonarr: Same as radarr but for TV shows
- Prowlarr: Torrent indexers proxy


It also has the following services 'built' but not in use.
- Lidarr: Same as radarr but for Music
- sonarr_netimport: A python script to fetch TV shows from tvdb.com and add them to sonarr
- radarr_netimport: Similar to sonarr_netimport but for radarr

### Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Plex | 32400 | WebUI |
| Gluetun | 8112 | Deluge's WebUI | 
| Deluge | - | exposed via Gluetun | 
| Prowlarr | 9696 | WebUI | 
| Radarr | 7878 | WebUI | 
| Sonarr | 8989 | WebUI | 
| Overseerr | 5055 | WebUI | 
| Tautulli | 8181 | WebUI | 
