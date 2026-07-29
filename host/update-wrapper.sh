#!/bin/bash
: '
Title:          Update Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/update so users
               can run "sudo update" to update lemon-vps.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh — copies this file to
                /usr/local/bin/update with 755 permissions.
'

exec /opt/lemon-vps/scripts/update.sh "$@"
