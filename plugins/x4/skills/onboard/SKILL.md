---
name: onboard
description: >
  Guide a new user through setting up their local development environment —
  checks for required tools, accounts, and CLI access, then walks through
  setup for anything missing.
version: 1.0.0
license: MIT
---

# /onboard — Developer Environment Setup Guide

Interactive onboarding wizard that checks every prerequisite for working with
x4-mono projects and the x4-agent-plugins workflow. Detects what's already
installed, skips what's ready, and walks through setup for anything missing.

Run this once on a new machine or when onboarding a new team member.

## Process

### Step 1: Welcome + Detect Current State

Run all detection checks in parallel, then present a dashboard:

```
## x4 Developer Onboarding

Checking your environment...

| Tool / Account       | Status | Version / Notes               |
|----------------------|--------|-------------------------------|
| Bun                  | OK     | 1.3.8                         |
| Node.js              | OK     | 22.1.0                        |
| Git                  | OK     | 2.44.0                        |
| GitHub CLI (gh)      | OK     | 2.50.0, authenticated         |
| Claude Code          | OK     | Running now                   |
| Neon account         | ?      | Need to check                 |
| Railway account      | ?      | Need to check                 |
| Vercel account       | ?      | Need to check                 |
| Anthropic API key    | ?      | Need to check                 |

Items to set up: 4
```

**Detection commands:**

| Check | Command | Pass condition |
|-------|---------|---------------|
| Bun | `bun --version` | >= 1.1 |
| Node.js | `node --version` | >= 18.0 |
| Git | `git --version` | Any version |
| GitHub CLI | `gh --version` | Installed |
| gh auth | `gh auth status` | Authenticated |
| Neon CLI | `neonctl --version` | Installed (optional) |
| Railway CLI | `railway --version` | Installed (optional) |
| Vercel CLI | `vercel --version` | Installed (optional) |
| Python 3 | `python3 --version` | >= 3.8 (for llmstxt script) |

### Step 2: Required Tools

Walk through each missing required tool. Only show steps for tools that
are NOT already installed.

#### 2a. Bun (Required)

If Bun is not installed or version < 1.1:

```
## Install Bun

Bun is the package manager and runtime for x4-mono projects.

Install now?

1. Yes — run: curl -fsSL https://bun.sh/install | bash
2. Skip — I'll install it myself later
```

If yes, run the install command and verify with `bun --version`.

#### 2b. Node.js (Required)

If Node.js is not installed or version < 18:

```
## Install Node.js

Node.js >= 18 is required for some tooling.

Recommended install method:

1. nvm (Node Version Manager) — best for managing multiple versions
2. Direct download from nodejs.org
3. Skip — I'll install it myself
```

If option 1:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 22
```

#### 2c. Git (Required)

If Git is not installed:

```
## Install Git

Git is required for version control.

1. Install via Homebrew: brew install git
2. Install via Xcode CLT: xcode-select --install
3. Skip — I'll install it myself
```

#### 2d. GitHub CLI (Required)

If `gh` is not installed or not authenticated:

```
## GitHub CLI

The GitHub CLI is used for PR management, CI watching, and repo operations.

1. Install: brew install gh
2. Skip — I'll install it myself
```

After install (or if already installed but not authenticated):
```
## GitHub Authentication

Run: gh auth login

1. Walk me through it now
2. Skip — I'll do it later

Note: Choose "GitHub.com", "HTTPS", and "Login with a web browser"
when prompted.
```

If option 1, run `gh auth login` and let the user complete the flow.

### Step 3: Accounts + Services

Present only the services that are relevant. Use `AskUserQuestion` for each.

#### 3a. Neon (Database)

```
## Neon PostgreSQL

x4-mono uses Neon for serverless PostgreSQL with branch-per-PR workflows.

Do you have a Neon account?

1. Yes — I have an account
2. No — help me sign up (free tier available)
3. Skip — I'll use a different database provider
```

If option 2:
```
Sign up at: https://console.neon.tech/signup

Free tier includes:
- 1 project, 10 branches
- 0.5 GB storage, 190 compute hours/month
- Enough for development + staging

Once signed up, come back and we'll set up the CLI.
Ready to continue? (yes / not yet)
```

After account confirmed, offer Neon CLI setup:
```
## Neon CLI (optional but recommended)

The Neon CLI enables database branch management from the terminal.

1. Install: npm install -g neonctl
2. Skip — I'll use the Neon dashboard instead

Note: The Neon MCP server in Claude Code can also manage branches
without the CLI.
```

If installed, authenticate: `neonctl auth`

#### 3b. Railway (Hosting + Preview)

```
## Railway

Railway provides hosting with automatic preview environments per PR.

Do you have a Railway account?

1. Yes — I have an account
2. No — help me sign up (free tier: $5/month credit)
3. Skip — I'll use a different hosting provider (Vercel, Netlify, etc.)
```

If option 2:
```
Sign up at: https://railway.app

Free tier includes:
- $5/month free credit
- Preview environments per PR
- Automatic deploys from GitHub

Ready to continue? (yes / not yet)
```

After account confirmed:
```
## Railway CLI

1. Install: npm install -g @railway/cli
2. Skip — I'll use the Railway dashboard

After install, authenticate: railway login
```

#### 3c. Vercel (Alternative hosting / Frontend deploys)

```
## Vercel

