---
name: llmstxt-status
description: >
  Read-only status report of llms.txt reference docs — shows what is current,
  stale, missing, or orphaned. Use for health checks after dependency changes.
version: 2.0.0
license: MIT
---

# /llmstxt-status — LLMs.txt Documentation Status

Read-only check of llms.txt documentation status. This command does NOT
download, modify, or delete any files.

## Process

1. Read `.llmstxt.json` config from the project root if it exists. If not, use
   defaults.

2. Scan all dependency manifests using the same ecosystem detection as
   `/llmstxt-update`:
   - JavaScript/Bun/Node, Python, Rust, Go, Ruby

3. Deduplicate and categorize. Apply the same skip rules (type stubs, packaging
   tools, config skip list).

4. List all `.txt` files currently in the configured docs directory.

5. For each dependency, classify:
   - **Current** — a matching doc file exists locally and the package is in
     dependencies
   - **Missing** — the package is in dependencies but no local doc exists (the
     library may or may not publish an llms.txt endpoint)
   - **Orphaned** — a local doc file exists but the package is no longer in any
     dependency manifest
   - **Stale** — a doc exists but was last modified more than 30 days ago and
     may benefit from a refresh

6. Check CLAUDE.md reference table sync:
   - Are all local docs listed in the table?
   - Are there table entries pointing to docs that no longer exist?

7. Print a status report:

    ## llmstxt-status Report

    Ecosystems detected: JavaScript (3 package.json files), Python (1 pyproject.toml)
    Total dependencies: 52 (14 skipped)
    Docs directory: docs/llms-txt/ (11 files)

    | Status   | Count | Details                              |
    |----------|-------|--------------------------------------|
    | Current  | 8     | zod, react, next, hono, drizzle, ... |
    | Missing  | 30    | express, lodash, chalk, ...          |
    | Orphaned | 1     | old-lib.txt                          |
    | Stale    | 2     | drizzle (45d ago), trpc (32d ago)    |

    CLAUDE.md sync: 1 doc not in table (hono), 0 stale table entries

    Run /llmstxt-update to discover and download missing docs.

## Use Cases

- Quick health check after adding or removing dependencies
- Identifying which docs might need refreshing after upgrades
- Finding orphaned docs from removed dependencies
- Verifying CLAUDE.md table is in sync with actual docs
