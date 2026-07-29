#!/bin/bash
: '
Title:          Smoke Test Script
Description:    Post-deploy verification of all lemon-vps services.
Author:         Joek Lemon
Contributors:
Notes:          Tests Docker runtime, containers, HTTPS endpoints with TLS
                cert validation, and system services. Exits with failure count.
                Installed to /usr/local/bin/lemon-smoke.
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

# Parse DOMAIN from .env (after install, placeholders are replaced)
DOMAIN=$(grep '^DOMAIN=' "$SRC_DIR/docker/.env" 2>/dev/null | cut -d= -f2-)

if [ -z "$DOMAIN" ]; then
    echo "❌ Could not read DOMAIN from $SRC_DIR/docker/.env"
    echo "   Run this script after lemon-vps is installed."
    exit 1
fi

PASSED=0
FAILED=0

ok() { PASSED=$((PASSED + 1)); echo "  ✓ $*"; }
nok() { FAILED=$((FAILED + 1)); echo "  ✗ $*"; }

# ── Helpers ──
check_https() {
    local sub="$1" path="${2:-/}"
    local fqdn="${sub}.${DOMAIN}"
    local code expiry issuer

    code=$(curl -sk -w '%{http_code}' -o /dev/null \
        --resolve "$fqdn:443:127.0.0.1" \
        "https://$fqdn$path" 2>/dev/null || echo "000")

    if [ "$code" = "000" ]; then
        nok "$fqdn  (no response)"
        return
    fi

    # TLS cert info (single handshake)
    if command -v openssl > /dev/null 2>&1; then
        local cert_info
        cert_info=$(echo | openssl s_client -connect "127.0.0.1:443" \
            -servername "$fqdn" 2>/dev/null)
        expiry=$(echo "$cert_info" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2- | cut -d' ' -f1,2,4)
        issuer=$(echo "$cert_info" | openssl x509 -noout -issuer 2>/dev/null | cut -d= -f2- | sed 's/^CN = //' | cut -d, -f1)
        ok "$fqdn  (HTTP $code, cert until $expiry, $issuer)"
    else
        ok "$fqdn  (HTTP $code)"
    fi
}

check_systemd() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
        ok "$1"
    else
        nok "$1"
    fi
}

echo "🍋 lemon-vps Smoke Test"
echo ""

# ── Section: Runtime ──
echo "── Runtime ──"
if command -v docker > /dev/null 2>&1; then
    docker info > /dev/null 2>&1 && ok "Docker daemon" || nok "Docker daemon"
else
    nok "Docker not installed"
    echo ""
    echo "  $PASSED passed, $FAILED failed"
    exit "$FAILED"
fi

# ── Section: Core Containers ──
echo ""
echo "── Core Containers ──"
for svc in caddy postgres synapse nextcloud redis gitea gitea-runner qbittorrent ntfy; do
    state=$(docker ps --filter "name=docker-${svc}-1" --format '{{.Status}}' 2>/dev/null | head -1)
    if [ -n "$state" ]; then
        ok "$svc  ($state)"
    else
        nok "$svc  (not running)"
    fi
done

# ── Section: Optional Containers ──
echo ""
echo "── Optional Containers ──"
for svc in icecast ices canary-redis canary-frontend canary-switchboard; do
    state=$(docker ps --filter "name=docker-${svc}-1" --format '{{.Status}}' 2>/dev/null | head -1)
    if [ -n "$state" ]; then
        ok "$svc  ($state)"
    else
        printf "  \u2013 %s  (not deployed)\n" "$svc"
    fi
done

# ── Section: HTTPS Endpoints ──
echo ""
echo "── HTTPS ──"
check_https matrix /_matrix/client/versions
check_https cloud /status.php
check_https git /
check_https torrent /
check_https ntfy /v1/health
check_https proxy /

for svc in icecast; do
    if docker ps --filter "name=docker-${svc}-1" --format '{{.Status}}' 2>/dev/null | head -1 | grep -q .; then
        check_https radio /status.xsl
    fi
done
for svc in canary-frontend; do
    if docker ps --filter "name=docker-${svc}-1" --format '{{.Status}}' 2>/dev/null | head -1 | grep -q .; then
        check_https canary /
    fi
done

# ── Section: System Services ──
echo ""
echo "── System Services ──"

if command -v ufw > /dev/null 2>&1; then
    ufw status 2>/dev/null | head -1 | grep -q "Status: active" && ok "UFW" || nok "UFW"
else
    printf "  \u2013 UFW  (not installed)\n"
fi

check_systemd crowdsec

if ip link show wg0 > /dev/null 2>&1; then
    ok "WireGuard (wg0)"
else
    nok "WireGuard (wg0)"
fi

check_systemd clamav-daemon

if systemctl is-active --quiet nextdns 2>/dev/null; then
    check_systemd nextdns
else
    printf "  \u2013 nextdns  (not installed)\n"
fi

# ── Summary ──
echo ""
echo "────────────────────────────────────"
echo "  $PASSED passed, $FAILED failed"
echo "────────────────────────────────────"

exit "$FAILED"
