#!/bin/bash
: '
Title:          Upgrade Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/upgrade so users
                can run "sudo upgrade" to pull latest code and update services.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh.
'

exec /opt/lemon-vps/scripts/upgrade.sh "$@"
