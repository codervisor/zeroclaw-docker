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

Config lives at `~/.zeroclaw/config.toml` inside the container (`/home/zeroclaw/.zeroclaw/config.toml`). The repo's [`config.toml`](config.toml) is baked into the image and bind-mounted read-only via `docker-compose.yml`.

Full upstream reference: [docs/config-reference.md](https://github.com/zeroclaw-labs/zeroclaw/blob/main/docs/config-reference.md)

### Quick Setup

```bash
# 1. Copy the env template and add your API key
cp .env.example .env
# Edit .env → set ZEROCLAW_API_KEY

# 2. (Optional) Customise config.toml for deeper settings

# 3. Start
docker compose up -d
```

### Environment Variable Overrides

Set these in `.env` or pass them directly — they override `config.toml` at runtime without editing the file:

| Variable                       | Overrides                    | Example                       |
| ------------------------------ | ---------------------------- | ----------------------------- |
| `ZEROCLAW_API_KEY`             | `api_key`                    | `sk-or-v1-abc123...`          |
| `ZEROCLAW_PROVIDER`            | `default_provider`           | `openrouter`, `ollama`        |
| `ZEROCLAW_MODEL`               | `default_model`              | `anthropic/claude-sonnet-4-6` |
| `ZEROCLAW_PORT`                | Docker host port mapping     | `42617`                       |
| `ZEROCLAW_OPEN_SKILLS_ENABLED` | `skills.open_skills_enabled` | `true`                        |

### Config Sections Overview

The included `config.toml` covers every section from the upstream reference with Docker-appropriate defaults. Sections are commented with explanations — uncomment and edit as needed.

| Section                  | Purpose                                              |
| ------------------------ | ---------------------------------------------------- |
| **Core keys**            | API key, provider, model, temperature                |
| `[memory]`               | Conversation memory backend and hybrid search tuning |
| `[gateway]`              | Bind address & port (42617), pairing requirements    |
| `[autonomy]`             | Execution policy, command allowlist, risk gates      |
| `[runtime]`              | Runtime kind, reasoning toggle                       |
| `[agent]`                | Tool iterations, history limits, parallel tools      |
| `[secrets]`              | At-rest encryption                                   |
| `[security.otp]`         | TOTP gating for sensitive actions/domains            |
| `[security.estop]`       | Emergency-stop state machine                         |
| `[observability]`        | Logging, Prometheus, OpenTelemetry                   |
| `[cost]`                 | Daily/monthly spend limits                           |
| `[skills]`               | Open-skills repo opt-in                              |
| `[identity]`             | OpenClaw / AIEOS identity format                     |
| `[multimodal]`           | Image attachment limits                              |
| `[browser]`              | Browser automation backend & domain allowlist        |
| `[http_request]`         | HTTP tool with domain allowlist                      |
| `[composio]`             | Composio managed OAuth tools                         |
| `[tunnel]`               | Tunnel provider                                      |
| `[hardware]`             | STM32 / serial / probe access                        |
| `[peripherals]`          | Board configs (nucleo, rpi-gpio, esp32)              |
| `[channels_config]`      | Telegram, Discord, WhatsApp, Nostr, Linq, Email, etc |
| `[agents.<name>]`        | Delegate sub-agents (researcher, coder, etc.)        |
| `[[model_routes]]`       | Stable hint → provider/model routing                 |
| `[[embedding_routes]]`   | Embedding hint → provider routing                    |
| `[query_classification]` | Auto-route messages to model hints by content        |

### Docker-Specific Notes

- **Gateway port** is `42617` in config (matching `EXPOSE` and `HEALTHCHECK`). The CLI flag `--host 0.0.0.0` in the Dockerfile CMD ensures the gateway binds to all interfaces inside the container.
- **Provider precedence**: `ZEROCLAW_PROVIDER` env → `PROVIDER` env (legacy) → `default_provider` in config.toml.
- **Hot-reload**: While `zeroclaw channel start` is running, changes to `api_key`, `default_provider`, `default_model`, `default_temperature`, and `reliability.*` are hot-applied from config.toml on the next inbound message.
- **Validate config** after edits: `docker compose exec zeroclaw zeroclaw doctor`

## CI/CD

The GitHub Actions workflow (`.github/workflows/docker.yml`) automatically builds and pushes to GHCR on every push to `main`.
