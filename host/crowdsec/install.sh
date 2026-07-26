#!/bin/bash
: '
Title:          CrowdSec Install Script
Description:    Installs CrowdSec with UFW bouncer, Caddy/NextCloud/qBittorrent parsers,
                and brute force / attack scenarios.
Author:         Joek Lemon
Contributors:
Notes:          Full pipeline: engine → bouncer → acquisition → collections → scenarios.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

echo "🛡️ Installing CrowdSec..."

# ── Step 1: Add CrowdSec repository ──
echo "   Adding CrowdSec repository..."
curl --fail --silent --show-error https://install.crowdsec.net | bash

# ── Step 2: Install CrowdSec engine ──
echo "   Installing CrowdSec engine..."
pkg_install crowdsec

# ── Step 3: Install UFW bouncer (iptables under the hood) ──
echo "   Installing UFW bouncer..."
pkg_install crowdsec-firewall-bouncer-iptables

# ── Step 4: Enroll with CrowdSec console ──
echo "   Enrolling with CrowdSec console..."
cscli console enroll "$CROWDSEC_API_KEY" || echo "   ⚠️  Enrollment may need manual completion"

# ── Step 5: Deploy acquisition config ──
echo "   Deploying acquisition config..."
sed -e "s|{{SRC_DIR}}|$SRC_DIR|g" "$SCRIPT_DIR/acquis.yaml" > /etc/crowdsec/acquis.yaml

# ── Step 6: Install collections (parser + scenarios bundle) ──
echo "   Installing collections..."
cscli collections install crowdsecurity/caddy || echo "   ⚠️  caddy collection already installed or unavailable"
cscli collections install crowdsecurity/nextcloud || echo "   ⚠️  nextcloud collection already installed or unavailable"
cscli collections install gilbsgilbs/qbittorrent || echo "   ⚠️  qbittorrent collection already installed or unavailable"

# ── Step 7: Install scenarios ──
echo "   Installing scenarios..."
cscli scenarios install crowdsecurity/base-http-scenarios || true
cscli scenarios install crowdsecurity/http-dos-invalid-http-versions || true
cscli scenarios install crowdsecurity/http-generic-bf || true
cscli scenarios install crowdsecurity/http-technology-probing || true
cscli scenarios install crowdsecurity/http-cve-probing || true
cscli scenarios install crowdsecurity/http-sensitive-files || true
cscli scenarios install crowdsecurity/nextcloud-bf || true
cscli scenarios install gilbsgilbs/qbittorrent-bf || true

# Verify wireguard-auth exists before installing
if cscli scenarios install crowdsecurity/wireguard-auth 2>/dev/null; then
    echo "   ✅ wireguard-auth scenario installed"
else
    echo "   ⚠️  wireguard-auth scenario not available in hub"
fi

# ── Step 8: Restart CrowdSec to pick up new config ──
echo "   Restarting CrowdSec..."
systemctl restart crowdsec

# ── Step 9: Verify ──
echo ""
echo "   CrowdSec status:"
cscli decisions list 2>/dev/null || true
echo ""
echo "   Bouncers:"
cscli bouncers list 2>/dev/null || true
echo ""
echo "   Acquisitions:"
cscli acquisition show 2>/dev/null || true

echo ""
echo "✅ CrowdSec installed"
echo "   Engine:    crowdsec"
echo "   Bouncer:   crowdsec-firewall-bouncer-iptables"
echo "   Logs:      /var/log/auth.log, Caddy access.log"
echo "   See host/crowdsec/Guide.md for next steps"
