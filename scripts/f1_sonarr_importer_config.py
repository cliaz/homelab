# Configuration for F1 mapping script

SONARR_URL = "http://localhost:8989"
SONARR_API_KEY = "YOUR_SONARR_API_KEY_HERE"  # get this from Sonarr settings -> General -> Security -> API Key
TARGET_SEASON = 2025
ALLOW_PARTIAL_MATCHING = False  # This will allow partial matching of Session (Practice / Qualifying / Race) names in the downloaded file
                                # to help with getting a match. May experience unwanted matches, eg "Ted's Qualifying Notebook" matching to
                                # the "Qualifying" session
F1_DOWNLOAD_DIR = "/media/MEDIA_SSD/torrents/f1"    # where the F1 files are downloaded to, as the host machine sees it
TARGET_IMPORT_DIR = "/media/MEDIA_SSD/torrents/tv"  # where the F1 files should be moved to, aka the downloads folder that Sonarr is watching
                                                    # this is the host machine path, NOT the Sonarr container path
SONARR_TARGET_IMPORT_DIR = "/data/torrents/tv"      # IMPORTANT: this is the Sonarr container path to the above folder
                                                    # usually /data/torrents/tv if you followed the TRaSH Guide.

# Example: 
# For my setup, I have /media/MEDIA_SSD/ mounted as /data in the Sonarr container, shown in a snippet from my docker-compose.yml:
# volumes:
#   - /media/MEDIA_SSD:/data
# 
# In that system folder /media/MEDIA_SSD, I have /torrents, /media, etc.
# Sonarr sees that as /data/torrents, /data/media, etc.