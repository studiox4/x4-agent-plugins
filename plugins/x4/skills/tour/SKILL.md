---
name: tour
description: Guided post-scaffold walkthrough -- explore apps, test login, try AI chat, set up git remote
version: 1.0.0
license: MIT
---

# /tour -- Post-Scaffold Guided Tour

Interactive walkthrough of a newly scaffolded x4-mono project. Detects which
platforms are installed, shows what's running, and guides the user through
testing each piece step by step.

Each step is paced with `AskUserQuestion` so the user can actually open
their browser and try things. Every step has a skip option.

## Prerequisites

Must be run from inside an x4-mono project root (has `turbo.json` and
`apps/` directory). If not in a project, suggest `/create`.

## Process

### Step 1: Detect project state

1. Verify `turbo.json` exists. If not, suggest `/create` and stop.
2. Scan `apps/` to determine which platforms are installed.
3. Check if `.env.local` exists and has `DATABASE_URL` set.
4. Check if dev servers are running (use `lsof -i :3000 -t`, `:3002`, etc.).
5. Check `git remote -v` for remote configuration.

### Step 2: Pre-tour checklist

If env is not configured or servers are not running, present a checklist
before starting the interactive tour:

```
## Before We Start

Your project needs a few things for the full tour:

| Requirement       | Status         |
|-------------------|----------------|
| .env.local        | Configured / Missing |
| Database synced   | Unknown (run bun db:push) |
| Dev servers       | Running / Stopped |

Options:
1. Set up now -- walk me through env + db + start servers
2. Structure tour only -- skip interactive steps, show me the codebase
3. Cancel
```

If option 1:
- If `.env.local` is missing, suggest: "Run /env to configure environment"
- Then suggest: `bun db:push && bun db:seed`
- Then suggest: `bun dev` (user should run this in a separate terminal)
- Wait for user to confirm servers are running before continuing

If option 2:
- Skip Steps 4-7 (interactive app walkthroughs)
- Still show Steps 3, 8, 9 (structure, git, next steps)

### Step 3: Monorepo structure overview

Scan the actual directories and show only what exists:

```
## Project Structure

Your x4-mono project is organized as a Turborepo monorepo:

<project>/
  apps/
    web/              -- Next.js 15 main app (http://localhost:3000)
    api/              -- Hono + tRPC API server (http://localhost:3002)
    marketing/        -- Marketing site (http://localhost:3001)
    mobile-<name>/    -- Expo 52 React Native app
  packages/
    shared/           -- Shared UI components, types, hooks, utilities
    database/         -- Drizzle ORM schema, migrations, seed scripts
    auth/             -- Better Auth config (server + client + native)
    ai-integrations/  -- Vercel AI SDK + Claude wrappers

Key files:
  turbo.json        -- Monorepo task definitions (build, dev, lint, test)
  .env.local        -- Environment variables (never committed)
  .env.example      -- Template showing required variables

Where to make changes:
  Add a page       -> apps/web/app/<route>/page.tsx
  Add an API route -> apps/api/src/routes/<name>.ts
  Add a tRPC proc  -> apps/api/src/trpc/routers/<name>.ts
  Add a DB table   -> packages/database/src/schema/<name>.ts
  Add a component  -> packages/shared/src/components/<name>.tsx

Ready to explore the apps? (yes / skip to git setup)
```

Only include directories that actually exist (check with Glob). Omit
`marketing/`, `mobile*/`, `ai-integrations/` etc. if not present.

### Step 4: Web app walkthrough

Only show if `apps/web/` exists AND dev servers are running.

```
## Web App

Open http://localhost:3000 in your browser.

What you should see:
- The x4 default landing page
- Navigation with Sign Up / Sign In links
- The app uses Next.js 15 with React 19 and Tailwind 4

Try this:
1. Click "Sign Up" and create an account
2. Fill in an email and password (this uses Better Auth)
3. After signup, you should be redirected to the dashboard
4. The dashboard loads data via tRPC calls to the API server

The web app source is in apps/web/app/ (uses Next.js App Router).

Done exploring? (yes / skip)
```

### Step 5: AI chat walkthrough

Only show if `packages/ai-integrations/` exists AND servers are running.

