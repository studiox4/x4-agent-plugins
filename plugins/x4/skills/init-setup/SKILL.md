---
name: init-setup
description: Use when setting up a project for x4 workflows or when the agent-team config is missing. Configures database branching, hosting, CI, package manager, and test framework into .claude/agent-team.config.md. Trigger for "set up my project", "configure x4", "I need to set up my database branching", or when /work reports missing configuration. Run once per project.
version: 2.0.0
license: MIT
---

# /init-setup — Tooling Configuration Wizard

Interactive setup wizard that detects project tooling and writes
`.claude/agent-team.config.md`. Uses `AskUserQuestion` for each choice,
auto-detects where possible.

## Process

### Step 1: Auto-detect

Before asking anything, scan the project for signals:

- **Package manager:** Check for lockfiles in priority order:
  `bun.lockb` → bun, `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm,
  `package-lock.json` → npm. If none found, default to npm.

- **Test framework:** Check `package.json` scripts and config files:
  `vitest.config.*` → vitest, `jest.config.*` → jest, `bun.lockb` + test script → bun test,
  `pytest.ini` or `pyproject.toml [tool.pytest]` → pytest.
  If none found, mark as unknown.

- **CI:** Check for `.github/workflows/` → GitHub Actions,
  `.gitlab-ci.yml` → GitLab CI. If none found, mark as unknown.

- **Existing config:** If `.claude/agent-team.config.md` already exists, read it
  and ask the user:
  ```
  Found existing config. What would you like to do?
  1. Update — walk through setup again with current values pre-filled as defaults
  2. Cancel — keep existing config as-is
  ```
  If they pick 2, stop. If they pick 1, continue with current values as defaults
  for each question — only overwrite values the user actively changes.

### Step 2: Database provider

Use `AskUserQuestion`:

```
## Database Provider

Choose your database branching provider (used for isolated dev branches):

1. Neon (via MCP tools)
2. PlanetScale (via CLI)
3. Supabase (via CLI)
4. None — no database branching

[Detected: <detection if any>]
```

If user picks 1-3, ask follow-up for project ID / connection details.
If user picks 4, omit `db_branching` from config entirely.

### Step 3: Hosting / Preview

Use `AskUserQuestion`:

```
## Hosting & Preview Environments

Where does this project deploy? (used for preview URL checks):

1. Railway
2. Vercel
3. Netlify
4. None — no preview environments
```

If user picks 1 (Railway), set `ci.preview_url_command` to:
`railway status --json | jq -r '.services[]? | "\(.name): \(.url // \"pending\")"'`

Then offer to run deploy-setup now:
```
Railway selected. Run /x4:deploy-setup to configure Railway services,
sync env vars, and enable PR previews?

1. Yes — run /deploy-setup now (recommended for first-time setup)
2. Skip — I'll run it later
```
If yes, delegate to `/deploy-setup`. After it completes, return to Step 4.

If user picks 2-3, set `ci.preview_url_command` to the appropriate CLI command.
If user picks 4, omit preview config.

### Step 4: CI Provider

Use `AskUserQuestion` (skip if already detected and user confirms):

```
## CI Provider

How do you run CI? [Detected: <provider or "none">]

1. GitHub Actions (default)
2. GitLab CI
3. None — no CI integration

Keep detected? (y/n)
```

Set `ci.watch_command` based on selection:
- GitHub Actions: `gh run watch`
- GitLab CI: `glab ci view`
- None: omit `ci` section

### Step 5: Package manager

Use `AskUserQuestion` (skip if auto-detected and user confirms):

```
## Package Manager

[Detected: <manager> from <lockfile>]

1. bun
2. npm
3. yarn
4. pnpm

Keep detected? (y/n)
```

### Step 6: Test framework

Use `AskUserQuestion` (skip if auto-detected and user confirms):

```
## Test Framework

[Detected: <framework> from <config file>]

1. vitest
2. jest
3. bun test
4. pytest
5. Custom — I'll provide the commands

Keep detected? (y/n)
```

If custom, ask for each command: unit, e2e, lint, typecheck.

Otherwise, set defaults:
- vitest: `npx vitest run`, e2e: `npx vitest run --config vitest.e2e.config.ts`
- jest: `npx jest`, e2e: `npx jest --config jest.e2e.config.js`
- bun test: `bun test`, e2e: `bun test --config bun.e2e.config.ts`
- pytest: `pytest tests/unit`, e2e: `pytest tests/e2e`

Also detect lint (`eslint`, `biome`, `ruff`) and typecheck (`tsc`, `pyright`)
from package.json scripts or config files.

### Step 7: Write config

Write `.claude/agent-team.config.md` with all selections. Only include sections
for providers the user selected — omit blocks for "None" choices.

Example output:

```markdown
---
package_manager: bun
base_branch: main

