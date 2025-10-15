# Tailscale VPN overview

This service provides secure mesh VPN networking using Tailscale for remote access to your homelab.

It consists of the following service:
- **Tailscale:** Zero-configuration mesh VPN for secure remote access

## Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Tailscale | - | No exposed ports (VPN mesh networking) |

## Data Flow
1. **Tailscale** creates secure encrypted tunnels between devices
2. **Route Publishing** allows access to local network subnets
3. **DNS Integration** provides seamless hostname resolution
4. **Magic DNS** enables device discovery across the mesh

## Use Cases
- **Remote Access:** Secure access to homelab services from anywhere
- **Site-to-Site:** Connect multiple locations securely
- **Exit Node:** Route all traffic through homelab connection
- **Service Access:** Direct access to services without port forwarding

## Security Considerations
- Zero Trust networking with device authentication
- End-to-end encryption for all mesh traffic
- ACL support for fine-grained access control
- No exposed ports required on firewall
- Device approval required for network access

## Network Architecture
- Creates secure overlay network over existing internet connection
- Routes specified subnets through Tailscale node
- Integrates with existing Docker networks
- Provides access to homelab services without VPN client configuration

## Installation & Configuration

For detailed installation and configuration instructions, see [INSTALL.md](./INSTALL.md).

### Environment Variables
Key variables to configure in your `.env` file:
- `TAILSCALE_PUID`/`TAILSCALE_PGID`: User/group for Tailscale
- `CONFIG_DIR`: Directory for Tailscale configuration
- `IP_RANGES_TO_ROUTE_THROUGH_TAILSCALE`: Subnets to advertise to mesh
- `HOST_IP`: IP address of the Docker host
- `TZ`: Timezone (default: Australia/Melbourne)

## Features
- **MagicDNS:** Automatic DNS resolution for mesh devices
- **Subnet Routing:** Advertise local networks to mesh
- **Exit Nodes:** Route internet traffic through specific nodes
- **Access Controls:** Define who can access what resources
- **Admin Console:** Web-based management interface
- **Multi-Platform:** Clients for all major operating systems
