# NextCloud Setup Guide

## Overview

NextCloud is your self-hosted cloud storage. It's pre-installed with Redis caching,
file locking, and trusted domain configuration. This guide covers first login,
client setup, and recommended configuration.

## 1. Point DNS

Add a DNS A record:

```
cloud.{{DOMAIN}}  →  YOUR_VPS_IP
```

## 2. First Login

Visit `https://cloud.{{DOMAIN}}` and log in with:

- **Username:** `{{ADMIN_USER}}`
- **Password:** `{{ADMIN_PASS}}`

## 3. Install Desktop & Mobile Apps

| Platform | App | Link |
|----------|-----|------|
| Windows / macOS / Linux | NextCloud Desktop | https://nextcloud.com/install/ |
| Android | NextCloud | Google Play / F-Droid |
| iOS | NextCloud | App Store |

When prompted for server address, enter:

```
https://cloud.{{DOMAIN}}
```

## 4. Recommended Apps to Install

From the Apps page (`https://cloud.{{DOMAIN}}/index.php/settings/apps`):

- **Calendar** — CalDAV calendar sync
- **Contacts** — CardDAV contact sync
- **Talk** — Video/audio calls
- **Deck** — Kanban boards
- **Forms** — Surveys and questionnaires

## 5. Background Jobs

NextCloud requires a cron job for background tasks. On the VPS:

```bash
# Add crontab entry for the system user
sudo -u {{SYSTEM_USER}} bash -c 'crontab -l 2>/dev/null; echo "*/5 * * * * docker exec nextcloud php occ cron"' | sudo -u {{SYSTEM_USER}} crontab -
```

Or run manually:

```bash
crontab -e
# Add this line:
*/5 * * * * docker exec nextcloud php occ cron
```

Then set the background job type in the admin panel:

1. Go to **Settings** → **Administration** → **Administration** → **Overview**
2. Set **Background jobs** to **Cron**

## 6. Verify Redis Caching

Redis is pre-configured. Verify it's working:

```bash
# On the VPS
docker exec nextcloud php occ config:system:get memcache.distributed
# Should return: \OC\Memcache\Memcached

docker exec nextcloud php occ config:system:get memcache.locking
# Should return: \OC\Memcache\Redis
```

## 7. Performance Tuning

### Increase Upload Limits

Edit the Caddyfile to increase upload size if needed:

```bash
# On the VPS
nano /opt/lemon-vps/docker/caddy/Caddyfile
# Add inside the cloud.{{DOMAIN}} block:
#   request_body {
#     max_size 10GB
#   }

# Then restart Caddy
cd /opt/lemon-vps/docker && docker compose restart caddy
```

### Memory Limit

```bash
# Check current memory limit
docker exec nextcloud php occ config:system:get default_phone_region
```

## 8. Trusted Domains

Already configured during install. To add more:

```bash
docker exec nextcloud php occ config:system:set trusted_domains 2 --value="https://cloud2.{{DOMAIN}}"
```

## 9. Sharing Settings

From the admin panel (**Settings** → **Administration** → **Sharing**):

- **Enforce password protection** — recommended for public links
- **Set default expiration date** — 7 days is common
- **Allow public shares** — toggle based on your needs

## 10. Client Configuration

When setting up desktop/mobile clients:

- **Server address:** `https://cloud.{{DOMAIN}}`
- **Username:** `{{ADMIN_USER}}`
- **Password:** `{{ADMIN_PASS}}`
- Enable **App Passwords** for additional security:
  1. Go to **Settings** → **Security**
  2. Create an app password for each device
  3. Use the app password instead of your main password

## Troubleshooting

### Can't access NextCloud

```bash
# Check container status
docker ps | grep nextcloud

# Check logs
docker logs nextcloud --tail 50

# Check Caddy routing
docker logs caddy --tail 50
```

### Slow performance

```bash
# Run OCC repair
docker exec nextcloud php occ maintenance:repair

# Check for file changes
docker exec nextcloud php occ files:scan --all

# View system status
docker exec nextcloud php occ status
```

### Redis not connecting

```bash
# Check Redis is running
docker ps | grep redis

# Test Redis from NextCloud
docker exec redis redis-cli ping
# Should return: PONG
```

### Trusted domain errors

```bash
# List trusted domains
docker exec nextcloud php occ config:system:get trusted_domains

# Add a new trusted domain
docker exec nextcloud php occ config:system:set trusted_domains 3 --value="https://new.{{DOMAIN}}"
```

## Further Reading

- [NextCloud Admin Manual](https://docs.nextcloud.com/server/latest/admin_manual/)
- [NextCloud Client Manual](https://docs.nextcloud.com/server/latest/user_manual/)
- [NextCloud Docker Image](https://github.com/nextcloud/docker)
