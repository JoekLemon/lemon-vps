# Canarytokens Setup Guide

## Overview

Canarytokens are tripwires — small pieces of data (documents, URLs, DNS records, API keys, etc.)
that alert you when someone accesses them. Your instance is self-hosted at `https://canary.{{DOMAIN}}`.

Alerts are sent to your NTFY topic at `https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}`.

## Initial Setup

### 1. Point DNS

Add a DNS A record:

```
canary.{{DOMAIN}}  →  YOUR_VPS_IP
nx.{{DOMAIN}}      →  YOUR_VPS_IP  (for PDF token NXDOMAIN tracking)
```

### 2. Access the Dashboard

Visit `https://canary.{{DOMAIN}}/generate` in your browser.

### 3. Create Your First Token

1. Click on a token type (e.g., "Web token")
2. Give it a descriptive name (e.g., "Server Room Document")
3. Under **Alert when triggered**, select **Webhook**
4. Enter the webhook URL:

```
https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}
```

5. Click **Create token**

### 4. Test It

1. Copy the token URL from the confirmation page
2. Open it in a new browser/incognito window
3. Check your NTFY notifications — you should receive an alert

## Token Types

| Type | How It Works |
|------|-------------|
| **Web token** | A URL that alerts when visited |
| **DNS token** | A DNS record that alerts when queried |
| **Microsoft Word doc** | A .docx file that alerts when opened |
| **PDF token** | A .pdf file that alerts when opened (requires nx.{{DOMAIN}} DNS) |
| **AWS key** | A fake AWS key that alerts when used |
| **Azure login certificate** | A fake Azure cert that alerts when used |
| **Cloned website** | A cloned login page that alerts on submission |
| **QR code** | A QR code that alerts when scanned |
| **WireGuard** | A WireGuard config that alerts when connected |
| **SQL server** | A MySQL connection string that alerts when connected |
| **Windows folder** | A Windows folder that alerts when browsed |
| **Kubeconfig** | A fake Kubernetes config that alerts when used |
| **Stripe key** | A fake Stripe API key that alerts when used |
| **CVE token** | A fake vulnerability that alerts when exploited |

## Managing Tokens

- **List tokens**: `https://canary.{{DOMAIN}}/manage`
- **History**: `https://canary.{{DOMAIN}}/history`
- **Settings**: `https://canary.{{DOMAIN}}/settings`

## Security Note

The dashboard is currently open to anyone with the URL. To add basic auth:

```bash
# On the VPS
htpasswd -c /opt/lemon-vps/docker/canarytokens/.htpasswd canary
# Enter a password when prompted
```

Then add to `docker/canarytokens/switchboard.env`:

```
CANARY_FORCE_HTTPS=true
```

And restart:

```bash
cd /opt/lemon-vps/docker && docker compose restart canary-switchboard canary-frontend
```

Then access at `https://canary.{{DOMAIN}}/generate` with the credentials you set.

## Troubleshooting

**Token alerts not arriving at NTFY?**

1. Test NTFY directly:
   ```bash
   curl -d "Test alert" https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}
   ```
2. Check switchboard logs:
   ```bash
   docker logs canary-switchboard
   ```
3. Verify the webhook URL in the token settings matches exactly

**Dashboard not loading?**

1. Check DNS: `dig canary.{{DOMAIN}}`
2. Check container status: `docker ps | grep canary`
3. Check frontend logs: `docker logs canary-frontend`
