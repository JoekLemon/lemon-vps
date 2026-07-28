#!/bin/bash
: '
Title:          Main Installer Script
Description:    Orchestrates the full lemon-vps installation.
Author:         Joek Lemon
Contributors:
Notes:          Called by setup.sh after repo is cloned.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

# Source helper scripts
# shellcheck source=detect-os.sh
source "$SCRIPT_DIR/detect-os.sh"
# shellcheck source=prompts.sh
source "$SCRIPT_DIR/prompts.sh"
# shellcheck source=generate-configs.sh
source "$SCRIPT_DIR/generate-configs.sh"

# ── Check root ──
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "   Usage: sudo bash setup.sh"
    exit 1
fi

# ── Detect OS ──
detect_os

# ── Update system ──
echo ""
echo "═══════════════════════════════════"
echo "  Updating system"
echo "═══════════════════════════════════"
pkg_update
pkg_upgrade

# ── Collect user input ──
collect_inputs

# ── Generate configs ──
generate_configs "$SRC_DIR"

# ── Export variables for sub-scripts ──
export SRC_DIR DOMAIN EMAIL ADMIN_USER ADMIN_PASS MATRIX_SERVER_NAME SYNAPSE_DB_USER SYNAPSE_DB_NAME
export SYSTEM_USER SYSTEM_USER_HOME SYSTEM_USER_UID SYSTEM_USER_GID
export ENABLE_ICECAST ICECAST_SOURCE_PASS QBIT_SAVE_PATH
export ENABLE_CROWDSEC CROWDSEC_API_KEY
export PROXY_AUTH PROXY_USER PROXY_PASS
export NTFY_TOPIC NTFY_TOKEN
export NEXTDNS_PROFILE
export ENABLE_CANARYTG

# ── Install host services ──
echo ""
echo "═══════════════════════════════════"
echo "  Installing host services"
echo "═══════════════════════════════════"

echo ""
echo "── UFW ──"
bash "$SRC_DIR/host/ufw/install.sh"
bash "$SRC_DIR/host/ufw/rules.sh"

if [ "$ENABLE_CROWDSEC" = "y" ]; then
    echo ""
    echo "── CrowdSec ──"
    bash "$SRC_DIR/host/crowdsec/install.sh"
else
    echo ""
    echo "── CrowdSec ──"
    echo "   ⏭️  Skipped"
fi

echo ""
echo "── WireGuard ──"
bash "$SRC_DIR/host/wireguard/install.sh"

echo ""
echo "── ClamAV ──"
bash "$SRC_DIR/host/clamav/install.sh"

if [ -n "$NEXTDNS_PROFILE" ]; then
    echo ""
    echo "── NextDNS ──"
    export NEXTDNS_PROFILE
    bash "$SRC_DIR/host/nextdns/install.sh"
else
    echo ""
    echo "── NextDNS ──"
    echo "   ⏭️  Skipped (no profile ID)"
fi

# ── Create first WireGuard peer ──
echo ""
echo "── WireGuard Peer ──"
bash "$SRC_DIR/host/wireguard/add-peer.sh" laptop || echo "   ⚠️  Could not create WireGuard peer"

# ── Deploy Docker services ──
echo ""
echo "═══════════════════════════════════"
echo "  Deploying Docker services"
echo "═══════════════════════════════════"

# Create data directories
echo "   Creating data directories..."
mkdir --parents "$SRC_DIR/docker/caddy/data"
    mkdir --parents "$SRC_DIR/docker/synapse/data"
    mkdir --parents "$SRC_DIR/docker/synapse/postgres"
    mkdir --parents "$SRC_DIR/docker/nextcloud/data"
mkdir --parents "$SRC_DIR/docker/gitea/data"
mkdir --parents "$SRC_DIR/docker/ntfy/data"
mkdir --parents "$SRC_DIR/docker/qbittorrent/config"
mkdir --parents "$SRC_DIR/docker/qbittorrent/data"
mkdir --parents "$QBIT_SAVE_PATH"

# Synapse UID 991 in the Docker image — fix ownership before starting
chown -R 991:991 "$SRC_DIR/docker/synapse/data"

if [ "$ENABLE_ICECAST" = "y" ]; then
    mkdir --parents "$SRC_DIR/docker/icecast/data"
fi

if [ "$ENABLE_CANARYTG" = "y" ]; then
    mkdir --parents "$SRC_DIR/docker/canarytokens/redis-data"
    mkdir --parents "$SRC_DIR/docker/canarytokens/uploads"
fi

# Install Docker if not present
if ! command -v docker > /dev/null 2>&1; then
    echo "   Installing Docker..."
    curl --fail --silent --show-error --location https://get.docker.com | sh
else
    echo "   Docker already installed"
fi

# Install docker-compose plugin if not present
if ! docker compose version > /dev/null 2>&1; then
    echo "   Installing Docker Compose plugin..."
    pkg_install docker-compose-plugin
else
    echo "   Docker Compose already installed"
fi

# Configure Docker DNS to bypass NextDNS (which may set system DNS to 10.0.0.1)
echo "   Configuring Docker DNS..."
if [ ! -f /etc/docker/daemon.json ] || ! grep -q '"dns"' /etc/docker/daemon.json 2>/dev/null; then
    mkdir --parents /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
        # Add dns key to existing config
        python3 -c "
import json
with open('/etc/docker/daemon.json') as f: cfg = json.load(f)
cfg['dns'] = ['9.9.9.9', '149.112.112.112']
with open('/etc/docker/daemon.json', 'w') as f: json.dump(cfg, f, indent=2)
" 2>/dev/null || echo '{"dns":["9.9.9.9","149.112.112.112"]}' > /etc/docker/daemon.json
    else
        echo '{"dns":["9.9.9.9","149.112.112.112"]}' > /etc/docker/daemon.json
    fi
    systemctl restart docker
    echo "   Docker DNS set to 9.9.9.9, 149.112.112.112"
