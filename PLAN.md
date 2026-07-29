# lemon-vps - Project Plan & Context

## Objective
One-command VPS provisioning: `bash <(curl -s https://raw.githubusercontent.com/JoekLemon/lemon-vps/main/setup.sh)`

Host services: UFW, CrowdSec, WireGuard, ClamAV, NextDNS
Docker containers: Caddy, Matrix Synapse, NextCloud, Gitea, qBittorrent, Icecast, NTFY.sh, Forward Proxy, Canarytokens (12 total)

## Key Design Decisions
- Subdomain model: `matrix.domain.tld`, `cloud.domain.tld`, etc.
- Single admin user/password for all services; system user (default: `lemon`)
- All scripts use long form flags, `{{PLACEHOLDER}}` syntax for configs
- Healthchecks on all Docker services; versions in `.env`
- Icecast, CrowdSec, Canarytokens optional (yes/no prompts)
- WireGuard: VPS=server, clients=full tunnel. Client configs via `add-peer.sh`
- NextDNS: `.deb` from GitHub, listens on `10.0.0.1:53` + `127.0.0.1:53`
- Docker + WireGuard: FORWARD in `DOCKER-USER` chain; UFW LAN rule for `wg0`
- Canarytokens: NTFY-only alerts (no SMTP), WG port remapped to 51821
- Caddy: custom Dockerfile with forwardproxy plugin via xcaddy
- CrowdSec: firewall bouncer (not `-ufw`), 9 collections, 57 scenarios
- ClamAV: `lemon-` prefixed systemd units, weekly `clamscan.timer`
- Gitea runner: auto-registers via `GITEA_RUNNER_REGISTRATION_TOKEN` env var, persisted in named Docker volume

## Status
All planned bug fixes and features are complete. See [`TODO.md`](./TODO.md) for the single remaining item (Kasm).

### Next Steps
1. Run `sudo lemon-smoke` for a full post-deploy smoke test (containers, HTTPS, TLS certs, services)
2. Test CrowdSec: confirm Caddy access log parsing, bouncer active
3. Run `sudo lemon-status` for health overview
4. Run `sudo update` to refresh containers and definitions (no code change)
5. Run `sudo upgrade` to pull latest code, then update everything
6. Run `sudo lemon-config` to reconfigure services post-install
7. Run `sudo lemon-notify "test"` to verify push notifications
8. Check `sudo systemctl status lemon-health.timer` for daily health checks

## File Structure
```
setup.sh                    # Entry point
scripts/
  install.sh                # Main orchestrator (Docker DNS, DOCKER-USER, Synapse/NC chown)
  detect-os.sh              # OS detection, pkg helpers
  prompts.sh                # User input
  generate-configs.sh       # Template replacement (Matrix key, NTFY token, VPS IP, DB pass)
  update.sh                 # Refresh containers and definitions (no code change)
  upgrade.sh                # git pull + .env key check + update
  config.sh                 # Interactive post-install reconfiguration
  common.sh                 # Shared functions (detect_docker_profiles, check_docker_svc, etc.)
host/
  ufw/install.sh, rules.sh
  crowdsec/install.sh, acquis.yaml, Guide.md
  wireguard/install.sh, add-peer.sh, Guide.md
  clamav/
    install.sh
    config/clamd.conf, clamonacc_logrotate.conf, clamscan_logrotate.conf
    scripts/logrotate.sh
    lemon-clamonacc.service, lemon-clamscan.service, lemon-clamscan.timer, lemon-clamav-logrotate.service
  nextdns/install.sh
  ssh/harden.sh             # Disables password auth, sets key-only root login, timeouts
  update-wrapper.sh         # Thin wrapper installed to /usr/local/bin/update
  upgrade-wrapper.sh        # Thin wrapper installed to /usr/local/bin/upgrade
  lemon-status-wrapper.sh   # Thin wrapper installed to /usr/local/bin/lemon-status
  lemon-smoke-wrapper.sh    # Thin wrapper installed to /usr/local/bin/lemon-smoke
  notify-wrapper.sh         # Thin wrapper installed to /usr/local/bin/lemon-notify
  config-wrapper.sh         # Thin wrapper installed to /usr/local/bin/lemon-config
  uninstall.sh              # Tears down Docker, systemd units, config files, repo
  lemon-status.sh           # Health overview (called via wrapper)
  smoke-test.sh             # Post-deploy smoke test (called via wrapper)
  notify.sh                 # Send push notifications via NTFY (called via wrapper)
  lemon-health.sh           # Daily health check script (called by systemd timer)
  lemon-health.service      # systemd oneshot for health check
  lemon-health.timer        # systemd timer (daily, runs lemon-health.service)
docker/
  docker-compose.yml, .env
  caddy/Dockerfile, Caddyfile
  synapse/homeserver.yaml, homeserver.md, add-user.sh
  nextcloud/custom.config.php, Guide.md
  gitea/app.ini, Guide.md
  gitea-runner/config.yaml
  qbittorrent/qBittorrent.conf
  icecast/icecast.xml
  ices/Dockerfile, stream.sh
  ntfy/config/server.yml
  ntfy/Guide.md
  canarytokens/frontend.env, switchboard.env, Guide.md
```

