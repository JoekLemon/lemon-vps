#!/bin/bash
: '
Title:          lemon-vps Entry Point
Description:    One-liner installer that clones the repo and runs the setup.
Author:         Joek Lemon
Contributors:
Notes:          Usage: bash <(curl -s https://raw.githubusercontent.com/JoekLemon/lemon-vps/main/setup.sh)
'

set -o errexit

REPO="https://github.com/JoekLemon/lemon-vps.git"
INSTALL_DIR="/opt/lemon-vps"
LOG_DIR="/var/log/lemon-vps"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir --parents "$LOG_DIR"

# Start logging to file and terminal
exec > >(tee --append "$LOG_FILE") 2>&1

echo "🍋 lemon-vps installer"
echo "======================"
echo ""
echo "📝 Log file: $LOG_FILE"
echo ""

# Ensure git is installed
if ! command -v git > /dev/null 2>&1; then
    echo "📦 Installing git..."
    if command -v apt > /dev/null 2>&1; then
        apt update && apt install --yes git
    elif command -v dnf > /dev/null 2>&1; then
        dnf install --yes git
    elif command -v yum > /dev/null 2>&1; then
        yum install --yes git
    else
        echo "❌ Cannot install git automatically. Please install git and try again."
        exit 1
    fi
fi

# Clone or update repo
echo "📥 Downloading lemon-vps..."
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "   Updating existing install..."
    git -C "$INSTALL_DIR" pull --ff-only || true
else
    rm --recursive --force "$INSTALL_DIR"
    git clone --depth 1 "$REPO" "$INSTALL_DIR"
fi

# Run installer
echo ""
bash "$INSTALL_DIR/scripts/install.sh"

echo ""
echo "✅ lemon-vps installed successfully!"
echo ""
echo "📁 Installed to: $INSTALL_DIR"
echo "📝 Full log saved to: $LOG_FILE"
echo ""
