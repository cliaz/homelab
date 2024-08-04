#!/usr/bin/env bash

# Overall, this script will:
# - create a bunch of users, without home directories
# - create folders for each of the docker services in the 'ROOT_DATA_DIR' folder
# - create a secrets folder for each of the docker services in the `ROOT_DATA_DIR`\secrets folder, 'secrets' folder, 
#   which is where you should store sensitive information like API keys / passwords etc.
# - make those users own those folders so they can write, and add your own user to that group so you can modify files

if (( EUID != 0 )); then
    echo "run this command with sudo" >&2
    exit 1
fi

# vars
YOUR_USER_NAME="klaus"      # this is your user on the host machine. We need it to add you to the groups so you can modify files
ROOT_DATA_DIR="/docker"     # where you want to store the docker config files, aka the mapped volumes. Not crazy read/write heavy
DOCKER_USERS=(              # users for all the services to create. If you don't want one, just comment it out
    "portainer"             # docker management
    "watchtower"            # auto-updates
    "swag"                  # reverse proxy
    "wireguard"             # vpn server
	"gluetun"               # outbound vpn client
    "homeassistant"         # home automation
    "mosquitto"             # mqtt broker
    "adguard"               # dns adblocker
    "homarr"                # home page for all the stuff you end up running
    "plex"                  # media server
    "tautulli"              # plex stats
    "radarr"                # movie downloader
    "sonarr"                # tv show downloader
    "overseer"              # combines radarr and sonarr into one nice frontend
    "prowlarr"              # indexer aggregator
    "qbittorrent"           # torrent client
    "notifiarr"             # notification aggregator. also used for keeping TRaSH Guides up to date
)

# create users, folders, and set permissions
# example folder structure for plex: /docker/plex, /docker/secrets/plex
# note: many of the services won't actually have secrets to put in the secrets folder
for NAME in "${DOCKER_USERS[@]}"; do \
    useradd --no-create-home -s /usr/bin/nologin $NAME; \
    mkdir -p $ROOT_DATA_DIR/$NAME $ROOT_DATA_DIR/secrets/$NAME; \
    chown -R $NAME:$NAME $ROOT_DATA_DIR/$NAME/ $ROOT_DATA_DIR/secrets/$NAME; \
    chmod -R 770 $ROOT_DATA_DIR/$NAME; usermod -aG $NAME $YOUR_USER_NAME; \
    echo $NAME:$(id -u $NAME):$(id -g $NAME); \
    done

# create a group called 'media' which we're going to make the primary group for the users that work with media
# set the primary group for those users to be media, to fix any permissions issues
MEDIA_GROUP=(
	"plex"
	"qbittorrent"
	"radarr"
	"sonarr"
)
groupadd media
for NAME in "${MEDIA_GROUP[@]}"; do usermod -g media $NAME; done