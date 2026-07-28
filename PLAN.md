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
All 12 containers verified running with Canarytokens enabled.

## Known Issues / Next Steps
1. Verify all HTTPS routes accessible via Caddy
2. Test CrowdSec: confirm Caddy access log parsing, bouncer active
3. Consider: system user docker group, sudoers config

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
  clamav/install.sh, lemon-*.service/.timer
  nextdns/install.sh
docker/
  docker-compose.yml, .env
  caddy/Dockerfile, Caddyfile
  synapse/homeserver.yaml, homeserver.md, add-user.sh
  nextcloud/custom.config.php
  gitea/app.ini, Guide.md
  gitea-runner/config.yaml
  qbittorrent/qBittorrent.conf
  icecast/icecast.xml
  ntfy/config/server.yml
  canarytokens/frontend.env, switchboard.env
```

## Critical Fixes to Remember
- `sed_fill` needs `"$1"` arg or `sed: no input files`
- NextCloud `custom.config.php`: `overwrite.cli.url` uses `getenv()` directly (was double-concatenating)
- NextCloud `config.php`: entrypoint merges as root, PHP runs as `www-data` — chown after install
- Synapse uses PostgreSQL (psycopg2) — `SYNAPSE_DB_PASSWORD` auto-generated, `SYNAPSE_DB_USER`/`SYNAPSE_DB_NAME` default to `synapse`
- Synapse data dir: created by root, Synapse runs as UID 999 — chown after install
- Gitea runner API: `/api/v1/user/actions/runners/registration-token` (includes `actions`)
- Gitea runner registration: use `docker exec -u git gitea gitea actions generate-runner-token` CLI, not API
- Gitea runner persistence: named `gitea-runner-data` volume stores `.runner` file
- CrowdSec bouncer: `crowdsec-firewall-bouncer-iptables` on Debian 13
- Docker DNS: system DNS (`10.0.0.1`) breaks container resolution — `daemon.json` with Quad9
