#!/bin/bash
: '
Title:          Upgrade Script
Description:    Pulls the latest code and updates all containers/services.
                Intended for one-time upgrades (unlike "update" which only
                refreshes containers and definitions without code changes).
Author:         Joek Lemon
Contributors:
Notes:          Run: sudo upgrade
                This will:
                  1. git pull --ff-only
                  2. Verify .env has all required keys
                  3. Run the regular update.sh
'

set -o errexit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"
source "$SRC_DIR/scripts/common.sh"

echo "🔄 Upgrading lemon-vps..."
echo ""

# ── Pull latest code ──
echo "── Git ──"
git -C "$SRC_DIR" pull --ff-only || echo "   ⚠️  Git pull failed"

# ── Verify .env keys ──
echo ""
echo "── Config ──"
ENV_FILE="$SRC_DIR/docker/.env"
EXPECTED_KEYS_FILE="$SRC_DIR/docker/.env.example"

TEMPLATE="$(sed 's/=.*//' "$EXPECTED_KEYS_FILE" 2>/dev/null || true)"
CONFIG="$(sed 's/=.*//' "$ENV_FILE" 2>/dev/null || true)"

MISSING=0
while IFS= read -r key; do
    [ -z "$key" ] && continue
    if ! echo "$CONFIG" | grep -qxF "$key"; then
        echo "   ⚠️  Missing key: $key"
        MISSING=$((MISSING + 1))
    fi
done <<< "$TEMPLATE"

if [ "$MISSING" -gt 0 ]; then
    echo ""
    echo "   $MISSING key(s) missing from .env — copy new entries from .env.example"
    echo "   or run 'sudo lemon-config' to reconfigure interactively."
fi

# ── Run update ──
echo ""
echo "── Update ──"
bash "$SCRIPT_DIR/update.sh"

echo ""
echo "✅ lemon-vps upgraded!"
