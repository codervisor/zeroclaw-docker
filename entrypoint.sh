#!/bin/sh
set -e

CONFIG="/home/zeroclaw/.zeroclaw/config.toml"

# Fix ownership of the mounted workspace volume so the zeroclaw user can write.
chown -R zeroclaw:zeroclaw /home/zeroclaw/.zeroclaw/workspace

# ── TOML patcher ─────────────────────────────────────────────
# Replaces a key's value inside a TOML section (or top-level).
# Handles both active and commented-out (# key = ...) lines.
#
# Usage: toml_set <section> <key> <value> [str|num|bool|raw]
#   section  ""              → top-level (before first [section])
#            "memory"        → [memory]
#            "security.otp"  → [security.otp]
#   type     str (default)   → wraps value in double quotes
#            num/bool/raw    → writes value as-is
toml_set() {
    _sect="$1"; _key="$2"; _val="$3"; _type="${4:-str}"
    if [ "$_type" = "str" ]; then
        _fmt="\"${_val}\""
    else
        _fmt="$_val"
    fi

    if [ -z "$_sect" ]; then
        awk -v key="$_key" -v val="$_fmt" '
            BEGIN { top = 1 }
            /^\[/ { top = 0 }
            top && $0 ~ "^#? *" key " *=" { $0 = key " = " val }
            { print }
        ' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
    else
        awk -v sect="[${_sect}]" -v key="$_key" -v val="$_fmt" '
            $0 == sect { in_s = 1; print; next }
            /^\[/ { in_s = 0 }
            in_s && $0 ~ "^#? *" key " *=" { $0 = key " = " val }
            { print }
        ' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
    fi
}

# ── Apply environment-variable overrides ─────────────────────
# Only variables that are set and non-empty trigger an override.
# Unset variables leave the config.toml defaults in place.

# Core
[ -n "$ZEROCLAW_API_KEY" ]     && toml_set "" api_key             "$ZEROCLAW_API_KEY"
[ -n "$ZEROCLAW_MODEL" ]       && toml_set "" default_model       "$ZEROCLAW_MODEL"
[ -n "$ZEROCLAW_PROVIDER" ]    && toml_set "" default_provider    "$ZEROCLAW_PROVIDER"
[ -n "$ZEROCLAW_TEMPERATURE" ] && toml_set "" default_temperature "$ZEROCLAW_TEMPERATURE" num

# Memory
[ -n "$ZEROCLAW_MEMORY_AUTO_SAVE" ]            && toml_set memory auto_save            "$ZEROCLAW_MEMORY_AUTO_SAVE" bool
[ -n "$ZEROCLAW_MEMORY_BACKEND" ]              && toml_set memory backend              "$ZEROCLAW_MEMORY_BACKEND"
[ -n "$ZEROCLAW_MEMORY_EMBEDDING_PROVIDER" ]   && toml_set memory embedding_provider   "$ZEROCLAW_MEMORY_EMBEDDING_PROVIDER"
[ -n "$ZEROCLAW_MEMORY_EMBEDDING_MODEL" ]      && toml_set memory embedding_model      "$ZEROCLAW_MEMORY_EMBEDDING_MODEL"
[ -n "$ZEROCLAW_MEMORY_EMBEDDING_DIMENSIONS" ] && toml_set memory embedding_dimensions "$ZEROCLAW_MEMORY_EMBEDDING_DIMENSIONS" num
[ -n "$ZEROCLAW_MEMORY_KEYWORD_WEIGHT" ]       && toml_set memory keyword_weight       "$ZEROCLAW_MEMORY_KEYWORD_WEIGHT" num
[ -n "$ZEROCLAW_MEMORY_VECTOR_WEIGHT" ]        && toml_set memory vector_weight        "$ZEROCLAW_MEMORY_VECTOR_WEIGHT" num

# Gateway
[ -n "$ZEROCLAW_GATEWAY_HOST" ]              && toml_set gateway host              "$ZEROCLAW_GATEWAY_HOST"
[ -n "$ZEROCLAW_GATEWAY_PORT" ]              && toml_set gateway port              "$ZEROCLAW_GATEWAY_PORT" num
[ -n "$ZEROCLAW_GATEWAY_ALLOW_PUBLIC_BIND" ] && toml_set gateway allow_public_bind "$ZEROCLAW_GATEWAY_ALLOW_PUBLIC_BIND" bool
[ -n "$ZEROCLAW_GATEWAY_REQUIRE_PAIRING" ]   && toml_set gateway require_pairing   "$ZEROCLAW_GATEWAY_REQUIRE_PAIRING" bool

# Autonomy
[ -n "$ZEROCLAW_AUTONOMY_LEVEL" ]                   && toml_set autonomy level                            "$ZEROCLAW_AUTONOMY_LEVEL"
[ -n "$ZEROCLAW_AUTONOMY_MAX_ACTIONS_PER_HOUR" ]    && toml_set autonomy max_actions_per_hour             "$ZEROCLAW_AUTONOMY_MAX_ACTIONS_PER_HOUR" num
[ -n "$ZEROCLAW_AUTONOMY_MAX_COST_PER_DAY_CENTS" ]  && toml_set autonomy max_cost_per_day_cents           "$ZEROCLAW_AUTONOMY_MAX_COST_PER_DAY_CENTS" num
[ -n "$ZEROCLAW_AUTONOMY_BLOCK_HIGH_RISK" ]         && toml_set autonomy block_high_risk_commands         "$ZEROCLAW_AUTONOMY_BLOCK_HIGH_RISK" bool
[ -n "$ZEROCLAW_AUTONOMY_REQUIRE_APPROVAL_MEDIUM" ] && toml_set autonomy require_approval_for_medium_risk "$ZEROCLAW_AUTONOMY_REQUIRE_APPROVAL_MEDIUM" bool
[ -n "$ZEROCLAW_AUTONOMY_WORKSPACE_ONLY" ]          && toml_set autonomy workspace_only                   "$ZEROCLAW_AUTONOMY_WORKSPACE_ONLY" bool
[ -n "$ZEROCLAW_AUTONOMY_ALLOWED_COMMANDS" ]        && toml_set autonomy allowed_commands                 "$ZEROCLAW_AUTONOMY_ALLOWED_COMMANDS" raw
[ -n "$ZEROCLAW_AUTONOMY_ALLOWED_ROOTS" ]           && toml_set autonomy allowed_roots                    "$ZEROCLAW_AUTONOMY_ALLOWED_ROOTS" raw

# Runtime
[ -n "$ZEROCLAW_RUNTIME_KIND" ]      && toml_set runtime kind              "$ZEROCLAW_RUNTIME_KIND"
[ -n "$ZEROCLAW_RUNTIME_REASONING" ] && toml_set runtime reasoning_enabled "$ZEROCLAW_RUNTIME_REASONING" bool

# Agent
[ -n "$ZEROCLAW_AGENT_MAX_HISTORY" ]        && toml_set agent max_history_messages "$ZEROCLAW_AGENT_MAX_HISTORY" num
[ -n "$ZEROCLAW_AGENT_MAX_TOOL_ITERATIONS" ] && toml_set agent max_tool_iterations "$ZEROCLAW_AGENT_MAX_TOOL_ITERATIONS" num
[ -n "$ZEROCLAW_AGENT_COMPACT_CONTEXT" ]    && toml_set agent compact_context      "$ZEROCLAW_AGENT_COMPACT_CONTEXT" bool
[ -n "$ZEROCLAW_AGENT_PARALLEL_TOOLS" ]     && toml_set agent parallel_tools       "$ZEROCLAW_AGENT_PARALLEL_TOOLS" bool
[ -n "$ZEROCLAW_AGENT_TOOL_DISPATCHER" ]    && toml_set agent tool_dispatcher      "$ZEROCLAW_AGENT_TOOL_DISPATCHER"

# Secrets
[ -n "$ZEROCLAW_SECRETS_ENCRYPT" ] && toml_set secrets encrypt "$ZEROCLAW_SECRETS_ENCRYPT" bool

# Security — OTP
[ -n "$ZEROCLAW_SECURITY_OTP_ENABLED" ]     && toml_set security.otp enabled         "$ZEROCLAW_SECURITY_OTP_ENABLED" bool
[ -n "$ZEROCLAW_SECURITY_OTP_METHOD" ]      && toml_set security.otp method          "$ZEROCLAW_SECURITY_OTP_METHOD"
[ -n "$ZEROCLAW_SECURITY_OTP_TOKEN_TTL" ]   && toml_set security.otp token_ttl_secs  "$ZEROCLAW_SECURITY_OTP_TOKEN_TTL" num
[ -n "$ZEROCLAW_SECURITY_OTP_CACHE_VALID" ] && toml_set security.otp cache_valid_secs "$ZEROCLAW_SECURITY_OTP_CACHE_VALID" num

# Security — E-Stop
[ -n "$ZEROCLAW_SECURITY_ESTOP_ENABLED" ]     && toml_set security.estop enabled              "$ZEROCLAW_SECURITY_ESTOP_ENABLED" bool
[ -n "$ZEROCLAW_SECURITY_ESTOP_REQUIRE_OTP" ] && toml_set security.estop require_otp_to_resume "$ZEROCLAW_SECURITY_ESTOP_REQUIRE_OTP" bool

# Observability
[ -n "$ZEROCLAW_OBSERVABILITY_BACKEND" ]           && toml_set observability backend           "$ZEROCLAW_OBSERVABILITY_BACKEND"
[ -n "$ZEROCLAW_OBSERVABILITY_OTEL_ENDPOINT" ]     && toml_set observability otel_endpoint     "$ZEROCLAW_OBSERVABILITY_OTEL_ENDPOINT"
[ -n "$ZEROCLAW_OBSERVABILITY_OTEL_SERVICE_NAME" ] && toml_set observability otel_service_name "$ZEROCLAW_OBSERVABILITY_OTEL_SERVICE_NAME"

# Cost
[ -n "$ZEROCLAW_COST_ENABLED" ]       && toml_set cost enabled         "$ZEROCLAW_COST_ENABLED" bool
[ -n "$ZEROCLAW_COST_DAILY_LIMIT" ]   && toml_set cost daily_limit_usd "$ZEROCLAW_COST_DAILY_LIMIT" num
[ -n "$ZEROCLAW_COST_MONTHLY_LIMIT" ] && toml_set cost monthly_limit_usd "$ZEROCLAW_COST_MONTHLY_LIMIT" num
[ -n "$ZEROCLAW_COST_WARN_PERCENT" ]  && toml_set cost warn_at_percent "$ZEROCLAW_COST_WARN_PERCENT" num

# Skills
[ -n "$ZEROCLAW_OPEN_SKILLS_ENABLED" ] && toml_set skills open_skills_enabled "$ZEROCLAW_OPEN_SKILLS_ENABLED" bool
[ -n "$ZEROCLAW_OPEN_SKILLS_DIR" ]     && toml_set skills open_skills_dir     "$ZEROCLAW_OPEN_SKILLS_DIR"

# Channels — top-level keys
[ -n "$ZEROCLAW_CHANNELS_CLI" ]             && toml_set channels_config cli                  "$ZEROCLAW_CHANNELS_CLI" bool
[ -n "$ZEROCLAW_CHANNELS_MESSAGE_TIMEOUT" ] && toml_set channels_config message_timeout_secs "$ZEROCLAW_CHANNELS_MESSAGE_TIMEOUT" num

# ── Channel sub-sections ─────────────────────────────────────
# Channel sections are commented out in the default config.toml,
# so we append fresh TOML blocks when env vars are provided.
# This avoids the need to uncomment section headers.

# Telegram
if [ -n "$ZEROCLAW_TELEGRAM_BOT_TOKEN" ]; then
    {
        echo ""
        echo "[channels_config.telegram]"
        echo "bot_token = \"$ZEROCLAW_TELEGRAM_BOT_TOKEN\""
        [ -n "$ZEROCLAW_TELEGRAM_ALLOWED_USERS" ] && echo "allowed_users = $ZEROCLAW_TELEGRAM_ALLOWED_USERS"
    } >> "$CONFIG"
fi

# Discord
if [ -n "$ZEROCLAW_DISCORD_BOT_TOKEN" ]; then
    {
        echo ""
        echo "[channels_config.discord]"
        echo "bot_token = \"$ZEROCLAW_DISCORD_BOT_TOKEN\""
        [ -n "$ZEROCLAW_DISCORD_ALLOWED_USERS" ] && echo "allowed_users = $ZEROCLAW_DISCORD_ALLOWED_USERS"
    } >> "$CONFIG"
fi

# Nostr
if [ -n "$ZEROCLAW_NOSTR_PRIVATE_KEY" ]; then
    {
        echo ""
        echo "[channels_config.nostr]"
        echo "private_key = \"$ZEROCLAW_NOSTR_PRIVATE_KEY\""
        [ -n "$ZEROCLAW_NOSTR_RELAYS" ]          && echo "relays = $ZEROCLAW_NOSTR_RELAYS"
        [ -n "$ZEROCLAW_NOSTR_ALLOWED_PUBKEYS" ] && echo "allowed_pubkeys = $ZEROCLAW_NOSTR_ALLOWED_PUBKEYS"
    } >> "$CONFIG"
fi

# WhatsApp (Meta Cloud API)
if [ -n "$ZEROCLAW_WHATSAPP_ACCESS_TOKEN" ]; then
    {
        echo ""
        echo "[channels_config.whatsapp]"
        echo "access_token = \"$ZEROCLAW_WHATSAPP_ACCESS_TOKEN\""
        [ -n "$ZEROCLAW_WHATSAPP_PHONE_NUMBER_ID" ] && echo "phone_number_id = \"$ZEROCLAW_WHATSAPP_PHONE_NUMBER_ID\""
        [ -n "$ZEROCLAW_WHATSAPP_VERIFY_TOKEN" ]    && echo "verify_token = \"$ZEROCLAW_WHATSAPP_VERIFY_TOKEN\""
        [ -n "$ZEROCLAW_WHATSAPP_ALLOWED_NUMBERS" ] && echo "allowed_numbers = $ZEROCLAW_WHATSAPP_ALLOWED_NUMBERS"
    } >> "$CONFIG"
fi

# Linq
if [ -n "$ZEROCLAW_LINQ_API_TOKEN" ]; then
    {
        echo ""
        echo "[channels_config.linq]"
        echo "api_token = \"$ZEROCLAW_LINQ_API_TOKEN\""
        [ -n "$ZEROCLAW_LINQ_FROM_PHONE" ]      && echo "from_phone = \"$ZEROCLAW_LINQ_FROM_PHONE\""
        [ -n "$ZEROCLAW_LINQ_ALLOWED_SENDERS" ] && echo "allowed_senders = $ZEROCLAW_LINQ_ALLOWED_SENDERS"
    } >> "$CONFIG"
fi

# Nextcloud Talk
if [ -n "$ZEROCLAW_NEXTCLOUD_APP_TOKEN" ]; then
    {
        echo ""
        echo "[channels_config.nextcloud_talk]"
        echo "app_token = \"$ZEROCLAW_NEXTCLOUD_APP_TOKEN\""
        [ -n "$ZEROCLAW_NEXTCLOUD_BASE_URL" ]      && echo "base_url = \"$ZEROCLAW_NEXTCLOUD_BASE_URL\""
        [ -n "$ZEROCLAW_NEXTCLOUD_ALLOWED_USERS" ] && echo "allowed_users = $ZEROCLAW_NEXTCLOUD_ALLOWED_USERS"
    } >> "$CONFIG"
fi

# Ensure config is owned by the zeroclaw user after modifications.
chown zeroclaw:zeroclaw "$CONFIG"

# Drop from root → zeroclaw and exec the main process.
exec gosu zeroclaw "$@"
