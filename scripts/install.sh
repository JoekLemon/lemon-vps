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
export SRC_DIR DOMAIN EMAIL ADMIN_USER ADMIN_PASS MATRIX_SERVER_NAME
export SYSTEM_USER SYSTEM_USER_HOME SYSTEM_USER_UID SYSTEM_USER_GID
export ENABLE_ICECAST ICECAST_SOURCE_PASS QBIT_SAVE_PATH
export ENABLE_CROWDSEC CROWDSEC_API_KEY
export PROXY_AUTH PROXY_USER PROXY_PASS
export NTFY_TOPIC NTFY_TOKEN

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

# ── Deploy Docker services ──
echo ""
echo "═══════════════════════════════════"
echo "  Deploying Docker services"
echo "═══════════════════════════════════"

# Create data directories
echo "   Creating data directories..."
mkdir --parents "$SRC_DIR/docker/caddy/data"
mkdir --parents "$SRC_DIR/docker/nextcloud/data"
mkdir --parents "$SRC_DIR/docker/gitea/data"
mkdir --parents "$SRC_DIR/docker/ntfy/data"
mkdir --parents "$SRC_DIR/docker/qbittorrent/config"
mkdir --parents "$SRC_DIR/docker/qbittorrent/data"
mkdir --parents "$QBIT_SAVE_PATH"

if [ "$ENABLE_ICECAST" = "y" ]; then
    mkdir --parents "$SRC_DIR/docker/icecast/data"
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

# Pull and start containers
echo "   Pulling Docker images..."
cd "$SRC_DIR/docker"

# Build Docker Compose command with profiles
DOCKER_PROFILES=""
if [ "$ENABLE_ICECAST" = "y" ]; then
    DOCKER_PROFILES="--profile icecast"
fi

docker compose $DOCKER_PROFILES pull

echo "   Starting containers..."
docker compose $DOCKER_PROFILES up -d

# ── Create NTFY admin user ──
echo "   Setting up NTFY authentication..."
sleep 3
docker exec ntfy ntfy user add --role admin "$ADMIN_USER" <<< "$ADMIN_PASS" > /dev/null 2>&1 || echo "   ⚠️  NTFY user creation may need manual setup"

# ── Register Gitea runner ──
echo "   Registering Gitea runner..."
sleep 5
RUNNER_TOKEN=$(curl --fail --silent --show-error \
    -X POST "http://localhost:3000/api/v1/user/runners/registration-token" \
    -H "Authorization: Basic $(echo -n "${ADMIN_USER}:${ADMIN_PASS}" | base64)" \
    -H "Content-Type: application/json" 2>/dev/null | grep -o '"token":"[^"]*"' | cut -d'"' -f4) || true

if [ -n "$RUNNER_TOKEN" ]; then
    docker exec gitea-runner act_runner register \
        --no-interactive \
        --instance "http://gitea:3000" \
        --token "$RUNNER_TOKEN" \
        --name "lemon-vps-runner" \
        --labels "ubuntu-latest:docker://node:20-bullseye,ubuntu-22.04:docker://node:20-bullseye" \
        > /dev/null 2>&1 || echo "   ⚠️  Runner registration may need manual setup"
    docker restart gitea-runner > /dev/null 2>&1 || true
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
echo "  Proxy:      https://proxy.$DOMAIN"
echo ""
echo "  Generated values (SAVE THESE):"
echo "  ─────────────────────────────────"
echo "  WireGuard client private key: $WG_CLIENT_PRIVATE_KEY"
echo "  NTFY auth token:              $NTFY_TOKEN"
echo ""
echo "  Next steps:"
echo "  1. Point your DNS subdomains to this VPS IP"
echo "  2. Add your WireGuard peer to the tunnel"
if [ "$ENABLE_CROWDSEC" = "y" ]; then
    echo "  3. See CrowdSec_Guide.md for CrowdSec setup"
fi
echo ""
