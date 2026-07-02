---
description: Generate project-specific agent files from templates. Reads CLAUDE.md to fill in project details.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/init-agents` skill to generate project-specific agent files in
`.claude/agents/` from bundled templates. Reads CLAUDE.md to fill in
tech stack, conventions, and owned directories.
