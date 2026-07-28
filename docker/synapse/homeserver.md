# Synapse Configuration Reference

## `server_name: "{{MATRIX_SERVER_NAME}}"`
The domain name of your Matrix server (e.g. `example.com`). This is the domain in your Matrix user IDs (`@user:example.com`). Must match your domain and cannot be changed after the first run.

## `pid_file: /data/homeserver.pid`
Prevents duplicate processes — Synapse writes its PID here on start.

## `listeners`
```yaml
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false
```
- **`port: 8008`** — Internal HTTP port. Caddy reverse-proxies HTTPS to this port.
- **`tls: false`** — TLS termination handled by Caddy, not Synapse.
- **`x_forwarded: true`** — Trust the `X-Forwarded-For` header from Caddy so Synapse sees the real client IP.
- **`names: [client, federation]`** — Serves both client API (Element) and federation API (other Matrix servers) on the same port.

## `database`
```yaml
database:
  name: psycopg2
  args:
    user: {{SYNAPSE_DB_USER}}
    password: {{SYNAPSE_DB_PASSWORD}}
    database: {{SYNAPSE_DB_NAME}}
    host: postgres
    port: 5432
    cp_min: 5
    cp_max: 10
```
- **`name: psycopg2`** — Uses PostgreSQL. SQLite (`sqlite3`) is the default but not recommended for production.
- **`user` / `password` / `database`** — Postgres credentials set at install time.
- **`host: postgres`** — Docker Compose service name. Synapse reaches Postgres via the internal Docker network.
- **`port: 5432`** — Default PostgreSQL port.
- **`cp_min: 5` / `cp_max: 10`** — Connection pool size. Keeps 5-10 database connections ready.

## `media_store_path: /data/media_store`
Where Synapse stores uploaded files (images, avatars, files shared in rooms). Maps to `./synapse/data/media_store` on the host.

## `upload_size: 52428800`
Maximum file upload size in bytes (50 MB). Files larger than this are rejected.

## `url_preview_enabled: false`
Disables link preview thumbnails. When enabled, Synapse fetches URLs posted in chat to generate preview cards. Disabled to reduce CPU/memory usage and network requests.

## `enable_registration: false`
Disables user registration through the client API (Element). Users can only be created via the CLI:
```bash
docker exec synapse register_new_matrix_user http://localhost:8008 -u bob -p password
```

## `report_stats: false`
Opts out of Synapse's anonymous usage statistics reporting to Matrix.org.

## `signing_key_path: /data/signing.key`
Path to Synapse's signing key. This key is auto-generated on first start and is required for federation — other Matrix servers use it to verify your server's identity. The file persists in `./synapse/data/`.

## `old_signing_keys: {}`
Stores expired signing keys. If you rotate your signing key, list old keys here so other servers can still verify old events. Empty by default.

## `retention`
```yaml
retention:
  enabled: true
  default_policy:
    min_lifetime_days: 7
    max_lifetime_days: 365
  purge_jobs:
    - interval: 12h
    - interval: 1d
  retainment_method: age
```
- **`enabled: true`** — Turns on automatic message purging.
- **`min_lifetime_days: 7`** — Messages less than 7 days old are never purged, even if a room sets a shorter policy.
- **`max_lifetime_days: 365`** — Messages older than 365 days are purged from all rooms.
- **`purge_jobs: [{interval: 12h}, {interval: 1d}]`** — Purge runs every 12 hours and daily.
- **`retainment_method: age`** — Retention is based on the age of the event (origin timestamp), not time since it was sent.

## `user_ips_max_age: 30d`
How long Synapse stores client IP/last-seen data. Records older than 30 days are purged.

## `redaction_retention_period: 30d`
How long redacted events are kept before being permanently deleted. After 30 days, redacted messages are fully removed from the database.

## `federation_ip_range_denylist`
```yaml
federation_ip_range_denylist:
  - '127.0.0.0/8'
  - '10.0.0.0/8'
  - '172.16.0.0/12'
  - '192.168.0.0/16'
  - '::1/128'
  - 'fe80::/64'
```
SSRF protection — prevents Synapse from attempting federation with private/internal IP addresses. Covers loopback (`127.0.0.0/8`), Docker networks (`172.16.0.0/12`), WireGuard (`10.0.0.0/8`), and local link addresses.

## `trusted_servers: [matrix.org]`
List of trusted Matrix servers for federation fallback. Synapse uses this list to find other servers when the federation target is unknown.

## `registration_shared_secret: "{{MATRIX_SECRET_KEY}}"`
A secret key that authorizes the `register_new_matrix_user` CLI tool. Without this, the CLI cannot create users. Must be kept confidential — anyone with this key can create admin accounts.

## `macaroon_secret_key: "{{MATRIX_SECRET_KEY}}"`
Used to sign access tokens and other auth-related objects. Must be stable across restarts or all existing sessions will be invalidated.

## `form_secret: "{{MATRIX_SECRET_KEY}}"`
Used for signing form-related operations (password reset tokens, email verification links). Must be stable across restarts or pending verifications will break.
