# lemon-vps - Project Plan & Context

## Objective
Build a one-command VPS provisioning project called `lemon-vps` that installs host services (UFW, CrowdSec, WireGuard, ClamAV) and Docker containers (Caddy, Matrix Synapse, NextCloud, Gitea, qBittorrent, Icecast, NTFY.sh, Forward Proxy) via an interactive setup script.

Public GitHub repo: `https://github.com/JoekLemon/lemon-vps`
User runs: `bash <(curl -s https://raw.githubusercontent.com/JoekLemon/lemon-vps/main/setup.sh)`

## Key Design Decisions
- **Domain model**: subdomains (e.g., `matrix.domain.tld`, `cloud.domain.tld`, `git.domain.tld`, `torrent.domain.tld`, `radio.domain.tld`, `ntfy.domain.tld`, `proxy.domain.tld`)
- **Single admin username/password** shared across all services
- **System user**: Non-root user (default: `lemon`) for running services and storing data. Created during install.
- **Target hardware**: 8GB RAM / 4 vCPU
- **Multi-distro support**: Debian 12/13, Ubuntu 24.04, Fedora Server, AlmaLinux
- All scripts use long form flags (`--yes` not `-y`, `mkdir --parents`, `rm --recursive --force`)
- Metadata header format: `Title:`, `Description:`, `Author: Joek Lemon`, etc.
- YAML files start with `---`
- All Docker services have healthchecks with `depends_on: condition: service_healthy`
- Docker image versions in `.env` file
- Templates use `{{PLACEHOLDER}}` syntax, replaced at install time
- No credentials in repo — `.gitignore` excludes `.env` and generated configs
- qBittorrent and Icecast share `/home/$SYSTEM_USER/Music` volume
- Caddy uses forwardproxy plugin (custom Dockerfile) instead of separate Squid container
- Icecast and CrowdSec are optional (yes/no prompts during install)
- Icecast uses Docker Compose profile so it only starts if enabled
- WireGuard keys auto-generated during install; user adds peer after
- Matrix server name auto-set to domain (no separate prompt)
- Install logs to `/var/log/lemon-vps/install-YYYYMMDD-HHMMSS.log`
- SSH config uses host alias `github` not `github.com` for git remote

## Completed
- [x] Full project scaffolding created with ~35 files
- [x] `setup.sh` — curl entry point, clones repo, runs installer, logs output
- [x] `scripts/install.sh` — main installer orchestrating everything
- [x] `scripts/detect-os.sh` — OS detection, `pkg_install`, `pkg_update`, `pkg_upgrade`
- [x] `scripts/prompts.sh` — interactive user input (Domain, Email, Admin, System User, Icecast Y/n, qBit path, NTFY topic, Proxy auth, CrowdSec Y/n)
- [x] `scripts/generate-configs.sh` — template replacement, installs wireguard-tools for key generation
- [x] `scripts/update.sh` — re-pulls images and restarts containers
- [x] All host service installers: `host/ufw/`, `host/crowdsec/`, `host/wireguard/`, `host/clamav/`
- [x] ClamAV with hardened config, on-access scanning, systemd units, logrotate configs
- [x] `docker/docker-compose.yml` — all services with healthchecks, Icecast behind profile
- [x] `docker/caddy/Dockerfile` — Caddy built with forwardproxy plugin
- [x] All config templates: Caddyfile, homeserver.yaml, app.ini, icecast.xml, qBittorrent.conf, wg0.conf, crowdsec.yaml, acquis.yaml
- [x] `CrowdSec_Guide.md` — setup guide for CrowdSec account/API
- [x] Logging to `/var/log/lemon-vps/install-*.log`
- [x] Git init, committed, pushed to `github:JoekLemon/lemon-vps.git`
- [x] Fixed: `set -o errexit` (not `--errexit`), host scripts source `detect-os.sh` + call `detect_os()`, Icecast image `ghcr.io/jee-r/icecast`, variables exported for sub-scripts
- [x] Added system user creation prompt (default: `lemon`), creates user + Music directory
- [x] qBittorrent uses system user's UID/GID instead of hardcoded 1000
- [x] Default qBittorrent download path points to system user's home

## Active
- User is testing on a Debian 13 VPS
- Last test run got further but hit `ufw: command not found` due to `PKG_MANAGER` not being set (fixed by adding `detect_os` call to host scripts)
- System update/upgrade added before installing services

## Next Steps
1. Re-test the latest push on the Debian 13 VPS
2. Fix any remaining issues that surface during testing
3. Consider adding: system user group memberships (docker group), sudoers config for system user

## File Structure
```
lemon-vps/
├── setup.sh                          # Entry point with logging
├── PLAN.md                           # This file
├── CrowdSec_Guide.md                 # CrowdSec account setup guide
├── .gitignore
├── scripts/
│   ├── install.sh                    # Main orchestrator
│   ├── detect-os.sh                  # OS detection, pkg helpers
│   ├── prompts.sh                    # All user prompts
│   ├── generate-configs.sh           # In-place config editing
│   └── update.sh                     # Update/restart containers
├── host/
│   ├── ufw/
│   │   ├── install.sh
│   │   └── rules.sh
│   ├── crowdsec/
│   │   └── install.sh
│   ├── wireguard/
│   │   └── install.sh
│   └── clamav/
│       ├── install.sh
│       ├── clamonacc.service
│       ├── clamscan.service
│       ├── clamav-logrotate.service
│       ├── scripts/
│       │   └── logrotate.sh
│       └── config/
│           ├── clamd.conf
│           ├── clamonacc_logrotate.conf
│           └── clamscan_logrotate.conf
├── docker/
│   ├── docker-compose.yml
│   ├── .env
│   ├── caddy/
│   │   ├── Dockerfile
│   │   └── Caddyfile
│   ├── synapse/
│   │   └── homeserver.yaml
│   ├── nextcloud/
│   │   └── custom.config.php
│   ├── gitea/
│   │   └── app.ini
│   ├── gitea-runner/
│   │   └── config.yaml
│   ├── qbittorrent/
│   │   └── qBittorrent.conf
│   ├── icecast/
│   │   └── icecast.xml
│   ├── ntfy/
│   │   └── config/
│   │       └── server.yml
│   └── proxy/
│       └── (forwardproxy handled by Caddy)
```

## Environment Variables (exported to sub-scripts)
```
SRC_DIR, DOMAIN, EMAIL, ADMIN_USER, ADMIN_PASS, MATRIX_SERVER_NAME
SYSTEM_USER, SYSTEM_USER_HOME, SYSTEM_USER_UID, SYSTEM_USER_GID
ENABLE_ICECAST, ICECAST_SOURCE_PASS, QBIT_SAVE_PATH
ENABLE_CROWDSEC, CROWDSEC_CUSTOMER_ID, CROWDSEC_API_KEY
PROXY_AUTH, PROXY_USER, PROXY_PASS
NTFY_TOPIC, NTFY_TOKEN
```