Vercel is used for Next.js frontend deployments (web + marketing sites).

Do you have a Vercel account?

1. Yes — I have an account
2. No — help me sign up (free for personal projects)
3. Skip — I'm using Railway or another provider for everything
```

If option 2:
```
Sign up at: https://vercel.com/signup

Recommended: Sign up with your GitHub account for automatic deploys.

Ready to continue? (yes / not yet)
```

After account confirmed:
```
## Vercel CLI

1. Install: npm install -g vercel
2. Skip

After install, authenticate: vercel login
```

#### 3d. Anthropic API Key (AI features)

```
## Anthropic API Key

x4-mono includes AI features powered by Claude. You need an API key
for AI integrations in your app (not for Claude Code itself).

Do you have an Anthropic API key?

1. Yes — I have a key
2. No — help me get one
3. Skip — I don't need AI features right now
```

If option 2:
```
Get an API key at: https://console.anthropic.com/settings/keys

1. Create an account if you don't have one
2. Go to Settings → API Keys → Create Key
3. Copy the key (starts with sk-ant-)

Paste your key when ready (or type "skip"):
```

If they provide a key, validate it starts with `sk-ant-` and store it
for use in `/env` later.

### Step 4: Claude Code Plugins & Companions

Check which plugins are installed. The x4 plugin works best with companion
plugins from the official Claude marketplace.

**Required by x4 workflows** (referenced directly in `/plan-backlog` and `/work`):
- `superpowers@claude-plugins-official` — brainstorming + writing plans
- `code-simplifier@claude-plugins-official` — code quality in review phase

**Recommended** (enhance specific agents and workflows):
- `frontend-design@claude-plugins-official` — UI design patterns (frontend agent)
- `code-review@claude-plugins-official` — structured reviews (reviewer agent)
- `playwright@claude-plugins-official` — e2e test authoring (tester agent)
- `typescript-lsp@claude-plugins-official` — TypeScript diagnostics (all agents)
- `commit-commands@claude-plugins-official` — git workflow helpers
- `github@claude-plugins-official` — PR and issue management
- `railway@railway-skills` — Railway deployment management

Present the dashboard:

```
## Claude Code Plugins

Checking installed plugins...

### x4 Plugin
| Plugin | Status    |
|--------|-----------|
| x4     | Installed |

### Companion Plugins — Required by x4
These plugins are used directly by x4 skills. Without them, x4 falls back
to built-in alternatives, but the experience is better with them installed.

| Plugin           | Status  | Used by                |
|------------------|---------|------------------------|
| superpowers      | ???     | /plan-backlog          |
| code-simplifier  | ???     | /work Phase 4          |

### Companion Plugins — Recommended
These plugins enhance specific agents and workflows.

| Plugin           | Status  | Enhances               |
|------------------|---------|------------------------|
| frontend-design  | ???     | Frontend agent         |
| code-review      | ???     | Reviewer agent         |
| playwright       | ???     | Tester agent, /verify  |
| typescript-lsp   | ???     | All TypeScript work    |
| commit-commands  | ???     | Git workflow           |
| github           | ???     | PR management          |
| railway          | ???     | Railway deploys        |

What would you like to install?

1. Install all missing (required + recommended)
2. Install required only (superpowers + code-simplifier)
3. Pick which ones to install
4. Skip
```

For option 1 or 2, install each missing plugin:
```
/plugin install superpowers@claude-plugins-official
/plugin install code-simplifier@claude-plugins-official
```
(and recommended plugins if option 1)

For option 3, present a numbered list of missing plugins and ask for
comma-separated selections.

After installation, confirm what was installed with a summary table.

### Step 5: Optional Tools

```
## Optional Tools

These aren't required but enhance the development experience:

| Tool | Purpose | Install? |
|------|---------|----------|
| Python 3.8+ | llms.txt download script | Already installed / Install |
| Expo CLI | Mobile development | eas-cli for builds |
| Playwright | E2E testing | bunx playwright install |

Install optional tools? (comma-separated numbers, or skip):
```

For each selected:
- Python: Check `python3 --version`, suggest install via Homebrew if missing
- Expo: `npm install -g eas-cli`, then `eas login`
- Playwright: `bunx playwright install` (installs browser binaries)

### Step 6: Summary + Next Steps

```
## Onboarding Complete!

### Environment
- Bun: 1.3.8
- Node.js: 22.1.0
- Git: 2.44.0
- GitHub CLI: authenticated

### Accounts
- Neon: configured (CLI authenticated)
- Railway: configured (CLI authenticated)
- Anthropic: API key saved

### Plugins
- x4: installed
- superpowers: installed / missing
- code-simplifier: installed / missing
- (list any other companion plugins that were installed)

### Ready to Go!

Create your first project:
  /create my-app

Or run /env in an existing project to configure environment variables.
```

If anything was skipped, add a "Still needs setup" section listing what
to come back to.

## Rules

- Never install anything without asking first
- Show what's already working — don't waste time on things that are set up
- All accounts have free tiers — always mention this
- Store detected state so we don't re-check during the same session
- If a tool install fails, show the error and suggest manual install
- Never ask for or display full API keys — mask after validation
- Neon MCP in Claude Code is an alternative to the Neon CLI — mention both
- This skill is idempotent — safe to re-run anytime to check status
