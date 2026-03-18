# x4-scaffold

A Claude Code plugin to scaffold and manage [x4-mono](https://github.com/corbanb/x4-mono) full-stack TypeScript monorepo projects.

## Commands

### `/x4-onboard`

First-time setup wizard for new developers. Checks your local environment and walks through everything you need:

- **Required tools:** Bun, Node.js, Git, GitHub CLI
- **Accounts:** Neon (database), Railway (hosting), Vercel (deploys), Anthropic (AI)
- **CLI authentication:** gh, neonctl, railway, vercel
- **Claude Code plugins:** installs any missing x4 plugins
- **Optional tools:** Python 3, Expo CLI, Playwright

Safe to re-run anytime to check your environment status.

### `/x4-create [project-name]`

Interactive wizard to scaffold a new x4-mono project. Guides you through:

- **Preset selection:** full-stack, saas, landing, api-only, or custom
- **Platform configuration:** web, API, mobile, desktop, AI, marketing, docs
- **Project settings:** npm scope, mobile app name, bundle ID, package manager
- **Environment setup:** database (Neon), auth secrets, AI API keys
- **Post-scaffold init:** db:push, db:seed, and optional dev server start

Uses `bunx create-x4` under the hood.

### `/x4-add`

Add a new mobile app (Expo 52) or web app (Next.js 15) to an existing x4-mono project. Must be run from the project root.

### `/x4-env`

Set up or update `.env.local` for an x4-mono project:

- **Database:** Auto-create Neon project (via MCP or CLI) or paste connection string
- **Auth:** Auto-generate JWT/Better Auth secrets or paste your own
- **AI:** Configure Anthropic and/or OpenAI API keys

## Tech Stack Created

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 15 + React 19 + Tailwind 4 |
| Backend | Hono + tRPC 11 + Drizzle ORM |
| Database | Neon PostgreSQL |
| Auth | Better Auth |
| AI | Vercel AI SDK + Claude |
| Mobile | Expo 52 + React Native |
| Desktop | Electron 33 |
| Build | Turborepo + Bun |

## Presets

| Preset | Platforms |
|--------|-----------|
| **full-stack** | Web + API + Mobile + Desktop + AI + Marketing + Docs |
| **saas** | Web + API + AI |
| **landing** | Web + API + Marketing |
| **api-only** | Hono + tRPC API server only |

## Prerequisites

Run `/x4-onboard` to check and install everything automatically, or set up manually:

- **Bun** >= 1.1 (`curl -fsSL https://bun.sh/install | bash`)
- **Node.js** >= 18 (via [nvm](https://github.com/nvm-sh/nvm) or [nodejs.org](https://nodejs.org))
- **Git** installed
- **GitHub CLI** (`brew install gh`, then `gh auth login`)
- **Neon account** (free tier at [console.neon.tech](https://console.neon.tech/signup))

## Installation

```bash
claude plugin install studiox4/x4-agent-plugins/x4-scaffold
```

## License

Apache 2.0
