#!/bin/bash
# Runs idle gate command for the teammate's role.
# $CLAUDE_AGENT_ROLE is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
ROLE="$CLAUDE_AGENT_ROLE"

if [ -z "$ROLE" ]; then exit 0; fi
if [ ! -f "$CONFIG_FILE" ]; then exit 0; fi

GATE_CMD=$(sed -n "/^teammate_idle_gates:/,/^[^ ]/{/^  $ROLE:/s/^  $ROLE: *[\"']*\([^\"']*\)[\"']*$/\1/p}" "$CONFIG_FILE")
if [ -z "$GATE_CMD" ]; then exit 0; fi

OUTPUT_FILE=$(mktemp)
eval "$GATE_CMD" > "$OUTPUT_FILE" 2>&1
CODE=$?
tail -10 "$OUTPUT_FILE"
rm -f "$OUTPUT_FILE"

if [ $CODE -ne 0 ]; then
  echo "Idle gate failed for $ROLE. Fix all issues before going idle."
  exit 2
fi