```
## AI Features

Your project includes AI integrations via the Vercel AI SDK.

To test:
1. Make sure your ANTHROPIC_API_KEY is set in .env.local
2. Look for a chat or AI page in the web app (usually /chat or /ai)
3. Send a test message -- you should get a response from Claude

The AI integration code is in packages/ai-integrations/.
API routes that use AI are in apps/api/src/routes/ (look for ai-related files).

If you don't see a chat page, the template may expose AI as an API-only
feature. Check: curl -X POST http://localhost:3002/api/ai/chat

Tried it? (yes / skip / my API key isn't set up)
```

If the user says their key isn't set up, suggest: "Run /env to add your
Anthropic API key."

### Step 6: API server exploration

Only show if `apps/api/` exists AND servers are running.

```
## API Server

Your API runs at http://localhost:3002 (Hono + tRPC 11).

Try these:
- Health check:  curl http://localhost:3002/health
- Auth endpoint: curl http://localhost:3002/api/auth/session (returns current session info)

Key directories:
  apps/api/src/
    routes/       -- Hono route handlers
    trpc/         -- tRPC router definitions
    middleware/   -- Auth, CORS, logging middleware

The API uses:
- Hono for HTTP routing
- tRPC 11 for type-safe client-server communication
- Drizzle ORM for database queries
- Better Auth for authentication

The web app calls the API via tRPC -- types are shared automatically
across apps/web and apps/api through the monorepo workspace.

Explored the API? (yes / skip)
```

### Step 7: Marketing site

Only show if `apps/marketing/` exists AND port 3001 is running.

```
## Marketing Site

Open http://localhost:3001 in your browser.

This is a separate Next.js app optimized for marketing pages. It includes
Three.js for 3D graphics and animations.

It shares components from packages/shared/ but has its own routing
and layout system.

The source is in apps/marketing/app/.

Checked it out? (yes / skip)
```

### Step 8: Git remote setup

Check `git remote -v`. If a remote IS configured, show it and move on.
If NO remote is configured:

```
## Git Remote

Your project has a local git repo (initialized by create-x4) but no
remote is configured yet.

Set up a GitHub remote?

1. Create new repo -- I'll use `gh` CLI to create a GitHub repo and push
2. Paste URL -- I have an existing repo URL
3. Skip -- I'll set this up later
```

**Option 1:** Requires `gh` CLI (check with `which gh`).
```bash
gh repo create <project-name> --private --source . --push
```
If `gh` is not installed, tell the user to install it or use option 2.

**Option 2:** Ask for the URL, then:
```bash
git remote add origin <url>
git push -u origin main
```

**Option 3:** Skip, but remind them:
```
No worries. When you're ready:
  git remote add origin <your-repo-url>
  git push -u origin main
```

### Step 9: Next steps and companion plugins

```
## Tour Complete!

Here's what you can do next:

### Build Features
- /idea "your feature idea"     -- Capture an idea to the backlog
- /plan-backlog                  -- Plan a feature into a full PRD
- /work                          -- Build with agent teams

### Manage Your Project
- /status                        -- Quick project health dashboard
- /add                           -- Add mobile, desktop, or marketing apps
- /env                           -- Reconfigure environment variables
- /llmstxt-update                -- Download AI-readable reference docs

### Companion Plugins
For the best experience, install companion plugins:
  /onboard   (Step 4 walks through plugin installation)

Key plugins:
- superpowers          -- brainstorming + writing plans (/plan-backlog)
- code-simplifier      -- code quality checks (/work)
- frontend-design      -- UI design patterns (frontend agent)
- playwright           -- e2e test authoring (tester agent)

### Typical Workflow
1. /idea "Add user dashboard"
2. /plan-backlog
3. /work
4. Ship!

Happy building!
```

## Rules

- Pace the tour with `AskUserQuestion` at every step. Do not dump all
  information at once.
- Every step MUST have a skip option. Respect the user's pace.
- Only show steps for platforms that actually exist in the project.
- If servers are not running, skip interactive steps (4-7) gracefully
  and focus on the structural tour (step 3) and git setup (step 8).
- Do NOT modify any files during the tour. This is read-only guidance.
- If the user asks a question mid-tour, answer it, then resume where
  you left off.
- Keep each step concise. The user can always ask for more detail.
