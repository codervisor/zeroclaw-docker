#!/bin/sh
set -e

CONFIG="/home/zeroclaw/.zeroclaw/config.toml"

# Fix ownership of the mounted /data volume so the zeroclaw user can write.
chown -R zeroclaw:zeroclaw /data

# Apply environment variable overrides on top of the config.

if [ -n "$ZEROCLAW_API_KEY" ]; then
  sed -i "s|^api_key = .*|api_key = \"$ZEROCLAW_API_KEY\"|" "$CONFIG"
fi

if [ -n "$ZEROCLAW_PROVIDER" ]; then
  sed -i "s|^default_provider = .*|default_provider = \"$ZEROCLAW_PROVIDER\"|" "$CONFIG"
fi

if [ -n "$ZEROCLAW_MODEL" ]; then
  sed -i "s|^default_model = .*|default_model = \"$ZEROCLAW_MODEL\"|" "$CONFIG"
fi

if [ -n "$ZEROCLAW_OPEN_SKILLS_ENABLED" ]; then
  sed -i "s|^open_skills_enabled = .*|open_skills_enabled = $ZEROCLAW_OPEN_SKILLS_ENABLED|" "$CONFIG"
fi

# Drop from root to zeroclaw and exec the main process.
exec gosu zeroclaw "$@"