branch_prefixes:
  feature: feat/
  fix: fix/
  chore: chore/

test_commands:
  unit: bunx vitest run
  e2e: bunx vitest run --config vitest.e2e.config.ts
  lint: bunx biome check .
  typecheck: bunx tsc --noEmit

db_branching:
  provider: neon
  project_id: <project-id>
  create_command: "mcp__Neon__create_branch"
  env_var: DATABASE_URL
  cleanup: github-action

ci:
  provider: github-actions
  watch_command: gh run watch
  preview_url_command: "railway status --json | jq -r '.services[]? | \"\(.name): \(.url // \"pending\")\"'"

pr:
  draft: true
  convert_on_ship: true
  labels: []

# [Only include if user configured marketing in Step 6b]
marketing:
  enabled: true
  site_dir: apps/marketing
  screenshots_dir: apps/marketing/public/screenshots
  pages:
    features: app/features/page.tsx     # [only if selected]
    changelog: app/changelog/page.tsx   # [only if selected]
    landing: app/page.tsx               # [only if selected]

---

# Agent Team Configuration

Auto-generated by `/init-setup`. Edit freely.
```

### Step 6b: Marketing site

Auto-detect: check if `apps/marketing/app/` exists and which of these pages are
present: `app/features/page.tsx`, `app/changelog/page.tsx`, `app/page.tsx`.
Pre-select any detected pages.

Use `AskUserQuestion`:

```
## Marketing Site

Does this project have a marketing site in apps/marketing/?

1. Yes — configure market-update integration
2. No / not yet — skip
```

If yes, follow up with page selection:

```
## Marketing Pages

Which pages should /market-update manage?
(Detected pages are pre-selected)

1. Features page (app/features/page.tsx) [Detected: Yes/No]
2. Changelog / What's New page (app/changelog/page.tsx) [Detected: Yes/No]
3. Landing hero (app/page.tsx) [Detected: Yes/No]
4. Custom path — I'll enter it

Enter numbers (e.g. "1 2 3" or "all"), or skip:
```

If user selects pages, include the `marketing` block in the Step 7 config output
(see config template below).

If user picks No or skip: omit the `marketing` block entirely. Its absence is
treated as disabled — no `enabled: false` needed.

After page selection (if marketing site exists), ask:

```
## Email Capture

Add an email sign-up form to capture visitor emails?
This scaffolds a SubscribeForm component and /api/subscribe route.
(Requires brand.email to be configured in the next step)

1. Yes — scaffold email capture after config is written
2. Skip — I'll add it later with /x4:market-subscribe
```

If yes, set a flag to delegate to `/market-subscribe` at the end of Step 7.

### Step 6c: Brand & marketing channels

Brand config lives in `brand/BRAND.md` — a human-editable markdown file at the
project root. All marketing skills (`/market-update`, `/market-email`,
`/market-linkedin`, `/market-tweet`, `/market-subscribe`) read from it.
Logo and image assets go in `brand/assets/`.

Use `AskUserQuestion`:

```
## Brand & Marketing Channels

x4's marketing skills use a brand guide at brand/BRAND.md — a plain markdown
file you can edit anytime to update your voice, logos, colors, and social handles.

Set up brand/BRAND.md now?

