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
Synapse + PostgreSQL verified healthy on test VPS after fixes below.

## Known Issues / Next Steps
1. Verify all HTTPS routes accessible via Caddy
2. Test CrowdSec: confirm Caddy access log parsing, bouncer active
3. Consider: system user docker group, sudoers config
4. Nextcloud: requires web-based setup on first boot (503 until completed)
5. **Icecast GUI unstyled**: `<fileserve>` block missing `<enabled>1</enabled>` — static assets (CSS, images, favicon) return 404. Fix in `docker/icecast/icecast.xml` and recreate container.
6. **Placeholder substitution**: `generate-configs.sh` fails to substitute many `{{PLACEHOLDER}}` values in `.env` (e.g. `DOMAIN`, `ADMIN_USER`, `ADMIN_PASS`). After fixing `.env`, affected services need config regeneration and container recreation.
7. **Nextcloud external storage / local mount**: Files uploaded to Nextcloud should appear on the host filesystem under `/home/lemon/{Documents,Music,Videos,Pictures}` so they're accessible via SSH. Approaches: Nextcloud external storage config pointing to bind-mounted host dirs, or symlink-based approaches. Requires mapping these host dirs into the Nextcloud container and configuring the `datadirectory` or external storage.
8. **qBittorrent output to user home dirs**: qBittorrent should be able to save downloads to `/home/lemon/{Downloads,Music,Videos,Documents}` so torrented files are accessible on the host filesystem. Requires mounting the user's home directories into the qBittorrent container and configuring `SavePath` and `TempPath` accordingly.
9. **Gitea runner test workflow**: Create a `.gitea/workflows/test.yml` that runs on push and exercises the Gitea Actions runner (e.g. checkout, lint, build, or simple echo/status check) to verify the runner is functioning correctly.

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
- Synapse data dir: created by root, Synapse runs as UID 991 — chown after install
- Postgres `initdb` locale: Synapse requires UTF8 encoding and C collation — set `POSTGRES_INITDB_ARGS=--encoding=UTF8 --lc-collate=C --lc-ctype=C`
- Gitea runner API: `/api/v1/user/actions/runners/registration-token` (includes `actions`)
- Gitea runner registration: use `docker exec -u git gitea gitea actions generate-runner-token` CLI, not API
- Gitea runner persistence: named `gitea-runner-data` volume stores `.runner` file
- CrowdSec bouncer: `crowdsec-firewall-bouncer-iptables` on Debian 13
- Docker DNS: system DNS (`10.0.0.1`) breaks container resolution — `daemon.json` with Quad9

## Backlog

### Kasm Workspaces (containerized desktop streaming)
**Status**: Planned, not implemented. Requires VPS upgrade to CX42 (16 GB, 8 vCPU) or similar.

**Integration approach**: LinuxServer.io Docker image (`lscr.io/linuxserver/kasm`) — runs Kasm in Docker-in-Docker, avoids official installer.

**Resource budget** (CX42, 16 GB):
| Component | RAM |
|-----------|-----|
| Existing 9 containers (idle) | ~2.5 GiB |
| Kasm server services | ~1.5 GiB |
| 2-3 workspace sessions (capped) | ~4 GiB |
| **Total** | **~8 GiB** |

**Implementation checklist**:
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
