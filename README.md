# Overview
This repo is aimed at providing an easy way of deploying all the components of a Media Management & Streaming service, mainly via the \*Arr apps as individual Docker Containers, with the intent to be as per ‘best practice’. They are also coupled in certain ways (eg. shared docker networks), which means deploying a stack individually may cause issues.
As much as possible design decisions will be explained / linked to explanations.

It consists of three Docker Stacks, as follows:
- Home Services stack: things that ideally remain active independently of the Media / eBook stacks. 
- Media stack: the media management stuff. Designed to use components of the Home Services stack for some of its functionality, but won’t break if it’s not there
- eBook stack: currently relies on the Media stack to download eBooks. Will serve existing content without Media stack being active, but won’t be able to download new content. 


## Features
- Per-service user segregation
- Secrets material stored in files accessible on a per-container basis
- Services configured by service-wide `.env` files
- Hardlinking of media for more efficient I/O operations
- Automated TRaSH Guide sync for media profiles

## Data Flows

I've put this in before describing the stacks in more details as I think having a visual representation of what's going on helps promote understanding more than, well, a wall of text.

First, the data flow in the context of interactions between the containers themselves:
![Container interactions](./docs/Homelab_Docker_Interactions.png)

Second, the data flow in the context of the homelab as deployed to your home network, and accessed in and out of your home:
![Data flow](./docs/Homelab_Data_Flow.png)


# Stacks

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
- Your own outbound VPN connection
