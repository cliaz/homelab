# Watchtower installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Set up notification credentials in Docker secrets
3. Configure update schedule and behaviour
4. Set container labels for update control
5. Test notification delivery

## Configuration

### Update Schedule
- **Cron Schedule**: Default runs at 3 AM daily (`0 0 3 * * *`)
- **Timeout**: 30 seconds for graceful container shutdown
- **Cleanup**: Automatically removes old images after updates
- **Stopped Containers**: Includes stopped containers in monitoring
- **Restart Behavior**: Containers restarted after successful updates

### Notification Setup
Choose between Discord (via Notifiarr) or email notifications:

#### Discord via Notifiarr
- Configure `WATCHTOWER_NOTIFICATION_URL` secret with Notifiarr webhook
- Provides real-time Discord notifications
- Includes update reports and statistics

#### Email Notifications
- Configure SMTP server settings in environment variables
- Set up app-specific password for email account
- Store password in `email_server_password` secret file

### Container Control
Use labels to control Watchtower behavior:

#### Disable Updates
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

#### Monitor Only
```yaml
labels:
  - "com.centurylinklabs.watchtower.monitor-only=true"
```

### Secret Configuration
Required secret files:
- `watchtower_notifiarr_API`: Notifiarr webhook URL for Discord
- `email_server_password`: SMTP password for email notifications

## Troubleshooting

### Update Issues
- Check Docker socket connectivity
- Verify image availability and accessibility
- Review container dependency chains
- Monitor disk space for image downloads

### Notification Problems
- Test webhook URLs and API keys
- Verify SMTP server connectivity
- Check notification template formatting
- Review Watchtower logs for errors

### Permission Issues
- Verify Docker socket access permissions
- Check secret file permissions and ownership
- Ensure container user has required access
- Test Docker command execution

### Schedule Problems
- Validate cron schedule syntax
- Check timezone configuration
- Monitor execution timing
- Review scheduled task logs

## Advanced Configuration

### Custom Update Templates
The notification template includes:
- Number of scanned containers
- Updated container details
- Failed update information
- Container state changes

### Selective Updates
Target specific containers:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower container1 container2
```

### Monitor Mode
Enable monitoring without updates:
```yaml
environment:
  WATCHTOWER_MONITOR_ONLY: true
```