1. Yes — collect brand details and generate the file
2. Skip — I'll create it later (or copy from references/brand-template.md)
```

If yes, collect (all optional — defaults shown):

```
Brand name: {project name from package.json as default}
Tagline: (one-liner, e.g. "Idea to shipped PR — with agent teams.")
One-liner description: (for someone who's never heard of you)
Voice/tone: (e.g. "developer-first, direct, show-don't-tell")
Target audience: (e.g. "developers building full-stack apps with Claude Code")
Website URL: (e.g. https://yourdomain.com)
```

Email:
```
Email provider:
1. Resend (recommended — resend.com, great for developer audiences)
2. Loops (SaaS-focused — loops.so)
3. None / I'll add this later

From address: (e.g. updates@yourdomain.com)
API key env var: (default: RESEND_API_KEY or LOOPS_API_KEY)
Audience ID: (optional — find in your Resend or Loops dashboard)
```

Social:
```
Twitter/X handle: (e.g. @yourbrand)
X API key env var name: (optional — enables --post in /market-tweet)
LinkedIn company URL: (e.g. https://linkedin.com/company/yourbrand)
Hashtags: (comma-separated, e.g. #ClaudeCode,#AIdev,#devtools)
```

**Generate brand/BRAND.md:**

Read the template from `references/brand-template.md` (in this skill's directory).
Replace all `{{PLACEHOLDER}}` tokens with the user's answers. Write to `brand/BRAND.md`.
Also create `brand/assets/` directory with a `README.md`:

```markdown
# Brand Assets

Add your logo and image files here. Update the paths in `../BRAND.md`.

| File | Size | Format | Purpose |
|------|------|--------|---------|
| logo.svg | any | SVG | Primary logo — light backgrounds |
| logo-dark.svg | any | SVG | Dark backgrounds |
| logo-icon.svg | any | SVG | Favicon, avatar |
| og-image.png | 1200×630 | PNG | Open Graph — link previews |
| banner.png | 1500×500 | PNG | Twitter/LinkedIn header |
```

Tell the user:
```
✓ brand/BRAND.md created — edit it anytime to update your brand across all marketing skills
✓ brand/assets/ created — add your logo.svg, og-image.png, and other assets here

Your brand guide lives at: brand/BRAND.md
```

If user skips: note in summary "Brand guide not configured. Create `brand/BRAND.md` anytime,
or run `/init-setup` again. Template is at `plugins/x4/skills/init-setup/references/brand-template.md`."

### Step 7b: Project Tracker

Use `AskUserQuestion`:

```
## Project Tracker

The project tracker scaffolds STATUS.md, BACKLOG.md, and planning folders
(todo / in-progress / complete). This powers /idea and /plan-backlog.

Set up project tracking for this project?

1. Yes — run /init-tracker to scaffold tracking files
2. Skip — I'll set this up later
```

If yes, delegate to the `/init-tracker` skill. After it completes, return
to the next step.

If `docs/BACKLOG.md` (or the configured backlog file) already exists, skip
this step and note it in the summary as "already configured."

### Step 7c: LLMs.txt Reference Docs

Use `AskUserQuestion`:

```
## Source Code References (opensrc)

opensrc fetches actual source code for your npm dependencies so agents can
read implementations — not just docs. This gives agents deeper context for
writing library-specific code correctly.

Set up opensrc for this project?

1. Yes — run /opensrc-init to detect key dependencies and fetch their source
2. Skip — I'll set this up later
```

If yes, delegate to the `/opensrc-init` skill. After it completes, return
to the summary step.

If `opensrc/sources.json` already exists, skip this step and note it in the
summary as "already configured."

### Step 7d: Email capture (conditional)

If the user opted into email capture in Step 6b AND `brand.email` was configured
in Step 6c, delegate to `/market-subscribe` now. After it completes, return to
the summary step.

### Step 7e: E2E test suites (conditional)

Only run this step if `apps/` directory exists with at least one app subdirectory.

Use `AskUserQuestion`:

```
## E2E Testing

Detected apps: {list of apps/web, apps/marketing, apps/desktop that exist}

Set up Playwright e2e test suites now?

1. Yes — run /e2e-setup to scaffold packages/playwright-{type} for each app
2. Skip — I'll configure e2e later with /e2e-setup
```

If yes, delegate to `/e2e-setup all`. After it completes, return to the summary step.

If `packages/playwright-web/` (or other playwright package) already exists,
skip this step and note it in the summary as "already configured."

### Step 8: Confirm

Write the current x4 plugin version to `.claude/x4-version`. Read the version
from `plugins/x4/.claude-plugin/plugin.json` (when in the x4-agent-plugins repo)
or from the `CURRENT_VERSION` comment in `skills/upgrade/SKILL.md`. This file
is used by the session-start hook and `/x4:upgrade` to track what's been applied.

Show the user a summary of what was configured and tell them:
- Their brand guide lives at `brand/BRAND.md` — edit it anytime to update
  voice, logos, colors, and social handles across all marketing skills
- Add logo files to `brand/assets/` and update the paths in `brand/BRAND.md`
- They can re-run `/init-setup` anytime to reconfigure
- They can edit `.claude/agent-team.config.md` directly
- Run `/init-agents` next to generate agent files
- Run `/e2e-setup` to scaffold Playwright suites for each app (if skipped during setup)
- Use `/idea` to capture features and `/plan-backlog` to write PRDs
- Run `/opensrc-update` anytime to refresh source code references
- Run `/x4:upgrade` after future plugin updates to apply migrations

## Rules

- Always auto-detect before asking — show detections as defaults
- Skip confirmation for auto-detected values only if confidence is high (lockfile exists)
- Never write config blocks for "None" selections
- If config already exists, preserve values the user doesn't change
- Create `.claude/` directory if it doesn't exist
