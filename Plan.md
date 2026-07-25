# lemon-vps

## Overview

One-command VPS provisioning and service deployment.
Clone a public repo, run a script, get a fully working server with self-hosted services.

## Install

```bash
bash <(curl -s https://raw.githubusercontent.com/JoekLemon/lemon-vps/main/setup.sh)
```

## Target Platforms

- Debian 12/13
- Ubuntu 24.04
- Fedora Server
- AlmaLinux

## Hardware

- 8GB RAM / 4 vCPU
- No backup scripts included

## Domain Model

Single domain with subdomains:

- `matrix.domain.tld` — Matrix Synapse
- `cloud.domain.tld` — NextCloud
- `git.domain.tld` — Gitea
- `radio.domain.tld` — Icecast (public)
- `ntfy.domain.tld` — NTFY.sh (auth required)
- `torrent.domain.tld` — qBittorrent (public, auth)
- `proxy.domain.tld` — Forward HTTP/HTTPS proxy

---

## Architecture

### Host Services (direct install)

| Service | Purpose |
|---------|---------|
| UFW | Firewall |
| CrowdSec | Intrusion prevention |
| WireGuard | VPN for admin access |
| ClamAV + ClamOn-Access | On-access virus scanning |

### Docker Containers (docker-compose)

| Container | Subdomain | Purpose |
|-----------|-----------|---------|
| Caddy | `*` | Reverse proxy, auto-TLS |
| Matrix Synapse | `matrix.*` | Federated chat |
| NextCloud | `cloud.*` | File storage |
| Gitea | `git.*` | Git hosting |
| Gitea-runner | (internal) | CI/CD Docker executor |
| qBittorrent | `torrent.*` | Torrent client |
| Icecast | `radio.*` | Audio streaming |
| NTFY.sh | `ntfy.*` | Push notifications (auth) |
| Forward Proxy | `proxy.*` | HTTP/HTTPS proxy |

---

## Security Model

- No credentials in repo — `.gitignore` excludes `.env` and generated configs
- Templates use `{{PLACEHOLDER}}` syntax, replaced at install time
- WireGuard for private admin access
- CrowdSec for IP banning
- Caddy handles TLS termination
- ClamAV excludes Docker, VFS, and system directories

---

## Music Flow

```
qBittorrent ──downloads──> /home/$USER/Music
                                │
Icecast ─────streams from──────┘
```

---

## Project Structure

```
lemon-vps/
├── setup.sh
├── .gitignore
├── README.md
├── Plan.md
├── CrowdSec_Guide.md
├── scripts/
│   ├── install.sh
│   ├── detect-os.sh
│   ├── prompts.sh
│   ├── generate-configs.sh
│   └── update.sh
├── host/
│   ├── ufw/
│   │   ├── install.sh
│   │   └── rules.sh
│   ├── crowdsec/
│   │   ├── install.sh
│   │   └── config/
│   │       ├── crowdsec.yaml.template
│   │       └── acquis.yaml.template
│   ├── wireguard/
│   │   ├── install.sh
│   │   └── templates/
│   │       └── wg0.conf.template
│   └── clamav/
│       ├── install.sh
│       ├── clamonacc.service
│       ├── clamscan.service
│       ├── clamav-logrotate.service
│       ├── config/
│       │   ├── clamd.conf
│       │   ├── clamonacc_logrotate.conf
│       │   └── clamscan_logrotate.conf
│       └── scripts/
│           └── logrotate.sh
├── docker/
│   ├── docker-compose.yml
│   ├── .env.template
│   ├── caddy/
│   │   └── Caddyfile.template
│   ├── synapse/
│   │   └── homeserver.yaml.template
│   ├── nextcloud/
│   │   └── data/
│   ├── gitea/
│   │   └── app.ini.template
│   ├── gitea-runner/
│   │   └── config.template
│   ├── proxy/
│   │   ├── Dockerfile
│   │   └── config/
│   ├── qbittorrent/
│   │   └── qBittorrent.conf.template
│   ├── icecast/
│   │   └── icecast.xml.template
│   └── ntfy/
│       └── config/
```

---

## Setup Flow

### setup.sh (entry point)

```
1. Ensure git is installed
2. Clone repo to /tmp/lemon-vps/
3. Run scripts/install.sh
4. Clean up /tmp/lemon-vps/
```

### scripts/install.sh (main installer)

```
1. Run detect-os.sh — identify distro, package manager
2. Run prompts.sh — collect all user input
3. Run generate-configs.sh — generate configs from templates
4. Install host services:
   ├── UFW — install, configure rules
   ├── CrowdSec — install, add bouncers
   ├── WireGuard — install, deploy config
   └── ClamAV — install, configure on-access scanning
5. Deploy Docker containers
6. Print summary with URLs
```

---

## Template System

All `.template` files use `{{VAR}}` placeholders.

Generated at install time by `scripts/generate-configs.sh`.

---

## Decisions Log

| Date | Decision | Reasoning |
|------|----------|-----------|
| 2026-07-25 | One-liner curl install | Minimal setup steps |
| 2026-07-25 | Subdomains model | Clean multi-service access |
| 2026-07-25 | Multi-distro support | VPS provider flexibility |
| 2026-07-25 | No backups included | Out of scope for v1 |
| 2026-07-25 | NTFY with auth | Notification security |
| 2026-07-25 | Federated Matrix | Full feature set |
| 2026-07-25 | Icecast public | Public radio streaming |
| 2026-07-25 | Docker executor for Gitea runner | Standard CI approach |
| 2026-07-25 | qBittorrent public with auth | torrent.domain.tld |
| 2026-07-25 | Shared Music volume | qBittorrent downloads → Icecast streams |
| 2026-07-25 | matrix. subdomain | User preference |
| 2026-07-25 | Keep Squid forward proxy | Different from Caddy reverse proxy |
| 2026-07-25 | Image versions in .env | Easy updates, version pinning |
| 2026-07-25 | Healthchecks on all services | Ensure dependencies are ready |
| 2026-07-25 | Hardened ClamAV config | Security-focused defaults |
| 2026-07-25 | Metadata headers on scripts | Consistent documentation |
| 2026-07-25 | Long form flags | Readability |
| 2026-07-25 | ClamAV excludes Docker/VFS | Prevent issues and false positives |

---

## Tasks

### Done

- [x] Define project scope and architecture
- [x] Choose tech stack and services
- [x] Design install flow
- [x] Create project scaffolding
- [x] Write all scripts
- [x] Write all config templates
- [x] Write docker-compose.yml
- [x] Write documentation
- [x] Git init and commit

### Todo

- [ ] Test on Debian 12
- [ ] Test on Ubuntu 24.04
- [ ] Test on Fedora
- [ ] Test on AlmaLinux
- [ ] Add NTFY config template
- [ ] Add NextCloud config if needed
