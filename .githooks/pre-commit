#!/usr/bin/env bash
# Git pre-commit hook: auto-bump plugin patch version when plugin files change.
# Install: git config core.hooksPath .githooks
set -euo pipefail

PLUGIN_JSON="plugins/x4/.claude-plugin/plugin.json"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"

# Check if any staged files are under plugins/x4/ (excluding plugin.json itself)
PLUGIN_CHANGES=$(git diff --cached --name-only -- 'plugins/x4/' | grep -v '.claude-plugin/plugin.json' || true)

if [ -z "$PLUGIN_CHANGES" ]; then
  exit 0  # No plugin file changes — nothing to bump
fi

# Check if plugin.json or marketplace.json are already staged (manual version bump)
ALREADY_BUMPED=$(git diff --cached --name-only -- "$PLUGIN_JSON" "$MARKETPLACE_JSON" || true)

if [ -n "$ALREADY_BUMPED" ]; then
  exit 0  # Version files already staged — assume intentional bump
fi

# Read current version from plugin.json
CURRENT_VERSION=$(jq -r '.version' "$PLUGIN_JSON")

if [ -z "$CURRENT_VERSION" ] || [ "$CURRENT_VERSION" = "null" ]; then
  echo "Warning: Could not read version from $PLUGIN_JSON — skipping auto-bump"
  exit 0
fi

# Bump patch version (e.g., 3.1.0 -> 3.1.1)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

# Update plugin.json
jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" > "${PLUGIN_JSON}.tmp" \
  && mv "${PLUGIN_JSON}.tmp" "$PLUGIN_JSON"

# Update marketplace.json (both metadata.version and plugins[].version)
jq --arg v "$NEW_VERSION" '
  .metadata.version = $v |
  .plugins[].version = $v
' "$MARKETPLACE_JSON" > "${MARKETPLACE_JSON}.tmp" \
  && mv "${MARKETPLACE_JSON}.tmp" "$MARKETPLACE_JSON"

# Stage the bumped files
git add "$PLUGIN_JSON" "$MARKETPLACE_JSON"

echo "Auto-bumped plugin version: $CURRENT_VERSION -> $NEW_VERSION"
