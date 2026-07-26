#!/bin/bash
: '
Title:          UFW Install Script
Description:    Installs and configures UFW firewall with default policies.
Author:         Joek Lemon
Contributors:
Notes:          Sets deny incoming, allow outgoing by default.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

echo "🔥 Installing UFW..."

pkg_install ufw

# Reset to defaults
echo "   Resetting UFW to defaults..."
ufw --force reset

# Default policies
echo "   Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

# SSH access
echo "   Allowing SSH..."
ufw allow 22/tcp comment "SSH"

# Enable firewall
echo "   Enabling UFW..."
ufw --force enable

echo "✅ UFW installed"
