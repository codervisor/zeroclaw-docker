# Zeroclaw Docker

Production Docker image for [Zeroclaw](https://github.com/zeroclaw-labs/zeroclaw) — a Rust-based gateway service.

## Container Image

```
ghcr.io/codervisor/zeroclaw:latest
```

## Architecture

Multi-stage build:

1. **Builder** (`rust:slim`) — clones and compiles Zeroclaw with `cargo build --release`
2. **Runtime** (`debian:bookworm-slim`) — minimal image with only the compiled binary, no Rust toolchain

The final image runs as a non-root user (`zeroclaw`, uid 10001) and exposes port `42617`.

## Quick Start

### Using Docker Compose (recommended)

```bash
# Pull the latest image
docker compose pull

# Start the service
docker compose up -d

# Check health
curl http://localhost:42617/health

# View logs
docker compose logs -f
```

### Using Docker directly

```bash
docker run -d \
  --name zeroclaw \
  -p 42617:42617 \
  -v ./data:/data \
  --restart unless-stopped \
  ghcr.io/codervisor/zeroclaw:latest
```

## Deploy on Azure VM

```bash
# SSH into the VM
ssh <user>@<vm-ip>

# Install Docker and Docker Compose (if not already installed)
# https://docs.docker.com/engine/install/ubuntu/

# Clone this repository
git clone https://github.com/codervisor/zeroclaw-docker.git
cd zeroclaw-docker

# Create data directory
mkdir -p data

# Pull and start
docker compose pull
docker compose up -d

# Verify
docker compose ps
curl http://localhost:42617/health
```

## Verify Image on GHCR

```bash
# List available tags
gh api /orgs/codervisor/packages/container/zeroclaw/versions

# Or pull directly
docker pull ghcr.io/codervisor/zeroclaw:latest
docker inspect ghcr.io/codervisor/zeroclaw:latest
```

## Build Locally

```bash
docker build -t zeroclaw:local .
docker run --rm -p 42617:42617 zeroclaw:local
```

## Configuration

| Variable | Default         | Description                    |
| -------- | --------------- | ------------------------------ |
| Port     | 42617           | Gateway listening port         |
| Data Dir | /data/workspace | Persistent workspace directory |

## CI/CD

The GitHub Actions workflow (`.github/workflows/docker.yml`) automatically builds and pushes to GHCR on every push to `main`.
