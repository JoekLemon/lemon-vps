#!/bin/bash
: '
Title:          Config Generator Script
Description:    Generates all config files from templates by replacing placeholders.
Author:         Joek Lemon
Contributors:
Notes:          Uses {{PLACEHOLDER}} syntax in templates.
'

generate_configs() {
    local src_dir="$1"

    echo "🔧 Generating configs from templates..."

    # Generate WireGuard keys
    echo "   Generating WireGuard keys..."
    WG_PRIVATE_KEY=$(wg genkey)
    WG_PUBLIC_KEY=$(echo "$WG_PRIVATE_KEY" | wg pubkey)
    WG_PRESHARED_KEY=$(wg genpsk)

    # Generate Matrix signing key
    echo "   Generating Matrix signing key..."
    MATRIX_SECRET_KEY=$(openssl rand -hex 32)

    # Generate NTFY auth token
    echo "   Generating NTFY auth token..."
    NTFY_TOKEN=$(openssl rand -hex 32)

    # Build sed replacement command
    sed_replace() {
        sed \
            -e "s|{{DOMAIN}}|$DOMAIN|g" \
            -e "s|{{EMAIL}}|$EMAIL|g" \
            -e "s|{{ADMIN_USER}}|$ADMIN_USER|g" \
            -e "s|{{ADMIN_PASS}}|$ADMIN_PASS|g" \
            -e "s|{{MATRIX_SERVER_NAME}}|$MATRIX_SERVER_NAME|g" \
            -e "s|{{MATRIX_SECRET_KEY}}|$MATRIX_SECRET_KEY|g" \
            -e "s|{{WG_PRIVATE_KEY}}|$WG_PRIVATE_KEY|g" \
            -e "s|{{WG_PUBLIC_KEY}}|$WG_PUBLIC_KEY|g" \
            -e "s|{{WG_PRESHARED_KEY}}|$WG_PRESHARED_KEY|g" \
            -e "s|{{WG_PEER_PUBKEY}}|$WG_PEER_PUBKEY|g" \
            -e "s|{{ICECAST_SOURCE_PASS}}|$ICECAST_SOURCE_PASS|g" \
            -e "s|{{QBIT_SAVE_PATH}}|$QBIT_SAVE_PATH|g" \
            -e "s|{{NTFY_TOPIC}}|$NTFY_TOPIC|g" \
            -e "s|{{NTFY_TOKEN}}|$NTFY_TOKEN|g" \
            -e "s|{{PROXY_AUTH}}|$PROXY_AUTH|g" \
            -e "s|{{PROXY_USER}}|$PROXY_USER|g" \
            -e "s|{{PROXY_PASS}}|$PROXY_PASS|g" \
            -e "s|{{CROWDSEC_CUSTOMER_ID}}|$CROWDSEC_CUSTOMER_ID|g" \
            -e "s|{{CROWDSEC_API_KEY}}|$CROWDSEC_API_KEY|g"
    }

    # Docker configs
    echo "   Writing docker configs..."
    sed_replace < "$src_dir/docker/.env.template" > "$src_dir/docker/.env"
    sed_replace < "$src_dir/docker/caddy/Caddyfile.template" > "$src_dir/docker/caddy/Caddyfile"
    sed_replace < "$src_dir/docker/synapse/homeserver.yaml.template" > "$src_dir/docker/synapse/homeserver.yaml"
    sed_replace < "$src_dir/docker/gitea/app.ini.template" > "$src_dir/docker/gitea/app.ini"
    sed_replace < "$src_dir/docker/gitea-runner/config.template" > "$src_dir/docker/gitea-runner/config.yaml"
    sed_replace < "$src_dir/docker/icecast/icecast.xml.template" > "$src_dir/docker/icecast/icecast.xml"
    sed_replace < "$src_dir/docker/qbittorrent/qBittorrent.conf.template" > "$src_dir/docker/qbittorrent/qBittorrent.conf"

    # Host configs
    echo "   Writing host configs..."
    sed_replace < "$src_dir/host/wireguard/templates/wg0.conf.template" > "$src_dir/host/wireguard/wg0.conf"
    sed_replace < "$src_dir/host/crowdsec/config/crowdsec.yaml.template" > "$src_dir/host/crowdsec/config/crowdsec.yaml"
    sed_replace < "$src_dir/host/crowdsec/config/acquis.yaml.template" > "$src_dir/host/crowdsec/config/acquis.yaml"

    # Export generated values for later use
    export WG_PRIVATE_KEY WG_PUBLIC_KEY WG_PRESHARED_KEY MATRIX_SECRET_KEY NTFY_TOKEN

    echo "✅ Configs generated"
}
