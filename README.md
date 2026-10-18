# Homelab
This repo is aimed at providing an easy way of deploying all the components of a Media Management & Streaming service, mainly via the \*Arr apps as individual Docker Containers, with the intent to be as per ‘best practice’ as possible. They are also coupled in certain ways (eg. shared docker networks), which means deploying a stack individually may cause issues.
As much as possible design decisions will be explained / linked to explanations.

📖 **Full documentation: [cliaz.github.io/homelab](https://cliaz.github.io/homelab/)** — architecture, per-stack setup, design notes and guides.

## Features
- Per-service user segregation
- Secrets material stored in files accessible on a per-container basis
- Services configured by service-wide `.env` files
- Hardlinking of media for more efficient I/O operations
- Automated TRaSH Guide sync for media profiles

## Repo layout
Each stack is a folder containing a `docker-compose.yml`, its `.env`, and (for most) a `README.md` and `INSTALL.md`:

| Folder | What it is |
|---|---|
| [`core_services_stack`](./core_services_stack) | Reverse proxy, DNS, dashboard, notifications |
| [`download_stack`](./download_stack) | VPN, torrent client, indexers |
| [`media_stack`](./media_stack) | Plex and the \*Arr apps |
| [`ebook_stack`](./ebook_stack) | eBooks and audiobooks |
| [`monitoring_stack`](./monitoring_stack) | Grafana, Prometheus, Loki |
| [`tailscale`](./tailscale), [`wireguard`](./wireguard) | Remote access |
| [`watchtower`](./watchtower) | Automated container updates |
| [`scripts`](./scripts) | Host setup and helper scripts |
| [`docs`](./docs) | Source for the documentation site |

## Docs site
The documentation site is built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published by the `Docs site` GitHub Action on every push to `main`. The stack pages are pulled straight from each stack folder's `README.md` / `INSTALL.md`, so edit those files and the site follows.

To preview locally:
```bash
pip install -r requirements-docs.txt
mkdocs serve
```