## Critical Fixes Applied
- `sed_fill` needs `"$1"` arg or `sed: no input files`
- NextCloud `custom.config.php`: `overwrite.cli.url` uses `getenv()` directly (was double-concatenating)
- NextCloud `config.php`: entrypoint merges as root, PHP runs as `www-data` — chown after install
- Synapse uses PostgreSQL (psycopg2) — `SYNAPSE_DB_PASSWORD` auto-generated, `SYNAPSE_DB_USER`/`SYNAPSE_DB_NAME` default to `synapse`
- Synapse data dir: created by root, Synapse runs as UID 991 — chown after install
- Postgres `initdb` locale: Synapse requires UTF8 encoding and C collation — set `POSTGRES_INITDB_ARGS=--encoding=UTF8 --lc-collate=C --lc-ctype=C`
- NextCloud PostgreSQL: NextCloud now uses Postgres (`--database=pgsql`) instead of SQLite; DB/user auto-created before container starts
- Gitea secret key: unique `GITEA_SECRET_KEY` generated instead of reusing `MATRIX_SECRET_KEY`
- Gitea runner API: `/api/v1/user/actions/runners/registration-token` (includes `actions`)
- Gitea runner registration: use `docker exec -u git gitea gitea actions generate-runner-token` CLI, not API
- Gitea runner persistence: named `gitea-runner-data` volume stores `.runner` file
- CrowdSec bouncer: `crowdsec-firewall-bouncer-iptables` on Debian 13
- Docker DNS: system DNS (`10.0.0.1`) breaks container resolution — `daemon.json` with Quad9
- `.env` placeholders: `ICECAST_SOURCE_PASS` and `QBIT_SAVE_PATH` use `{{PLACEHOLDER}}` syntax
- ClamAV logrotate: `clamav-clamonacc.service` → `lemon-clamonacc.service`
- Caddy proxy auth: `basic_auth` line deleted when `PROXY_AUTH != "y"`
- CrowdSec Guide: `ufw` → `iptables` bouncer references
- Icecast: `<fileserve>` enabled for GUI assets
- `update.sh`: auto-detects running profiles and adds `--profile` flags
- `VPS_PUBLIC_IP`: multiple fallback services + `"unknown"` default
- NextDNS arch: `dpkg --print-architecture` → `uname -m`
- `apt update`: guarded by `_pkg_updated` flag to avoid redundant calls
- `NTFY_TOKEN`: registered with `ntfy token add` after user creation
- Timezone: `TZ=UTC` → `TZ=${TZ:-UTC}` configurable via `.env`
- `freshclam`: removed redundant `ExecStartPre` from `lemon-clamscan.service`
- `WakeSystem=true`: removed from `lemon-clamscan.timer`
- NTFY setup: `sleep 3` → healthcheck wait loop
- `wg syncconf`: kernel-version fallback to `wg setconf` for pre-5.6 kernels
- Canarytokens frontend: no longer mounts `switchboard.env`
- `scripts/common.sh`: shared functions for profile detection, Docker/systemd checks, sshd config
- `host/uninstall.sh`: full teardown with prompts for volumes and packages
- `host/lemon-status.sh`: `sudo lemon-status` health overview
- `host/ssh/harden.sh`: SSH hardening with backup and prompt
- `update-wrapper.sh`: `/usr/local/bin/update` wrapper installed by install.sh
- `crowdsec/install.sh`, `clamav/install.sh`, `ufw/install.sh`: added `set -o errexit`
- `detect_docker_profiles()`: wrapped in subshell to avoid caller CWD side-effect
- `install.sh`: `GITEA_RUNNER_REGISTRATION_TOKEN` dedup (re-run safety)
- `generate-configs.sh`: replaced inline apt/dnf/yum with `pkg_install`
- Docker log rotation: `daemon.json` now sets `max-size=10m, max-file=3`
- `host/smoke-test.sh`: full post-deploy verification (containers, HTTPS, TLS certs, services)
- Wrappers for `/usr/local/bin/` commands: `update-wrapper.sh`, `lemon-status-wrapper.sh`, `lemon-smoke-wrapper.sh` — installed to `/usr/local/bin/`, exec real scripts from `/opt/lemon-vps`
- `daemon.json` Python fallback: guarded with `command -v python3` — no longer silently overwrites existing config on failure
- `update.sh`: Docker section guarded — skips with message if Docker unavailable instead of aborting
- `smoke-test.sh`: added `-connect_timeout 5` to `openssl s_client`, curl availability check for HTTPS section
- `generate-configs.sh`: `pkg_install openssl` ensures required tool before 5x `openssl rand` calls
- `install.sh` export block: documented `SYNAPSE_DB_PASSWORD`, `NEXTCLOUD_DB_PASSWORD`, `MATRIX_SECRET_KEY`, `GITEA_SECRET_KEY`
- `host/notify.sh`: sends push notifications via `docker compose exec ntfy ntfy publish` (no port needed), installed as `lemon-notify`
- `docker/ntfy/Guide.md`: user-facing docs with curl examples, priority levels, mobile/desktop subscribe — `sed_fill` replaces tokens during install
- `host/lemon-health.sh` + `.service` + `.timer`: systemd daily health check (06:00 ± 1h), runs smoke test and sends NTFY alert on failure
- `scripts/upgrade.sh`: git pull + `.env` key verification vs `.env.example` + calls `update.sh`; installed as `upgrade`
- `scripts/config.sh`: menu-driven reconfiguration (domain, passwords, services, apply); installed as `lemon-config`