else
    echo "   Docker DNS already configured"
fi

# Pull and start containers
echo "   Pulling Docker images..."
cd "$SRC_DIR/docker"

# Build Docker Compose command with profiles
DOCKER_PROFILES=""
if [ "$ENABLE_ICECAST" = "y" ]; then
    DOCKER_PROFILES="--profile icecast"
fi
if [ "$ENABLE_CANARYTG" = "y" ]; then
    DOCKER_PROFILES="$DOCKER_PROFILES --profile canarytokens"
fi

docker compose $DOCKER_PROFILES pull

echo "   Starting containers..."
docker compose $DOCKER_PROFILES up -d

# ── Ensure WireGuard FORWARD rule is in DOCKER-USER ──
echo "   Configuring WireGuard firewall rules..."
if iptables -L DOCKER-USER >/dev/null 2>&1 && ! iptables -C DOCKER-USER -i wg0 -j ACCEPT 2>/dev/null; then
    iptables -I DOCKER-USER 1 -i wg0 -j ACCEPT
    iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
    echo "   WireGuard rule moved to DOCKER-USER chain"
fi

# ── Create NTFY admin user ──
echo "   Setting up NTFY authentication..."
sleep 3
printf '%s\n%s\n' "$ADMIN_PASS" "$ADMIN_PASS" | docker compose exec -T ntfy ntfy user add --role admin "$ADMIN_USER" > /dev/null 2>&1 || echo "   ⚠️  NTFY user creation may need manual setup"

# ── Install NextCloud if not auto-installed ──
echo "   Checking NextCloud installation..."
sleep 5
if ! docker compose exec -T nextcloud php occ status 2>/dev/null | grep -q 'installed: true'; then
    echo "   Installing NextCloud..."
    docker compose exec -T nextcloud php occ maintenance:install \
        --admin-user="$ADMIN_USER" \
        --admin-pass="$ADMIN_PASS" \
        --database=sqlite > /dev/null 2>&1 || echo "   ⚠️  NextCloud install may need manual setup"
    docker compose exec -T nextcloud php occ config:system:set trusted_domains 1 --value="https://cloud.$DOMAIN" > /dev/null 2>&1 || true
fi
# Fix config.php ownership (entrypoint merges as root, PHP runs as www-data)
docker compose exec -T nextcloud chown www-data:www-data /var/www/html/config/config.php 2>/dev/null || true
docker compose exec -T nextcloud chmod 640 /var/www/html/config/config.php 2>/dev/null || true

# ── Register Gitea runner ──
echo "   Registering Gitea runner..."
sleep 5
RUNNER_TOKEN=$(docker compose exec -T -u git gitea gitea actions generate-runner-token 2>/dev/null) || true

if [ -n "$RUNNER_TOKEN" ]; then
    echo "GITEA_RUNNER_REGISTRATION_TOKEN=$RUNNER_TOKEN" >> "$SRC_DIR/docker/.env"
    docker compose up -d --force-recreate gitea-runner > /dev/null 2>&1 || echo "   ⚠️  Runner registration may need manual setup"
else
    echo "   ⚠️  Could not register runner — do it manually from Gitea UI"
fi

# ── Summary ──
echo ""
echo "═══════════════════════════════════"
echo "  ✅ lemon-vps installed!"
echo "═══════════════════════════════════"
echo ""
echo "  Services:"
echo "  ─────────────────────────────────"
echo "  Matrix:     https://matrix.$DOMAIN"
echo "  NextCloud:  https://cloud.$DOMAIN"
echo "  Gitea:      https://git.$DOMAIN"
echo "  qBit:       https://torrent.$DOMAIN"
if [ "$ENABLE_ICECAST" = "y" ]; then
    echo "  Icecast:    https://radio.$DOMAIN"
fi
echo "  NTFY:       https://ntfy.$DOMAIN"
if [ "$ENABLE_CANARYTG" = "y" ]; then
    echo "  Canary:    https://canary.$DOMAIN"
fi
echo "  Proxy:      https://proxy.$DOMAIN"
if [ -n "$NEXTDNS_PROFILE" ]; then
    echo "  DNS:        NextDNS (profile: $NEXTDNS_PROFILE)"
fi
echo ""
echo "  WireGuard:"
echo "  ─────────────────────────────────"
echo "  Client config: /opt/lemon-vps/host/wireguard/clients/laptop.conf"
echo ""
echo "  Download the config:"
echo "  scp root@<VPS_IP>:/opt/lemon-vps/host/wireguard/clients/laptop.conf ."
echo "  Then import it into your WireGuard client app."
echo ""
echo "  Generated values (SAVE THESE):"
echo "  ─────────────────────────────────"
echo "  NTFY auth token: $NTFY_TOKEN"
echo ""
echo "  Guides (in /opt/lemon-vps or the repo):"
echo "  ─────────────────────────────────"
echo "  host/wireguard/Guide.md      — Add devices, split tunnel, troubleshooting"
echo "  docker/nextcloud/Guide.md    — Desktop/mobile apps, cron, performance"
echo "  docker/gitea/Guide.md        — CI/CD workflows, runner management"
echo "  host/crowdsec/Guide.md       — Bouncer setup, testing bans"
echo "  docker/canarytokens/Guide.md — Token creation, NTFY alerts"
echo ""
echo "  Next steps:"
echo "  1. Point your DNS subdomains to this VPS IP"
echo "  2. Download the WireGuard client config via scp"
echo "  3. See the guides above for detailed setup steps"
echo ""
