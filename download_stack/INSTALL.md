# Download stack installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Set up VPN credentials in Docker secrets:
   - Create `OPENVPN_USER` secret
   - Create `OPENVPN_PASSWORD` secret (add '+pmp' suffix for port forwarding)
3. Ensure the `media_net` Docker network exists

## Configuration

### Gluetun
- **VPN Provider**: Configured via `VPN_SERVICE_PROVIDER` environment variable
- **Port Forwarding**: Automatically enabled for better seeding ratios
- **Dynamic Port Updates**: Automatically configures qBittorrent with forwarded ports
- **Health Check**: Verify VPN connectivity with:
  ```bash
  docker exec gluetun wget -q -O- http://ipecho.net/plain
  ```

### qBittorrent
- **WebUI Port**: Configurable via `QBIT_WEBUI_PORT` (default: 8080)
- **Port Changing**: To change WebUI port:
  1. Start container with default port
  2. Change port in WebUI settings
  3. Stop container and update docker-compose.yml
  4. Restart with new port configuration
- **Automatic Port Updates**: VPN port forwarding is automatically configured

### Prowlarr
- **Indexer Management**: Add and configure torrent sites
- **API Integration**: Connect to *arr applications for unified search
- **FlareSolverr Integration**: Configure for sites requiring captcha solving

### FlareSolverr
- **Purpose**: Primarily used for 1337x indexer and other protected sites
- **No Volume Mounts**: Runs without host file access for security
- **User Context**: Runs as flaresolverr:1000:1000 inside container

## Troubleshooting

### VPN Connection Issues
- Check VPN credentials in secrets
- Verify `SERVER_COUNTRIES` configuration
- Ensure port forwarding is enabled on VPN provider
- Check Gluetun logs for connection status

### Port Forwarding
- Forwarded port status written to `/config/forwarded_port.txt`
- qBittorrent automatically updated with new ports
- Verify port forwarding with VPN provider supports P2P

### Container Dependencies
- qBittorrent uses `network_mode: "service:gluetun"` for VPN dependency
- No explicit `depends_on` needed due to network mode configuration
- Gluetun must be healthy before qBittorrent can start