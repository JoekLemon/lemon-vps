# TODO

## Critical

- [x] **`.env` hardcodes `ICECAST_SOURCE_PASS` and `QBIT_SAVE_PATH`**: Changed to `{{PLACEHOLDER}}` syntax in `docker/.env` so `sed_fill` picks them up.
- [ ] **ClamAV logrotate wrong service name**: `host/clamav/config/clamonacc_logrotate.conf` references `clamav-clamonacc.service` (doesn't exist) instead of `lemon-clamonacc.service`. Log rotation signals never reach the scanner.
- [ ] **Caddy proxy auth breaks when auth disabled**: Caddyfile always emits `basic_auth {{PROXY_USER}} {{PROXY_PASS}}`. When `PROXY_AUTH=n` both are empty, Caddy fails to start. Need conditional to omit `basic_auth` entirely when auth is off.

## High

- [ ] **CrowdSec Guide references wrong bouncer**: `host/crowdsec/Guide.md` uses `crowdsec-firewall-bouncer-ufw` throughout but install.sh uses `crowdsec-firewall-bouncer-iptables` (intentional per PLAN.md). Users following the Guide get "unit not found" errors.
- [ ] **Icecast GUI unstyled**: `<fileserve>` block missing `<enabled>1</enabled>` — static assets (CSS, images, favicon) return 404. Fix in `docker/icecast/icecast.xml` and recreate container.

## Medium

- [ ] **`update.sh` ignores Docker profiles**: `docker compose pull` / `up -d` without `--profile icecast --profile canarytokens` means optional services never get updated.
- [ ] **NextCloud uses SQLite**: PostgreSQL is already running in the stack but `occ maintenance:install --database=sqlite` is used. Should use Postgres for multi-user scalability.
- [ ] **Shared `MATRIX_SECRET_KEY` across Synapse and Gitea**: Same secret used as Synapse `registration_shared_secret`/`macaroon_secret_key`/`form_secret` AND Gitea `SECRET_KEY`/`INTERNAL_TOKEN`. Each should have a unique generated secret.
- [ ] **`VPS_PUBLIC_IP` has no fallback**: If both `api.ipify.org` and `ifconfig.co` fail in `generate-configs.sh`, Canarytokens `frontend.env` gets empty IP, breaking token URLs.
- [ ] **NextDNS arch detection Debian-only**: `host/nextdns/install.sh` uses `dpkg --print-architecture` which doesn't exist on Fedora/AlmaLinux; silently falls back to `amd64`. Should use `uname -m`.
- [ ] **`apt update` runs on every `pkg_install` call**: Called 5+ times during install instead of once. `detect-os.sh` should track whether update has run.

## Low

- [ ] **`eval` injection risk in `prompts.sh`**: `eval "$var_name='$value'"` and `eval echo ~"$SYSTEM_USER"` should use `printf -v` / `getent passwd` instead.
- [ ] **`host/ufw/rules.sh` missing shebang**: No `#!/bin/bash` line.
- [ ] **`logrotate.sh` runs `sudo` as root**: `host/clamav/scripts/logrotate.sh` uses `sudo` but the systemd unit runs as root. `sudo` may not be installed on minimal systems.
- [ ] **`NTFY_TOKEN` generated but never registered**: Token is generated, displayed in summary, but never added to NTFY's user database — only `ADMIN_USER`/`ADMIN_PASS` are registered.
- [ ] **Timezone hardcoded `TZ=UTC`**: Should be a prompt or `.env` variable.
- [ ] **`freshclam` runs redundantly**: `clamav-freshclam` service updates definitions continuously; `ExecStartPre=/usr/bin/freshclam` in `lemon-clamscan.service` is duplicate and may race.
- [ ] **`WakeSystem=true` in clamscan timer**: Meaningless on a VPS that never suspends.
- [ ] **NTFY user creation uses `sleep 3`**: Brittle timing — should use a healthcheck wait loop.
- [ ] **`wg syncconf` requires kernel 5.6+**: `add-peer.sh` has no fallback for older kernels.
- [ ] **`canary-frontend` mounts `switchboard.env` unnecessarily**: `docker-compose.yml` mounts both `.env` files but frontend only needs `frontend.env`.

## Completed / Resolved

- [x] **NextCloud external storage / local mount**: Files uploaded to NextCloud appear on host under `/home/lemon/{Documents,Music,Videos,Pictures}` via bind-mounts + ACLs + `files_external`.
- [x] **qBittorrent output to user home dirs**: All user dirs mounted into qBittorrent container. Default `SavePath` fixed to `/downloads` (container-side path).
- [x] **Gitea runner test workflow**: Documented inline in `docker/gitea/Guide.md` — user copies into repo to verify runner.
- [x] **Placeholder substitution cleanup**: Removed unused `{{WG_PRIVATE_KEY}}`, `{{WG_PUBLIC_KEY}}`, `{{WG_PRESHARED_KEY}}`, `{{CROWDSEC_CUSTOMER_ID}}`, `{{CROWDSEC_API_KEY}}` from `.env`.
