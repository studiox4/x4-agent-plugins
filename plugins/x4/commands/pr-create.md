---
description: Create a feature branch, DB branch (if configured), push, and open a draft PR.
argument-hint: "<name> [--type feature|fix|chore]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/pr-create` skill to set up a new branch and PR.

Reads configuration from `.claude/agent-team.config.md` for branch prefixes,
database branching, and PR settings.
