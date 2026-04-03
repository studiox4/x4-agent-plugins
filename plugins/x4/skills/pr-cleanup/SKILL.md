---
name: pr-cleanup
description: Use after a PR is merged to clean up the database branch and local git branch. Trigger for "clean up the branch", "PR is merged, clean up", "delete the DB branch", or after /work Phase 7 when the user wants to finalize. Safe to run manually at any time post-merge.
version: 2.0.0
license: MIT
---

# /pr-cleanup — Post-Merge Cleanup

Cleans up resources after a PR is merged: database branches, local git
branches. Manual alternative to GitHub Actions-based cleanup.

## Process

### Step 1: Identify branch

Determine the branch to clean up:
- If an argument is provided, use it as the branch name.
- Otherwise, use the current branch.
- If on `main`/`master`, ask the user which branch to clean up.

### Step 2: Verify PR is merged

Run: `gh pr view <branch> --json state -q .state`

- If `MERGED` — proceed with cleanup.
- If `OPEN` — warn: "PR for `<branch>` is still open. Close or merge it first."
- If `CLOSED` (not merged) — ask: "PR was closed without merging. Still clean up?"
- If no PR found — ask: "No PR found for `<branch>`. Still clean up the branch?"

### Step 3: [If `db_branching` is configured] Delete database branch

Execute based on provider:

| Provider | Action |
|----------|--------|
| `neon` | Call `mcp__Neon__delete_branch` with the branch ID |
| `planetscale` | Run: `pscale branch delete <db> <branch-name> --force` |
| `supabase` | Run: `supabase branches delete <branch-name>` |

If deletion fails, report the error but continue with git cleanup.

If `db_branching` is NOT configured, skip. No mention of databases.

### Step 4: Clean up local git branch

1. Switch to base branch: `git checkout <base_branch>`
2. Pull latest: `git pull`
3. Delete local branch: `git branch -d <branch-name>`
4. Prune remote tracking: `git fetch --prune`

### Step 5: Report

```
## Cleanup Complete

- **Branch:** <branch-name> (deleted locally)
- **DB Branch:** deleted [if configured]
- **Now on:** <base_branch> (up to date)
```

## Rules

- Always verify PR state before deleting anything
- Use `-d` (not `-D`) for branch deletion — let git warn about unmerged changes
- If db branch deletion fails, still clean up the git branch
- Never delete the base branch
