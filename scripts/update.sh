#!/bin/bash
: '
Title:          Update Script
Description:    Updates all lemon-vps Docker containers and services.
Author:         Joek Lemon
Contributors:
Notes:          Run this periodically or after git pull.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=common.sh
source "$SRC_DIR/scripts/common.sh"

echo "🔄 Updating lemon-vps..."
echo ""

# ── Update Docker containers ──
echo "── Docker ──"
if ! command -v docker > /dev/null 2>&1 || ! docker compose version > /dev/null 2>&1; then
    echo "   ⏭️  Docker not available"
else
    cd "$SRC_DIR/docker"

    PROFILES=$(detect_docker_profiles "$SRC_DIR/docker")

    echo "   Pulling latest images..."
    docker compose $PROFILES pull

    echo "   Restarting containers..."
    docker compose $PROFILES up -d
fi

# ── Update CrowdSec ──
echo ""
echo "── CrowdSec ──"
echo "   Restarting CrowdSec..."
systemctl restart crowdsec 2>/dev/null || echo "   ⚠️  CrowdSec not running"

# ── Update ClamAV definitions ──
echo ""
echo "── ClamAV ──"
echo "   Updating virus definitions..."
freshclam --quiet 2>/dev/null || echo "   ⚠️  freshclam failed"

# ── Update UFW ──
echo ""
echo "── UFW ──"
echo "   Reloading UFW..."
ufw reload 2>/dev/null || echo "   ⚠️  UFW reload failed"

echo ""
echo "✅ lemon-vps updated!"
