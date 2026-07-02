#!/bin/bash
# Blocks Edit/Write on files matching protected patterns from config.
# $CLAUDE_FILE_PATH is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
PROTECTED_DEFAULT="*.env *.env.*"

if [ -f "$CONFIG_FILE" ]; then
  PROTECTED=$(sed -n '/^protected_files:/,/^[^ ]/{ /^  - /s/^  - ["'\'']*\([^"'\'']*\)["'\'']*$/\1/p }' "$CONFIG_FILE")
else
  PROTECTED="$PROTECTED_DEFAULT"
fi

FILE="$CLAUDE_FILE_PATH"
for pattern in $PROTECTED; do
  case "$FILE" in
    $pattern)
      echo "BLOCK: Editing $FILE is not allowed (matches protected pattern: $pattern)"
      exit 1
      ;;
  esac
done
