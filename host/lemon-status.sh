#!/bin/bash
: '
Title:          Lemon Status Script
Description:    Quick health overview of all lemon-vps services.
Author:         Joek Lemon
Contributors:
Notes:          Installed to /usr/local/bin/lemon-status. Run with sudo.
'

echo "🍋 lemon-vps Status"
echo ""

# ── Docker containers ──
echo "── Docker ──"
if command -v docker > /dev/null 2>&1; then
    SERVICES="caddy postgres synapse nextcloud redis gitea gitea-runner qbittorrent ntfy"
    for svc in $SERVICES; do
        state=$(docker ps --filter "name=docker-$svc-1" --format '{{.Status}}' 2>/dev/null | head -1)
        if [ -n "$state" ]; then
            echo "  $svc        running  ($state)"
        else
            # Check if container exists but is stopped
            exists=$(docker ps -a --filter "name=docker-$svc-1" --format '{{.Status}}' 2>/dev/null | head -1)
            if [ -n "$exists" ]; then
                echo "  $svc        stopped  ($exists)"
            else
                echo "  $svc        —        (not deployed)"
            fi
        fi
    done
    # Profile-gated services
    for svc in icecast ices canary-redis canary-frontend canary-switchboard; do
        state=$(docker ps --filter "name=docker-$svc-1" --format '{{.Status}}' 2>/dev/null | head -1)
        if [ -n "$state" ]; then
            echo "  $svc  running  ($state)"
        fi
    done
else
    echo "  Docker not found"
fi

# ── System services ──
echo ""
echo "── System Services ──"
for svc in wg-quick@wg0 crowdsec clamav-daemon clamav-freshclam nextdns docker; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  $svc  active"
    else
        echo "  $svc  inactive"
    fi
done
for svc in lemon-clamonacc lemon-clamscan.timer; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  $svc  active"
    else
        echo "  $svc  inactive"
    fi
done

# ── UFW ──
echo ""
echo "── Firewall ──"
if command -v ufw > /dev/null 2>&1; then
    ufw status verbose 2>/dev/null | head -3 || echo "  UFW not active"
else
    echo "  UFW not installed"
fi

# ── System ──
echo ""
echo "── System ──"
echo "  Uptime: $(uptime -p | sed 's/up //')"
echo "  Load:   $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "  Memory: $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
echo "  Disk:   $(df -h / | awk 'NR==2 {print $5 " used (" $3 " / " $2 ")"}')"
