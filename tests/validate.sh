#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
ERRORS=0

# 0. Validate root marketplace.json exists
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MARKETPLACE" ]; then
  echo "FAIL: Root .claude-plugin/marketplace.json missing"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: .claude-plugin/marketplace.json exists"
fi

# 1. Validate .claude-plugin/plugin.json manifests, LICENSE, and README.md
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir/.claude-plugin/plugin.json"

  # Check manifest exists at .claude-plugin/plugin.json (not root plugin.json)
  if [ ! -f "$manifest" ]; then
    echo "FAIL: $plugin_name missing .claude-plugin/plugin.json"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check required fields
  for field in name description; do
    if ! grep -q "\"$field\"" "$manifest"; then
      echo "FAIL: $plugin_name/.claude-plugin/plugin.json missing '$field' field"
      ERRORS=$((ERRORS + 1))
    fi
  done

  echo "OK: $plugin_name/.claude-plugin/plugin.json is valid"

  # Check LICENSE file exists
  if [ ! -f "$plugin_dir/LICENSE" ]; then
    echo "FAIL: $plugin_name missing LICENSE file"
    ERRORS=$((ERRORS + 1))
  else
    echo "OK: $plugin_name/LICENSE exists"
  fi

  # Check README.md exists
  if [ ! -f "$plugin_dir/README.md" ]; then
    echo "FAIL: $plugin_name missing README.md"
    ERRORS=$((ERRORS + 1))
  else
    echo "OK: $plugin_name/README.md exists"
  fi
done

# 2. Validate all referenced skill files exist
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")

  if [ -d "$plugin_dir/skills" ]; then
    for skill_dir in "$plugin_dir/skills"/*/; do
      skill_file="$skill_dir/SKILL.md"
      if [ ! -f "$skill_file" ]; then
        echo "FAIL: $plugin_name skill $(basename "$skill_dir") missing SKILL.md"
        ERRORS=$((ERRORS + 1))
      else
        echo "OK: $plugin_name/skills/$(basename "$skill_dir")/SKILL.md exists"
      fi
    done
  fi

  if [ -d "$plugin_dir/commands" ]; then
    for cmd_file in "$plugin_dir/commands"/*.md; do
      if [ ! -f "$cmd_file" ]; then
        echo "FAIL: $plugin_name command file missing: $cmd_file"
        ERRORS=$((ERRORS + 1))
      else
        echo "OK: $plugin_name/commands/$(basename "$cmd_file") exists"
      fi
    done
  fi

  if [ -d "$plugin_dir/hooks" ]; then
    for hook_file in "$plugin_dir/hooks"/*.sh; do
      if [ -f "$hook_file" ]; then
        if [ ! -x "$hook_file" ]; then
          echo "FAIL: $plugin_name hook script not executable: $(basename "$hook_file")"
          ERRORS=$((ERRORS + 1))
        else
          echo "OK: $plugin_name/hooks/$(basename "$hook_file") is executable"
        fi
      fi
    done
  fi
done

# 3. Validate no plugin references files outside its own directory
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")
  if grep -r '\.\./\.\.' "$plugin_dir" --include="*.md" 2>/dev/null; then
    echo "WARN: $plugin_name contains parent directory traversals -- review manually"
  fi
done

# 4. Report
echo ""
if [ $ERRORS -gt 0 ]; then
  echo "FAILED: $ERRORS error(s) found"
  exit 1
else
  echo "PASSED: All plugins valid"
  exit 0
fi
