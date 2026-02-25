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
  -v ./data:/home/zeroclaw/.zeroclaw/workspace \
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

Config lives at `~/.zeroclaw/config.toml` inside the container (`/home/zeroclaw/.zeroclaw/config.toml`). The repo's [`config.toml`](config.toml) is baked into the image at build time. Use environment variables to override values at runtime without mounting a config file.

Full upstream reference: [docs/config-reference.md](https://github.com/zeroclaw-labs/zeroclaw/blob/main/docs/config-reference.md)

### Quick Setup

```bash
# 1. Copy the env template and add your API key
cp .env.example .env
# Edit .env → set ZEROCLAW_API_KEY

# 2. Start
docker compose up -d
```

### Environment Variable Overrides

Set these in `.env` (copy from `.env.example`) — they override `config.toml` values at runtime. Unset variables leave the baked-in defaults in place.

Docker Compose automatically loads `.env` from the project directory and passes all variables to the container via `env_file`.

#### Core

| Variable               | Config key                   | Type   | Default                       |
| ---------------------- | ---------------------------- | ------ | ----------------------------- |
| `ZEROCLAW_API_KEY`     | `api_key`                    | string | `sk-...`                      |
| `ZEROCLAW_PROVIDER`    | `default_provider`           | string | `openrouter`                  |
| `ZEROCLAW_MODEL`       | `default_model`              | string | `anthropic/claude-sonnet-4-6` |
| `ZEROCLAW_TEMPERATURE` | `default_temperature`        | number | `0.3`                         |
| `ZEROCLAW_PORT`        | *(Docker host port mapping)* | number | `42617`                       |

#### Memory

| Variable                               | Config key                    | Type   | Default   |
| -------------------------------------- | ----------------------------- | ------ | --------- |
| `ZEROCLAW_MEMORY_AUTO_SAVE`            | `memory.auto_save`            | bool   | `true`    |
| `ZEROCLAW_MEMORY_BACKEND`              | `memory.backend`              | string | `sqlite`  |
| `ZEROCLAW_MEMORY_EMBEDDING_PROVIDER`   | `memory.embedding_provider`   | string | `none`    |
| `ZEROCLAW_MEMORY_EMBEDDING_MODEL`      | `memory.embedding_model`      | string | *(unset)* |
| `ZEROCLAW_MEMORY_EMBEDDING_DIMENSIONS` | `memory.embedding_dimensions` | number | *(unset)* |
| `ZEROCLAW_MEMORY_KEYWORD_WEIGHT`       | `memory.keyword_weight`       | number | `0.3`     |
| `ZEROCLAW_MEMORY_VECTOR_WEIGHT`        | `memory.vector_weight`        | number | `0.7`     |

#### Gateway

| Variable                             | Config key                  | Type   | Default   |
| ------------------------------------ | --------------------------- | ------ | --------- |
| `ZEROCLAW_GATEWAY_HOST`              | `gateway.host`              | string | `0.0.0.0` |
| `ZEROCLAW_GATEWAY_PORT`              | `gateway.port`              | number | `42617`   |
| `ZEROCLAW_GATEWAY_ALLOW_PUBLIC_BIND` | `gateway.allow_public_bind` | bool   | `true`    |
| `ZEROCLAW_GATEWAY_REQUIRE_PAIRING`   | `gateway.require_pairing`   | bool   | `true`    |

#### Autonomy

| Variable                                    | Config key                                  | Type       | Default               |
| ------------------------------------------- | ------------------------------------------- | ---------- | --------------------- |
| `ZEROCLAW_AUTONOMY_LEVEL`                   | `autonomy.level`                            | string     | `full`                |
| `ZEROCLAW_AUTONOMY_MAX_ACTIONS_PER_HOUR`    | `autonomy.max_actions_per_hour`             | number     | `20`                  |
| `ZEROCLAW_AUTONOMY_MAX_COST_PER_DAY_CENTS`  | `autonomy.max_cost_per_day_cents`           | number     | `500`                 |
| `ZEROCLAW_AUTONOMY_BLOCK_HIGH_RISK`         | `autonomy.block_high_risk_commands`         | bool       | `false`               |
| `ZEROCLAW_AUTONOMY_REQUIRE_APPROVAL_MEDIUM` | `autonomy.require_approval_for_medium_risk` | bool       | `false`               |
| `ZEROCLAW_AUTONOMY_WORKSPACE_ONLY`          | `autonomy.workspace_only`                   | bool       | `false`               |
| `ZEROCLAW_AUTONOMY_ALLOWED_COMMANDS`        | `autonomy.allowed_commands`                 | TOML array | `["git", "npm", ...]` |
| `ZEROCLAW_AUTONOMY_ALLOWED_ROOTS`           | `autonomy.allowed_roots`                    | TOML array | `["/home/zeroclaw"]`  |

#### Runtime

| Variable                     | Config key                  | Type   | Default   |
| ---------------------------- | --------------------------- | ------ | --------- |
| `ZEROCLAW_RUNTIME_KIND`      | `runtime.kind`              | string | `native`  |
| `ZEROCLAW_RUNTIME_REASONING` | `runtime.reasoning_enabled` | bool   | *(unset)* |

#### Agent

| Variable                             | Config key                   | Type   | Default   |
| ------------------------------------ | ---------------------------- | ------ | --------- |
| `ZEROCLAW_AGENT_MAX_HISTORY`         | `agent.max_history_messages` | number | `50`      |
| `ZEROCLAW_AGENT_MAX_TOOL_ITERATIONS` | `agent.max_tool_iterations`  | number | `10`      |
| `ZEROCLAW_AGENT_COMPACT_CONTEXT`     | `agent.compact_context`      | bool   | *(unset)* |
| `ZEROCLAW_AGENT_PARALLEL_TOOLS`      | `agent.parallel_tools`       | bool   | *(unset)* |
| `ZEROCLAW_AGENT_TOOL_DISPATCHER`     | `agent.tool_dispatcher`      | string | *(unset)* |

#### Secrets

| Variable                   | Config key        | Type | Default |
| -------------------------- | ----------------- | ---- | ------- |
| `ZEROCLAW_SECRETS_ENCRYPT` | `secrets.encrypt` | bool | `true`  |

#### Security — OTP

| Variable                            | Config key                      | Type   | Default   |
| ----------------------------------- | ------------------------------- | ------ | --------- |
| `ZEROCLAW_SECURITY_OTP_ENABLED`     | `security.otp.enabled`          | bool   | `false`   |
| `ZEROCLAW_SECURITY_OTP_METHOD`      | `security.otp.method`           | string | *(unset)* |
| `ZEROCLAW_SECURITY_OTP_TOKEN_TTL`   | `security.otp.token_ttl_secs`   | number | *(unset)* |
| `ZEROCLAW_SECURITY_OTP_CACHE_VALID` | `security.otp.cache_valid_secs` | number | *(unset)* |

#### Security — E-Stop

| Variable                              | Config key                             | Type | Default   |
| ------------------------------------- | -------------------------------------- | ---- | --------- |
| `ZEROCLAW_SECURITY_ESTOP_ENABLED`     | `security.estop.enabled`               | bool | `false`   |
| `ZEROCLAW_SECURITY_ESTOP_REQUIRE_OTP` | `security.estop.require_otp_to_resume` | bool | *(unset)* |

#### Observability

| Variable                                   | Config key                        | Type   | Default   |
| ------------------------------------------ | --------------------------------- | ------ | --------- |
| `ZEROCLAW_OBSERVABILITY_BACKEND`           | `observability.backend`           | string | `none`    |
| `ZEROCLAW_OBSERVABILITY_OTEL_ENDPOINT`     | `observability.otel_endpoint`     | string | *(unset)* |
| `ZEROCLAW_OBSERVABILITY_OTEL_SERVICE_NAME` | `observability.otel_service_name` | string | *(unset)* |

#### Cost Tracking

| Variable                      | Config key               | Type   | Default   |
| ----------------------------- | ------------------------ | ------ | --------- |
| `ZEROCLAW_COST_ENABLED`       | `cost.enabled`           | bool   | `false`   |
| `ZEROCLAW_COST_DAILY_LIMIT`   | `cost.daily_limit_usd`   | number | *(unset)* |
| `ZEROCLAW_COST_MONTHLY_LIMIT` | `cost.monthly_limit_usd` | number | *(unset)* |
| `ZEROCLAW_COST_WARN_PERCENT`  | `cost.warn_at_percent`   | number | *(unset)* |

#### Skills

| Variable                       | Config key                   | Type   | Default   |
| ------------------------------ | ---------------------------- | ------ | --------- |
| `ZEROCLAW_OPEN_SKILLS_ENABLED` | `skills.open_skills_enabled` | bool   | `false`   |
| `ZEROCLAW_OPEN_SKILLS_DIR`     | `skills.open_skills_dir`     | string | *(unset)* |

#### GitHub CLI

| Variable       | Purpose                                                                  | Default   |
| -------------- | ------------------------------------------------------------------------ | --------- |
| `GH_TOKEN`     | Auth token for `gh` CLI (GitHub API). Takes precedence over GITHUB_TOKEN | *(unset)* |
| `GITHUB_TOKEN` | Fallback auth token; copied to `GH_TOKEN` if `GH_TOKEN` is unset         | *(unset)* |

#### HTTP Request Tool

| Variable                        | Config key             | Type | Default |
| ------------------------------- | ---------------------- | ---- | ------- |
| `ZEROCLAW_HTTP_REQUEST_ENABLED` | `http_request.enabled` | bool | `true`  |

#### Browser Tool

| Variable                   | Config key        | Type | Default |
| -------------------------- | ----------------- | ---- | ------- |
| `ZEROCLAW_BROWSER_ENABLED` | `browser.enabled` | bool | `true`  |

#### Channels (top-level)

| Variable                            | Config key                             | Type   | Default |
| ----------------------------------- | -------------------------------------- | ------ | ------- |
| `ZEROCLAW_CHANNELS_CLI`             | `channels_config.cli`                  | bool   | `true`  |
| `ZEROCLAW_CHANNELS_MESSAGE_TIMEOUT` | `channels_config.message_timeout_secs` | number | `300`   |

#### Channel: Telegram

| Variable                          | Config key                               | Type       | Default   |
| --------------------------------- | ---------------------------------------- | ---------- | --------- |
| `ZEROCLAW_TELEGRAM_BOT_TOKEN`     | `channels_config.telegram.bot_token`     | string     | *(unset)* |
| `ZEROCLAW_TELEGRAM_ALLOWED_USERS` | `channels_config.telegram.allowed_users` | TOML array | *(unset)* |

#### Channel: Discord

| Variable                         | Config key                              | Type       | Default   |
| -------------------------------- | --------------------------------------- | ---------- | --------- |
| `ZEROCLAW_DISCORD_BOT_TOKEN`     | `channels_config.discord.bot_token`     | string     | *(unset)* |
| `ZEROCLAW_DISCORD_ALLOWED_USERS` | `channels_config.discord.allowed_users` | TOML array | *(unset)* |

#### Channel: Nostr

| Variable                         | Config key                              | Type       | Default   |
| -------------------------------- | --------------------------------------- | ---------- | --------- |
| `ZEROCLAW_NOSTR_PRIVATE_KEY`     | `channels_config.nostr.private_key`     | string     | *(unset)* |
| `ZEROCLAW_NOSTR_RELAYS`          | `channels_config.nostr.relays`          | TOML array | *(unset)* |
| `ZEROCLAW_NOSTR_ALLOWED_PUBKEYS` | `channels_config.nostr.allowed_pubkeys` | TOML array | *(unset)* |

#### Channel: WhatsApp (Meta Cloud API)

| Variable                            | Config key                                 | Type       | Default   |
| ----------------------------------- | ------------------------------------------ | ---------- | --------- |
| `ZEROCLAW_WHATSAPP_ACCESS_TOKEN`    | `channels_config.whatsapp.access_token`    | string     | *(unset)* |
| `ZEROCLAW_WHATSAPP_PHONE_NUMBER_ID` | `channels_config.whatsapp.phone_number_id` | string     | *(unset)* |
| `ZEROCLAW_WHATSAPP_VERIFY_TOKEN`    | `channels_config.whatsapp.verify_token`    | string     | *(unset)* |
| `ZEROCLAW_WHATSAPP_ALLOWED_NUMBERS` | `channels_config.whatsapp.allowed_numbers` | TOML array | *(unset)* |

#### Channel: Linq

| Variable                        | Config key                             | Type       | Default   |
| ------------------------------- | -------------------------------------- | ---------- | --------- |
| `ZEROCLAW_LINQ_API_TOKEN`       | `channels_config.linq.api_token`       | string     | *(unset)* |
| `ZEROCLAW_LINQ_FROM_PHONE`      | `channels_config.linq.from_phone`      | string     | *(unset)* |
| `ZEROCLAW_LINQ_ALLOWED_SENDERS` | `channels_config.linq.allowed_senders` | TOML array | *(unset)* |

#### Channel: Nextcloud Talk

| Variable                           | Config key                                     | Type       | Default   |
| ---------------------------------- | ---------------------------------------------- | ---------- | --------- |
| `ZEROCLAW_NEXTCLOUD_BASE_URL`      | `channels_config.nextcloud_talk.base_url`      | string     | *(unset)* |
| `ZEROCLAW_NEXTCLOUD_APP_TOKEN`     | `channels_config.nextcloud_talk.app_token`     | string     | *(unset)* |
| `ZEROCLAW_NEXTCLOUD_ALLOWED_USERS` | `channels_config.nextcloud_talk.allowed_users` | TOML array | *(unset)* |

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
