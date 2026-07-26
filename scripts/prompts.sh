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

    if [ -n "$default" ]; then
        if [ "$silent" = true ]; then
            read -rp "$prompt [$default]: " -s value
            echo ""
        else
            read -rp "$prompt [$default]: " value
        fi
        value="${value:-$default}"
    else
        if [ "$silent" = true ]; then
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

    if [ "$default" = "y" ]; then
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

    # Matrix server name is always the domain
    MATRIX_SERVER_NAME="$DOMAIN"

    # ── Icecast ──
    echo ""
    echo "── Icecast ──"
    prompt_yes_no "Enable Icecast radio streaming?" "y" ENABLE_ICECAST
    if [ "$ENABLE_ICECAST" = "y" ]; then
        prompt_input "Source password (for streaming clients)" "" ICECAST_SOURCE_PASS
    else
        ICECAST_SOURCE_PASS=""
    fi

    # ── qBittorrent ──
    echo ""
    echo "── qBittorrent ──"
    prompt_input "Download path" "/home/${SUDO_USER:-$USER}/Music" QBIT_SAVE_PATH

    # ── NTFY.sh ──
    echo ""
    echo "── NTFY.sh ──"
    prompt_input "Notification topic" "alerts" NTFY_TOPIC

    # ── Forward Proxy ──
    echo ""
    echo "── Forward Proxy ──"
    prompt_yes_no "Require authentication?" "y" PROXY_AUTH
    if [ "$PROXY_AUTH" = "y" ]; then
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
    if [ "$ENABLE_CROWDSEC" = "y" ]; then
        echo "   Sign up at: https://app.crowdsec.net/"
        prompt_input "CrowdSec Customer ID" "" CROWDSEC_CUSTOMER_ID
        prompt_input "CrowdSec API Key" "" CROWDSEC_API_KEY
    else
        CROWDSEC_CUSTOMER_ID=""
        CROWDSEC_API_KEY=""
    fi

    echo ""
    echo "═══════════════════════════════════"
    echo "  Configuration complete"
    echo "═══════════════════════════════════"
    echo ""
}
