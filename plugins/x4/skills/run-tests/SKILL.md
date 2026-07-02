---
name: run-tests
description: Use when the user wants to run tests — detects app types (web, marketing, desktop), routes to the right e2e strategy per app, and runs unit, lint, and typecheck from config. Trigger for "run tests", "run unit tests", "run e2e", "check lint", "run all checks", or any request to execute the test suite. Pass a specific type (unit/e2e/lint/typecheck) or run all. App-type-aware for e2e: loads the right Playwright strategy for Next.js web app, marketing site (Three.js), or Electron.
argument-hint: "[unit|e2e|lint|typecheck]"
version: 3.0.0
license: MIT
---

# /run-tests

Run test commands. App-type-aware for e2e: detects Next.js web, marketing site,
and Electron apps and routes each to its correct Playwright strategy.

Reference files in `references/` contain app-specific guidance — loaded at
runtime to diagnose failures and verify prerequisites.

## Behavior

### Step 1: Load config

Read `.claude/agent-team.config.md` and parse `test_commands`:
- `unit` — unit test command
- `e2e` — e2e command (may be overridden by app-type routing)
- `lint` — lint command
- `typecheck` — typecheck command

### Step 2: Determine which checks to run

- **No argument** → run all configured types in order: unit → e2e → lint → typecheck
- **Argument provided** (`unit`, `e2e`, `lint`, `typecheck`) → run only that type

### Step 3: Run unit / lint / typecheck

For `unit`, `lint`, `typecheck`: run the configured command via Bash, show output,
record pass/fail. These checks are unchanged from prior behavior.

Fallback if no config:
- Unit: `bun test` or `npm test`
- Lint: `bun run lint` (if `lint` script in `package.json`)
- Typecheck: `npx tsc --noEmit` (if `tsconfig.json` exists)

### Step 4: E2E routing

When running e2e (either as the only argument or as part of "run all"):

#### Step 4a: Detect app types

Read `references/e2e-detection.md`. Apply the detection algorithm:

1. Check which app directories exist: `apps/web/`, `apps/marketing/`, `apps/desktop/`
2. Check which playwright packages exist: `packages/playwright-web/playwright.config.ts`,
   `packages/playwright-marketing/playwright.config.ts`, `packages/playwright-desktop/playwright.config.ts`
3. Classify each detected app as **configured** or **not configured**

**Fallback (legacy / single-app):** If no `apps/` directory exists but `test_commands.e2e`
is set, run that command directly and skip all app-type routing.

#### Step 4b: Handle unconfigured apps

If any detected app is not yet configured:

```
E2E not configured for: web, marketing

Run /e2e-setup to scaffold Playwright for these apps.

1. Run /e2e-setup now — scaffold then run
2. Skip e2e for this run
3. Run configured apps only (if any are configured)
```

If option 1: delegate to `/e2e-setup`. After it completes, re-run Step 4.
If option 2: skip e2e, continue with lint/typecheck.
If option 3: proceed with only the configured apps.

#### Step 4c: Check prerequisites per app

For each **configured** app, load its runtime reference:
- web → read `references/e2e-web.md`
- marketing → read `references/e2e-marketing.md`
- desktop → read `references/e2e-desktop.md`

Check the prerequisites listed in that reference. If a prerequisite fails (e.g.,
missing storageState, no marketing build), report specifically before running:

```
⚠ web: .playwright/storageState.json not found
  → Auth setup hasn't run. The setup project will seed it automatically on first run.

⚠ marketing: apps/marketing/.next/ not found
  → A production build is required. Run: turbo run build --filter=marketing
  Continue anyway? (yes / no)
```

#### Step 4d: Build run commands

Read `references/e2e-turbo.md` for the Turborepo command shape.

If `test_commands.e2e` is set in config: use it (respects any custom command the project configured).
Otherwise construct from convention:

- Single app: `turbo run e2e --filter=playwright-{type}`
- Multiple apps: `turbo run e2e` (runs all configured suites in parallel via Turbo)

#### Step 4e: Run e2e suites

Execute the commands. Show full output per suite.

For each failure, look up the error string in the loaded reference file's
"Failure Triage" table and surface the most likely cause and fix alongside
the raw output.

**Visual regression special handling (marketing):** If a snapshot comparison
fails in `packages/playwright-marketing/`, do NOT attempt any auto-fix.
Report clearly:
```
⚠ Visual regression failure in playwright-marketing
  Review the diff in playwright-report/ then:
  - If intentional: npx playwright test --update-snapshots && git add snapshots/
  - If a bug: revert the UI change that caused the diff
```

### Step 5: Report

```
## Test Results

| Type            | Status | Details                          |
|-----------------|--------|----------------------------------|
| unit            | PASS   | 42 passed, 0 failed              |
| e2e (web)       | PASS   | 18 passed, 0 failed              |
| e2e (marketing) | FAIL   | snapshot mismatch — see above    |
| e2e (desktop)   | SKIP   | Not configured                   |
| lint            | PASS   | Clean                            |
| typecheck       | PASS   | Clean                            |
```

If any check fails: show failure output and the triage suggestion (if found in reference).

## Rules

- Always load detection and runtime references — never hardcode app-type logic inline
- Fallback to `test_commands.e2e` literal for projects without `apps/` or playwright packages
- Visual regression failures in marketing e2e must never be auto-fixed
- If no test commands are configured at all, tell the user to run `/init-setup`
