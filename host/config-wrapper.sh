#!/bin/bash
: '
Title:          Config Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/lemon-config so
                users can run "sudo lemon-config" to reconfigure services.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh.
'

exec /opt/lemon-vps/scripts/config.sh "$@"
