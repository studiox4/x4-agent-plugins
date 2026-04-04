---
name: opensrc-update
description: Use when dependencies have changed, source feels outdated, or the session-start hook flags stale opensrc sources. Compares current package.json against opensrc/sources.json to find new, outdated, and removed packages, then applies targeted updates. Trigger for "refresh opensrc", "update source code", "I added a new library", or after the session-start hook warns about stale sources.
version: 1.0.0
license: MIT
---

# /opensrc-update — Refresh Fetched Source Code

Keeps `opensrc/` in sync with the current dependency set. Fetches source for
new packages, updates outdated fetches, and removes source for removed packages.

## Process

### Step 1: Check setup

1. Verify `opensrc/sources.json` exists.
   - If not: "No opensrc sources found. Run `/opensrc-init` first." Stop.
2. Read `opensrc/sources.json` — collect all currently fetched packages and their versions.

### Step 2: Detect current dependencies

Read `package.json` (and workspace `package.json` files if monorepo).
Apply the same filters as `/opensrc-init` — runtime deps, skip dev tools and type stubs.

### Step 3: Diff

Compare current deps against fetched sources:

**New** — in `package.json` but not in `sources.json`. These are packages added
since the last init/update that might benefit from source fetching.

**Outdated** — in both, but the version in `node_modules` or lockfile differs
from what was fetched. Source is from an older version.

**Removed** — in `sources.json` but no longer in `package.json`. Source is
orphaned and can be cleaned up.

**Current** — fetched version matches installed version and fetch was recent.

### Step 4: Present findings

```
## opensrc Update

  New (3):        @ai-sdk/openai, better-auth, @tanstack/react-query
  Outdated (2):   next (fetched 14.1.0, installed 15.0.0), zod (3.21.0 → 3.23.0)
  Removed (1):    old-package
  Current (8):    hono, drizzle-orm, @trpc/server, ...

Fetch new + update outdated? (yes / review each / skip all)
```

If "yes": apply all updates.
If "review each": walk through each item individually.
If "skip all": report without changes.

For the "Removed" list, ask separately:
```
Remove source for old-package? (opensrc remove old-package) (yes / no)
```

### Step 5: Apply updates

For new and outdated packages:
```bash
npx opensrc <package1> <package2> ...
```

For removed packages (if confirmed):
```bash
npx opensrc remove <package>
```

### Step 6: Update CLAUDE.md

Update the "Source Code References" table in CLAUDE.md if it exists:
- Add rows for newly fetched packages
- Remove rows for packages that were removed
- Do not change existing rows that weren't updated

### Step 7: Report

```
## opensrc-update Complete

  ✓ Fetched: @ai-sdk/openai → opensrc/@ai-sdk/openai/
  ✓ Updated: next (14.1.0 → 15.0.0)
  ✓ Updated: zod (3.21.0 → 3.23.0)
  ✓ Removed: old-package
  ○ Skipped: 8 packages already current

CLAUDE.md updated.
```
