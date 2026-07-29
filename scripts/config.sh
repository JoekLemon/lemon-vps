#!/bin/bash
: '
Title:          Lemon Config Script
Description:    Interactive post-install reconfiguration for lemon-vps.
                Lets you view, change, and regenerate configuration
                values without re-running the full install.
Author:         Joek Lemon
Contributors:
Notes:          Run: sudo lemon-config
                Installed to /usr/local/bin/lemon-config.
'

set -o errexit

SRC_DIR="/opt/lemon-vps"
ENV_FILE="$SRC_DIR/docker/.env"
CONFIGS_DIR="$SRC_DIR/docker"

# shellcheck source=/dev/null
source "$ENV_FILE"
source "$SRC_DIR/scripts/common.sh"

show_config() {
    echo ""
    echo "═══════════════════════════════════"
    echo "  Current Configuration"
    echo "═══════════════════════════════════"
    echo ""

    local keys=(
        DOMAIN EMAIL ADMIN_USER
        SYSTEM_USER SYSTEM_USER_HOME SYSTEM_USER_UID SYSTEM_USER_GID
        MATRIX_SERVER_NAME
        SYNAPSE_DB_USER SYNAPSE_DB_NAME NEXTCLOUD_DB_USER NEXTCLOUD_DB_NAME
        ENABLE_ICECAST ICECAST_SOURCE_PASS
        QBIT_SAVE_PATH
        NTFY_TOPIC NTFY_TOKEN
        PROXY_AUTH PROXY_USER
        ENABLE_CROWDSEC CROWDSEC_API_KEY
        NEXTDNS_PROFILE
        ENABLE_CANARYTG
    )

    for key in "${keys[@]}"; do
        local val="${!key}"
        if [[ "$key" == *PASS* || "$key" == *SECRET* || "$key" == *TOKEN* || "$key" == *API_KEY* ]]; then
            if [[ -n "$val" ]]; then
                val="${val:0:4}... (hidden)"
            fi
        fi
        printf "  %-30s = %s\n" "$key" "${val:-<empty>}"
    done
    echo ""
}

regenerate_passwords() {
    echo ""
    echo "── Regenerating Passwords and Tokens ──"
    echo "   This will update passwords in the .env file."
    echo "   Services that depend on these will need to be restarted."
    echo ""

    local pw_keys=(SYNAPSE_DB_PASSWORD NEXTCLOUD_DB_PASSWORD PROXY_PASS)
    local tk_keys=(MATRIX_SECRET_KEY GITEA_SECRET_KEY)

    for key in "${pw_keys[@]}"; do
        local val
        val=$(openssl rand -base64 32 | tr -d '/+=')
        # Update in current shell
        printf -v "$key" '%s' "$val"
        # Update in .env
        sed -i "s|^$key=.*|$key=$val|" "$ENV_FILE"
        echo "   $key regenerated"
    done

    for key in "${tk_keys[@]}"; do
        local val
        val=$(openssl rand -base64 48 | tr -d '/+=')
        printf -v "$key" '%s' "$val"
        sed -i "s|^$key=.*|$key=$val|" "$ENV_FILE"
        echo "   $key regenerated"
    done

    local ntfy_token
    ntfy_token=$(openssl rand -base64 24 | tr -d '/+=')
    NTFY_TOKEN="$ntfy_token"
    sed -i "s|^NTFY_TOKEN=.*|NTFY_TOKEN=$ntfy_token|" "$ENV_FILE"
    echo "   NTFY_TOKEN regenerated"

    source "$ENV_FILE"
    echo "   ✅ Passwords/tokens updated in .env"
}

restart_services() {
    local profiles
    profiles=$(detect_docker_profiles "$CONFIGS_DIR")
    echo "   Restarting Docker containers..."
    docker compose -f "$CONFIGS_DIR/docker-compose.yml" $profiles up -d
    echo "   ✅ Containers restarted"
}

