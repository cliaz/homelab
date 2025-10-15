# Tailscale installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Create Tailscale auth key at [Tailscale Admin Console](https://login.tailscale.com/admin/)
3. Store auth key in `${CONFIG_DIR}/tailscale/ts_authkey` file
4. Configure subnet routes to advertise
5. Set up proper permissions for configuration directory

## Configuration

### Tailscale Setup
- **Auth Key**: One-time use key for device authentication
- **Subnet Routes**: Configure `IP_RANGES_TO_ROUTE_THROUGH_TAILSCALE` 
- **DNS Accept**: Automatically enabled for MagicDNS
- **Device Approval**: Must approve subnet routes in admin console
- **Persistent Configuration**: Stored in mounted config directory

### Network Configuration
- **Host Access**: Uses host networking for optimal performance
- **TUN Device**: Mounted for VPN tunnel creation
- **Subnet Advertising**: Advertises specified IP ranges to mesh
- **Route Approval**: Routes must be approved in Tailscale admin console

### Auth Key Management
1. Generate auth key in Tailscale admin console
2. Configure key permissions (reusable, ephemeral, etc.)
3. Store key in secret file
4. Note: Current implementation reads key as literal string (limitation)

## Troubleshooting

### Authentication Issues
- Verify auth key is valid and not expired
- Check auth key permissions in admin console
- Ensure key file exists and is readable
- Review container logs for authentication errors

### Network Connectivity
- Verify TUN device is available on host
- Check subnet route approval in admin console
- Test connectivity between mesh devices
- Monitor Tailscale daemon logs

### Route Advertising
- Confirm IP ranges are correctly specified
- Approve advertised routes in admin console
- Test connectivity to advertised subnets
- Verify no IP conflicts with existing networks

### DNS Resolution
- Enable MagicDNS in Tailscale admin console
- Test hostname resolution across mesh
- Check DNS configuration on client devices
- Verify DNS search domains are configured

## Admin Console Configuration
Required steps in Tailscale admin console:

### Approve Routes
1. Navigate to Machines tab
2. Find your homelab node
3. Click "..." menu → "Edit route settings"
4. Approve advertised subnet routes

### Enable Features
- **MagicDNS**: Enable for automatic hostname resolution
- **Key Expiry**: Configure auth key expiration policy
- **Access Controls**: Set up ACLs if needed

### Device Management
- **Device Naming**: Set descriptive names for identification
- **Tags**: Apply tags for ACL organization
- **Key Management**: Rotate keys periodically

## Integration Notes
- **Watchtower**: Monitoring disabled to prevent connection loss
- **Network Access**: Provides access to all Docker networks
- **Service Discovery**: Works with existing service hostnames
- **Firewall**: No port forwarding required
