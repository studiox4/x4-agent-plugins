---
name: x4-create
description: >
  Scaffold a new x4-mono full-stack TypeScript monorepo using the create-x4 CLI.
  Interactive wizard for project name, preset, platforms, scope, and environment setup.
version: 1.0.0
license: MIT
---

# /create — Scaffold a New x4-mono Project

Interactive wizard that guides the user through creating a new full-stack
TypeScript monorepo using the `create-x4` CLI. Handles preset selection,
platform configuration, environment setup, and post-scaffold initialization.

## Prerequisites

Before running, verify:
1. **Bun** is installed (`bun --version`). If not, inform the user:
   `curl -fsSL https://bun.sh/install | bash`
2. **Git** is installed (`git --version`).
3. The target directory does not already exist.

## Process

### Step 1: Project Name

Use `AskUserQuestion`:

```
## New x4-mono Project

What should the project be called?

Enter a name (kebab-case, e.g., my-saas-app):
```

Validate the name:
- Must be lowercase kebab-case (letters, numbers, hyphens)
- Max 214 characters
- Cannot be an npm reserved name (`node_modules`, `favicon.ico`, etc.)

### Step 2: Preset Selection

Use `AskUserQuestion`:

```
## Project Preset

Choose a starting point:

1. full-stack — Web + API + Mobile + Desktop + AI + Marketing + Docs (everything)
2. saas       — Web + API + AI (most common for SaaS products)
3. landing    — Web + API + Marketing (landing pages with backend)
4. api-only   — Hono + tRPC API server only (backend microservice)
5. custom     — Pick platforms individually

What type of project? (1-5):
```

### Step 3: Platform Selection (if custom)

If the user picked "custom" in Step 2, use `AskUserQuestion`:

```
## Select Platforms

Which platforms to include? (comma-separated numbers):

1. Web app       (Next.js 15 + React 19 + Tailwind 4)
2. API server    (Hono + tRPC 11 + Drizzle ORM)
3. Mobile app    (Expo 52 + React Native)
4. Desktop app   (Electron 33)
5. AI integration (Vercel AI SDK + Claude/OpenAI)
6. Marketing site (Next.js + Three.js)
7. Docs site
8. Storybook     (Component library docs)

Example: 1,2,3,5 for web + API + mobile + AI
```

### Step 4: Project Configuration

Use `AskUserQuestion`:

```
## Configuration

- npm scope [@<project-name>]:
- Mobile app name [<project-name>]: (if mobile included)
- Bundle ID [com.<project-name>]: (if mobile included)
- Package manager [bun]:
```

Show defaults in brackets. Accept Enter to keep defaults.

Validate:
- Scope must start with `@` and be kebab-case
- Bundle ID must be reverse-domain notation (e.g., `com.myapp`)
- Package manager must be one of: bun, npm, yarn, pnpm

### Step 5: Run create-x4

Build and execute the CLI command:

```bash
bunx create-x4 <project-name> \
  --yes \
  --scope <scope> \
  --package-manager <pm> \
  [--bundle-id <bundle-id>] \
  [--no-mobile] \
  [--no-desktop] \
  [--no-marketing] \
  [--no-docs] \
  [--no-ai]
```

The `--yes` flag runs non-interactively using the provided arguments.

Platform exclusion flags are added based on which platforms were NOT selected:
- If mobile not selected: `--no-mobile`
- If desktop not selected: `--no-desktop`
- If marketing not selected: `--no-marketing`
- If docs not selected: `--no-docs`
- If AI not selected: `--no-ai`

Run the command and show output to the user. This will:
1. Download the x4-mono template from GitHub
2. Apply naming transformations (scope, bundle ID, mobile name)
3. Filter out excluded platforms
4. Initialize git with an initial commit
5. Install dependencies

### Step 6: Environment Setup

After scaffolding completes, ask:

```
## Environment Setup

Set up environment variables now?

1. Yes — walk me through database, auth, and AI setup
2. Skip — I'll configure .env.local later

(You can always run /env later to set this up)
```

If yes, delegate to the `/env` skill in the new project directory.

If skip, inform the user:
```
Skipped env setup. Before running the project:
1. cd <project-name>
2. Run /env to set up your database and auth
3. bun db:push (sync schema)
4. bun db:seed (seed data)
5. bun dev (start all servers)
```

### Step 7: Post-scaffold Setup (optional)

If the user set up the environment, offer to run initial setup:

```
## Initialize Project?

Run database setup and start dev servers?

1. Yes — run db:push, db:seed, and bun dev
2. Just db:push and db:seed (don't start servers)
3. Skip — I'll do it manually
```

If yes or option 2:
```bash
cd <project-name>
bun db:push
bun db:seed
```

If option 1, also run:
```bash
bun dev
```

### Step 8: Plugin Setup (optional)

Since project tracking and agent team ops are included in this plugin, offer:

```
## Workflow Setup

Set up project tracking and agent team ops for this project?

1. Yes — run /init-tracker and /init-setup
2. Skip — I'll set these up later
```

### Step 9: Report

```
## Project Created!

- **Name:** <project-name>
- **Location:** ./<project-name>
- **Preset:** <preset>
- **Platforms:** <list>
- **Scope:** <scope>
- **Package Manager:** <pm>

### Local URLs (when running `bun dev`):
- Web:       http://localhost:3000
- API:       http://localhost:3002
- Marketing: http://localhost:3001 [if included]

### Tech Stack:
- Frontend: Next.js 15 + React 19 + Tailwind 4
- Backend: Hono + tRPC 11 + Drizzle ORM
- Database: Neon PostgreSQL
- Auth: Better Auth
- AI: Vercel AI SDK + Claude [if included]
- Mobile: Expo 52 + React Native [if included]
- Desktop: Electron 33 [if included]

### Next Steps:
- cd <project-name>
- bun dev (start all servers)
- Run /tour for a guided walkthrough of your project
- Run /status to check project health at any time
- Run /add to add more apps later

### Companion Plugins (recommended):
Install these for the best x4 experience:
- superpowers      -- brainstorming + writing plans (/plan-backlog)
- code-simplifier  -- code quality checks (/work review phase)
Run /onboard to install all companion plugins.
```

## Rules

- Always validate project name before running the CLI
- Never run create-x4 if the target directory already exists
- Use `--yes` flag to avoid double-prompting (the skill handles all interaction)
- If `bunx create-x4` fails, show the full error and suggest:
  - Check internet connection (template downloads from GitHub)
  - Try `GIGET_AUTH=<github-token> bunx create-x4 ...` if rate-limited
  - Check Bun version (`bun --version`, needs >= 1.1)
- Default to the `saas` preset if the user seems unsure
- The CLI creates its own git repo — do NOT run `git init` separately
