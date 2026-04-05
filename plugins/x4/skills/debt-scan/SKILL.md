---
name: debt-scan
description: Use after building a feature with /work to audit the codebase for technical debt introduced by the agent team — duplicated utilities, copy-pasted logic, naming inconsistencies, and code that belongs in shared packages but ended up in individual apps. Also run this skill whenever the user says "check for duplicates", "clean up after the build", "did we introduce any debt?", "look for copy-paste", "find redundant code", or "did the agents mess anything up?". Produces a structured, line-referenced debt report grouped by severity (HIGH / MEDIUM / LOW) with exact file:line locations and specific extraction targets — actionable enough to turn directly into a cleanup PRD. Can run standalone or as part of the post-ship phase.
version: 1.0.0
license: MIT
---

# /debt-scan — Post-Build Technical Debt Audit

Scans a monorepo for technical debt introduced during agent team builds — the
kinds of issues that arise when backend, frontend, and tester agents work
independently without full awareness of each other's code.

**Arguments:**
- `--since <branch>` — only scan files changed since this branch (default: compare to base branch from config)
- `--full` — scan entire codebase, not just changed files
- `--fix` — after reporting, offer to create a cleanup PRD in `docs/planning/todo/`

**Output format is the point.** Claude can detect debt without this skill — the skill's job is to produce a report that's *structured enough to act on*: severity-grouped sections, exact `file.ts:line` references, and specific extraction targets. A narrative summary is not good enough. The grouped, line-referenced format is what lets a developer (or a future agent) turn findings into a cleanup PR without re-investigating.

---

## Process

### Step 0: Load context

Read `.claude/agent-team.config.md` to get `base_branch` (default: `main`).

Determine scan scope:
- If `--full` was passed: scan everything under `apps/` and `packages/`
- If `--since <branch>` was passed: use that branch as the diff base
- Default: `git diff --name-only <base_branch>...HEAD` to get the list of files
  changed in the current feature branch. If that returns nothing (e.g. already
  merged), fall back to full scan.

Collect the list of directories to scan: all `apps/*/src/`, `apps/*/app/`,
`packages/*/src/` that exist. If none exist, report:
"No apps/ or packages/ directories found. Is this an x4-mono project?"

### Step 1: Detect duplicated utilities

**Why this matters:** When backend and frontend agents independently solve the
same problem — formatting a date, validating an email, building a URL — they
often write near-identical utilities rather than checking if one already exists.
These duplicates are safe individually but create divergence over time.

For each `.ts` and `.tsx` file in scope:

1. **Exact function signature matches** — grep for exported function declarations
   (`export function`, `export const ... = (`). Compare function names across
   files. Flag any name that appears in 2+ different files with the same
   signature shape (name + parameter count).

2. **Copy-paste detection (structural)** — read utility files (files in
   `utils/`, `helpers/`, `lib/`) and compare their exported function bodies.
   Flag functions where the implementation is >80% similar (same logic, just
   different variable names). Read up to 50 lines per function for comparison.

3. **Candidate for extraction** — when a utility function exists in 2+ `apps/`
   directories, flag it as a candidate to move into `packages/shared/`.

Report format per duplicate found:
```
[DUPLICATE] formatDate
  apps/web/src/utils/date.ts:12
  apps/api/src/utils/format.ts:8
  → Move to packages/shared/src/utils/date.ts
```

### Step 2: Detect naming inconsistencies

**Why this matters:** Agents name things based on what they're building, not
what already exists. After a few builds, the same concept may be named
differently across the codebase — making search harder and suggesting the
codebase has no agreed conventions.

Scan for these patterns:

1. **Route/endpoint naming drift** — find all tRPC router files
   (`router.ts`, `*.router.ts`) and API route handlers (`route.ts` in `app/api/`).
   Look for the same CRUD operation named differently across routers
   (e.g., `getUser` in one, `fetchUser` in another, `loadUser` in a third).

2. **Component naming drift** — find React components (files with JSX/TSX in
   `components/`). Flag when the same UI concept appears under multiple names
   (e.g., `UserCard`, `UserTile`, `UserItem` all rendering user info).

