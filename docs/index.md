# Overview
This repo is aimed at providing an easy way of deploying all the components of a Media Management & Streaming service, mainly via the \*Arr apps as individual Docker Containers, with the intent to be as per ‘best practice’ as possible. They are also coupled in certain ways (eg. shared docker networks), which means deploying a stack individually may cause issues.
As much as possible design decisions will be explained / linked to explanations.

It consists of three Docker Stacks, as follows:
- Home Services stack: things that ideally remain active independently of the Media / eBook stacks, and are used to support overall home network functionality
- Media stack: the media management stuff. Designed to use components of the Home Services stack for some of its functionality, but won’t break if it’s not there
- eBook stack: currently relies on the Media stack to download eBooks. Will serve existing content without Media stack being active, but won’t be able to download new content


## Features
- Per-service user segregation
- Secrets material stored in files accessible on a per-container basis
- Services configured by service-wide `.env` files
- Hardlinking of media for more efficient I/O operations
- Automated TRaSH Guide sync for media profiles


## Components
As well as reading the different component descriptions, check out the [Things to note](design-notes.md) section, as some of the design decisions are elaborated on there.

### Home Services stack
This stack is designed to provide overarching services that will be used by various different stacks.
It should be able to run independently of other stacks, however other stacks may rely on it.

It consists of the following services:
- Swag: Reverse proxy to support easy connectivity. Also updates your dynamic DNS
- AdGuard Home: Ad Blocking and internal DNS resolution
- Home Assistant: Home automation system
- Homarr: Configurable home page for all the various services created across these stacks

### Media stack
This stack is purely for media management. It may break if the Home Services stack is not present.

It consists of the following services:
- Plex: Main media server
- Tautulli: Plex media server monitoring service
- Gluetun: VPN client to provide containers secure outbound connectivity
- qBittorrent: torrent client. Relies on Gluetun to provide outbound DNS
- Flaresolverr: solves Cloudflares checks for qBittorrent
- Radarr: Automated movie management and integration with torrent client
- Sonarr: Same as radarr but for TV shows
- Prowlarr: Torrent indexers proxy
- Notifiarr: A notification aggregator, which also supports [TRaSH Guides](https://trash-guides.info/) sync for media quality profiles 

It also has the following services 'built' but not in use.
- Lidarr: Same as radarr but for Music
- sonarr_netimport: A python script to fetch TV shows from tvdb.com and add them to sonarr
- radarr_netimport: Similar to sonarr_netimport but for radarr

### eBook Stack
This stack is purely for eBooks management. It may break if the Home Services stack is not present.
- Calibre: an eBook to eReader management system
- Calibre-Web: a web app providing a clean interface for browsing, reading and downloading eBooks using an existing Calibre database
- Readarr: Automated eBook management and integration with torrent client

