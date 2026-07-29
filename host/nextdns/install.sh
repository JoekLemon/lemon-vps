#!/bin/bash
: '
Title:          NextDNS Install Script
Description:    Installs NextDNS as a local DNS resolver on the VPS.
Author:         Joek Lemon
Contributors:
Notes:          Listens only on the WireGuard interface (10.0.0.1:53).
                DNS queries from WireGuard clients are resolved via NextDNS.
'

set -o errexit

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

# Detect architecture via uname (portable across all Linux distros)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) NEXTDNS_ARCH="amd64" ;;
    aarch64) NEXTDNS_ARCH="arm64" ;;
    armv7l)  NEXTDNS_ARCH="armv7" ;;
    *)       echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Get latest version from GitHub API and download .deb package
echo "   Downloading NextDNS..."
NEXTDNS_VERSION=$(curl --fail --silent --show-error "https://api.github.com/repos/nextdns/nextdns/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$NEXTDNS_VERSION" ]; then
    echo "❌ Could not determine NextDNS version"
    exit 1
fi
echo "   Version: $NEXTDNS_VERSION"
NEXTDNS_DEB=$(mktemp /tmp/nextdns_XXXXXX.deb)
curl --fail --silent --show-error --location \
    "https://github.com/nextdns/nextdns/releases/download/${NEXTDNS_VERSION}/nextdns_${NEXTDNS_VERSION#v}_linux_${NEXTDNS_ARCH}.deb" \
    -o "$NEXTDNS_DEB"

echo "   Installing NextDNS..."
dpkg --install "$NEXTDNS_DEB"
rm -f "$NEXTDNS_DEB"

# Configure (without auto-activate to avoid race with systemctl below)
echo "   Configuring NextDNS (profile: $NEXTDNS_PROFILE)..."
nextdns install \
    -config "$NEXTDNS_PROFILE" \
    -listen 10.0.0.1:53 \
    -listen 127.0.0.1:53 \
    -report-client-info \
    -cache-size 10MB || echo "   ⚠️  nextdns install had issues, continuing..."

# Enable and start
echo "   Starting NextDNS..."
systemctl enable --now nextdns 2>/dev/null || echo "   ⚠️  NextDNS start had issues, continuing..."

# Verify it's listening
sleep 2
if ss -ulnp | grep -q "10.0.0.1:53" && ss -ulnp | grep -q "127.0.0.1:53"; then
    echo "✅ NextDNS installed and listening on 10.0.0.1:53 and 127.0.0.1:53"
else
    echo "⚠️  NextDNS installed but may not be listening correctly"
    echo "   Check with: systemctl status nextdns"
fi
