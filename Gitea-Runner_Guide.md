# Gitea & CI/CD Runner Guide

## Overview

Gitea is your self-hosted Git service with built-in CI/CD via the Gitea Act Runner.
The runner is pre-installed and registered as `lemon-vps-runner`. This guide covers
creating repos, running workflows, and managing runners.

## 1. Point DNS

Add a DNS A record:

```
git.{{DOMAIN}}  →  YOUR_VPS_IP
```

## 2. First Login

Visit `https://git.{{DOMAIN}}` and register your first account:

- Choose a username and password (this becomes the admin)
- **Tip:** Use the same `{{ADMIN_USER}}` / `{{ADMIN_PASS}}` for consistency

## 3. Verify Runner

The runner should already be registered. To verify:

1. Go to **Site Administration** → **Runners** (`https://git.{{DOMAIN}}/admin/runners`)
2. You should see `lemon-vps-runner` with status **Idle**

If the runner is not registered:

```bash
# On the VPS — get a registration token
TOKEN=$(curl --fail --silent \
    -X POST "http://localhost:3000/api/v1/user/runners/registration-token" \
    -H "Authorization: Basic $(echo -n '{{ADMIN_USER}}:{{ADMIN_PASS}}' | base64)" \
    -H "Content-Type: application/json" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Register the runner
docker exec gitea-runner act_runner register \
    --no-interactive \
    --instance "http://gitea:3000" \
    --token "$TOKEN" \
    --name "lemon-vps-runner" \
    --labels "ubuntu-latest:docker://node:20-bullseye,ubuntu-22.04:docker://node:20-bullseye"

# Restart the runner
docker restart gitea-runner
```

## 4. Create a Test Repository

1. Click the **+** button → **New Repository**
2. Name it `test-ci`
3. Initialize with a README
4. Click **Create Repository**

## 5. Add a CI Workflow

1. In your repo, click **New File**
2. Name it `.gitea/workflows/test.yml`
3. Paste this content:

```yaml
name: Test CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Print hello
        run: echo "Hello from lemon-vps CI!"

      - name: Show system info
        run: |
          echo "Runner: $(hostname)"
          echo "Date: $(date)"
          uname -a
```

4. Click **Commit changes**

## 6. Watch It Run

1. Go to **Actions** tab in your repo
2. You should see the workflow running
3. Click on it to see the steps execute in real-time

## 7. Runner Labels

Your runner supports these labels:

| Label | Image |
|-------|-------|
| `ubuntu-latest` | `node:20-bullseye` |
| `ubuntu-22.04` | `node:20-bullseye` |

Use these in your workflows:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # or ubuntu-22.04
```

## 8. Adding More Runners

To add a runner on another machine:

```bash
# Get a fresh registration token
TOKEN=$(curl --fail --silent \
    -X POST "http://localhost:3000/api/v1/user/runners/registration-token" \
    -H "Authorization: Basic $(echo -n '{{ADMIN_USER}}:{{ADMIN_PASS}}' | base64)" \
    -H "Content-Type: application/json" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# Run on the new machine (Docker required)
docker run -d --name gitea-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e GITEA_INSTANCE_URL=https://git.{{DOMAIN}} \
    -e GITEA_RUNNER_REGISTRATION_TOKEN="$TOKEN" \
    --restart unless-stopped \
    gitea/act_runner:latest
```

## 9. Common CI Examples

### Build & Test a Node.js Project

```yaml
name: Node.js CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
```

### Build & Push Docker Image

```yaml
name: Build Docker Image

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp:${{ github.ref_name }} .

      - name: Tag image
        run: docker tag myapp:${{ github.ref_name }} git.{{DOMAIN }}/${{ github.repository_owner }}/myapp:${{ github.ref_name }}
```

## Troubleshooting

### Runner not picking up jobs

```bash
# Check runner status
docker logs gitea-runner --tail 50

# Restart runner
docker restart gitea-runner

# Check runner registration
docker exec gitea-runner act_runner list
```

### Workflow fails immediately

- Check the runner labels match your workflow's `runs-on`
- Verify the runner is online in **Site Administration** → **Runners**
- Check the workflow logs in the **Actions** tab

### Runner can't pull Docker images

The runner uses Docker-in-Docker, so it pulls images from the VPS:

```bash
# Test image pull
docker pull node:20-bullseye
```

## Further Reading

- [Gitea Documentation](https://docs.gitea.com/)
- [Gitea Actions](https://docs.gitea.com/usage/actions/overview)
- [Act Runner](https://gitea.com/gitea/act_runner)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/writing-workflows) (compatible with Gitea)
