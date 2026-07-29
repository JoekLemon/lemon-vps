# TODO

All items resolved. See commit log below.

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
