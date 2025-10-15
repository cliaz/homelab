# Core Services stack installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Set up Docker secrets:
   - Create `DUCKDNSTOKEN` secret for Swag DNS validation
   - Create `CLOUDFLARE_TOKEN` secret for Cloudflare tunnel
   - Create Wyze-bridge secrets: `WYZE_EMAIL`, `WYZE_PASSWORD`, `API_ID`, `API_KEY`, `WB_USERNAME`, `WB_PASSWORD`
3. Create Docker networks (if not using external networks)

## Configuration

### Swag
- **Domain Setup**: Configure `SWAG_URL` with your domain name
- **DNS Validation**: Uses DuckDNS for DNS challenge validation
- **SSL Certificates**: Automatically generates wildcard certificates
- **Proxy Configuration**: Edit nginx proxy-confs in `/config/nginx/proxy-confs/`
- **Mods**: Edit the mods you want (https://github.com/linuxserver/docker-mods. Auto-reload and dashboard mods are enabled by default.
- **Networks**: Connects to both `core_services_net` and `media_net`

### Cloudflared
- **Tunnel Setup**: Requires Cloudflare tunnel token
- **Alternative Access**: Can be used instead of or alongside Swag
- **Zero Trust**: Provides secure access without exposing ports
- **Configuration**: Set up tunnel endpoints in Cloudflare dashboard

### AdGuard Home
- **Initial Setup**: Access via port 3000 for first-time configuration
- **DNS**: Primary DNS server for network-wide ad blocking
- **Internal DNS**: Configure internal service names
- **Upstream DNS**: Configure reliable upstream DNS servers
- **Blocklists**: Add appropriate ad and malware blocking lists
- **Networks**: Connects to `core_services_net`

### Homarr
- **Dashboard**: Configurable home page for all services
- **Service Integration**: Add tiles for all your homelab services
- **Themes**: Customize appearance to match your preferences
- **Docker Integration**: Can auto-discover Docker containers and allow basic management
- **Networks**: Connects to `core_services_net`, `media_net`, `download_net` and `ebooks_net`

### Notifiarr
- **Discord Integration**: Configure Discord webhook for notifications
- **Service Notifications**: Receives notifications from various *arr services
- **Watchtower Integration**: Receives container update notifications
- **Custom Notifications**: Configure custom notification templates
- **Networks**: Connects to `media_net`

### Wyze-bridge
- **Camera Setup**: Configure Wyze account credentials
- **RTSP Streams**: Converts Wyze cameras to standard RTSP
- **Home Assistant**: Can integrate with Home Assistant for automation
- **Multiple Formats**: Provides RTSP, HLS, and WebRTC streams
- **Networks**: Connects to `core_services_net`

## Troubleshooting

### SSL Certificate Issues
- Verify DuckDNS token is correct and active
- Check DNS propagation for your domain
- Ensure wildcard certificate generation is working
- Review Swag logs for certificate generation errors

### Network Connectivity
- Verify all required networks are created
- Check container networking between services
- Ensure proper DNS resolution within containers
- Test internal service communication

### Proxy Configuration
- Check nginx proxy-conf files are properly configured
- Verify service hostnames and ports are correct
- Test proxy routing with internal requests
- Review nginx error logs for routing issues

### Secret Management
- Verify all secret files exist and contain correct values
- Check file permissions on secret files
- Ensure secret paths match compose file references
- Test secret loading in containers

## Network Architecture
This stack creates and manages several networks:
```bash
docker network create --attachable --subnet=172.16.0.0/24 core_services_net
docker network create --attachable --subnet=172.16.1.0/24 download_net
docker network create --attachable --subnet=172.16.2.0/24 media_net
docker network create --attachable --subnet=172.16.3.0/24 ebooks_net
```
