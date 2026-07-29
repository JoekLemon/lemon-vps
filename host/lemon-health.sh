#!/bin/bash
: '
Title:          Lemon Health Check Script
Description:    Runs the smoke test and sends a push notification on failure.
Author:         Joek Lemon
Contributors:
Notes:          Called by lemon-health.service (systemd timer). Runs quietly
                and only alerts when checks fail.
'

set -o errexit

SRC_DIR="/opt/lemon-vps"

OUTPUT=$(bash "$SRC_DIR/host/smoke-test.sh" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -gt 0 ]; then
    bash "$SRC_DIR/host/notify.sh" \
        "Smoke test: $EXIT_CODE checks failed. Run 'sudo lemon-smoke' for details." \
        "lemon-vps Health Alert" \
        high
fi

exit "$EXIT_CODE"
