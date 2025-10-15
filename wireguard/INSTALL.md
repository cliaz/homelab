# WireGuard VPN Server installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Set up port forwarding on your router (UDP 51820)
3. Generate password hash for web interface
4. Configure DNS and routing settings
5. Set up proper permissions for configuration directory

## Configuration

### Network Setup
- **Public Access**: Configure `WIREGUARD_URL` with your public IP/domain
- **Port Forwarding**: Forward UDP port 51820 to server
- **VPN Port**: Default 51820/udp for WireGuard tunnel
- **Web Interface**: Port 51821/tcp for management interface

### Password Configuration
Generate password hash:
```bash
docker run --rm -it ghcr.io/wg-easy/wg-easy:nightly wgpw PASSWORD
```
Store result in `WIREGUARD_PASSWORD_HASH` environment variable.

### Routing Configuration
- **Split Tunneling**: Configure specific IP ranges to route through VPN
- **Full Tunneling**: Route all traffic through VPN (0.0.0.0/0)
- **Local Access**: Allow access to local networks
- **DNS Servers**: Set reliable DNS servers for VPN clients

### Client Management
- **Web Interface**: Access via `http://server-ip:51821`
- **Add Clients**: Create new client configurations
- **QR Codes**: Scan QR codes for mobile device setup
- **Download Configs**: Download configuration files for desktop clients

## Troubleshooting

### Connection Issues
- Verify port forwarding is correctly configured
- Check firewall rules allow UDP 51820
- Test public IP/domain accessibility
- Monitor WireGuard logs for connection attempts

### Web Interface Access
- Verify password hash is correctly generated
- Check web interface port accessibility
- Test authentication with generated password
- Review web server logs for errors

### Client Configuration
- Verify client configuration matches server settings
- Test DNS resolution from VPN clients
- Check routing table on client devices
- Monitor traffic statistics for connectivity

### Performance Issues
- Monitor server CPU and memory usage
- Check network bandwidth utilization
- Optimize MTU settings if needed
- Review client connection limits

## Advanced Configuration

### Custom DNS
Configure DNS servers for VPN clients:
- **Ad Blocking**: Use AdGuard or Pi-hole DNS
- **Privacy**: Use privacy-focused DNS providers
- **Performance**: Use geographically close DNS servers

### Traffic Routing
Configure which traffic routes through VPN:
- **Home Network Only**: Route only home network traffic
- **Internet + Home**: Route all traffic through VPN
- **Specific Subnets**: Route only specified IP ranges


## Client Setup

### Mobile Devices
1. Install WireGuard app from app store
2. Access web interface and create new client
3. Scan QR code with WireGuard app
4. Enable VPN connection

### Desktop Clients
1. Download WireGuard client for your OS
2. Create new client in web interface
3. Download configuration file
4. Import configuration into WireGuard client
5. Activate connection

## Integration Notes
- **Watchtower**: Updates disabled to prevent connection loss
- **Network Isolation**: VPN clients on separate network segment
- **Service Access**: Can provide access to all homelab services
- **Backup**: Configuration includes all client keys and settings