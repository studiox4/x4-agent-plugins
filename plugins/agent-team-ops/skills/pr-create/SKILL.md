---
name: pr-create
description: Create git branch, DB branch (if configured), push, open draft PR, wait for preview, report URLs
version: 2.0.0
license: MIT
---

# /pr-create — Branch + PR Setup

Creates the development environment for a feature: git branch, database branch
(if configured), draft PR, and preview environment. Extracted from `/work`
Phase 2 for standalone use.

## Arguments

- `<name>` — Feature/fix/chore name (will be slugified)
- `--type <feature|fix|chore>` — Branch type (default: feature)

## Process

### Step 1: Load config

Read `.claude/agent-team.config.md`. Extract:
- `branch_prefixes` (default: `feat/`, `fix/`, `chore/`)
- `base_branch` (default: `main`)
- `db_branching` (optional)
- `ci.preview_url_command` (optional)
- `pr.draft` (default: true)
- `pr.labels` (default: [])

### Step 2: Create git branch

1. Ensure working tree is clean (warn if not).
2. Slugify the name: lowercase, replace spaces/special chars with hyphens.
3. Build branch name: `{branch_prefixes.<type>}<slug>`
4. Run: `git checkout -b <branch-name>`

### Step 3: [If `db_branching` is configured] Create database branch

Execute based on provider:

| Provider | Action |
|----------|--------|
| `neon` | Call `mcp__Neon__create_branch` with branch name derived from git branch |
| `planetscale` | Run: `pscale branch create <db> <branch-name>` |
| `supabase` | Run: `supabase branches create <branch-name>` |

Capture the connection string from output. Set it in the environment variable
specified by `db_branching.env_var`.

If `db_branching` is NOT configured, skip entirely. No mention of databases.

### Step 4: Push and open PR

1. Push: `git push -u origin <branch-name>`
2. Create PR:
   - If `pr.draft` is true:
     ```
     gh pr create --draft --title "<Name>" --body "WIP: <description>"
     ```
   - If `pr.draft` is false:
     ```
     gh pr create --title "<Name>" --body "<description>"
     ```
3. Apply labels from `pr.labels` if any:
   ```
   gh pr edit --add-label "<label1>,<label2>"
   ```

### Step 5: [If `ci.preview_url_command` is configured] Wait for preview

1. Wait briefly for CI to trigger (10-15 seconds).
2. Run `ci.preview_url_command` to retrieve preview URLs.
3. If command fails (preview not ready yet), retry up to 3 times with 15s waits.
4. Report URLs when available.

If NOT configured, skip. No mention of previews.

### Step 6: Report

```
## PR Created

- **Branch:** <branch-name>
- **PR:** <pr-url> (draft)
- **DB Branch:** <db-branch-name> [if configured]
- **Preview:** <preview-url> [if configured]
```

### Step 7: [If in /work pipeline] Update status + move PRD

If running as part of the `/work` pipeline:
- Mark feature as "In Progress" in the status file.
- If PRD exists in `docs/planning/todo/`:
  ```
  git mv docs/planning/todo/<prd-file> docs/planning/in-progress/<prd-file>
  ```
- Update the PRD link in the status file's Planning Documents table.
- Commit: `docs: move PRD to in-progress, update status`

## Rules

- Always check for clean working tree before branching
- Never hardcode provider commands — read from config
- If `gh` CLI is not available, report and suggest installing it
- Slugify branch names: no special chars, max 50 chars
