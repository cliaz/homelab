## Home Services stack
This stack is designed to provide overarching services that will be used by various different stacks.
It should be able to run independantly of other stacks, however other stacks may rely on it

It consists of the following services:
- Swag: Reverse proxy to support easy connectivity. Also updates your dynamic DNS
- AdGuard Home: DNS service to block ads, plus handle internal service naming
- Home Assistant: Home automation system
- Homarr: Configurable home page for all the various services created across these stacks
- Wyze-bridge: Wyze camera feed aggregator. Makes video streams accessible without having to go online



### Exposed Ports
| Service | Port | Purpose |
|---|---|--- |
| Swag | 443 | |
| Adguard Home | 53 | DNS | 
| | 80 | WebUI | 
| | 853 | WebUI | 
| | 3000 | Used for initial setup only | 
| | 4443 | WebUI | 
| | 5443 | WebUI | 
| Homarr | 7575 | WebUI | 
| Notifiarr | 5454 | WebUI | 
| Home Assisstant | 8123 | WebUI | 
| Wyze Bridge | 5000 | WebUI | 
| | 8554 | RTSP Camera stream | 
| | 8888 | HLS Camera stream | 
| | 8189 | WebRTC/ICE Camera stream | 


### Swag 
Swag is acting as a reverse proxy for services, meaning we don't need to expose loads of ports on our home network - we simply expose `443`, set up the services to be and a DNS name, and access the services via DNS requests. Swag will also generate SSL certificates for everything.

Uses nginx proxy-confs to proxy services
Uses nginx site-confs to configure what the default homepage is
Using DNS challenge to get an SSL certificate from Let's Encrypt
- https://letsencrypt.org/docs/challenge-types/#dns-01-challenge
- https://docs.linuxserver.io/general/swag/#create-container-via-duckdns-validation-with-a-wildcard-cert