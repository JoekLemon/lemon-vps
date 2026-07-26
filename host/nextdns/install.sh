#!/bin/bash
: '
Title:          NextDNS Install Script
Description:    Installs NextDNS as a local DNS resolver on the VPS.
Author:         Joek Lemon
Contributors:
Notes:          Listens only on the WireGuard interface (10.0.0.1:53).
                DNS queries from WireGuard clients are resolved via NextDNS.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

if [ -z "$NEXTDNS_PROFILE" ]; then
    echo "   ⏭️  NextDNS skipped (no profile ID provided)"
    exit 0
fi

echo "🌐 Installing NextDNS..."

# Add NextDNS repository
echo "   Adding NextDNS repository..."
if command -v apt > /dev/null 2>&1; then
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://nextdns.io/repo.key | gpg --dearmor -o /etc/apt/keyrings/nextdns.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nextdns.gpg] https://repo.nextdns.io/deb stable main" > /etc/apt/sources.list.d/nextdns.list
    apt update --quiet
    apt install --yes --quiet apt-transport-https
    apt install --yes --quiet nextdns
elif command -v dnf > /dev/null 2>&1; then
    curl -fsSL https://repo.nextdns.io/nextdns.repo -o /etc/yum.repos.d/nextdns.repo
    dnf install --yes nextdns
elif command -v yum > /dev/null 2>&1; then
    curl -fsSL https://repo.nextdns.io/nextdns.repo -o /etc/yum.repos.d/nextdns.repo
    yum install --yes nextdns
fi

# Configure NextDNS
#   -listen 10.0.0.1:53   Only listen on WireGuard interface
#   -report-client-info   Show device names in dashboard
#   -cache-size 10MB      Local DNS cache
#   -auto-activate        Enable on install
echo "   Configuring NextDNS (profile: $NEXTDNS_PROFILE)..."
nextdns install \
    -config "$NEXTDNS_PROFILE" \
    -listen 10.0.0.1:53 \
    -report-client-info \
    -cache-size 10MB \
    -auto-activate

# Enable and start
echo "   Starting NextDNS..."
systemctl enable --now nextdns

# Verify it's listening
if ss -ulnp | grep -q "10.0.0.1:53"; then
    echo "✅ NextDNS installed and listening on 10.0.0.1:53"
else
    echo "⚠️  NextDNS installed but may not be listening on 10.0.0.1:53"
    echo "   Check with: systemctl status nextdns"
fi
