# lemon-vps

One-command VPS provisioning. Spin up a fully self-hosted server with
Matrix, NextCloud, Gitea, and more.

## Install

```bash
bash <(curl -s https://raw.githubusercontent.com/JoekLemon/lemon-vps/main/setup.sh)
```

## What's Included

### Host Services

| Service | Purpose |
|---------|---------|
| **UFW** | Firewall |
| **CrowdSec** | Intrusion prevention |
| **WireGuard** | VPN |
| **ClamAV** | Antivirus with on-access scanning |

### Docker Services

| Service | Subdomain | Purpose |
|---------|-----------|---------|
| **Caddy** | `*` | Reverse proxy + auto-TLS |
| **Matrix Synapse** | `matrix.*` | Federated chat |
| **NextCloud** | `cloud.*` | File storage |
| **Gitea** | `git.*` | Git hosting |
| **Gitea Runner** | (internal) | CI/CD Docker executor |
| **qBittorrent** | `torrent.*` | Torrent client |
| **Icecast** | `radio.*` | Audio streaming |
| **NTFY.sh** | `ntfy.*` | Push notifications |
| **Forward Proxy** | `proxy.*` | HTTP/HTTPS proxy |

## Supported OS

- Debian 12/13
- Ubuntu 24.04
- Fedora Server
- AlmaLinux

## Requirements

- Fresh VPS with root access
- 8GB RAM / 4 vCPU recommended
- Domain pointed at VPS IP

## Services

### Matrix Synapse
Federated chat server at `matrix.yourdomain.com`.

### NextCloud
File storage and sync at `cloud.yourdomain.com`.

### Gitea
Self-hosted Git at `git.yourdomain.com`.

### qBittorrent
Web UI for torrenting at `torrent.yourdomain.com`.
Downloads to `/home/$USER/Music`.

### Icecast
Audio streaming at `radio.yourdomain.com`.
Streams from `/home/$USER/Music`.

### NTFY.sh
Push notifications at `ntfy.yourdomain.com`.

### Forward Proxy
HTTP/HTTPS proxy at `proxy.yourdomain.com`.

## Updating

```bash
cd /path/to/lemon-vps
bash scripts/update.sh
```

## License

MIT
