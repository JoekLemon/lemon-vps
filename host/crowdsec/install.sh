#!/bin/bash
: '
Title:          CrowdSec Install Script
Description:    Installs CrowdSec for intrusion prevention.
Author:         Joek Lemon
Contributors:
Notes:          Follows official CrowdSec install guide.
'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
# shellcheck source=../../scripts/detect-os.sh
source "$SRC_DIR/scripts/detect-os.sh"
detect_os

echo "🛡️ Installing CrowdSec..."

# Step 1: Add CrowdSec repository
echo "   Adding CrowdSec repository..."
curl --fail --silent --show-error https://install.crowdsec.net | bash

# Step 2: Install CrowdSec
echo "   Installing CrowdSec..."
pkg_install crowdsec

# Step 3: Enroll with CrowdSec console
echo "   Enrolling with CrowdSec console..."
cscli console enroll "$CROWDSEC_API_KEY" || echo "   ⚠️  Enrollment may need manual completion"

echo "✅ CrowdSec installed"
echo "   See CrowdSec_Guide.md for next steps"
