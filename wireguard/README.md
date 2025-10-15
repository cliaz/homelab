# WireGuard VPN Server overview

This service provides a self-hosted VPN server using WireGuard with an easy-to-use web interface.

It consists of the following service:
- **wg-easy:** WireGuard VPN server with web-based client management

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| wg-easy | 51820/udp | WireGuard VPN tunnel |
| | 51821/tcp | Web management interface |

## Data Flow
1. **Client Connection** establishes encrypted tunnel to WireGuard server
2. **Traffic Routing** routes specified traffic through VPN tunnel
3. **Web Interface** manages client configurations and monitoring
4. **DNS Resolution** provides custom DNS for VPN clients

## Use Cases
- **Remote Access:** Secure access to homelab from external networks
- **Privacy Protection:** Route internet traffic through VPN
- **Site Bridging:** Connect remote locations to home network
- **Secure Browsing:** Encrypted browsing on public networks

## Security Considerations
- Modern WireGuard protocol with strong encryption
- Web interface protected by password authentication
- Client keys generated securely
- Traffic statistics and monitoring available
- Automatic key rotation support

## Features
- **Web Interface:** Easy client management via browser
- **QR Codes:** Mobile device setup via QR code scanning
- **Traffic Stats:** Real-time bandwidth monitoring
- **Multiple Clients:** Support for multiple simultaneous connections
- **Custom DNS:** Configurable DNS servers for VPN clients
- **Automatic Config:** Auto-generated client configurations

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `WIREGUARD_PUID`/`WIREGUARD_PGID`: User/group for WireGuard
- `WIREGUARD_URL`: Public URL/IP for VPN access
- `WIREGUARD_VPN_PORT`: VPN tunnel port (default: 51820)
- `WEBUI_PORT`: Web interface port (default: 51821)
- `WIREGUARD_PASSWORD_HASH`: Hashed password for web interface
- `IP_RANGES_TO_ROUTE_THROUGH_WG`: Traffic routing configuration
- `WIREGUARD_VPN_DNS`: DNS servers for VPN clients
- `IP_RANGE_FOR_WG_CLIENTS`: VPN client IP allocation range
- `CONFIG_DIR`: Directory for WireGuard configuration
- `TZ`: Timezone (default: Australia/Melbourne)

## Network Configuration
- **Port Forwarding:** Requires UDP port 51820 forwarded to server
- **IP Routing:** Configurable traffic routing rules
- **DNS Setup:** Custom DNS servers for VPN clients
- **Client Networks:** Separate IP range for VPN clients