# TODO

## In Progress / Upcoming

### Kasm Workspaces (containerized desktop streaming)
Requires VPS upgrade to CX42 (16 GB, 8 vCPU) or similar.

Integration: LinuxServer.io Docker image (`lscr.io/linuxserver/kasm`) — runs Kasm in Docker-in-Docker, avoids official installer.

Resource budget (CX42, 16 GB):
| Component | RAM |
|-----------|-----|
| Existing 14 containers (idle) | ~2.5 GiB |
| Kasm server services | ~1.5 GiB |
| 2-3 workspace sessions (capped) | ~4 GiB |
| **Total** | **~8 GiB** |

- [ ] `docker/docker-compose.yml`: add `kasm` service (privileged, `--profile kasm`, maps 4443:443)
- [ ] `docker/caddy/Caddyfile`: add `kasm.{{DOMAIN}}` → `kasm:443` (with `tls_insecure_skip_verify`)
- [ ] `docker/.env`: add `KASM_VERSION=latest`
- [ ] `scripts/prompts.sh`: add `ENABLE_KASM` prompt
- [ ] `scripts/install.sh`: conditional swap (8 GiB file), sysctl `vm.max_map_count=262144`, `--profile kasm`
- [ ] Post-install: cap workspace images to 1.5 GiB / 1 CPU via Admin UI

**Constraints**:
- Community Edition caps at 5 concurrent sessions
- Privileged container required (Docker-in-Docker)
- Each workspace session defaults to 2.8 GiB / 2 cores — must lower in Admin UI
- Requires 8+ GiB swap for stability

### Postfix (Mail Server)
Relay-only SMTP for transactional emails (password resets, notifications) from Gitea, NextCloud, and Synapse.

- [ ] Evaluate: host-level Postfix vs Docker container
- [ ] Add UFW rules for port 25 (outbound-only relay)
- [ ] Configure relay-only outbound SMTP (no inbound, no IMAP)
- [ ] Wire up service-specific SMTP configs in Gitea, NextCloud, Synapse

### RSS Aggregator (e.g. Miniflux)
Self-hosted RSS reader with subdomain access. Miniflux is the leading candidate (Go binary, PostgreSQL backend, lightweight).

- [ ] `docker/docker-compose.yml`: add `miniflux` service (`--profile rss`)
- [ ] `docker/caddy/Caddyfile`: add `rss.{{DOMAIN}}` → `miniflux:8080`
- [ ] `docker/.env`: add `MINIFLUX_VERSION=latest`, `MINIFLUX_DB_PASSWORD={{PLACEHOLDER}}`
- [ ] `docker/.env.example`: mirror new vars
- [ ] `scripts/prompts.sh`: add `ENABLE_RSS` prompt (default n)
- [ ] `scripts/generate-configs.sh`: generate `MINIFLUX_DB_PASSWORD`, fill configs
- [ ] `scripts/install.sh`: create DB/user in postgres, `--profile rss`

### Review: Post-Install Commands
Audit `sudo update` and `sudo upgrade` for completeness and robustness.

- [ ] `scripts/update.sh`: verify coverage of all running services (nextdns, wireguard, caddy rebuild?)
- [ ] `scripts/upgrade.sh`: verify `.env` key diff against actual required keys after git pull
- [ ] `scripts/upgrade.sh`: confirm config templates are re-applied (regenerated) after pull
- [ ] Add `lemon-notify` alert on update/upgrade failure
- [ ] Improve logging/output clarity for both scripts

## Completed

### Critical
- [x] **`.env` hardcodes `ICECAST_SOURCE_PASS` and `QBIT_SAVE_PATH`**: Changed to `{{PLACEHOLDER}}` syntax in `docker/.env` so `sed_fill` picks them up.
- [x] **ClamAV logrotate wrong service name**: `host/clamav/config/clamonacc_logrotate.conf` — `clamav-clamonacc.service` → `lemon-clamonacc.service`.
- [x] **Caddy proxy auth breaks when auth disabled**: `generate-configs.sh` deletes `basic_auth` line from Caddyfile when `PROXY_AUTH != "y"`.

### High
- [x] **CrowdSec Guide references wrong bouncer**: `ufw` → `iptables` in `host/crowdsec/Guide.md`.
- [x] **Icecast GUI unstyled**: Added `<enabled>1</enabled>` to `<fileserve>` in `docker/icecast/icecast.xml`.

### Medium
- [x] **`update.sh` ignores Docker profiles**: Detects running icecast/canary containers and adds `--profile` flags.
- [x] **NextCloud uses SQLite**: Migrated to PostgreSQL — `install.sh` creates DB/user, `occ` uses `--database=pgsql`.
- [x] **Shared `MATRIX_SECRET_KEY` across Synapse and Gitea**: Generated unique `GITEA_SECRET_KEY` for Gitea.
- [x] **`VPS_PUBLIC_IP` has no fallback**: Added `icanhazip.com`, `checkip.amazonaws.com`, `dig`, and `"unknown"` fallback.
- [x] **NextDNS arch detection Debian-only**: Replaced `dpkg --print-architecture` with `uname -m`.
- [x] **`apt update` runs on every `pkg_install` call**: Guard variable `_pkg_updated` prevents redundant updates.

### Low
- [x] **`eval` injection risk in `prompts.sh`**: `eval` → `printf -v` / `getent passwd`.
- [x] **`logrotate.sh` runs `sudo` as root**: Removed `sudo` — runs as root via systemd.
- [x] **`NTFY_TOKEN` generated but never registered**: Added `ntfy token add` after user creation.
- [x] **Timezone hardcoded `TZ=UTC`**: Made configurable via `TZ=${TZ:-UTC}` in `docker-compose.yml` and `.env`.
- [x] **`freshclam` runs redundantly**: Removed `ExecStartPre=/usr/bin/freshclam` from `lemon-clamscan.service`.
- [x] **`WakeSystem=true` in clamscan timer**: Removed — meaningless on a VPS.
- [x] **NTFY user creation uses `sleep 3`**: Replaced with healthcheck wait loop.
- [x] **`wg syncconf` requires kernel 5.6+**: Added kernel-version fallback to `wg setconf` in `add-peer.sh`.
- [x] **`canary-frontend` mounts `switchboard.env` unnecessarily**: Removed extra mount from `docker-compose.yml`.

### Previously resolved
- [x] **NextCloud external storage / local mount**: Files appear on host under `/home/lemon/{Documents,Music,Videos,Pictures}`.
- [x] **qBittorrent output to user home dirs**: All user dirs mounted into container. Default `SavePath` fixed.
- [x] **Gitea runner test workflow**: Documented inline in `docker/gitea/Guide.md`.
- [x] **Placeholder substitution cleanup**: Removed unused `{{WG_PRIVATE_KEY}}`, `{{WG_PUBLIC_KEY}}`, `{{WG_PRESHARED_KEY}}`, `{{CROWDSEC_CUSTOMER_ID}}`, `{{CROWDSEC_API_KEY}}`.
