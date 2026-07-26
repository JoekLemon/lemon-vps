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

# Detect architecture
ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
case "$ARCH" in
    amd64)  NEXTDNS_ARCH="amd64" ;;
    arm64)  NEXTDNS_ARCH="arm64" ;;
    armhf)  NEXTDNS_ARCH="arm" ;;
    *)      echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download and install NextDNS binary
echo "   Downloading NextDNS..."
curl --fail --silent --show-error --location \
    "https://github.com/nextdns/nextdns/releases/latest/download/nextdns_${NEXTDNS_ARCH}" \
    -o /usr/local/bin/nextdns
chmod +x /usr/local/bin/nextdns

# Create systemd service
echo "   Creating systemd service..."
cat > /etc/systemd/system/nextdns.service <<EOF
[Unit]
Description=NextDNS DNS Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nextdns run -config $NEXTDNS_PROFILE -listen 10.0.0.1:53 -report-client-info -cache-size 10MB
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Enable and start
echo "   Starting NextDNS..."
systemctl enable --now nextdns

# Verify it's listening
sleep 2
if ss -ulnp | grep -q "10.0.0.1:53"; then
    echo "✅ NextDNS installed and listening on 10.0.0.1:53"
else
    echo "⚠️  NextDNS installed but may not be listening on 10.0.0.1:53"
    echo "   Check with: systemctl status nextdns"
fi
