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
See [`TODO.md`](./TODO.md) for completed items and upcoming work.

### Next Steps
1. Verify all HTTPS routes accessible via Caddy
2. Test CrowdSec: confirm Caddy access log parsing, bouncer active
3. Consider: system user docker group, sudoers config
4. Nextcloud: requires web-based setup on first boot (503 until completed)

## File Structure
```
setup.sh                    # Entry point
scripts/
  install.sh                # Main orchestrator (Docker DNS, DOCKER-USER, Synapse/NC chown)
  detect-os.sh              # OS detection, pkg helpers
  prompts.sh                # User input
  generate-configs.sh       # Template replacement (Matrix key, NTFY token, VPS IP, DB pass)
  update.sh                 # Re-pull images, restart
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

