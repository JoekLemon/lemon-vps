#!/bin/bash
: '
Title:          Common Library
Description:    Shared functions used across lemon-vps scripts.
Author:         Joek Lemon
Contributors:
Notes:          Source with: source "$SRC_DIR/scripts/common.sh"
'

# Detect active Docker profiles by inspecting running containers.
# Usage: PROFILES=$(detect_docker_profiles /path/to/docker/dir)
detect_docker_profiles() {
    local dir="$1"
    (
        cd "$dir" 2>/dev/null || { echo ""; exit; }
        if docker compose ps 2>/dev/null | grep -q "icecast"; then
            echo "--profile icecast"
        fi
        if docker compose ps 2>/dev/null | grep -q "canary"; then
            echo "--profile canarytokens"
        fi
    ) | paste -sd " "
}

# Check a Docker container status and print formatted line.
# Usage: check_docker_svc "container-name" "label"
check_docker_svc() {
    local name="$1"
    local label="${2:-$name}"
    local state
    state=$(docker ps --filter "name=docker-$name-1" --format '{{.Status}}' 2>/dev/null | head -1)
    if [ -n "$state" ]; then
        printf "  %-15s running  (%s)\n" "$label" "$state"
    else
        state=$(docker ps -a --filter "name=docker-$name-1" --format '{{.Status}}' 2>/dev/null | head -1)
        if [ -n "$state" ]; then
            printf "  %-15s stopped  (%s)\n" "$label" "$state"
        else
            printf "  %-15s \u2014        (not deployed)\n" "$label"
        fi
    fi
}

# Check systemd service status and print formatted line.
# Usage: check_systemd_svc "service-name"
check_systemd_svc() {
    local name="$1"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        printf "  %-20s active\n" "$name"
    else
        printf "  %-20s inactive\n" "$name"
    fi
}

# Set an sshd_config option idempotently (update or append).
# Usage: set_sshd_option "Key" "Value" [/path/to/sshd_config]
set_sshd_option() {
    local key="$1" val="$2"
    local file="${3:-/etc/ssh/sshd_config}"
    if grep -q "^$key" "$file" 2>/dev/null; then
        sed -i "s/^$key.*/$key $val/" "$file"
    else
        echo "$key $val" >> "$file"
    fi
}
