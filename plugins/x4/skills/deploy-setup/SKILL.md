---
name: deploy-setup
description: Use when setting up Railway deployments for the first time, when PR preview deployments aren't working, or when adding a new service to the monorepo. Creates or links a Railway project, generates railway.toml for all apps in the monorepo, syncs environment variables from .env.local, and walks through GitHub connection and PR preview setup. Trigger for "set up Railway", "configure deployments", "PR previews aren't working", "how do I deploy this?", "set up preview environments", or when /work reports that preview_url_command returns no URLs.
version: 1.0.0
license: MIT
---

# /deploy-setup — Railway Deployment Wizard

One-time wizard that configures Railway for a monorepo project. Detects all
apps, generates `railway.toml` with per-service config, syncs env vars from
`.env.local`, and walks through the dashboard steps needed for GitHub
integration and PR preview deployments.

**Arguments:**
- `--project <name>` — Railway project name (skips the name prompt)

## Process

### Step 0: Prerequisites

Before asking anything, verify the environment is ready:

1. **Railway CLI**: `railway --version` — if not found:
   "Railway CLI is required. Install it with: `bun add -g @railway/cli` or `npm install -g @railway/cli`"
   Stop.

2. **Railway auth**: `railway whoami` — if not authenticated:
   "You're not logged in to Railway. Run: `railway login`"
   Stop.

3. **GitHub remote**: `git remote get-url origin` — if no remote:
   "A GitHub remote is required for PR preview deployments. Add one first."
   Stop.

4. **Existing railway.toml**: If `railway.toml` exists in the project root, read it and
   note the currently configured services. Ask the user:
   ```
   Found existing railway.toml with {N} service(s): {service names}.

   1. Update it — add missing services, sync env vars (existing services preserved)
   2. Skip — keep railway.toml as-is and exit the wizard
   ```
   If the user picks 2, stop. If they pick 1, continue and treat existing service
   blocks as already-configured (don't regenerate them unless they're missing).

5. **Existing Railway link**: Run `railway status` to check if the project is already
   linked. If linked, note the project name and skip Step 1's "create" path — go
   straight to the "use existing" path.

### Step 1: Project setup

**If already linked** (detected in Step 0):
```
## Railway Project

Already linked to Railway project: {project-name}

1. Keep using {project-name}
2. Link to a different project
3. Create a new Railway project
```

**If not linked:**
```
## Railway Project

1. Create a new Railway project
2. Link to an existing Railway project (I already have one)
```

For **Create new**:
- If `--project <name>` was passed, use it directly: `railway init --name <name>`
- Otherwise, suggest a name from the root `package.json` `name` field (strip scopes,
  convert to kebab-case) and ask for confirmation or override.
- Run: `railway init --name <project-name>`
- Confirm the project was created: `railway status`

For **Link to existing**:
- Run: `railway link`
- This opens an interactive selector — tell the user to pick their project.
- After completion, confirm with: `railway status`

### Step 2: Detect services

Scan the project to determine what services need Railway configuration:

1. Glob for `apps/*/package.json`. For each app, extract:
   - App name (directory name)
   - Start command (from `scripts.start` in package.json)
   - Build command (from `scripts.build` in package.json)
   - Port (from `scripts.dev`, env files, or common defaults)
   - App type: detect from dependencies:
     - Has `next` → Next.js app (HTTP, port 3000)
     - Has `express` or `fastify` or `hono` → API server (HTTP, port 3001 or 3002)
     - Has `expo` → mobile app (skip — not deployable to Railway)
     - Has `vite` → SPA (HTTP)

2. Present the detection results for confirmation:

```
## Detected Services

The following apps will be configured as Railway services:

  web          → apps/web         (Next.js, port 3000)
  api          → apps/api         (Hono API, port 3002)
  marketing    → apps/marketing   (Next.js, port 3000)

  ○ mobile     → apps/mobile      (Expo — skipped, not deployable to Railway)

1. Use this service plan
2. Add a service
3. Remove a service
4. Adjust a port
```

Wait for confirmation before continuing. Make adjustments as requested.

### Step 3: Generate railway.toml

Write `railway.toml` to the project root based on the confirmed service plan.

Use this template, substituting per-service values:

```toml
[build]
builder = "NIXPACKS"

[[services]]
name = "{app-name}"
rootDirectory = "apps/{app-name}"

  [services.build]
  buildCommand = "bun run build"

  [services.deploy]
  startCommand = "bun run start"
  healthcheckPath = "/"
  healthcheckTimeout = 30
```

**API services** (non-Next.js HTTP servers): add `tcpProxyApplicationPort`:
```toml
  [services.deploy]
  startCommand = "bun run start"
  healthcheckPath = "/health"
  healthcheckTimeout = 30
  tcpProxyApplicationPort = {port}
```

**Database services** (Postgres, Redis — if detected in Railway dashboard or noted
by user): skip generating service blocks for these — Railway manages them as
plugins, not services in railway.toml.

After writing the file, show the generated `railway.toml` to the user and ask:
```
railway.toml written. Does this look right?
1. Yes — continue
2. Let me edit it — I'll tell you what to change
```

Incorporate any requested changes before proceeding.

### Step 4: Environment variables

Sync environment variables from the local env file to Railway's per-service config.

1. Detect the env file: check `.env.local`, `.env`, `.env.production` in order.
   If none found: "No .env file found — skipping env var sync. You can add them
   manually in the Railway dashboard."

2. Read the env file and parse key=value pairs. Exclude:
   - Lines starting with `#` (comments)
   - Empty lines
   - Keys that are obviously local-only: `PORT`, `HOST`, `HOSTNAME`, `NODE_ENV`,
     `NEXT_PUBLIC_*` that point to localhost URLs

