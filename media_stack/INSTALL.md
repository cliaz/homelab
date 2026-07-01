# Media Stack installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Ensure the Download Stack is running (for Prowlarr, qBittorrent, etc.)
3. Create required directories for media storage and Plex transcoding
4. Set up proper permissions for media files and secret files
5. Configure GPU transcoding (if available)

## Configuration

### Plex
- **Initial Setup**: Access via port 32400 for first-time configuration
- **Media Libraries**: Set up separate libraries for Movies, TV Shows, etc.
- **Library Paths**: Point Movies to both `/data/media/movies` and `/data_archive/media/movies`; point TV Shows to both `/data/media/tv` and `/data_archive/media/tv`
- **Hardware Transcoding**: Enabled via `/dev/dri` device mapping. May not be available if running the docker host as VM 
- **Transcode Directory**: Use `/var/cache/plex_transcode` on the VM disk for faster temporary transcode writes
- **Network**: Uses host networking for better streaming performance and discovery
- **Remote Access**: Configure for external streaming access

### Radarr
- **Root Folders**: Configure `/data/media/movies` and `/data_archive/media/movies` as root folders
- **Quality Profiles**: Set up quality preferences and upgrade rules
- **Indexers**: Connect to Prowlarr for torrent sources
- **Download Client**: Configure qBittorrent connection
- **Naming**: Set up file and folder naming conventions
- **Import Lists**: Optionally configure movie discovery lists
- **Archive Tag**: Create an `archive` tag and apply it to movies that should be moved to `/data_archive/media/movies`

### Sonarr
- **Root Folders**: Configure `/data/media/tv` and `/data_archive/media/tv` as root folders
- **Series Types**: Set up Standard, Daily, and Anime series types
- **Quality Profiles**: Configure quality preferences for different content
- **Release Profiles**: Set up preferred/ignored release groups
- **Season Folders**: Enable season-based organization
- **Calendar**: Monitor upcoming episodes and seasons
- **Archive Tag**: Create an `archive` tag and apply it to series that should be moved to `/data_archive/media/tv`

### Archive Automation
- **Scripts**: Install `python3-requests`, then configure API keys in `scripts/sonarr_tag_based_move.py` and `scripts/radarr_tag_based_move.py`
- **Cron**: Install host cron entries on the Debian VM, not in the containers:
  ```cron
  0 1 * * * sonarr /usr/bin/python3 /home/klaus/code/homelab/scripts/sonarr_tag_based_move.py >> /dockers/sonarr/archive_move.log 2>&1
  30 1 * * * radarr /usr/bin/python3 /home/klaus/code/homelab/scripts/radarr_tag_based_move.py >> /dockers/radarr/archive_move.log 2>&1
  ```
- **Cron File**: Put those entries in `/etc/cron.d/servarr-archive-move`, then secure it with `sudo chown root:root /etc/cron.d/servarr-archive-move` and `sudo chmod 644 /etc/cron.d/servarr-archive-move`

### Overseerr
- **Plex Integration**: Connect to Plex server for library scanning
- **Service Integration**: Connect to Radarr and Sonarr APIs
- **User Management**: Set up user permissions and quotas
- **Notifications**: Configure Discord/email notifications
- **Request Approval**: Set up approval workflows if needed

### Tautulli
- **Plex Connection**: Connect to Plex server for monitoring
- **Logs Access**: Mounted Plex logs for detailed analytics
- **Notifications**: Set up activity and performance alerts
- **Users**: Monitor user activity and statistics
- **Maintenance**: Set up automated cleanup tasks

## Troubleshooting

### Plex Issues
- Check `/dev/dri` device availability for transcoding
- Verify media file permissions and ownership
- Test network connectivity for remote access
- Check hardware transcoding logs for GPU issues

### *arr Application Issues
- Verify download client connectivity
- Check API key configurations
- Test indexer connections through Prowlarr
- Monitor disk space for downloads and media storage

### Permission Problems
- Ensure consistent PUID/PGID across all containers
- Check media file ownership matches container users
- Verify shared volume permissions
- Test file access between containers

### Network Connectivity
- Verify containers are on correct Docker networks
- Test API connectivity between services
- Check proxy configurations for web access
- Monitor download client connectivity

## File Structure
Recommended media organization:
```
/data/media/
├── movies/
│   ├── Movie Name (Year)/
│   │   └── Movie Name (Year).mkv
└── tv/
    ├── Series Name/
    │   ├── Season 01/
    │   │   └── Series Name - S01E01.mkv
    │   └── Season 02/
```

## Quality Settings
- **Movies**: Configure quality profiles for different content types
- **TV Shows**: Set up separate profiles for different series types
- **Upgrades**: Enable automatic quality upgrades when available
- **Custom Formats**: Use Trash Guides for optimal quality settings

## Integration Notes
- All services share the same media directory structure
- Download client should use hardlinks for seeding efficiency
- Proper category/label configuration ensures correct file placement
