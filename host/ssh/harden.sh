#!/bin/bash
: '
Title:          SSH Hardening Script
Description:    Hardens SSH configuration: disables password auth, restricts root
                login, sets sane timeouts. Backs up original config first.
Author:         Joek Lemon
Contributors:
Notes:          Run during install or standalone. Requires SSH key to already
                be installed — prompts for confirmation before applying.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/common.sh
source "$SRC_DIR/scripts/common.sh"

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.lemon-vps.bak"

echo "🔒 Hardening SSH..."
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# Warn and confirm
echo "⚠️  SSH hardening will:"
echo "   • Disable password authentication"
echo "   • Restrict root login to key-based only"
echo "   • Set MaxAuthTries to 3"
echo "   • Set client timeout (300s idle, 2 probes)"
echo ""
echo "   Make sure your SSH key is installed and working"
echo "   before continuing, or you may lock yourself out."
echo ""
read -rp "   Continue? [y/N]: " confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo "   ⏭️  SSH hardening skipped"
    exit 0
fi

# Backup
if [ ! -f "$BACKUP" ]; then
    cp "$SSHD_CONFIG" "$BACKUP"
    echo "   Backup saved to $BACKUP"
else
    echo "   Backup already exists at $BACKUP"
fi

# Apply settings
echo "   Applying SSH hardening..."
set_sshd_option PermitRootLogin prohibit-password "$SSHD_CONFIG"
set_sshd_option PasswordAuthentication no "$SSHD_CONFIG"
set_sshd_option ChallengeResponseAuthentication no "$SSHD_CONFIG"
set_sshd_option PubkeyAuthentication yes "$SSHD_CONFIG"
set_sshd_option MaxAuthTries 3 "$SSHD_CONFIG"
set_sshd_option ClientAliveInterval 300 "$SSHD_CONFIG"
set_sshd_option ClientAliveCountMax 2 "$SSHD_CONFIG"

# Restart SSH
echo "   Restarting SSH..."
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || echo "   ⚠️  Could not restart SSH — do it manually"

echo "✅ SSH hardened"
