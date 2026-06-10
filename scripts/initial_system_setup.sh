#!/usr/bin/env bash
set -Eeuo pipefail

# Overall, this script will:
# - create a bunch of users, without home directories, with fixed UID/GID values
# - create folders for each of the docker services that write stuff to disk in the 'ROOT_DATA_DIR' folder
# - create a secrets folder for each of the docker services (=that uses secrets in the `ROOT_DATA_DIR`\secrets folder, 'secrets' folder,
#   which is where you should store sensitive information like API keys / passwords etc.
# - make those users own those folders so they can write, and add your own user to that group so you can modify files
# - create a 'media' group, and add the users (aka services) that work with media to that group, to fix any permissions issues


# Define stuff here
YOUR_USER_NAME="klaus"      # this is your user on the host machine. We need it to add you to the groups so you can modify files
ROOT_DATA_DIR="/dockers"     # where you want to store the docker config files, aka the mapped volumes. Not crazy read/write heavy
PLEX_TRANSCODE_DIR="/var/cache/plex_transcode"
MEDIA_GID="3000"             # shared group for services that need access to media/download files
DOCKER_GID="3001"            # Docker socket group; Homarr uses this for Docker integration

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
    "overseerr"             # combines radarr and sonarr into one nice frontend
    "prowlarr"              # indexer aggregator
    "qbittorrent"           # torrent client
    "notifiarr"             # notification aggregator. also used for keeping TRaSH Guides up to date
    "readarr"               # ebook downloader
    "calibre"               # ebook server
    "calibre-web"           # web interface for calibre
    "cloudflare"            # cloudflare tunnel client
    "tailscale"             # tailscale client
    "neutarr"               # hunts for missing and upgradable media in your *arr libraries
    "audiobookshelf"        # audiobook server
    "lazylibrarian"         # audiobook downloader
    "unpackerr"             # automatic unpacking of downloaded media
    "wyzebridge"            # wyze camera bridge
    "grafana"               # metrics dashboards
    "loki"                  # log aggregation
    "prometheus"            # metrics database
)

# Fixed IDs used by the .env files. Keep these stable across rebuilds.
declare -A DOCKER_USER_IDS=(
    ["portainer"]=2000
    ["watchtower"]=2001
    ["swag"]=2002
    ["wireguard"]=2003
    ["gluetun"]=2004
    ["homeassistant"]=2005
    ["mosquitto"]=2006
    ["adguard"]=2007
    ["homarr"]=2008
    ["plex"]=2009
    ["tautulli"]=2010
    ["radarr"]=2011
    ["sonarr"]=2012
    ["overseerr"]=2013
    ["prowlarr"]=2014
    ["qbittorrent"]=2015
    ["notifiarr"]=2016
    ["readarr"]=2017
    ["calibre"]=2018
    ["calibre-web"]=2019
    ["cloudflare"]=2020
    ["tailscale"]=2021
    ["neutarr"]=2022
    ["audiobookshelf"]=2023
    ["lazylibrarian"]=2024
    ["unpackerr"]=2025
    ["wyzebridge"]=2026
    ["grafana"]=2027
    ["loki"]=2028
    ["prometheus"]=2029
)


#### Don't touch below here unless you know what you're doing

# services that don't need a folder in the ROOT_DATA_DIR, because they don't write anything to disk
SERVICES_THAT_DONT_TOUCH_DISK=(
    "cloudflare"
    "watchtower"
    "wyzebridge"
)

# services that need a folder in the SECRETS_DIR, because they have sensitive information
SERVICES_THAT_NEED_SECRETS=(
    "cloudflare"            # cloudflare tunnel token
    "gluetun"               # outbound VPN provider credentials
    "swag"                  # duckdnstoken
    "tailscale"             # tailscale oauth client secret
    "unpackerr"             # unpackerr config with api keys
    "watchtower"            # notifiarr token
    "wireguard"             # wireguard password hash
    "wyzebridge"            # wyze acc email / password, api, container webapp user / pass
)

create_group_if_needed() {
    local name="$1"
    local gid="$2"
    local existing_name
    local existing_gid

    if getent group "$name" >/dev/null; then
        existing_gid="$(getent group "$name" | cut -d: -f3)"
        if [[ "$existing_gid" != "$gid" ]]; then
            echo "group '$name' already exists with GID $existing_gid, expected $gid" >&2
            exit 1
        fi
        return
    fi

    if getent group "$gid" >/dev/null; then
        existing_name="$(getent group "$gid" | cut -d: -f1)"
        echo "cannot create group '$name' with GID $gid; already used by '$existing_name'" >&2
        exit 1
    fi

    groupadd --gid "$gid" "$name"
}

