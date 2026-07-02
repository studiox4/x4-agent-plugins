---
description: Post-merge cleanup — delete database branch (if configured) and remove local git branch.
argument-hint: "[branch-name]"
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

Run the `/pr-cleanup` skill to clean up after a merged PR.

Deletes the database branch (if configured in `.claude/agent-team.config.md`)
and removes the local git branch.
