#!/bin/bash
: '
Title:          WireGuard Install Script
Description:    Installs WireGuard and configures the VPN tunnel.
Author:         Joek Lemon
Contributors:
Notes:          Generates keys and deploys wg0.conf.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"

echo "🔒 Installing WireGuard..."

# Install WireGuard
pkg_install wireguard wireguard-tools

# Copy generated config
echo "   Deploying WireGuard configuration..."
cp "$SRC_DIR/host/wireguard/wg0.conf" /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf

# Enable IP forwarding
echo "   Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard-forward.conf
sysctl --system > /dev/null 2>&1

# Enable and start WireGuard
echo "   Starting WireGuard..."
systemctl enable --now wg-quick@wg0

echo "✅ WireGuard installed"
echo "   Interface: wg0"
echo "   Network:   10.0.0.0/24"