create_docker_group_if_needed() {
    local existing_name
    local existing_gid

    if getent group docker >/dev/null; then
        existing_gid="$(getent group docker | cut -d: -f3)"
        if [[ "$existing_gid" != "$DOCKER_GID" ]]; then
            if getent group "$DOCKER_GID" >/dev/null; then
                existing_name="$(getent group "$DOCKER_GID" | cut -d: -f1)"
                echo "cannot change docker group to GID $DOCKER_GID; already used by '$existing_name'" >&2
                exit 1
            fi
            groupmod --gid "$DOCKER_GID" docker
        fi
        return
    fi

    create_group_if_needed "docker" "$DOCKER_GID"
}

create_user_if_needed() {
    local name="$1"
    local uid="$2"
    local gid="$3"
    local existing_name
    local existing_uid

    if id "$name" >/dev/null 2>&1; then
        existing_uid="$(id -u "$name")"
        if [[ "$existing_uid" != "$uid" ]]; then
            echo "user '$name' already exists with UID $existing_uid, expected $uid" >&2
            exit 1
        fi
        return
    fi

    if getent passwd "$uid" >/dev/null; then
        existing_name="$(getent passwd "$uid" | cut -d: -f1)"
        echo "cannot create user '$name' with UID $uid; already used by '$existing_name'" >&2
        exit 1
    fi

    useradd --no-create-home --uid "$uid" --gid "$gid" -s /usr/sbin/nologin "$name"
}

secure_secret_dir() {
    local name="$1"
    local path="$ROOT_DATA_DIR/secrets/$name"

    mkdir -p "$path"
    chown root:root "$ROOT_DATA_DIR/secrets"
    chmod 711 "$ROOT_DATA_DIR/secrets"
    chown -R "$name:$name" "$path"
    find "$path" -type d -exec chmod 700 {} +
    find "$path" -type f -exec chmod 600 {} +
}

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
create_docker_group_if_needed
for NAME in "${DOCKER_USERS[@]}"; do
    USER_ID="${DOCKER_USER_IDS[$NAME]}"

    create_group_if_needed "$NAME" "$USER_ID"
    create_user_if_needed "$NAME" "$USER_ID" "$USER_ID"
    usermod -aG "$NAME" "$YOUR_USER_NAME"
    echo "$NAME:$(id -u "$NAME"):$(id -g "$NAME")"

    # if the name is in the list of services that don't touch the disk, skip creating the folder
    if [[ " ${SERVICES_THAT_DONT_TOUCH_DISK[*]} " =~ [[:space:]]${NAME}[[:space:]] ]]; then
        # do nothing
        :
    else
        mkdir -p "$ROOT_DATA_DIR/$NAME"
        chown -R "$NAME:$NAME" "$ROOT_DATA_DIR/$NAME/"
        chmod -R 770 "$ROOT_DATA_DIR/$NAME"
    fi

    # if the name is in the list of services that need secrets, create the secrets folder
    if [[ " ${SERVICES_THAT_NEED_SECRETS[*]} " =~ [[:space:]]${NAME}[[:space:]] ]]; then
        secure_secret_dir "$NAME"
    fi
done
usermod -aG docker homarr

# create a group called 'media' which we're going to make the primary group for the users that work with media
# set the primary group for those users to be media, to fix any permissions issues
MEDIA_GROUP=(
    "plex"
    "tautulli"
    "radarr"
    "sonarr"
    "prowlarr"
    "qbittorrent"
    "readarr"
    "calibre"
    "calibre-web"
    "audiobookshelf"
    "lazylibrarian"
    "unpackerr"
)
create_group_if_needed "media" "$MEDIA_GID"
for NAME in "${MEDIA_GROUP[@]}"; do usermod -g media "$NAME"; done

mkdir -p "$PLEX_TRANSCODE_DIR"
chown plex:media "$PLEX_TRANSCODE_DIR"
chmod 770 "$PLEX_TRANSCODE_DIR"

# also add your own user to that group, so you can modify files if needed
usermod -a -G media "$YOUR_USER_NAME"
usermod -a -G docker "$YOUR_USER_NAME"

echo -e "\n\nUsers and groups created, and permissions set"