3. **Type naming drift** — compare TypeScript interface/type names across files.
   Flag near-identical type definitions (same fields, different names).

Report format:
```
[NAMING] User fetch operation named inconsistently
  apps/web/src/app/api/users/route.ts → getUser
  apps/api/src/routers/user.router.ts → fetchUser
  → Pick one name and use it everywhere
```

### Step 3: Detect dead exports

**Why this matters:** Agents often scaffold more than they use — creating utility
functions, types, or components that were planned but never imported anywhere.
Dead code accumulates silently.

For each exported symbol in scope, check if it's imported anywhere in the project.

Focus on:
- Exported functions in `utils/` and `lib/` directories
- Exported TypeScript types and interfaces
- Exported React components that aren't referenced in any page or layout

Use grep to check for imports: for each `export function Foo` / `export const Foo` /
`export type Foo`, search for `import.*Foo` across the codebase. If zero matches
found, flag it.

Exclude:
- `index.ts` re-exports (these are intentionally public)
- Files named `*.stories.tsx` (Storybook stories may not be imported)
- Test files (`*.test.ts`, `*.spec.ts`)

Report format:
```
[DEAD] validateEmailFormat — never imported
  apps/web/src/utils/validation.ts:34
  → Delete or move to shared package if needed elsewhere
```

### Step 4: Detect misplaced shared code

**Why this matters:** Agents work within their assigned app directory and may not
know about or contribute to `packages/shared/`. Logic that would benefit multiple
apps ends up duplicated instead of shared.

Scan for:
1. **Database query patterns** — if the same Neon/Drizzle query pattern appears
   in both `apps/web` and `apps/api`, it's likely a candidate for a shared
   query helper.
2. **Auth/session helpers** — Better Auth session reads appearing in multiple
   apps rather than in a shared package.
3. **Config/constant duplication** — the same constant value (API URLs, config
   keys, magic numbers) defined in multiple apps.

Report format:
```
[MISPLACED] Database query for user by email duplicated
  apps/web/src/lib/auth.ts:22
  apps/api/src/lib/user.ts:15
  → Extract to packages/shared/src/queries/user.ts
```

### Step 5: Generate the debt report

Compile all findings into a structured report. Group by severity:

- **HIGH** — exact duplicates, misplaced shared code with 3+ copies
- **MEDIUM** — naming inconsistencies, 2-copy duplicates
- **LOW** — dead exports, style drift

```
## Debt Scan Report — <branch or "full scan">
Scanned: <N> files across <M> apps/packages
Date: <YYYY-MM-DD>

### Summary
  HIGH:   <N> findings
  MEDIUM: <N> findings
  LOW:    <N> findings

### HIGH — Exact Duplicates
...

### MEDIUM — Naming Inconsistencies
...

### LOW — Dead Exports
...

### Clean
✓ No issues found in: [list any sections with zero findings]
```

If no findings at all: "✓ No significant technical debt detected. The agent team
kept things clean."

### Step 6: [Conditional] Offer cleanup PRD

If `--fix` was passed, or if HIGH findings exist, ask the user:

```
Found <N> high-severity issues. Want me to create a cleanup PRD in
docs/planning/todo/ to track fixing them?

1. Yes — create cleanup PRD
2. No — report only
```

If yes, write a PRD to `docs/planning/todo/cleanup-debt-<YYYY-MM-DD>.md`:
- Title: "Technical Debt Cleanup — <date>"
- Overview: summary of findings
- User stories: one per HIGH finding, framed as developer experience improvements
- Each story includes the exact file locations from the scan

Update `docs/STATUS.md` Planning Documents table if it exists.

---

## Rules

- Report findings with exact file paths and line numbers — vague findings aren't actionable
- Never auto-fix anything — this is an audit tool, not a code modifier
- Skip `node_modules/`, `.next/`, `dist/`, `build/`, `.turbo/` directories
- For the dead export check, if grep is slow on large projects, limit to files changed in scope
- If the scan turns up 0 findings, say so clearly — a clean bill of health is valuable signal
- The goal is signal, not noise: if similarity detection is uncertain, prefer to skip rather than flood the report with false positives
