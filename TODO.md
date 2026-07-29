# TODO

## Known Issues

- [ ] **Icecast GUI unstyled**: `<fileserve>` block missing `<enabled>1</enabled>` — static assets (CSS, images, favicon) return 404. Fix in `docker/icecast/icecast.xml` and recreate container.
- [ ] **Placeholder substitution**: `generate-configs.sh` fails to substitute many `{{PLACEHOLDER}}` values in `.env` (e.g. `DOMAIN`, `ADMIN_USER`, `ADMIN_PASS`). After fixing `.env`, affected services need config regeneration and container recreation.

## Features

- [ ] **Nextcloud external storage / local mount**: Files uploaded to Nextcloud should appear on the host filesystem under `/home/lemon/{Documents,Music,Videos,Pictures}` so they're accessible via SSH. Approaches: Nextcloud external storage config pointing to bind-mounted host dirs, or symlink-based approaches. Requires mapping these host dirs into the Nextcloud container and configuring the `datadirectory` or external storage.
- [ ] **qBittorrent output to user home dirs**: qBittorrent should be able to save downloads to `/home/lemon/{Downloads,Music,Videos,Documents}` so torrented files are accessible on the host filesystem. Requires mounting the user's home directories into the qBittorrent container and configuring `SavePath` and `TempPath` accordingly.
- [ ] **Gitea runner test workflow**: Create a `.gitea/workflows/test.yml` that runs on push and exercises the Gitea Actions runner (e.g. checkout, lint, build, or simple echo/status check) to verify the runner is functioning correctly.
