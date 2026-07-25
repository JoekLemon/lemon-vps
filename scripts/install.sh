#!/bin/bash
: '
Title:          Main Installer Script
Description:    Orchestrates the full lemon-vps installation.
Author:         Joek Lemon
Contributors:
Notes:          Called by setup.sh after repo is cloned.
'

set -e

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

# ── Collect user input ──
collect_inputs

# ── Generate configs ──
generate_configs "$SRC_DIR"

# ── Install host services ──
echo ""
echo "═══════════════════════════════════"
echo "  Installing host services"
echo "═══════════════════════════════════"

echo ""
echo "── UFW ──"
bash "$SRC_DIR/host/ufw/install.sh"
bash "$SRC_DIR/host/ufw/rules.sh"

echo ""
echo "── CrowdSec ──"
bash "$SRC_DIR/host/crowdsec/install.sh"

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
mkdir -p "$SRC_DIR/docker/caddy/data"
mkdir -p "$SRC_DIR/docker/nextcloud/data"
mkdir -p "$SRC_DIR/docker/gitea/data"
mkdir -p "$SRC_DIR/docker/ntfy/data"
mkdir -p "$SRC_DIR/docker/qbittorrent/config"
mkdir -p "$SRC_DIR/docker/qbittorrent/data"
mkdir -p "$SRC_DIR/docker/icecast/data"
mkdir -p "$QBIT_SAVE_PATH"

# Install Docker if not present
if ! command -v docker > /dev/null 2>&1; then
    echo "   Installing Docker..."
    curl -fsSL https://get.docker.com | sh
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
docker compose pull

echo "   Starting containers..."
docker compose up -d

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
echo "  Icecast:    https://radio.$DOMAIN"
echo "  NTFY:       https://ntfy.$DOMAIN"
echo "  Proxy:      https://proxy.$DOMAIN"
echo ""
echo "  Generated values (SAVE THESE):"
echo "  ─────────────────────────────────"
echo "  WireGuard private key:  $WG_PRIVATE_KEY"
echo "  WireGuard public key:   $WG_PUBLIC_KEY"
echo "  NTFY auth token:        $NTFY_TOKEN"
echo ""
echo "  Next steps:"
echo "  1. Point your DNS subdomains to this VPS IP"
echo "  2. Add your WireGuard peer to the tunnel"
echo "  3. See CrowdSec_Guide.md for CrowdSec setup"
echo ""
