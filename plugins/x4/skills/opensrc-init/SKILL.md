---
name: opensrc-init
description: Use when setting up opensrc source code fetching for the first time — detects key npm dependencies, runs npx opensrc to clone their source locally, and wires up AGENTS.md so agents can read actual implementations. Trigger for "set up opensrc", "fetch source code for dependencies", "I want agents to read library source", or when /opensrc-update reports no sources found. Run once per project.
version: 1.0.0
license: MIT
---

# /opensrc-init — Set Up opensrc Source Code Fetching

One-time setup that fetches source code for key project dependencies using
[opensrc](https://github.com/vercel-labs/opensrc) (`npx opensrc`). Gives AI
agents access to actual implementations — not just docs — for deeper context.

opensrc stores source in `opensrc/` at the project root. It auto-adds this
directory to `.gitignore` and generates `AGENTS.md` with usage instructions.

## Process

### Step 1: Check prerequisites

1. Verify Node 18+ is available: `node --version`
2. Verify npm/npx is available: `npx --version`
3. Check if `opensrc/` already exists and has a `sources.json`:
   - If yes, ask the user: "opensrc is already initialized. Re-run to add more packages, or run `/opensrc-update` to refresh existing ones."
4. Confirm opensrc CLI works: `npx opensrc --version`
   - If this fails, Node 18+ required — report the error and stop.

### Step 2: Detect key dependencies

Read `package.json` (and monorepo workspace `package.json` files if present).
Collect **runtime dependencies only** (`dependencies`, not `devDependencies`).

Filter down to packages worth fetching source for — prioritize:
- **Frameworks**: Next.js, Hono, Express, Fastify, Expo
- **ORMs/DB clients**: Drizzle, Prisma, Neon, Supabase
- **Auth**: Better Auth, NextAuth, Lucia
- **API layers**: tRPC, GraphQL
- **AI/ML**: Vercel AI SDK, OpenAI, Anthropic SDK
- **State/Data**: React Query, Zustand, Jotai
- **Validation**: Zod, Valibot, Yup

Skip: `@types/*`, `eslint*`, `prettier`, `postcss`, `autoprefixer`, `typescript`,
`tailwindcss`, build tools, and packages that are thin type wrappers.

Also accept GitHub repos: detect from common config files:
- `vercel.json` → `vercel/vercel`
- `railway.toml` → `railwayapp/railway-cli`

### Step 3: Confirm package selection

Present the detected packages:

```
## opensrc — Source Code Fetching

These packages were detected as candidates. Select which to fetch source for:

Framework:
  [x] next (Next.js)
  [x] hono

Database / Auth:
  [x] drizzle-orm
  [x] @neondatabase/serverless
  [x] better-auth

API:
  [x] @trpc/server
  [x] @trpc/client

AI:
  [x] ai (Vercel AI SDK)
  [x] @anthropic-ai/sdk

Validation:
  [x] zod

All selected? (yes / edit list / cancel)
```

Let the user deselect packages they don't need source for. Fetching full
source can take time and disk space for large packages — the user should
choose packages where implementation detail matters most for agents.

### Step 4: Fetch source

Run opensrc for the confirmed packages:

```bash
npx opensrc <package1> <package2> ...
```

Run all packages in one command. opensrc will:
- Resolve versions from `node_modules` or lockfiles automatically
- Clone the source at the exact installed version
- Store under `opensrc/<package-name>/`
- Auto-update `.gitignore` to exclude `opensrc/`
- Generate/update `opensrc/AGENTS.md`

Show progress as packages are fetched. If individual packages fail
(no public repo, private registry), note them in the report but continue.

### Step 5: Update CLAUDE.md

If `CLAUDE.md` exists, add or update a "Source Code References" section:

```markdown
## Source Code References

Fetched library source is in `opensrc/`. Agents can read actual implementations
for deep context beyond documentation.

| Package | Path | Use when... |
|---------|------|-------------|
| next | opensrc/next/ | Understanding Next.js internals, middleware, routing |
| drizzle-orm | opensrc/drizzle-orm/ | ORM internals, query building, schema patterns |
| zod | opensrc/zod/ | Validation internals, type inference |
```

Populate the table with the packages that were successfully fetched. Generate
"Use when..." hints based on the package category.

If a "Reference Docs" section already exists (from old llmstxt setup), replace
it with "Source Code References" pointing to `opensrc/`.

### Step 6: Commit

```bash
git add CLAUDE.md
git commit -m "feat: add opensrc source code context for AI agents"
```

(opensrc/ is gitignored — only CLAUDE.md is committed)

### Step 7: Report

```
## opensrc-init Complete

Fetched source for N packages:
  ✓ next          → opensrc/next/
  ✓ drizzle-orm   → opensrc/drizzle-orm/
  ✓ zod           → opensrc/zod/
  ✗ some-package  — no public repository found

opensrc/ is gitignored. Each developer runs /opensrc-init once.
AGENTS.md updated with usage instructions for agents.
CLAUDE.md updated with source reference table.

Run /opensrc-update anytime to refresh after adding new dependencies.
Run /opensrc-status to check coverage.
```

## Rules

- Never overwrite existing source without asking
- Never fetch private packages (they'll fail gracefully — just report)
- Prioritize runtime dependencies over dev tools
- opensrc/ is always gitignored — never commit source to the repo
- Each developer on the team runs this once on their machine
