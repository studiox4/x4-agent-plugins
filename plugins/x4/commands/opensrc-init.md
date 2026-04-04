---
description: Set up opensrc — fetches npm package source code locally so AI agents can read actual implementations, not just docs. Detects key dependencies and runs npx opensrc to clone their source. Run once per project.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /opensrc-init

Run the `/opensrc-init` skill to set up opensrc source code fetching.

Detects key runtime dependencies, fetches their source with `npx opensrc`,
and wires up `AGENTS.md` so agents know where to find implementation details.
