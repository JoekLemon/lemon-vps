# CrowdSec Setup Guide

## Overview

CrowdSec is an open-source intrusion prevention system that analyzes logs
to ban malicious IPs. This guide walks you through setup and connecting
your account to the CrowdSec API.

## Step 1: Create a CrowdSec Account

1. Go to https://app.crowdsec.net/
2. Sign up for a free account
3. Complete the onboarding process

## Step 2: Get Your Credentials

After signing in:

1. Go to **Settings** → **API Keys**
2. Copy your **Console API Key**
3. Go to **Settings** → **Overview**
4. Copy your **Customer ID**

You'll be prompted for these during the lemon-vps installation.

## Step 3: Installation

The installer will:

1. Add the CrowdSec repository
2. Install CrowdSec and the iptables firewall bouncer
3. Configure your API credentials
4. Enroll your instance with the console

## Step 4: Verify Installation

```bash
# Check CrowdSec status
sudo cscli decisions list

# Check bouncer status
sudo cscli bouncers list

# View alerts
sudo cscli alerts list
```

## Step 5: Verify Bouncer

The iptables firewall bouncer enforces bans at the firewall level:

```bash
# Check bouncer is active
sudo systemctl status crowdsec-firewall-bouncer-iptables

# View bouncer logs
sudo journalctl -u crowdsec-firewall-bouncer-iptables
```

## Step 6: Test Protection

```bash
# Manually ban an IP
sudo cscli decisions add --ip 1.2.3.4 --duration 24h

# Check if an IP is banned
sudo cscli decisions list

# Unban an IP
sudo cscli decisions delete --ip 1.2.3.4
```

## Step 7: Configure Log Sources

Edit `/etc/crowdsec/acquis.yaml` to add or modify log sources:

```yaml
# System logs
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog

# Web server logs
filenames:
  - /var/log/nginx/access.log
  - /var/log/caddy/access.log
labels:
  type: nginx
```

After changes:

```bash
sudo systemctl restart crowdsec
```

## Step 8: Access Dashboard

1. Go to https://app.crowdsec.net/
2. Your enrolled instance will appear
3. View alerts, bans, and statistics

## Useful Commands

```bash
# View all alerts
sudo cscli alerts list

# View all bans
sudo cscli decisions list

# View installed scenarios
sudo cscli scenarios list

# View installed parsers
sudo cscli parsers list

# Check config
sudo cscli config show

# View hub status
sudo cscli hub list

# Test acquisition config
sudo cscli acquisition validate
```

## Adding Community Scenarios

CrowdSec has a hub of community scenarios:

```bash
# Search for scenarios
sudo cscli hub list --type scenarios

# Install a scenario
sudo cscli scenarios install crowdsecurity/http-crawl-static_static
```

## Troubleshooting

### CrowdSec won't start

```bash
# Check logs
sudo journalctl -u crowdsec -f

# Validate config
sudo cscli config show
```

### Bouncer not banning

```bash
# Check bouncer status
sudo cscli bouncers list

# Check UFW status
sudo ufw status

# Restart bouncer
sudo systemctl restart crowdsec-firewall-bouncer-iptables
```

### No alerts appearing

```bash
# Check acquisition sources
sudo cscli acquisition show

# Test log parsing
sudo cscli log-parse /var/log/auth.log
```

## Further Reading

- [CrowdSec Documentation](https://doc.crowdsec.net/)
- [CrowdSec Hub](https://hub.crowdsec.net/)
- [Console Documentation](https://doc.crowdsec.net/docs/console/)
