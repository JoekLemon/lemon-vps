#!/bin/bash
: '
Title:          Config Generator Script
Description:    Replaces placeholders in config files with user values.
Author:         Joek Lemon
Contributors:
Notes:          Uses {{PLACEHOLDER}} syntax, sed -i to edit in-place.
'

generate_configs() {
    local src_dir="$1"

    echo "🔧 Configuring files..."

    # Generate WireGuard tools (needed for add-peer.sh later)
    echo "   Installing WireGuard tools..."
    if command -v apt > /dev/null 2>&1; then
        apt install --yes --quiet wireguard-tools > /dev/null 2>&1
    elif command -v dnf > /dev/null 2>&1; then
        dnf install --yes wireguard-tools > /dev/null 2>&1
    elif command -v yum > /dev/null 2>&1; then
        yum install --yes wireguard-tools > /dev/null 2>&1
    fi

    # Generate Matrix signing key
    echo "   Generating Matrix signing key..."
    MATRIX_SECRET_KEY=$(openssl rand -hex 32)

    # Generate NTFY auth token
    echo "   Generating NTFY auth token..."
    NTFY_TOKEN=$(openssl rand -hex 32)

    # Generate Synapse database password
    echo "   Generating Synapse database password..."
    SYNAPSE_DB_PASSWORD=$(openssl rand -hex 32)

    # Generate NextCloud database password
    echo "   Generating NextCloud database password..."
    NEXTCLOUD_DB_PASSWORD=$(openssl rand -hex 32)

    # Generate Canarytokens WireGuard key seed
    if [ "$ENABLE_CANARYTG" = "y" ]; then
        echo "   Generating Canarytokens WireGuard key seed..."
        CANARYTG_WG_KEY_SEED=$(dd bs=32 count=1 if=/dev/urandom 2>/dev/null | base64)
        echo "   Detecting VPS public IP for Canarytokens..."
        VPS_PUBLIC_IP=$(curl --fail --silent --show-error https://api.ipify.org || curl --fail --silent --show-error https://ifconfig.co)
    fi

    # sed in-place replacement
    sed_fill() {
        sed -i \
            -e "s|{{DOMAIN}}|$DOMAIN|g" \
            -e "s|{{EMAIL}}|$EMAIL|g" \
            -e "s|{{ADMIN_USER}}|$ADMIN_USER|g" \
            -e "s|{{ADMIN_PASS}}|$ADMIN_PASS|g" \
            -e "s|{{SYSTEM_USER}}|$SYSTEM_USER|g" \
            -e "s|{{SYSTEM_USER_HOME}}|$SYSTEM_USER_HOME|g" \
            -e "s|{{SYSTEM_USER_UID}}|$SYSTEM_USER_UID|g" \
            -e "s|{{SYSTEM_USER_GID}}|$SYSTEM_USER_GID|g" \
            -e "s|{{SYNAPSE_DB_USER}}|$SYNAPSE_DB_USER|g" \
            -e "s|{{SYNAPSE_DB_PASSWORD}}|$SYNAPSE_DB_PASSWORD|g" \
            -e "s|{{SYNAPSE_DB_NAME}}|$SYNAPSE_DB_NAME|g" \
            -e "s|{{NEXTCLOUD_DB_NAME}}|$NEXTCLOUD_DB_NAME|g" \
            -e "s|{{NEXTCLOUD_DB_USER}}|$NEXTCLOUD_DB_USER|g" \
            -e "s|{{NEXTCLOUD_DB_PASSWORD}}|$NEXTCLOUD_DB_PASSWORD|g" \
            -e "s|{{MATRIX_SERVER_NAME}}|$MATRIX_SERVER_NAME|g" \
            -e "s|{{MATRIX_SECRET_KEY}}|$MATRIX_SECRET_KEY|g" \
            -e "s|{{ICECAST_SOURCE_PASS}}|$ICECAST_SOURCE_PASS|g" \
            -e "s|{{QBIT_SAVE_PATH}}|$QBIT_SAVE_PATH|g" \
            -e "s|{{NTFY_TOPIC}}|$NTFY_TOPIC|g" \
            -e "s|{{NTFY_TOKEN}}|$NTFY_TOKEN|g" \
            -e "s|{{PROXY_AUTH}}|$PROXY_AUTH|g" \
            -e "s|{{PROXY_USER}}|$PROXY_USER|g" \
            -e "s|{{PROXY_PASS}}|$PROXY_PASS|g" \
            -e "s|{{CANARYTG_WG_KEY_SEED}}|$CANARYTG_WG_KEY_SEED|g" \
            -e "s|{{VPS_PUBLIC_IP}}|$VPS_PUBLIC_IP|g" \
            "$1"
    }

    # Docker configs
    echo "   Writing docker configs..."
    sed_fill "$src_dir/docker/.env"

    # Remove basic_auth from Caddyfile if proxy auth is disabled
    if [ "$PROXY_AUTH" != "y" ]; then
        sed -i "/basic_auth/d" "$src_dir/docker/caddy/Caddyfile"
    fi
    sed_fill "$src_dir/docker/caddy/Caddyfile"
    sed_fill "$src_dir/docker/synapse/homeserver.yaml"
    sed_fill "$src_dir/docker/gitea/app.ini"
    sed_fill "$src_dir/docker/qbittorrent/qBittorrent.conf"
    sed_fill "$src_dir/docker/ntfy/config/server.yml"

    # Icecast config (conditional)
    if [ "$ENABLE_ICECAST" = "y" ]; then
        echo "   Writing Icecast config..."
        sed_fill "$src_dir/docker/icecast/icecast.xml"
    fi

    # Canarytokens configs (conditional)
    if [ "$ENABLE_CANARYTG" = "y" ]; then
        echo "   Writing Canarytokens configs..."
        sed_fill "$src_dir/docker/canarytokens/frontend.env"
        sed_fill "$src_dir/docker/canarytokens/switchboard.env"
    fi

    # Fix ownership for files that containers write to
    echo "   Fixing file ownership..."
    # Gitea drops to UID 1000 (git user) and writes JWT_SECRET to app.ini
    chown 1000:1000 "$src_dir/docker/gitea/app.ini"
    chown 1000:1000 "$src_dir/docker/gitea/data/gitea/conf/" 2>/dev/null || true

    # Export generated values for later use
    export MATRIX_SECRET_KEY NTFY_TOKEN SYNAPSE_DB_PASSWORD NEXTCLOUD_DB_PASSWORD

    echo "✅ Configs generated"
}
