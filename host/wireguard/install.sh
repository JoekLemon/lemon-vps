#!/bin/bash
: '
Title:          WireGuard Install Script
Description:    Installs WireGuard and configures the VPN tunnel.
Author:         Joek Lemon
Contributors:
Notes:          Generates the [Interface] block for wg0.conf.
                Peers are added later via add-peer.sh.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

echo "🔒 Installing WireGuard..."

# Install WireGuard
pkg_install wireguard wireguard-tools

WG_CONF="/etc/wireguard/wg0.conf"

# Generate server keys if they don't exist
if [ ! -f /etc/wireguard/server.key ]; then
    echo "   Generating server keypair..."
    wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub
    chmod 600 /etc/wireguard/server.key
    chmod 644 /etc/wireguard/server.pub
fi

SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server.key)

# Detect VPS public IP
echo "   Detecting VPS public IP..."
VPS_IP=$(curl --fail --silent --connect-timeout 5 ifconfig.me 2>/dev/null || \
         curl --fail --silent --connect-timeout 5 icanhazip.com 2>/dev/null || \
         curl --fail --silent --connect-timeout 5 api.ipify.org 2>/dev/null)

if [ -z "$VPS_IP" ]; then
    echo "❌ Could not detect VPS public IP"
    exit 1
fi
echo "   VPS IP: $VPS_IP"

# Detect primary network interface
PRIMARY_IF=$(ip route show default | awk '{print $5}' | head -n1)
if [ -z "$PRIMARY_IF" ]; then
    PRIMARY_IF="eth0"
fi

# Write wg0.conf with just the [Interface] block
echo "   Writing $WG_CONF..."
cat > "$WG_CONF" <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = sh -c 'if iptables -L DOCKER-USER >/dev/null 2>&1; then iptables -I DOCKER-USER 1 -i wg0 -j ACCEPT; else iptables -I FORWARD 1 -i wg0 -j ACCEPT; fi'; iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
PostDown = sh -c 'iptables -D DOCKER-USER -i wg0 -j ACCEPT 2>/dev/null; iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null'; iptables -t nat -D POSTROUTING -o $PRIMARY_IF -j MASQUERADE
EOF

chmod 600 "$WG_CONF"

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
echo "   Server IP: $VPS_IP"
