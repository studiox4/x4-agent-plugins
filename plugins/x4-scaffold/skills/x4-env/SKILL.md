---
name: x4-env
description: Set up or update environment variables for an x4-mono project — database, auth secrets, AI keys
version: 1.0.0
license: MIT
---

# /x4-env — Environment Variable Setup

Interactive wizard to configure `.env.local` for an x4-mono project.
Handles database connection, authentication secrets, and AI API keys.

## Prerequisites

Must be run from inside an x4-mono project root (has `turbo.json` and
`.env.example`).

## Process

### Step 1: Check existing state

1. Read `.env.example` to know all required variables.
2. Check if `.env.local` already exists.
3. If it exists, read current values (mask secrets in display).
4. Determine which platforms are installed (check `apps/` directory)
   to know which env vars are needed.

Report:
```
## Environment Status

Project: <project-name>
Platforms: web, api, mobile, ai

Existing .env.local: Yes / No
Missing variables: DATABASE_URL, ANTHROPIC_API_KEY
```

### Step 2: Database Setup

Use `AskUserQuestion`:

```
## Database (Neon PostgreSQL)

How would you like to set up the database?

1. Auto-create — Create a new Neon project (requires Neon MCP or CLI)
2. Paste URL  — I have a PostgreSQL connection string
3. Skip       — I'll configure this later

[Current: <masked URL or "not set">]
```

**If auto-create (option 1):**

Check if Neon MCP tools are available:
- If yes: Call `mcp__Neon__create_project` with the project name.
  Then call `mcp__Neon__get_connection_string` to get the URL.
- If no: Try `neonctl projects create --name <project-name>` via Bash.
- If neither available: Fall back to option 2 (paste URL).

Set `DATABASE_URL` from the result.

**If paste URL (option 2):**

Use `AskUserQuestion`:
```
Paste your PostgreSQL connection string:
(format: postgresql://user:password@host/dbname?sslmode=require)
```

Validate the URL starts with `postgresql://` or `postgres://`.

**If skip:** Leave `DATABASE_URL` unset. Warn that `bun db:push` will fail
until configured.

### Step 3: Authentication Secrets

Use `AskUserQuestion`:

```
## Authentication

JWT_SECRET and BETTER_AUTH_SECRET need to be set (min 32 characters).

1. Auto-generate — Create a secure random secret
2. Paste         — I have my own secret
3. Skip          — I'll configure this later

[Current: <"set" or "not set">]
```

**If auto-generate:**
Generate a 64-character hex string:
```bash
openssl rand -hex 32
```
Set both `JWT_SECRET` and `BETTER_AUTH_SECRET` to this value.

**If paste:**
Ask for the secret, validate it's at least 32 characters.
Set both `JWT_SECRET` and `BETTER_AUTH_SECRET`.

### Step 4: AI Configuration (if AI platform included)

Only show this step if `packages/ai-integrations/` exists or the AI platform
was included.

Use `AskUserQuestion`:

```
## AI Integration

Set up Anthropic (Claude) API key?

1. Paste key  — I have an ANTHROPIC_API_KEY
2. Skip       — I'll add this later (AI features will be disabled)

[Current: <"set" or "not set">]
```

If the user provides a key, validate it starts with `sk-ant-`.

Optionally ask for `OPENAI_API_KEY` as well:
```
Also set up OpenAI API key? (optional, press Enter to skip):
```

### Step 5: App URLs

Set the standard local development URLs:

```
BETTER_AUTH_URL=http://localhost:3002
WEB_URL=http://localhost:3000
MARKETING_URL=http://localhost:3001
DOCS_URL=http://localhost:3003
NODE_ENV=development
PORT=3002
```

These are set automatically (no user input needed) unless the user has
customized ports.

### Step 6: Write .env.local

Build the `.env.local` file with all configured values:

```bash
# Database
DATABASE_URL=<value>

# Authentication
JWT_SECRET=<value>
BETTER_AUTH_SECRET=<value>
BETTER_AUTH_URL=http://localhost:3002

# AI (optional)
ANTHROPIC_API_KEY=<value>

# App URLs
WEB_URL=http://localhost:3000
MARKETING_URL=http://localhost:3001
DOCS_URL=http://localhost:3003
NODE_ENV=development
PORT=3002
```

If `.env.local` already exists:
- Merge new values with existing ones
- Don't overwrite values the user didn't change
- Ask before overwriting any existing value

### Step 7: Report

```
## Environment Configured

- Database: <configured | skipped>
- Auth secrets: <generated | provided | skipped>
- AI keys: <configured | skipped> [if applicable]
- File: .env.local

### Next Steps:
- bun db:push (sync schema to database)
- bun db:seed (populate test data)
- bun dev (start all servers)
```

## Rules

- Never display full secrets or connection strings — mask them
- Never commit `.env.local` to git (verify it's in `.gitignore`)
- If `.env.local` exists, merge don't overwrite
- Validate all inputs (URL format, secret length, API key format)
- If Neon MCP is available, prefer it over CLI for database creation
- `JWT_SECRET` and `BETTER_AUTH_SECRET` should always have the same value
- Only ask about AI keys if the AI platform is included in the project
