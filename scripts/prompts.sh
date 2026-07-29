#!/bin/bash
: '
Title:          User Input Collection Script
Description:    Collects all user input for lemon-vps configuration.
Author:         Joek Lemon
Contributors:
Notes:          Exports all variables needed for config generation.
'

prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local silent="$4"

    if [[ -n "$default" ]]; then
        if [[ "$silent" = true ]]; then
            read -rp "$prompt [$default]: " -s value
            echo ""
        else
            read -rp "$prompt [$default]: " value
        fi
        value="${value:-$default}"
    else
        if [[ "$silent" = true ]]; then
            read -rp "$prompt: " -s value
            echo ""
        else
            read -rp "$prompt: " value
        fi
    fi

    eval "$var_name='$value'"
}

prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [[ "$default" = "y" ]]; then
        read -rp "$prompt [Y/n]: " value
        value="${value,,}"
        value="${value:-y}"
    else
        read -rp "$prompt [y/N]: " value
        value="${value,,}"
        value="${value:-n}"
    fi

    eval "$var_name='$value'"
}

collect_inputs() {
    echo ""
    echo "═══════════════════════════════════"
    echo "  🍋 lemon-vps Setup"
    echo "═══════════════════════════════════"
    echo ""

    # ── General ──
    echo "── General ──"
    prompt_input "Domain name" "" DOMAIN
    prompt_input "Email (for Let's Encrypt)" "" EMAIL

    # ── Admin Account ──
    echo ""
    echo "── Admin Account (shared across services) ──"
    prompt_input "Admin username" "admin" ADMIN_USER
    prompt_input "Admin password" "" ADMIN_PASS true

    # ── System User ──
    echo ""
    echo "── System User ──"
    echo "   A non-root user for running services and storing data."
    prompt_input "System username" "lemon" SYSTEM_USER

    # Get or create the system user
    if id "$SYSTEM_USER" > /dev/null 2>&1; then
        echo "   User '$SYSTEM_USER' already exists"
    else
        echo "   Creating user '$SYSTEM_USER'..."
        useradd --create-home --shell /bin/bash "$SYSTEM_USER"
    fi

    # Add to docker group
    if getent group docker > /dev/null 2>&1; then
        usermod --append --groups docker "$SYSTEM_USER"
    fi

    # Set variables based on system user
    SYSTEM_USER_HOME="$(eval echo ~"$SYSTEM_USER")"
    SYSTEM_USER_UID="$(id --user "$SYSTEM_USER")"
    SYSTEM_USER_GID="$(id --group "$SYSTEM_USER")"

    # Create user directories (shared with NextCloud and qBittorrent)
    mkdir --parents "$SYSTEM_USER_HOME/Downloads"
    mkdir --parents "$SYSTEM_USER_HOME/Documents"
    mkdir --parents "$SYSTEM_USER_HOME/Music"
    mkdir --parents "$SYSTEM_USER_HOME/Videos"
    mkdir --parents "$SYSTEM_USER_HOME/Pictures"
    chown "$SYSTEM_USER:$SYSTEM_USER" "$SYSTEM_USER_HOME/Downloads" \
        "$SYSTEM_USER_HOME/Documents" \
        "$SYSTEM_USER_HOME/Music" \
        "$SYSTEM_USER_HOME/Videos" \
        "$SYSTEM_USER_HOME/Pictures"

    echo "   Home: $SYSTEM_USER_HOME"
    echo "   UID:GID = $SYSTEM_USER_UID:$SYSTEM_USER_GID"

    # Matrix server name is always the domain
    MATRIX_SERVER_NAME="$DOMAIN"

    # Synapse database defaults
    SYNAPSE_DB_USER="synapse"
    SYNAPSE_DB_NAME="synapse"

    # NextCloud database defaults
    NEXTCLOUD_DB_USER="nextcloud"
    NEXTCLOUD_DB_NAME="nextcloud"

    # ── Icecast ──
    echo ""
    echo "── Icecast ──"
    prompt_yes_no "Enable Icecast radio streaming?" "y" ENABLE_ICECAST
    if [[ "$ENABLE_ICECAST" = "y" ]]; then
        prompt_input "Source password (for streaming clients)" "" ICECAST_SOURCE_PASS
    else
        ICECAST_SOURCE_PASS=""
    fi

    # ── qBittorrent ──
    echo ""
    echo "── qBittorrent ──"
    prompt_input "Download path (also used as Icecast music library)" "$SYSTEM_USER_HOME/Music" QBIT_SAVE_PATH

    # ── NTFY.sh ──
    echo ""
    echo "── NTFY.sh ──"
    prompt_input "Notification topic" "alerts" NTFY_TOPIC

    # ── Forward Proxy ──
    echo ""
    echo "── Forward Proxy ──"
    prompt_yes_no "Require authentication?" "y" PROXY_AUTH
    if [[ "$PROXY_AUTH" = "y" ]]; then
        prompt_input "Proxy username" "proxy" PROXY_USER
        prompt_input "Proxy password" "" PROXY_PASS true
    else
        PROXY_USER=""
        PROXY_PASS=""
    fi

    # ── CrowdSec ──
    echo ""
    echo "── CrowdSec ──"
    prompt_yes_no "Enable CrowdSec intrusion prevention?" "y" ENABLE_CROWDSEC
    if [[ "$ENABLE_CROWDSEC" = "y" ]]; then
        echo "   Sign up at: https://app.crowdsec.net/"
        echo "   Get your API key from: Settings → API Keys"
        prompt_input "CrowdSec API Key" "" CROWDSEC_API_KEY
    else
        CROWDSEC_API_KEY=""
    fi

    # ── NextDNS ──
    echo ""
    echo "── NextDNS ──"
    echo "   DNS resolver for WireGuard clients (ad-blocking, tracking protection)."
    echo "   Get your profile ID at: https://my.nextdns.io"
    prompt_input "NextDNS profile ID (leave empty to skip)" "" NEXTDNS_PROFILE

    # ── Canarytokens ──
    echo ""
    echo "── Canarytokens ──"
    echo "   Self-hosted honeytokens. Alerts sent via NTFY webhooks."
    prompt_yes_no "Enable Canarytokens?" "n" ENABLE_CANARYTG

    echo ""
    echo "═══════════════════════════════════"
    echo "  Configuration complete"
    echo "═══════════════════════════════════"
    echo ""
}
