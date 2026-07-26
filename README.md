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
| **NextDNS** | DNS resolver for WireGuard clients (optional) |

### Docker Services

| Service | Subdomain | Purpose |
|---------|-----------|---------|
| **Caddy** | `*` | Reverse proxy + auto-TLS + forward proxy |
| **Matrix Synapse** | `matrix.*` | Federated chat |
| **NextCloud** | `cloud.*` | File storage |
| **Gitea** | `git.*` | Git hosting |
| **Gitea Runner** | (internal) | CI/CD Docker executor |
| **qBittorrent** | `torrent.*` | Torrent client |
| **Icecast** | `radio.*` | Audio streaming |
| **NTFY.sh** | `ntfy.*` | Push notifications |
| **Forward Proxy** | `proxy.*` | HTTP/HTTPS proxy |
| **Canarytokens** | `canary.*` | Self-hosted honeytokens (optional) |

## Guides

Each service has a setup guide for post-install steps:

| Guide | Location |
|-------|----------|
| [WireGuard](host/wireguard/Guide.md) | Add devices, split tunnel, troubleshooting |
| [NextCloud](docker/nextcloud/Guide.md) | Desktop/mobile apps, cron, performance |
| [Gitea & CI/CD](docker/gitea/Guide.md) | Workflows, runner management |
| [CrowdSec](host/crowdsec/Guide.md) | Bouncer setup, testing bans |
| [Canarytokens](docker/canarytokens/Guide.md) | Token creation, NTFY alerts |

## Supported OS

- Debian 12/13
- Ubuntu 24.04
- Fedora Server
- AlmaLinux

## Requirements

- Fresh VPS with root access
- 8GB RAM / 4 vCPU recommended
- Domain pointed at VPS IP

## Updating

```bash
cd /opt/lemon-vps
bash scripts/update.sh
```

## License

MIT
