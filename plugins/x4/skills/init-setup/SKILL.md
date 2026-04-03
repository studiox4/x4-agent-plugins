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
  and present current values as defaults for each question.

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

# [Only include if user configured brand in Step 6c]
brand:
  name: "Your Product"
  tagline: "Your tagline."
  voice: "developer-first, direct, show-don't-tell"
  audience: "developers building X with Y"
  email:
    provider: resend                    # or loops
    api_key_env: RESEND_API_KEY
    from: "updates@yourdomain.com"
    audience_id: ""                     # Resend audience ID or Loops list ID
  social:
    twitter_handle: "@yourbrand"
    x_api_key_env: X_API_KEY           # optional — enables --post in /market-tweet
    linkedin_url: "https://linkedin.com/company/yourbrand"
    hashtags: []
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

Auto-detect: check if `docs/CHANGELOG.md` exists (brand is more useful if changelog is present).

Use `AskUserQuestion`:

```
## Brand & Marketing Channels

Configure your brand voice and marketing channels for /market-email,
/market-linkedin, and /market-tweet.

1. Yes — configure brand settings now
2. Skip — I'll set this up later
```

If yes, collect the following (all optional, but the more filled in the better):

```
Brand name: {project name from package.json as default}
Tagline: (one-liner — e.g. "Idea to shipped PR — with agent teams.")
Voice/tone: (e.g. "developer-first, direct, show-don't-tell")
Target audience: (e.g. "developers building full-stack apps with Claude Code")
```

Email provider:
```
Email provider:
1. Resend (recommended for developer projects — resend.com)
2. Loops (SaaS-focused email — loops.so)
3. None / manual
```

If Resend or Loops:
```
From address: (e.g. updates@yourdomain.com)
API key env var name: (default: RESEND_API_KEY or LOOPS_API_KEY)
Audience ID: (optional — your Resend audience or Loops list ID)
```

Social channels:
```
Twitter/X handle: (e.g. @yourbrand)
X API key env var: (optional — enables --post flag in /market-tweet)
LinkedIn company URL: (e.g. https://linkedin.com/company/yourbrand)
Hashtags: (comma-separated, e.g. #ClaudeCode,#AIdev,#devtools)
```

Include the `brand` block in the Step 7 config output (see config template).
If the user skips, omit the `brand` block entirely.

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
## LLMs.txt Reference Docs

llms.txt files give Claude context about your dependencies — frameworks,
libraries, and tools. This helps agents write better code with fewer mistakes.

Set up llms.txt for this project?

1. Yes — run /llmstxt-init to scaffold config and download docs
2. Skip — I'll set this up later
```

If yes, delegate to the `/llmstxt-init` skill. After it completes, return
to the summary step.

If `.llmstxt.json` already exists, skip this step and note it in the summary
as "already configured."

### Step 7d: Email capture (conditional)

If the user opted into email capture in Step 6b AND `brand.email` was configured
in Step 6c, delegate to `/market-subscribe` now. After it completes, return to
the summary step.

### Step 8: Confirm

Show the user a summary of what was configured and tell them:
- They can re-run `/init-setup` anytime to reconfigure
- They can edit `.claude/agent-team.config.md` directly
- Run `/init-agents` next to generate agent files
- Use `/idea` to capture features and `/plan-backlog` to write PRDs
- Run `/llmstxt-update` anytime to refresh reference docs

## Rules

- Always auto-detect before asking — show detections as defaults
- Skip confirmation for auto-detected values only if confidence is high (lockfile exists)
- Never write config blocks for "None" selections
- If config already exists, preserve values the user doesn't change
- Create `.claude/` directory if it doesn't exist
