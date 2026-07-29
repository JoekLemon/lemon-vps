#!/bin/bash
: '
Title:          Lemon Smoke Wrapper Script
Description:    Thin wrapper installed to /usr/local/bin/lemon-smoke so users
                can run "sudo lemon-smoke" for a full smoke test.
Author:         Joek Lemon
Contributors:
Notes:          Installed by scripts/install.sh — copies this file to
                /usr/local/bin/lemon-smoke with 755 permissions.
'

exec /opt/lemon-vps/host/smoke-test.sh "$@"
