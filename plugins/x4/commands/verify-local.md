---
description: Run all configured checks (unit, e2e, lint, typecheck) with auto-fix. Mandatory gate before shipping.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/verify-local` skill to execute all configured verification checks.

Reads test commands from `.claude/agent-team.config.md`, runs each in sequence,
and auto-fixes failures up to 3 attempts per check.
