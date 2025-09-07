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
    NOTIFICATION_TITLE="Torrent Grabbed"
    NOTIFICATION_CONTENT="Started downloading: $TORRENT_NAME (Files: $FILE_COUNT)"
    NOTIFICATION_COLOR="FFFF00"
    EVENT_TYPE="grab"
    NOTIFICATION_CHANNEL=$CHANNEL_ID_ADDED
elif [[ "$TORRENT_STATE" == "finished" ]]; then
    NOTIFICATION_TITLE="Torrent Completed"
    NOTIFICATION_CONTENT="Finished downloading: $TORRENT_NAME (Files: $FILE_COUNT)"
    NOTIFICATION_COLOR="00FF00"
    EVENT_TYPE="complete"
    NOTIFICATION_CHANNEL=$CHANNEL_ID_FINISHED
else
    exit 0
fi

# Send notification via Notifiarr
curl -s -X POST "$NOTIFIARR_API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Accept: text/plain" \
  -d "{
    \"notification\": {
      \"update\": false,
      \"name\": \"QBittorrent Notification\",
      \"event\": \"$EVENT_TYPE\"
    },
    \"discord\": {
      \"color\": \"$NOTIFICATION_COLOR\",
      \"text\": {
        \"title\": \"$NOTIFICATION_TITLE\",
        \"content\": \"$NOTIFICATION_CONTENT\",
        \"description\": \"Category: $TORRENT_CATEGORY\"
      },
      \"ids\": {
        \"channel\": \"$NOTIFICATION_CHANNEL\"
      }
    }
  }" > /dev/null