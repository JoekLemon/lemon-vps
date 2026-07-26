#!/bin/bash
: '
Title:          ClamAV Logrotate Script
Description:    Runs logrotate for ClamAV On-Access and ClamScan logs.
Author:         Joek Lemon
Contributors:
Notes:          Called by clamav-logrotate.service.
'

set -o errexit

LOGROTATE="/usr/sbin/logrotate"
LOGROTATE_DIR="/etc/logrotate.d"

echo "🔄 Running ClamAV logrotate..."

# Rotate ClamScan logs
if [[ -f "$LOGROTATE_DIR/clamscan_logrotate.conf" ]]; then
    sudo "$LOGROTATE" --force "$LOGROTATE_DIR/clamscan_logrotate.conf"
    echo "   ✅ ClamScan logs rotated"
fi

# Rotate ClamAV On-Access logs
if [[ -f "$LOGROTATE_DIR/clamonacc_logrotate.conf" ]]; then
    sudo "$LOGROTATE" --force "$LOGROTATE_DIR/clamonacc_logrotate.conf"
    echo "   ✅ ClamAV On-Access logs rotated"
fi

echo "🔄 Logrotate complete"
