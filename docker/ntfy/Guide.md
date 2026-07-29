# NTFY.sh Notification Service

NTFY.sh provides push notifications to your phone, desktop, or any HTTP client.

## Topic

Your notification topic: `{{NTFY_TOPIC}}`

## Sending Notifications

### From the VPS (using lemon-notify)

```bash
sudo lemon-notify "Your message here"
sudo lemon-notify "CPU > 90%" "Server Alert" high
```

### From the VPS (curl, via Docker network)

```bash
docker compose exec ntfy ntfy publish {{NTFY_TOPIC}} "Your message here"
```

### From anywhere (curl, with auth token)

```bash
curl -H "Authorization: Bearer {{NTFY_TOKEN}}" \
     -d "Your message here" \
     https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}
```

### With title, priority, and tags

```bash
curl -H "Title: Backup Complete" \
     -H "Priority: high" \
     -H "Tags: white_check_mark" \
     -H "Authorization: Bearer {{NTFY_TOKEN}}" \
     -d "Backup completed successfully" \
     https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}
```

## Priority Levels

| Name | Value |
|------|-------|
| min | 1 |
| low | 2 |
| default | 3 |
| high | 4 |
| max | 5 |

## Subscribing

### Mobile (Android / iOS)

1. Install the NTFY app from [F-Droid](https://f-droid.org/packages/io.heckel.ntfy/) or [Play Store](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
2. Tap **+** and enter: `https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}`
3. Enable notifications

### Desktop (Web)

Open `https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}` in your browser and click **Subscribe**.

### Desktop (CLI)

```bash
curl -s https://ntfy.{{DOMAIN}}/{{NTFY_TOPIC}}/json
```
