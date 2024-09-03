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
- Flaresolverr: Proxy to allow Prowlarr to bypass Cloudflare and DDoS-GUARD protection


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
| Flaresolverr| 8191 | Requests port |
| Radarr | 7878 | WebUI | 
| Sonarr | 8989 | WebUI | 
| Overseerr | 5055 | WebUI | 
| Tautulli | 8181 | WebUI | 


### Install


### Configuration

#### Deluge

**Plugin: Label**
(Required)

**Plugin: YaRSS2**
(Optional)
I like watching sports - specifically F1 - and Sonarr doesn't handle that well. There's a whole discussion about why, but in short it's that F1 doesn't really have 'seasons' and 'episodes' as Sonarr knows it, and people don't upload it in the SxxxExxx format so Prowlarr / Sonarr can't find it.
So, instead we can install a plugin that will allow custom regex matching, set it up to look for what I'm after, and once the file is downloaded open Sonarr and add the file via Manual Import.

To install the plugin:
1. download the latest version of the `.egg` from the [YaRSS2 downloads page](https://bitbucket.org/bendikro/deluge-yarss-plugin/downloads/)
2. move it to <Deluge config folder/plugins>, eg `/data/dockers/deluge/plugins`
3. remove the `py3.11` reference from the name. eg it will be named `YaRSS2-2.1.5-py3.11.egg`, make it look like `YaRSS2-2.1.5.egg`
4. restart Deluge
5. install it as any other pre-supplied plugin

References:
- [deluge docs](https://deluge-torrent.org/plugins/#InstallingPlugins)
- [YaRSS2 Deluge Plugin](https://deluge-torrent.org/plugins/yarss2/)
- [Forum post explaining troubleshooting steps](https://forum.deluge-torrent.org/viewtopic.php?t=56261)



