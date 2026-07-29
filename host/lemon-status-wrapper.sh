#!/bin/bash
: '
Title:          Lemon Status Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/lemon-status so users
                can run "sudo lemon-status" for a quick health overview.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh — copies this file to
                /usr/local/bin/lemon-status with 755 permissions.
'

exec /opt/lemon-vps/host/lemon-status.sh "$@"
