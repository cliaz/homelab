# Configuration for F1 mapping script
import os

TARGET_SEASON = 2026
ALLOW_PARTIAL_MATCHING = False  # This will allow partial matching of Session (Practice / Qualifying / Race) names in the downloaded file

SONARR_API_KEY = "YOUR_SONARR_API_KEY_HERE"  # get this from Sonarr settings -> General -> Security -> API Key
                                # to help with getting a match. May experience unwanted matches, eg "Ted's Qualifying Notebook" matching to
                                # the "Qualifying" session
# Paths for the downloaded F1 files and the target import directory for Sonarr.
# The "host" paths are used when running this script on the host (e.g. via SSH), and the "container" paths are used 
# when running inside a container (e.g. as a qBittorrent hook). 
# The script will automatically detect its execution context and pick the appropriate paths.
HOST_F1_TORRENTS_DIR       = "/media/MEDIA_SSD/torrents/f1"
CONTAINER_F1_TORRENTS_DIR  = "/data/torrents/f1"
HOST_TV_TORRENTS_DIR       = "/media/MEDIA_SSD/torrents/tv"
CONTAINER_TV_TORRENTS_DIR  = "/data/torrents/tv"

# Pick the right values for our execution context. The qBittorrent "Run on torrent
# finished" hook runs this script inside the qBit container; manual SSH-and-run
# invocations on the host see the host filesystem.
if os.path.exists("/.dockerenv"):
    # Running inside a container (e.g. qBit hook)
    SONARR_URL        = "http://sonarr:8989"
    F1_DOWNLOAD_DIR   = CONTAINER_F1_TORRENTS_DIR
    TARGET_IMPORT_DIR = CONTAINER_TV_TORRENTS_DIR 
else:
    # Running on the host (manual run)
    SONARR_URL        = "http://localhost:8989"
    F1_DOWNLOAD_DIR   = HOST_F1_TORRENTS_DIR
    TARGET_IMPORT_DIR = HOST_TV_TORRENTS_DIR


# Only consulted in host mode, when convert_path_between_host_and_container() needs to
# translate a host filesystem path (e.g. /media/MEDIA_SSD/torrents/tv/...) into the path
# Sonarr (in its container) sees (/data/torrents/tv/...) before passing it to the Sonarr
# API. In container mode the qBit and Sonarr containers happen to mount the torrents
# folder at the identical /data/torrents/... path, so no translation is needed and this
# table isn't consulted. Kept for the host-side ad-hoc workflow.
#
# For reference, my setup mounts /media/MEDIA_SSD/ as /data inside the Sonarr container:
# volumes:
#   - /media/MEDIA_SSD:/data
PATH_MAPPINGS = [
    {"host": HOST_TV_TORRENTS_DIR, "container": CONTAINER_TV_TORRENTS_DIR},
    {"host": HOST_F1_TORRENTS_DIR, "container": CONTAINER_F1_TORRENTS_DIR},
]
