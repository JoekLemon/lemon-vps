#!/bin/bash
: '
Title:          NTFY Notify Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/lemon-notify so users
                can run "lemon-notify" to send push notifications.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh — copies this file to
                /usr/local/bin/lemon-notify with 755 permissions.
'

exec /opt/lemon-vps/host/notify.sh "$@"
