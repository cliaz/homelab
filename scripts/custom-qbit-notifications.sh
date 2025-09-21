#!/bin/bash

## DESCRIPTION
# This script sends notifications to Discord via the Notifiarr API when a torrent is added or finished downloading.
# It uses the Passthrough Integration in Notifiarr to push notifications to the specified Discord channel.

## REQUIREMENTS
# Enable the Passthrough Integration in Notifiarr and obtain an API key. Configure it in this script.
# Create a Discord webhook or use the Notifiarr Discord integration to get the channel ID.


## QBITTORRENT CONFIGURATION:
# 1. Go to Tools > Options > Downloads > Run external program
# 2. Add this script with the following parameters:
#    /path/to/custom-qbit-notifications.sh "%N" "%L" "%C" <"added" or "finished">
# 3. The parameters are:
#    - %N = Torrent name
#    - %L = Category
#    - %C = Number of files in torrent
# 4. Make sure to set executable permissions: chmod +x /path/to/custom-qbit-notifications.sh

# Get QBittorrent environment variables
NOTIFIARR_API_ENDPOINT="<YOUR_NOTIFIARR_API_ENDPOINT_HERE>"
CHANNEL_ID_ADDED="<YOUR_CHANNEL_ID_HERE>"  # content-management channel
CHANNEL_ID_FINISHED="<YOUR_CHANNEL_ID_HERE>"  # notifiarr-catchall channel

DISCORD_MESSAGE_ICON_URL="https://github.com/qbittorrent/qBittorrent/blob/master/dist/unix/menuicons/64x64/apps/qbittorrent.png?raw=true"
F1_ICON_URL="https://artworks.thetvdb.com/banners/v4/series/387219/posters/65345ed871dfe.jpg"
F1_BANNER_URL="https://artworks.thetvdb.com/banners/v4/series/387219/backgrounds/62379c199d9e8.jpg"
TORRENT_NAME="$1"
TORRENT_CATEGORY="$2"
FILE_COUNT="$3"
TORRENT_STATE="$4"
MEDIA_QUALITY=$(echo "$TORRENT_NAME" | grep -oE '([0-9]{3,4}p|HDTV|WEB[- ]DL|BluRay|BRRip|DVDRip|HDRip|CAM|TS|TC)' | head -1)



# Only proceed if the category is "f1" or "prowlarr"
if [[ "$TORRENT_CATEGORY" != "f1" && "$TORRENT_CATEGORY" != "prowlarr" ]]; then
    exit 0
fi

# Set notification details based on torrent state
if [[ "$TORRENT_STATE" == "added" ]]; then
    NOTIFICATION_TITLE="Grabbed"
    NOTIFICATION_COLOR="FFFF00"  # Yellow in decimal (FFFF00)
    EVENT_TYPE=""
    NOTIFICATION_CHANNEL=$CHANNEL_ID_ADDED
    # For grabbed torrents, don't show file count since it's -1
    FILE_COUNT_TEXT=""
elif [[ "$TORRENT_STATE" == "finished" ]]; then
    NOTIFICATION_TITLE="Completed"
    NOTIFICATION_COLOR="00FF00"     # Green in decimal (00FF00)
    EVENT_TYPE=""
    NOTIFICATION_CHANNEL=$CHANNEL_ID_FINISHED
    # For finished torrents, show file count if available
    if [[ "$FILE_COUNT" != "-1" && "$FILE_COUNT" != "" ]]; then
        FILE_COUNT_TEXT="\nFiles: $FILE_COUNT"
    else
        FILE_COUNT_TEXT=""
    fi
else
    exit 0
fi

# Send notification via Notifiarr using Discord embed format
# Set thumbnail and banner based on category
if [[ "$TORRENT_CATEGORY" == "f1" ]]; then
    THUMBNAIL_URL="$F1_ICON_URL"
    BANNER_URL="$F1_BANNER_URL"
else
    THUMBNAIL_URL=""
    BANNER_URL=""
fi

# Use heredoc to build the JSON payload to avoid shell escaping issues
JSON_PAYLOAD=$(cat <<EOF
{
    "notification": {
        "update": false,
        "name": "$NOTIFICATION_TITLE",
        "event": "$EVENT_TYPE"
    },
    "discord": {
        "color": "$NOTIFICATION_COLOR",
        "images": {
            "thumbnail": "$THUMBNAIL_URL",
            "image": "$BANNER_URL"
        },
        "text": {
            "title": "$TORRENT_NAME",
            "icon": "$DISCORD_MESSAGE_ICON_URL",
            "content": "$NOTIFICATION_TITLE",
            "description": "Category: $TORRENT_CATEGORY$FILE_COUNT_TEXT",
            "fields": [
                {
                    "title": "Quality",
                    "text": "${MEDIA_QUALITY:-N/A}",
                    "inline": true
                },
                {
                    "title": "Category", 
                    "text": "$TORRENT_CATEGORY",
                    "inline": true
                }
            ],
            "footer": "$(date "+%d/%m/%Y, %H:%M")"
        },
        "ids": {
            "channel": "$NOTIFICATION_CHANNEL"
        }
    }
}
EOF
)

curl -s -X POST "$NOTIFIARR_API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Accept: text/plain" \
    -d "$JSON_PAYLOAD"