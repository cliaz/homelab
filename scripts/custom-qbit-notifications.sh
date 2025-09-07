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
NOTIFIARR_API_ENDPOINT="<YOUR_NOTIFIARR_PASSTHROUGH_API_ENDPOINT>"  # Replace with your Notifiarr Passthrough API endpoint
TORRENT_NAME="$1"
TORRENT_CATEGORY="$2"
FILE_COUNT="$3"
TORRENT_STATE="$4"
CHANNEL_ID_ADDED="<YOUR_DISCORD_CHANNEL_ID>"  # content-management channel
CHANNEL_ID_FINISHED="<YOUR_OTHER_DISCORD_CHANNEL_ID>"  # notifiarr-catchall channel

# Only proceed if the category is "f1" or "prowlarr"
if [[ "$TORRENT_CATEGORY" != "f1" && "$TORRENT_CATEGORY" != "prowlarr" ]]; then
    exit 0
fi

# Set notification details based on torrent state
if [[ "$TORRENT_STATE" == "added" ]]; then
    NOTIFICATION_TITLE="Grabbed"
    NOTIFICATION_COLOR="16776960"  # Yellow in decimal (FFFF00)
    EVENT_TYPE="grab"
    NOTIFICATION_CHANNEL=$CHANNEL_ID_ADDED
    # For grabbed torrents, don't show file count since it's -1
    FILE_COUNT_TEXT=""
elif [[ "$TORRENT_STATE" == "finished" ]]; then
    NOTIFICATION_TITLE="Completed"
    NOTIFICATION_COLOR="65280"     # Green in decimal (00FF00)
    EVENT_TYPE="complete"
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
curl -s -X POST "https://notifiarr.com/api/v1/notification/passthrough/19ca8b61-2c89-4c42-be83-611da4bfb3d8" \
    -H "Content-Type: application/json" \
    -H "Accept: text/plain" \
    -d "{
        \"notification\": {
            \"update\": false,
            \"name\": \"QBittorrent Notification\",
            \"event\": \"$EVENT_TYPE\"
        },
        \"discord\": {
            \"embeds\": [{
                \"color\": $NOTIFICATION_COLOR,
                \"author\": {
                    \"name\": \"$NOTIFICATION_TITLE\",
                    \"icon_url\": \"https://raw.githubusercontent.com/qbittorrent/qBittorrent/master/src/icons/qbittorrent-tray.png\"
                },
                \"title\": \"$TORRENT_NAME\",
                \"description\": \"Category: $TORRENT_CATEGORY$FILE_COUNT_TEXT\",
                \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
            }],
            \"ids\": {
                \"channel\": \"$NOTIFICATION_CHANNEL\"
            }
        }
    }" > /dev/null