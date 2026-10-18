# Deployment / Installation

## Prerequisites
- [docker and docker-compose](https://docs.docker.com/engine/install/)
- Your own outbound VPN connection
- a....basic...knowledge of how to work in the command line, aka edit `.env` files, run shell scripts.

## Pre-deployment
Edit and then run the `initial_system_setup.sh` script in the `scripts` folder.


## Container deployment
Each of the stacks in this repo are designed to be deployed via Portainer using the [Git Repository option](https://docs.portainer.io/user/docker/stacks/add#option-3-git-repository)
This means that when a given stack - defined by a subfolder in this repo and the `docker-compose.yml` file contained within - is deployed, the `.env` file in the same folder will automatically be loaded by Portainer for that stack.

You can of course deploy them manually. Download the stack's folder, modify the `.env` file, and run with `docker compose up`

**IMPORTANT**: The `.env` file is where the bulk of your configuration should occur. 
If you need to edit the `docker-compose.yml` file outside of disabling services, it needs to be improved. Please create an issue for tracking.


## Post-deployment configuration
There is a lot to be covered here, so I'm just going to do the ol 'RTFM' thing and point you to a couple of wikis:
- [Radarr](https://wiki.servarr.com/radarr)
- [Sonarr](https://wiki.servarr.com/sonarr)
- [Prowlarr](https://wiki.servarr.com/prowlarr)

In addition, IBRACORP have done a great job on making some guides:
- [Homarr](https://docs.ibracorp.io/homarr)
- [Docker Compose](https://docs.ibracorp.io/docker-compose)
- [SWAG](https://docs.ibracorp.io/swag-2)
- [Notifiarr](https://www.youtube.com/watch?v=DCxU3Vzaz6k)


