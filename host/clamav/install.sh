#!/bin/bash
: '
Title:          ClamAV Install Script
Description:    Installs ClamAV with on-access scanning and hardened configuration.
Author:         Joek Lemon
Contributors:
Notes:          Includes clamonacc, clamscan, and logrotate services.
'

echo "🦠 Installing ClamAV..."

# Install ClamAV packages
pkg_install clamav clamav-daemon clamav-on-access clamav-unofficial-sigs

# Stop services for initial setup
echo "   Stopping ClamAV services for update..."
systemctl stop clamav-daemon 2>/dev/null || true
systemctl stop clamav-freshclam 2>/dev/null || true

# Update virus definitions
echo "   Updating virus definitions (this may take a while)..."
freshclam

# Create quarantine directory
echo "   Creating quarantine directory..."
mkdir -p /var/log/clamav/quarantine

# Deploy hardened clamd.conf
echo "   Deploying hardened clamd.conf..."
cp "$SRC_DIR/host/clamav/config/clamd.conf" /etc/clamav/clamd.conf

# Deploy systemd units
echo "   Deploying systemd units..."
cp "$SRC_DIR/host/clamav/clamonacc.service" /etc/systemd/system/
cp "$SRC_DIR/host/clamav/clamscan.service" /etc/systemd/system/
cp "$SRC_DIR/host/clamav/clamav-logrotate.service" /etc/systemd/system/

# Deploy logrotate configs
echo "   Deploying logrotate configs..."
cp "$SRC_DIR/host/clamav/config/clamonacc_logrotate.conf" /etc/logrotate.d/
cp "$SRC_DIR/host/clamav/config/clamscan_logrotate.conf" /etc/logrotate.d/

# Deploy logrotate script
echo "   Deploying logrotate script..."
cp "$SRC_DIR/host/clamav/scripts/logrotate.sh" /usr/local/bin/clamav-logrotate
chmod +x /usr/local/bin/clamav-logrotate

# Reload systemd
echo "   Reloading systemd..."
systemctl daemon-reload

# Enable and start services
echo "   Starting ClamAV services..."
systemctl enable --now clamav-daemon
systemctl enable --now clamav-freshclam
systemctl enable --now clamonacc

echo "✅ ClamAV installed with on-access scanning"
echo "   Quarantine: /var/log/clamav/quarantine"
echo "   Logs: /var/log/clamav/"
