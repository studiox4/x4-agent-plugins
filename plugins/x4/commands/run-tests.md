---
description: Run all configured test commands (unit, e2e, lint, typecheck) from agent-team config.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

Run the `/run-tests` skill to execute the test suite configured in
`.claude/agent-team.config.md`.

Runs unit tests, e2e tests, lint, and typecheck in sequence.
Reports results and highlights failures.
