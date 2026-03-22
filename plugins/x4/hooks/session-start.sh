#!/usr/bin/env bash

# --- llms.txt staleness check ---
LLMSTXT_DIR="docs/llms-txt"
LLMSTXT_CONFIG=".llmstxt.json"
STALE_DAYS=30
STALE_MSG=""

if [ -d "$LLMSTXT_DIR" ] && [ -f "$LLMSTXT_CONFIG" ]; then
  # Find the most recently modified doc
  NEWEST=$(find "$LLMSTXT_DIR" -name '*.txt' -type f -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | sort -rn | head -1 | awk '{print $1}')

  if [ -n "$NEWEST" ]; then
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - NEWEST) / 86400 ))
    if [ "$AGE_DAYS" -ge "$STALE_DAYS" ]; then
      STALE_MSG="  ⚠ llms.txt docs are ${AGE_DAYS}d old — run /x4:llmstxt-update to refresh"
    fi
  fi
elif [ -f "$LLMSTXT_CONFIG" ] && [ ! -d "$LLMSTXT_DIR" ]; then
  STALE_MSG="  ⚠ llms.txt configured but no docs downloaded — run /x4:llmstxt-update"
fi

# --- Session start message ---
cat <<HOOK_MSG
x4 plugin is active. Key commands:
  /x4:idea <idea>     — capture a feature idea to the backlog
  /x4:work            — dispatch agent team to build next feature
  /x4:plan-backlog    — triage backlog items into PRDs
  /x4:create <name>   — scaffold a new x4-mono project
  /x4:status          — project health dashboard
  /x4:tour            — guided walkthrough of your project
  /x4:llmstxt-update  — refresh llms.txt reference docs
Config: .claude/project-tracker.config.md, .claude/agent-team.config.md
HOOK_MSG

if [ -n "$STALE_MSG" ]; then
  echo "$STALE_MSG"
fi
