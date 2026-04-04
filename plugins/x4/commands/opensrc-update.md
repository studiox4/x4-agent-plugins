---
description: Refresh opensrc — adds source for newly added dependencies, updates outdated fetches, and removes source for removed packages. Run after adding libraries or when source feels stale.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /opensrc-update

Run the `/opensrc-update` skill to refresh fetched source code.

Compares current `package.json` dependencies against `opensrc/sources.json`,
fetches what's new, updates what's outdated, removes what's gone.
