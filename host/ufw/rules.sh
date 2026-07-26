#!/bin/bash
: '
Title:          UFW Rules Script
Description:    Adds UFW rules for all lemon-vps services.
Author:         Joek Lemon
Contributors:
Notes:          Called after install.sh to add service-specific rules.
'

echo "🔥 Adding UFW rules..."

# WireGuard VPN
echo "   Allowing WireGuard..."
ufw allow 51820/udp comment "WireGuard"
ufw allow in on wg0 from 10.0.0.0/24 comment "WireGuard LAN"

# HTTP/HTTPS for Caddy reverse proxy
echo "   Allowing HTTP/HTTPS..."
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"

# Matrix Synapse federation port
echo "   Allowing Matrix federation..."
ufw allow 8448/tcp comment "Matrix Federation"

# Icecast streaming (conditional)
if [[ "$ENABLE_ICECAST" = "y" ]]; then
    echo "   Allowing Icecast..."
    ufw allow 8000/tcp comment "Icecast"
fi

# Canarytokens (conditional)
if [[ "$ENABLE_CANARYTG" = "y" ]]; then
    echo "   Allowing Canarytokens..."
    ufw allow 51821/udp comment "Canarytokens WireGuard"
    ufw allow 5354/tcp comment "Canarytokens DNS"
    ufw allow 5354/udp comment "Canarytokens DNS UDP"
    ufw allow 2500/tcp comment "Canarytokens SMTP"
    ufw allow 3306/tcp comment "Canarytokens MySQL"
fi

# Reload to apply rules
echo "   Reloading UFW..."
ufw reload

echo "✅ UFW rules added"
ufw status verbose
