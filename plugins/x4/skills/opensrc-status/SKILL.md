---
name: opensrc-status
description: Use for a health check on opensrc source coverage — shows fetched packages, version freshness vs lockfile, and key dependencies missing source. Read-only. Trigger for "check opensrc", "what source do I have", "is my source up to date", or before a build session.
version: 1.0.0
license: MIT
---

# /opensrc-status — Source Code Coverage Report

Read-only check of opensrc source status. Does NOT fetch, modify, or delete anything.

## Process

1. Check `opensrc/sources.json` exists. If not: "opensrc not initialized — run `/opensrc-init`."

2. Read `opensrc/sources.json` for all fetched packages and their versions/dates.

3. Read `package.json` (and workspace files) for current runtime dependencies.
   Apply the same filters as `/opensrc-init` (skip dev tools, type stubs, etc.).

4. For each tracked package, classify:
   - **Current** — fetched version matches installed version, fetched within 30 days
   - **Stale** — fetched more than 30 days ago (may still be correct version)
   - **Outdated** — fetched version differs from installed version in lockfile/node_modules
   - **Missing** — in runtime deps (and likely worth fetching) but no source yet

5. For each fetched package no longer in `package.json`, classify as **Orphaned**.

6. Print the status report:

```
## opensrc Status

Fetched: 11 packages in opensrc/

| Status   | Count | Packages                                   |
|----------|-------|--------------------------------------------|
| Current  | 8     | hono, drizzle-orm, zod, @trpc/server, ...  |
| Stale    | 2     | next (fetched 35d ago), react (42d ago)    |
| Outdated | 1     | better-auth (fetched 1.0.0, installed 1.2) |
| Missing  | 3     | @ai-sdk/openai, react-query, lucia         |
| Orphaned | 1     | old-lib                                    |

CLAUDE.md: Source Code References table present (11 entries)

Run /opensrc-update to refresh stale/outdated packages and fetch missing ones.
```

## Rules

- Read-only — never fetch, modify, or delete anything
- Use `opensrc/sources.json` as the source of truth for what's fetched
- Compare versions against `package-lock.json`, `bun.lockb`, or `pnpm-lock.yaml` if available, otherwise `package.json` version ranges
- Stale threshold: 30 days since `fetchedAt` timestamp in sources.json
