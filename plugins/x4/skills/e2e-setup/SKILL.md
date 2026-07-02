---
name: e2e-setup
description: Use when Playwright e2e tests need to be scaffolded for an x4-mono app. Creates packages/playwright-{web,marketing,desktop} with tailored configs, starter tests, and turbo.json integration. Trigger for "set up e2e tests", "configure Playwright", "scaffold e2e for web", "add e2e tests", or when /run-tests reports e2e is not configured. Safe to run for a single app type without affecting others.
argument-hint: "[web|marketing|desktop|all]"
version: 1.0.0
license: MIT
---

# /e2e-setup — Scaffold E2E Test Suites

One-time wizard that creates Playwright packages for each x4-mono app type.
Each app gets a purpose-built suite with the right config, launcher, and starter tests.

Reference files in `references/` contain the exact templates to write — always
read them before writing files, never hardcode content inline.

## Process

### Step 0: Detect project and prerequisites

1. Verify `turbo.json` exists — this is a Turborepo project requirement. If absent:
   "This project doesn't appear to be a Turborepo monorepo. Run `/init-setup` first."
2. Verify `packages/` directory exists. If absent, create it.
3. Read `references/../run-tests/references/e2e-detection.md` for the detection algorithm.
   Apply it to determine: which apps are present, which suites are already configured.

If an argument was passed (`web`, `marketing`, `desktop`), skip detection and go straight
to that app type. If `all` or no argument, proceed to Step 1.

### Step 1: Confirm scope

Present what was found:

```
## E2E Setup

Detected apps:
  ✓ apps/web       (Next.js)           — e2e: not configured
  ✓ apps/marketing (Next.js + Three.js) — e2e: not configured
  ✗ apps/desktop                        — not found

Which apps should I scaffold Playwright for?

1. Both: web + marketing (recommended — all detected)
2. web only
3. marketing only
4. Skip — I'll run /e2e-setup later
```

For apps already configured (`packages/playwright-*/playwright.config.ts` exists):
show them as "already set up" and exclude from the menu. If all apps are already
configured, report "All detected apps already have e2e suites" and stop.

### Step 2: Shared config

Check if `packages/playwright-config/` exists. If not, ask:

```
Set up shared packages/playwright-config first?
All app suites extend this base config for consistent timeouts, reporters,
and retry settings.

1. Yes — create shared base config (recommended)
2. No — each suite will have standalone config
```

If yes: read `references/scaffold-shared-config.md`. Write the files it describes.
Run `bun install` (or detected package manager) from the repo root to link the workspace.

### Step 3: Per-app scaffolding

For each selected app type, read the corresponding scaffold reference:
- web → `references/scaffold-web.md`
- marketing → `references/scaffold-marketing.md`
- desktop → `references/scaffold-desktop.md`

**Before writing each scaffold**, ask the questions defined in that reference file.
Collect all answers first, then write all files. Never write partial file sets.

Show what will be created:

```
## web — Files to create

  packages/playwright-web/package.json
  packages/playwright-web/playwright.config.ts
  packages/playwright-web/e2e/auth.setup.ts
  packages/playwright-web/e2e/tests/auth.spec.ts
  packages/playwright-web/e2e/tests/trpc.spec.ts

  .gitignore — add: .playwright/storageState.json

Create these files? (yes / skip web / cancel)
```

Substitute `{{PLACEHOLDER}}` tokens in templates with the user's answers before writing.

### Step 4: Update `turbo.json`

Read current `turbo.json`. Check if an `e2e` task already exists.

If not, read `references/../run-tests/references/e2e-turbo.md` for the canonical task shape.
Show the proposed addition:

```json
"e2e": {
  "cache": false,
  "dependsOn": ["^build"],
  "passThroughEnv": ["PLAYWRIGHT_BROWSERS_PATH", "CI", "TEST_USER_EMAIL", "TEST_USER_PASSWORD"],
  "outputs": ["test-results/**", "playwright-report/**"]
}
```

Ask: "Add this e2e task to turbo.json? (yes / no)"
If yes, merge it into the existing `tasks` block.

If an `e2e` task already exists, leave it unchanged and note it in the report.

### Step 5: Update `agent-team.config.md`

If `test_commands.e2e` is not set in `.claude/agent-team.config.md`, add:
```yaml
test_commands:
  e2e: turbo run e2e
```

If already set, leave it unchanged.

If the write is blocked by a file-protection hook, print this instead of failing silently:

```
Manual step required — add to .claude/agent-team.config.md:

  test_commands:
    e2e: turbo run e2e
```

### Step 6: Install dependencies

Detect package manager: check for `bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, else npm.

For each scaffolded package, install deps:
```bash
bun install   # or pnpm install / npm install
```

Run from the repo root (Turborepo manages workspace installs).

Then install Playwright browsers for each suite:
```bash
npx playwright install chromium
```
Run from each `packages/playwright-*/` directory (or pass `--filter` if using pnpm).

### Step 7: Report

```
## E2E Setup Complete

Scaffolded:
  packages/playwright-config/     — 2 files
  packages/playwright-web/        — 5 files
  packages/playwright-marketing/  — 6 files

turbo.json — e2e task added
.claude/agent-team.config.md — test_commands.e2e set

Next steps:
  1. Set TEST_USER_PASSWORD in .env.test (web only)
  2. Ensure a test user exists in the dev database
  3. Generate marketing baselines:
       turbo run build --filter=marketing
       turbo run e2e --filter=playwright-marketing -- --update-snapshots
       git add packages/playwright-marketing/snapshots/
  4. Run all suites: /run-tests e2e
```

Customize the next steps based on which suites were actually scaffolded.

## Rules

- Never overwrite existing `playwright.config.ts` without asking
- Always read scaffold reference files — never hardcode template content inline
- Never write partial file sets (ask once, then write all or none)
- The shared `playwright-config` package must be installed before app-specific packages reference it
- Marketing: always remind user to generate initial snapshot baselines — tests will fail until baselines exist
- Desktop: always remind user to add `ELECTRON_IS_TEST=1` handling in `apps/desktop/src/main.ts`
