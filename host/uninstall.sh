#!/bin/bash
: '
Title:          Uninstall Script
Description:    Tears down lemon-vps: removes Docker containers, systemd units,
                config files, and optionally Docker volumes and system packages.
Author:         Joek Lemon
Contributors:
Notes:          Run with sudo bash host/uninstall.sh or from /usr/local/bin/uninstall
                after install. Prompts before destructive operations.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "   Usage: sudo bash host/uninstall.sh"
    exit 1
fi

echo "🍋 lemon-vps uninstall"
echo "======================"
echo ""

# ── Docker compose down ──
echo "── Docker ──"
if command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    cd "$SRC_DIR/docker" 2>/dev/null || cd /opt/lemon-vps/docker 2>/dev/null || true

    PROFILES=""
    if docker compose ps 2>/dev/null | grep -q "icecast"; then
        PROFILES="$PROFILES --profile icecast"
    fi
    if docker compose ps 2>/dev/null | grep -q "canary"; then
        PROFILES="$PROFILES --profile canarytokens"
    fi

    echo "   Stopping containers..."
    docker compose $PROFILES down

    read -rp "   Remove Docker volumes? This deletes all Postgres DBs, NextCloud files, Gitea data [y/N]: " rm_volumes
    if [[ "${rm_volumes,,}" = "y" ]]; then
        echo "   Removing volumes..."
        docker compose $PROFILES down --volumes
    fi

    echo "   ✅ Containers stopped"
else
    echo "   ⏭️  Docker not found — skipping"
fi

# ── Systemd units ──
echo ""
echo "── Systemd ──"
for unit in lemon-clamonacc.service lemon-clamscan.service lemon-clamscan.timer lemon-clamav-logrotate.service; do
    if systemctl list-units --all 2>/dev/null | grep -q "$unit"; then
        echo "   Stopping and disabling $unit..."
        systemctl stop "$unit" 2>/dev/null || true
        systemctl disable "$unit" 2>/dev/null || true
    fi
    if [ -f "/etc/systemd/system/$unit" ]; then
        rm -f "/etc/systemd/system/$unit"
    fi
done
systemctl daemon-reload
echo "   ✅ Custom systemd units removed"

# ── Config files ──
echo ""
echo "── Config files ──"
rm -f /usr/local/bin/update
rm -f /usr/local/bin/lemon-clamav-logrotate
rm -f /etc/logrotate.d/clamonacc_logrotate.conf
rm -f /etc/logrotate.d/clamscan_logrotate.conf
rm -f /etc/sysctl.d/99-wireguard-forward.conf
rm -f /etc/crowdsec/acquis.yaml
echo "   ✅ Config files removed"

# ── Repo ──
echo ""
echo "── Repo ──"
if [ -d "/opt/lemon-vps" ]; then
    rm -rf /opt/lemon-vps
    echo "   ✅ /opt/lemon-vps removed"
else
    echo "   ⏭️  /opt/lemon-vps not found"
fi

# ── Packages (optional) ──
echo ""
echo "── Packages ──"
read -rp "   Remove installed packages? (ufw, clamav*, crowdsec*, wireguard-tools, docker, docker-compose-plugin, acl) [y/N]: " rm_pkgs
if [[ "${rm_pkgs,,}" = "y" ]]; then
    echo "   Removing packages..."
    if command -v apt > /dev/null 2>&1; then
        apt remove --yes --quiet \
            ufw clamav clamav-daemon clamav-freshclam \
            crowdsec crowdsec-firewall-bouncer-iptables \
            wireguard wireguard-tools \
            docker-compose-plugin acl 2>/dev/null || true
        apt autoremove --yes --quiet 2>/dev/null || true
    elif command -v dnf > /dev/null 2>&1; then
        dnf remove --yes \
            ufw clamav clamav-daemon clamav-freshclam \
            crowdsec crowdsec-firewall-bouncer-iptables \
            wireguard-tools \
            docker-compose-plugin acl 2>/dev/null || true
    elif command -v yum > /dev/null 2>&1; then
        yum remove --yes \
            ufw clamav clamav-daemon clamav-freshclam \
            crowdsec crowdsec-firewall-bouncer-iptables \
            wireguard-tools \
            docker-compose-plugin acl 2>/dev/null || true
    fi
    echo "   ✅ Packages removed"
else
    echo "   ⏭️  Skipped"
fi

echo ""
echo "✅ lemon-vps uninstalled"
