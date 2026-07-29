#!/bin/bash
: '
Title:          NTFY Notify Script
Description:    Sends push notifications via NTFY using docker compose exec.
Author:         Joek Lemon
Contributors:
Notes:          Installed to /usr/local/bin/lemon-notify. Reads NTFY_TOPIC
                from .env and publishes through the running ntfy container.
                Usage: lemon-notify <message> [title] [priority]
'

set -o errexit

SRC_DIR="/opt/lemon-vps"
TOPIC=$(grep '^NTFY_TOPIC=' "$SRC_DIR/docker/.env" 2>/dev/null | cut -d= -f2-)

MESSAGE="${1:?Usage: lemon-notify <message> [title] [priority]}"
TITLE="${2:-lemon-vps}"
PRIORITY="${3:-default}"

docker compose -f "$SRC_DIR/docker/docker-compose.yml" exec -T ntfy \
    ntfy publish \
    --title="$TITLE" \
    --priority="$PRIORITY" \
    "$TOPIC" \
    "$MESSAGE"
