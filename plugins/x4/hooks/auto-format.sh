#!/bin/bash
# Runs the configured formatter on the file that was just edited/written.
# $CLAUDE_FILE_PATH is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
FORMATTER=""

if [ -f "$CONFIG_FILE" ]; then
  FORMATTER=$(grep '^formatter:' "$CONFIG_FILE" | sed "s/^formatter: *[\"']*\([^\"']*\)[\"']*$/\1/" | sed 's/^ *//')
fi

if [ -n "$FORMATTER" ] && [ "$FORMATTER" != '""' ] && [ "$FORMATTER" != "''" ]; then
  CMD=$(echo "$FORMATTER" | sed "s|\$FILE|$CLAUDE_FILE_PATH|g")
  eval "$CMD" 2>/dev/null || true
fi
