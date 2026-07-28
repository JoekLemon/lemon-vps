#!/bin/bash
: '
Title:          Synapse Add User Script
Description:    Creates a new Matrix user via the register_new_matrix_user CLI.
Author:         Joek Lemon
Contributors:
Notes:          Run this on the VPS to add users without Element.
                Usage: sudo bash add-user.sh <username> [password]
                       sudo bash add-user.sh --admin <username> [password]
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "   Usage: sudo bash add-user.sh <username> [password]"
    echo "          sudo bash add-user.sh --admin <username> [password]"
    exit 1
fi

ADMIN_FLAG=""
if [ "$1" = "--admin" ]; then
    ADMIN_FLAG="-a"
    shift
fi

if [ -z "$1" ]; then
    echo "❌ Provide a username"
    echo "   Usage: sudo bash add-user.sh <username> [password]"
    echo "   Usage: sudo bash add-user.sh --admin <username> [password]"
    echo "   Example: sudo bash add-user.sh alice"
    echo "   Example: sudo bash add-user.sh --admin alice"
    exit 1
fi

USERNAME="$1"
PASSWORD="${2:-}"

# Check Synapse container is running
if ! docker ps --format '{{.Names}}' | grep --quiet '^synapse$'; then
    echo "❌ Synapse container is not running"
    echo "   Start it with: cd $SRC_DIR/docker && docker compose up -d synapse"
    exit 1
fi

echo "👤 Creating Matrix user: $USERNAME"

if [ -n "$ADMIN_FLAG" ]; then
    echo "   Role: admin"
fi

if [ -n "$PASSWORD" ]; then
    docker exec synapse register_new_matrix_user \
        http://localhost:8008 \
        --user "$USERNAME" \
        --password "$PASSWORD" \
        $ADMIN_FLAG
else
    docker exec --interactive synapse register_new_matrix_user \
        http://localhost:8008 \
        --user "$USERNAME" \
        $ADMIN_FLAG
fi

echo ""
echo "✅ User '$USERNAME' created"
echo "   Server: $USERNAME@$(docker exec synapse cat /data/homeserver.yaml 2>/dev/null | grep server_name | awk '{print $2}' | tr -d '"' || echo '<your_domain>')"
echo "   Login at: https://matrix.<your_domain>"
