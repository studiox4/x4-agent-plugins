# 00 — x4-scaffold Plugin

A Claude Code plugin to scaffold and manage [x4-mono](https://github.com/corbanb/x4-mono) full-stack TypeScript monorepo projects using the `create-x4` CLI.

---

## 1. Overview

The x4-scaffold plugin provides four skills:

| Skill | Purpose |
|-------|---------|
| `/x4-onboard` | Check local dev environment, walk through tool + account setup |
| `/x4-create` | Scaffold a new x4-mono project with interactive preset/platform selection |
| `/x4-add` | Add a mobile or web app to an existing x4-mono project |
| `/x4-env` | Set up or update `.env.local` (database, auth, AI keys) |

---

## 2. Prerequisites

The onboarding wizard (`/x4-onboard`) checks all of these automatically:

### Required Tools

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Bun | >= 1.1 | `curl -fsSL https://bun.sh/install \| bash` |
| Node.js | >= 18 | `nvm install 22` or nodejs.org |
| Git | Any | `brew install git` or `xcode-select --install` |
| GitHub CLI | Any | `brew install gh` then `gh auth login` |

### Accounts (all have free tiers)

| Service | Purpose | Free Tier | Signup |
|---------|---------|-----------|--------|
| Neon | Serverless PostgreSQL | 0.5 GB, 190 compute hrs/mo | console.neon.tech/signup |
| Railway | Hosting + preview envs | $5/mo credit | railway.app |
| Vercel | Next.js deploys | Personal projects | vercel.com/signup |
| Anthropic | AI features in app | Pay-as-you-go | console.anthropic.com |

### Optional CLIs

| CLI | Purpose | Install |
|-----|---------|---------|
| neonctl | DB branch management | `npm install -g neonctl` |
| railway | Deploy management | `npm install -g @railway/cli` |
| vercel | Frontend deploys | `npm install -g vercel` |
| eas-cli | Expo mobile builds | `npm install -g eas-cli` |

---

## 3. `/x4-onboard` — Developer Environment Setup

The onboarding wizard detects what's already installed and only walks through what's missing.

### Flow

1. **Detect current state** — Run all checks in parallel, present a dashboard
2. **Required tools** — Install Bun, Node.js, Git, GitHub CLI (only missing ones)
3. **Accounts** — Neon, Railway, Vercel, Anthropic (signup links + CLI auth)
4. **Plugins** — Check and install missing x4 plugins
5. **Optional tools** — Python 3, Expo CLI, Playwright
6. **Summary** — Environment status + next steps

### Key behaviors

- Idempotent — safe to re-run anytime as a health check
- Never installs without asking first
- All accounts have free tiers — always mentions this
- Detects what's working and skips it

---

## 4. `/x4-create` — Project Scaffolding

### Presets

| Preset | Platforms Included |
|--------|-------------------|
| **full-stack** | Web + API + Mobile + Desktop + AI + Marketing + Docs |
| **saas** | Web + API + AI (most common) |
| **landing** | Web + API + Marketing |
| **api-only** | Hono + tRPC API server only |
| **custom** | Pick platforms individually |

### Platforms

| Platform | Technology | Port |
|----------|-----------|------|
| Web | Next.js 15 + React 19 + Tailwind 4 | :3000 |
| API | Hono + tRPC 11 + Drizzle ORM | :3002 |
| Mobile | Expo 52 + React Native | N/A |
| Desktop | Electron 33 | N/A |
| AI | Vercel AI SDK + Claude | N/A |
| Marketing | Next.js + Three.js | :3001 |
| Docs | Documentation site | :3003 |

### Wizard Flow

1. **Project name** — Validate kebab-case, max 214 chars
2. **Preset selection** — full-stack, saas, landing, api-only, or custom
3. **Platform selection** — If custom, pick platforms individually
4. **Configuration** — npm scope, mobile app name, bundle ID, package manager
5. **Run create-x4** — `bunx create-x4 <name> --yes [flags]`
6. **Environment setup** — Delegate to `/x4-env` or skip
7. **Post-scaffold** — Optional db:push, db:seed, bun dev
8. **Plugin setup** — Optional /init-tracker + /init-setup
9. **Report** — URLs, tech stack, next steps

### CLI Flags

```bash
bunx create-x4 <name> \
  --yes \                    # Non-interactive mode
  --scope @myorg \           # npm scope
  --package-manager bun \    # bun/npm/yarn/pnpm
  --bundle-id com.myapp \    # Mobile bundle ID
  --no-mobile \              # Exclude platforms
  --no-desktop \
  --no-marketing \
  --no-docs \
  --no-ai
```

---

## 5. `/x4-add` — Add Apps to Existing Projects

Must be run from inside an x4-mono project root.

### Supported additions

- **Mobile app** — Expo 52 + React Native
- **Web app** — Next.js 15 + React 19

### Flow

1. Verify project (turbo.json, apps/ dir, workspaces)
2. Detect existing apps
3. Choose what to add (mobile or web)
4. Configure (name, bundle ID, port)
5. Run `bunx create-x4 add`
6. Install dependencies
7. Report

---

## 6. `/x4-env` — Environment Configuration

### Variables configured

| Variable | Source | Required |
|----------|--------|----------|
| `DATABASE_URL` | Neon auto-create or paste | Yes |
| `JWT_SECRET` | Auto-generate (64-char hex) or paste | Yes |
| `BETTER_AUTH_SECRET` | Same as JWT_SECRET | Yes |
| `BETTER_AUTH_URL` | Auto-set (http://localhost:3002) | Yes |
| `ANTHROPIC_API_KEY` | Paste (sk-ant-*) | If AI platform |
| `WEB_URL` | Auto-set (http://localhost:3000) | Yes |
| `MARKETING_URL` | Auto-set (http://localhost:3001) | If marketing |
| `NODE_ENV` | Auto-set (development) | Yes |
| `PORT` | Auto-set (3002) | Yes |

### Database setup options

1. **Auto-create** — Create Neon project via MCP or CLI
2. **Paste URL** — Enter existing PostgreSQL connection string
3. **Skip** — Configure later

### Key behaviors

- Merges with existing `.env.local` (never overwrites without asking)
- Validates all inputs (URL format, secret length, API key prefix)
- Never displays full secrets — masks after validation
- Verifies `.env.local` is in `.gitignore`

---

## 7. Tech Stack Created

```
apps/
├── api/              # Hono + tRPC 11 + Drizzle ORM (:3002)
├── web/              # Next.js 15 + React 19 + Tailwind 4 (:3000)
├── mobile-*/         # Expo 52 + React Native
├── desktop/          # Electron 33
├── marketing/        # Next.js + Three.js (:3001)
├── docs/             # Documentation
└── storybook/        # Component library docs

packages/
├── shared/           # UI components, types, utils, hooks
├── database/         # Drizzle ORM + Neon PostgreSQL
├── auth/             # Better Auth (server/client/native)
└── ai-integrations/  # Vercel AI SDK + Claude/OpenAI
```

### Dependency boundaries (enforced by ESLint)

```
packages/shared (no imports)
  ↑ packages/database
    ↑ packages/auth
      ↑ packages/ai-integrations
        ↑ apps/* (can import any package)
```

Critical rule: Never import from `apps/*` in `packages/*`.
