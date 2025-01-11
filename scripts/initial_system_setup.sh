#!/usr/bin/env bash

# Overall, this script will:
# - create a bunch of users, without home directories
# - create folders for each of the docker services that write stuff to disk in the 'ROOT_DATA_DIR' folder
# - create a secrets folder for each of the docker services (=that uses secrets in the `ROOT_DATA_DIR`\secrets folder, 'secrets' folder, 
#   which is where you should store sensitive information like API keys / passwords etc.
# - make those users own those folders so they can write, and add your own user to that group so you can modify files
# - create a 'media' group, and add the users (aka services) that work with media to that group, to fix any permissions issues


# Define stuff here
YOUR_USER_NAME="klaus"      # this is your user on the host machine. We need it to add you to the groups so you can modify files
ROOT_DATA_DIR="/dockers"     # where you want to store the docker config files, aka the mapped volumes. Not crazy read/write heavy
DOCKER_USERS=(              # users for all the services to create. If you don't want one, just delete or comment it out
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
    "deluge"                # torrent client
    "notifiarr"             # notification aggregator. also used for keeping TRaSH Guides up to date
    "readarr"               # ebook downloader
    "calibre"               # ebook server
    "calibre-web"           # web interface for calibre
)


#### Don't touch below here unless you know what you're doing

# services that don't need a folder in the ROOT_DATA_DIR, because they don't write anything to disk
SERVICES_THAT_DONT_TOUCH_DISK=(
    "watchtower"
)

# services that need a folder in the SECRETS_DIR, because they have sensitive information
SERVICES_THAT_NEED_SECRETS=(
    "swag"
    "watchtower"
    "wireguard"
)

# make sure this is run as root
if (( EUID != 0 )); then
    echo "run this command with sudo" >&2
    exit 1
fi

# make sure the user has edited the script to add their own user name
echo "*** WARNING ***"
echo "If you haven't edited this script to configure:"
echo " - which users you want to create"
echo " - where you want to store the docker config files"
echo " - your own user name on the system"
echo "then you should do that now, and then run the script again"
read -p "press enter to continue, or ctrl+c to cancel"


# create users, folders, and set permissions
# example folder structure for plex: /docker/plex, /docker/secrets/plex
# note: many of the services won't actually have secrets to put in the secrets folder
echo "Create all the users for the docker services"
for NAME in "${DOCKER_USERS[@]}"; do \
    useradd --no-create-home -s /usr/bin/nologin $NAME; \
    usermod -aG $NAME $YOUR_USER_NAME
    echo $NAME:$(id -u $NAME):$(id -g $NAME)
    
    # if the name is in the list of services that don't touch the disk, skip creating the folder
    if [[ " ${SERVICES_THAT_DONT_TOUCH_DISK[@]} " =~ " ${NAME} " ]]; then
        # do nothing
    else
        mkdir -p $ROOT_DATA_DIR/$NAME
        chown -R $NAME:$NAME $ROOT_DATA_DIR/$NAME/
        chmod -R 770 $ROOT_DATA_DIR/$NAME
    fi

    # if the name is in the list of services that need secrets, create the secrets folder
    if [[ " ${SERVICES_THAT_NEED_SECRETS[@]} " =~ " ${NAME} " ]]; then
        mkdir -p $ROOT_DATA_DIR/secrets/$NAME
        chown -R $NAME:$NAME $ROOT_DATA_DIR/secrets/$NAME/
    fi

    done

# create a group called 'media' which we're going to make the primary group for the users that work with media
# set the primary group for those users to be media, to fix any permissions issues
MEDIA_GROUP=(
	"plex"
	"deluge"
	"radarr"
	"sonarr"
    "readarr"
    "calibre"
    "calibre-web"
)
groupadd media
for NAME in "${MEDIA_GROUP[@]}"; do usermod -g media $NAME; done

# also add your own user to that group, so you can modify files if needed
usermod -a -G media $YOUR_USER_NAME

echo -e "\n\nUsers and groups created, and permissions set"