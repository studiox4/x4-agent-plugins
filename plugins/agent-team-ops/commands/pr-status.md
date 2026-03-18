---
description: Check the current branch's PR status — CI checks, preview URLs, and review state.
allowed-tools: Read, Bash, Glob, Grep
---

Run the `/pr-status` skill to check the current PR's status.

Uses `gh pr view` and configured CI/preview commands from
`.claude/agent-team.config.md`.
