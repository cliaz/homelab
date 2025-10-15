# Watchtower overview

This service provides automated container updates for your homelab Docker environment.

It consists of the following service:
- **Watchtower:** Automated Docker container update service with notifications

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Watchtower | - | No exposed ports (update service) |

## Data Flow
1. **Watchtower** monitors Docker images for updates on a schedule
2. **Update Process** pulls new images and recreates containers
3. **Notifications** sent via Discord/email when updates occur
4. **Cleanup** removes old images after successful updates

## Features
- **Scheduled Updates:** Configurable update schedule (default: 3 AM daily)
- **Selective Updates:** Can target specific containers or exclude others
- **Notifications:** Discord and email notification support
- **Cleanup:** Automatic removal of old images
- **Graceful Shutdown:** Configurable timeout for container stops
- **Monitor Mode:** Option to notify without updating

## Security Considerations
- Requires Docker socket access for container management
- Uses Docker secrets for notification credentials
- Can be configured for monitor-only mode
- Respects container labels for update control

## Container Labels
Control Watchtower behavior with Labels on containers:
- `com.centurylinklabs.watchtower.enable=false`: Disable updates
- `com.centurylinklabs.watchtower.monitor-only=true`: Monitor without updating

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `WATCHTOWER_UID`/`WATCHTOWER_GID`: User/group for Watchtower
- `TIME_TO_CHECK_FOR_UPDATES`: Cron schedule (default: 0 0 3 * * *)
- `EMAIL_FROM`/`EMAIL_TO`: Email notification addresses
- `EMAIL_SERVER_HOST`/`EMAIL_SERVER_PORT`: SMTP server configuration
- `SECRETS`: Directory for Docker secrets
- `TZ`: Timezone (default: Australia/Melbourne)

## Notification Options
- **Notifiarr/Discord:** Real-time Discord notifications
- **Email:** SMTP email notifications
- **Custom Templates:** Configurable notification formats
- **Report Mode:** Detailed update reports