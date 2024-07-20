# Homelab
This repo contains a bunch of different docker stacks designed to do different things. They are also coupled in certain ways (eg. shared docker networks), which means deploying a stack individually may cause issues.


## Home Services stack
This stack is designed to provide overarching services that will be used by various different stacks.
It should be able to run independantly of other stacks, however other stacks may rely on it

It consists of the following services:
- Swag: Reverse proxy to support easy connectivity. Also updates your dynamic DNS
- Home Assistant: Home automation system
- Homarr: Configurable home page for all the various services created across these stacks
- Wyze-bridge: Wyze camera feed aggregator. Makes video streams accessible without having to go online

## Media stack
This stack is purely for media management. It may break if the Home Services stack is not present

It consists of the following services:
- Plex: Main media server
- Tautulli: Plex media server monitoring service
- Gluetun: VPN client to provide containers secure outbound connectivity
- qBittorrent: torrent client. Relies on Gluetun
- Radarr: Automated movie management and integration with torrent client
- Sonarr: Same as radarr but for TV shows
- Prowlarr: Torrent indexers proxy
- Notifiarr: A notification aggregator, which also supports [TRaSH Guides](https://trash-guides.info/) sync for media quality profiles 

It also has the following services 'built' but not in use.
- Lidarr: Same as radarr but for Music
- sonarr_netimport: A python script to fetch TV shows from tvdb.com and add them to sonarr
- radarr_netimport: Similar to sonarr_netimport but for radarr



# Deployment
Each of the stacks in this repo are designed to be deployed via Portainer using the [Git Repository option](https://docs.portainer.io/user/docker/stacks/add#option-3-git-repository)
This means that when a given stack - defined by a subfolder in this repo and the `docker-compose.yml` file contained within - is deployed, the `.env` file in the same folder will automatically be loaded by Portainer for that stack.

You can of course deploy them manually. Download the stack's folder, modify the `.env` file, and run with `docker compose up`


**IMPORTANT**: The `.env` file is where the bulk of your configuration should occur. 
If you need to edit the `docker-compose.yml` file outside of disabling services, it needs to be improved. Please create an issue for tracking.


## Prerequisites
- [docker and docker-compose](https://docs.docker.com/engine/install/)
