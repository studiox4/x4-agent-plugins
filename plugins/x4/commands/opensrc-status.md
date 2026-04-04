---
description: Check opensrc health — shows which packages have source fetched, which are missing, and which may be stale. Read-only.
allowed-tools: [Read, Glob, Grep, Bash]
---

# /opensrc-status

Run the `/opensrc-status` skill to check source code coverage.

Read-only report: fetched packages, version freshness vs lockfile, and
key dependencies that don't yet have source fetched.