3. Group variables by service:
   - Database URLs → all services that use a DB (or ask which services need it)
   - `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` → api service
   - `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL` → web service
   - Unknown keys → ask the user which service(s) should receive them

4. Present a summary and ask for confirmation before syncing:

```
## Environment Variables

The following variables will be synced to Railway (values hidden):

  web:
    BETTER_AUTH_SECRET  ••••••••
    BETTER_AUTH_URL     ••••••••
    DATABASE_URL        ••••••••

  api:
    ANTHROPIC_API_KEY   ••••••••
    DATABASE_URL        ••••••••

  marketing:
    (none)

1. Sync these variables
2. Adjust assignments
3. Skip — I'll manage env vars manually
```

5. If user approves, set variables per service:
   ```bash
   railway variables set KEY="value" --service {service-name}
   ```
   Run one command per variable per service. Never echo values in command output —
   pipe through the CLI directly without logging the value.

6. Report how many variables were set per service.

### Step 5: GitHub integration + PR previews

This step requires Railway dashboard actions that cannot be automated via the CLI.
Walk the user through each step with clear instructions and pause for confirmation.

```
## GitHub Integration & PR Previews

Railway requires a few manual steps in the dashboard to connect your GitHub
repo and enable PR preview deployments. I'll walk you through each one.

**Step 5.1 — Open your Railway project:**
Go to: https://railway.app/dashboard
Click on: {project-name}

Done? (yes / skip)
```

After "yes":

```
**Step 5.2 — Connect your GitHub repository:**

In the Railway project dashboard:
1. Click "New Service" → "GitHub Repo"
2. If prompted, authorize Railway to access your GitHub account
3. Search for and select: {github-repo-name}
   (from git remote: {remote-url})
4. Railway will ask which branch to deploy from — select: main (or your base branch)

Note: If you already connected GitHub in Step 1 (via railway init), Railway
may have done this automatically. Check if services already appear in the dashboard.

Done? (yes / skip)
```

After "yes":

```
**Step 5.3 — Enable PR preview deployments:**

In the Railway project dashboard:
1. Click the "Settings" tab for the project
2. Find "PR Deployments" or "Preview Environments"
3. Toggle it ON
4. Set the source branch to: main (or your base branch)

This creates a temporary environment for every PR — each PR gets its own
isolated set of services with the PR's code deployed.

Done? (yes / skip)
```

After "yes":

```
**Step 5.4 — Share variables across environments (optional but recommended):**

By default, Railway PR preview environments don't inherit your production
variables. To share them:
1. In the project settings, find "Shared Variables" or "Environment Variables"
2. Add variables that should be the same in all environments (e.g., ANTHROPIC_API_KEY)
3. Service-specific variables (like DATABASE_URL) should use Railway's
   "Reference Variable" feature to auto-create per-environment databases.

Done? (yes / skip)
```

### Step 6: Update preview_url_command in config

After GitHub is connected and PR previews are enabled, update `.claude/agent-team.config.md`
to use the correct command for fetching preview URLs.

Read the current config. Find the `ci.preview_url_command` key (or add it if absent).

Replace with:
```yaml
ci:
  preview_url_command: "railway status --json | jq -r '.services[]? | \"\(.name): \(.url // \"pending\")\"'"
```

This command lists all service URLs for the current Railway environment — works
correctly for multi-service monorepos and returns "pending" for services still deploying.

Tell the user:
"Updated `preview_url_command` in `.claude/agent-team.config.md`. `/x4:pr-status`
will now show URLs for all Railway services."

### Step 7: Test deployment

Offer to trigger a test deployment to verify the setup is working:

```
## Test Deployment

Would you like to trigger a test deployment to verify everything is configured correctly?

1. Yes — deploy the current branch to Railway
2. Skip — I'll test it when I create the first PR
```

If user picks Yes:
1. Run: `railway up --detach`
2. Poll for deployment status every 10 seconds (max 5 minutes):
   `railway status --json | jq -r '.services[]? | "\(.name): \(.status // "unknown")"'`
3. Stop polling when all services reach `ACTIVE` or any reach `FAILED`.
4. If all ACTIVE: "Deployment successful!" and show URLs.
5. If any FAILED: show the service name and suggest checking Railway dashboard logs.

If user picks Skip: move directly to Step 8.

### Step 8: Summary

Print a structured report:

```
## Deploy Setup Complete

### Railway Project
  Project:  {project-name}
  Region:   {region if known, else "Railway default"}
  Dashboard: https://railway.app/dashboard

### Services Configured
  {service-name}  apps/{name}  → {url or "pending PR preview"}
  {service-name}  apps/{name}  → {url or "pending PR preview"}

### Environment Variables
  {N} variables synced across {M} services

### PR Previews
  {Enabled / Manual — configure in Railway dashboard}

### Config Updated
  .claude/agent-team.config.md — preview_url_command updated
  railway.toml — service definitions written

### Next Steps
  - Push a PR and check preview URLs with /x4:pr-status
  - Run /x4:llmstxt-update if you added Railway docs to your deps
  - Re-run /deploy-setup anytime to add new services or update env vars
```

## Rules

- Never print environment variable values — only report key names and whether they were synced
- Never force-push or modify git history
- Always confirm the service plan with the user before generating railway.toml
- Always show generated railway.toml before writing env vars
- Dashboard steps cannot be automated — guide clearly and wait for user confirmation
- If any CLI command fails, show the raw error and suggest the Railway docs or dashboard as fallback
- Do not assume services exist in Railway before `railway status` confirms them
