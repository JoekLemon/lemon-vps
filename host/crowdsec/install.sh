#!/bin/bash
: '
Title:          CrowdSec Install Script
Description:    Installs CrowdSec and the iptables bouncer for intrusion prevention.
Author:         Joek Lemon
Contributors:
Notes:          Requires CrowdSec account credentials.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

echo "🛡️ Installing CrowdSec..."

# Add CrowdSec repository
echo "   Adding CrowdSec repository..."
curl --fail --silent --show-error https://install.crowdsec.net | bash

# Install CrowdSec
echo "   Installing CrowdSec..."
pkg_install crowdsec

# Install the iptables bouncer (works with UFW)
echo "   Installing firewall bouncer..."
pkg_install crowdsec-firewall-bouncer-iptables

# Wait for CrowdSec to initialize
sleep 3

# Copy configuration
echo "   Deploying configuration..."
if [ -d /etc/crowdsec ]; then
    cp "$SRC_DIR/host/crowdsec/config/crowdsec.yaml" /etc/crowdsec/config.yaml
    cp "$SRC_DIR/host/crowdsec/config/acquis.yaml" /etc/crowdsec/acquis.yaml

    # Configure API key
    echo "   Configuring API credentials..."
    sed -i "s|customer_id:.*|customer_id: \"$CROWDSEC_CUSTOMER_ID\"|" /etc/crowdsec/config.yaml
    sed -i "s|console_api_key:.*|console_api_key: \"$CROWDSEC_API_KEY\"|" /etc/crowdsec/config.yaml
else
    echo "   ⚠️  /etc/crowdsec not found — using default config"
fi

# Enable and start services
echo "   Starting CrowdSec services..."
systemctl enable --now crowdsec || echo "   ⚠️  Failed to start crowdsec"
systemctl enable --now crowdsec-firewall-bouncer || echo "   ⚠️  Failed to start firewall bouncer"

# Enroll with console
echo "   Enrolling with CrowdSec console..."
cscli console enroll "$CROWDSEC_API_KEY" 2>/dev/null || echo "   ⚠️  Enrollment may need manual completion"

echo "✅ CrowdSec installed"
echo "   See CrowdSec_Guide.md for next steps"
