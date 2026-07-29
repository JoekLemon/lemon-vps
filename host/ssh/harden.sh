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

# PermitRootLogin
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin prohibit-password" >> "$SSHD_CONFIG"
fi

# PasswordAuthentication
if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
fi

# ChallengeResponseAuthentication
if grep -q "^ChallengeResponseAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
else
    echo "ChallengeResponseAuthentication no" >> "$SSHD_CONFIG"
fi

# PubkeyAuthentication
if grep -q "^PubkeyAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
fi

# MaxAuthTries
if grep -q "^MaxAuthTries" "$SSHD_CONFIG"; then
    sed -i 's/^MaxAuthTries.*/MaxAuthTries 3/' "$SSHD_CONFIG"
else
    echo "MaxAuthTries 3" >> "$SSHD_CONFIG"
fi

# ClientAliveInterval
if grep -q "^ClientAliveInterval" "$SSHD_CONFIG"; then
    sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' "$SSHD_CONFIG"
else
    echo "ClientAliveInterval 300" >> "$SSHD_CONFIG"
fi

# ClientAliveCountMax
if grep -q "^ClientAliveCountMax" "$SSHD_CONFIG"; then
    sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSHD_CONFIG"
else
    echo "ClientAliveCountMax 2" >> "$SSHD_CONFIG"
fi

# Restart SSH
echo "   Restarting SSH..."
systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || echo "   ⚠️  Could not restart SSH — do it manually"

echo "✅ SSH hardened"