menu() {
    while true; do
        echo ""
        echo "═══════════════════════════════════"
        echo "  🍋 lemon-vps Configuration"
        echo "═══════════════════════════════════"
        echo ""
        echo "  1) View current configuration"
        echo "  2) Change domain"
        echo "  3) Change admin password"
        echo "  4) Regenerate all passwords and tokens"
        echo "  5) Enable/disable services"
        echo "  6) Run full setup prompts (reconfigure all)"
        echo "  7) Regenerate configs and restart services"
        echo "  q) Quit"
        echo ""
        read -rp "  Choose an option [1-7/q]: " choice

        case "$choice" in
            1) show_config ;;
            2) change_domain ;;
            3) change_admin_pass ;;
            4) regenerate_passwords
               echo "   Run option 7 to apply changes." ;;
            5) toggle_services ;;
            6) full_reconfigure ;;
            7) apply_configs ;;
            q|Q) echo "   Exiting."; break ;;
            *) echo "   Invalid option." ;;
        esac
    done
}

change_domain() {
    echo ""
    echo "── Change Domain ──"
    read -rp "  New domain name [current: $DOMAIN]: " new_domain
    if [[ -z "$new_domain" ]]; then
        echo "   No change."
        return
    fi
    DOMAIN="$new_domain"
    MATRIX_SERVER_NAME="$DOMAIN"
    sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN|" "$ENV_FILE"
    sed -i "s|^MATRIX_SERVER_NAME=.*|MATRIX_SERVER_NAME=$MATRIX_SERVER_NAME|" "$ENV_FILE"
    echo "   Domain updated to $DOMAIN"
    echo "   Run option 7 to regenerate configs and restart services."
}

change_admin_pass() {
    echo ""
    echo "── Change Admin Password ──"
    read -rsp "  New admin password: " new_pass
    echo ""
    if [[ -z "$new_pass" ]]; then
        echo "   Password unchanged."
        return
    fi
    ADMIN_PASS="$new_pass"
    sed -i "s|^ADMIN_PASS=.*|ADMIN_PASS=$ADMIN_PASS|" "$ENV_FILE"
    echo "   Admin password updated."
}

toggle_services() {
    echo ""
    echo "── Toggle Services ──"
    echo ""

    local toggle_list=(
        "ENABLE_ICECAST:Icecast streaming"
        "ENABLE_CROWDSEC:CrowdSec intrusion prevention"
        "ENABLE_CANARYTG:Canarytokens honeytokens"
    )

    # Source current .env to get fresh values
    source "$ENV_FILE"

    for entry in "${toggle_list[@]}"; do
        local var="${entry%%:*}"
        local label="${entry#*:}"
        local current="${!var}"

        echo "   $var: $current"
        read -rp "   Enable $label? [y/N]: " yn
        yn="${yn,,}"
        yn="${yn:-n}"
        if [[ "$yn" = "y" ]]; then
            if [[ "$var" = "ENABLE_CROWDSEC" && -z "$CROWDSEC_API_KEY" ]]; then
                read -rp "   CrowdSec API Key: " CROWDSEC_API_KEY
                sed -i "s|^CROWDSEC_API_KEY=.*|CROWDSEC_API_KEY=$CROWDSEC_API_KEY|" "$ENV_FILE"
            fi
            sed -i "s|^$var=.*|$var=y|" "$ENV_FILE"
            printf -v "$var" '%s' "y"
            echo "   $label enabled."
        else
            sed -i "s|^$var=.*|$var=|" "$ENV_FILE"
            printf -v "$var" '%s' ""
            echo "   $label disabled."
        fi
    done
    echo "   Run option 7 to apply changes."
}

full_reconfigure() {
    echo ""
    echo "── Full Reconfiguration ──"
    echo "   You will be asked all setup questions again."
    echo "   Existing values will be shown as defaults."
    echo ""

    # Source prompts, but modify it to use existing .env values as defaults
    pushd "$SRC_DIR" > /dev/null

    # Collect new values
    source "$SRC_DIR/scripts/prompts.sh"
    # Override collect_inputs with a version that pre-fills from current env
    collect_inputs
    # Now all prompt variables are set

    # Save to .env — reuse the existing generation logic
    bash "$SRC_DIR/scripts/generate-configs.sh"
    source "$ENV_FILE"

    echo "   Configuration updated."
    echo "   Run option 7 to apply."
    popd > /dev/null
}

apply_configs() {
    echo ""
    echo "── Apply Configuration ──"
    echo "   Regenerating config files and restarting services..."
    bash "$SRC_DIR/scripts/generate-configs.sh"
    restart_services
    echo "   ✅ Configuration applied."
}

# Only run menu if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    menu
fi
