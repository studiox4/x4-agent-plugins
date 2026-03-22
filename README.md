# x4-agent-plugins

A Claude Code plugin marketplace for the complete AI-powered development workflow: project scaffolding, backlog management, agent team coordination, and reference documentation.

![x4 Workflow Diagram](public/images/x4-workflow-diagram.png)

## How It Works

The `x4` plugin provides a complete pipeline from idea to shipped PR:

| Stage | Command | What happens |
|-------|---------|--------------|
| **Onboard** | `/x4:onboard` | Check tools, accounts, CLI access — get your machine ready |
| **Scaffold** | `/x4:create my-app` | Create a full-stack TypeScript monorepo (Next.js, Hono, Expo, etc.) |
| **Capture** | `/x4:idea <idea>` | Drop a feature idea into a structured backlog |
| **Plan** | `/x4:plan-backlog` | Brainstorm, create implementation plan, write PRD |
| **Build** | `/x4:work` | Dispatch an agent team, build, review, verify, ship |

## Getting Started

### 1. Install Claude Code

If you don't have Claude Code yet, install it from [claude.ai/download](https://claude.ai/download) or via:

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. Add the marketplace and install the plugin

```bash
# Add the x4 plugin marketplace
/plugin marketplace add studiox4/x4-agent-plugins

# Install the x4 plugin
/plugin install x4@x4-agent-plugins
```

### 3. Run the onboarding wizard

```bash
/x4:onboard
```

This checks your machine for everything you need and walks you through setup:

| Requirement | Why | Free tier? |
|-------------|-----|------------|
| **Bun** >= 1.1 | Package manager + runtime | Open source |
| **Node.js** >= 18 | Required by some tooling | Open source |
| **Git** | Version control | Open source |
| **GitHub CLI** (`gh`) | PR management, CI watching | Free |
| **Neon** account | Serverless PostgreSQL with branch-per-PR | Yes (0.5 GB, 190 compute hrs/mo) |
| **Railway** account | Hosting + preview environments | Yes ($5/mo credit) |
| **Vercel** account | Next.js frontend deploys | Yes (personal projects) |
| **Anthropic API key** | AI features in your app | Pay-as-you-go |

The onboarding wizard detects what's already installed and only walks through what's missing.

### 4. Create your first project

```bash
/x4:create my-app
```

Choose a preset:
- **saas** — Web + API + AI (most common)
- **full-stack** — Everything: web, API, mobile, desktop, AI, marketing, docs
- **landing** — Web + API + marketing site
- **api-only** — Hono + tRPC backend microservice

The wizard handles environment setup (database, auth secrets, AI keys), then you're ready:

```bash
cd my-app
bun dev        # Web on :3000, API on :3002, Marketing on :3001
```

### 5. Start building features

```bash
/x4:idea "Add user dashboard with analytics"     # Capture the idea
/x4:plan-backlog                                   # Brainstorm → plan → write PRD
/x4:work                                           # Agent team builds, reviews, ships
```

---

## Commands

All commands live under the `/x4:` namespace.

### Scaffolding

Scaffold and manage [x4-mono](https://github.com/corbanb/x4-mono) full-stack TypeScript monorepo projects.

| Command | Description |
|---------|-------------|
| `/x4:onboard` | Check tools, accounts, CLIs — set up your dev environment |
| `/x4:create [name]` | Scaffold a new project (presets: full-stack, saas, landing, api-only) |
| `/x4:add` | Add a mobile or web app to an existing project |
| `/x4:env` | Set up environment variables (database, auth, AI keys) |

**Tech stack created:** Next.js 15 + React 19 + Tailwind 4 / Hono + tRPC 11 + Drizzle ORM / Neon PostgreSQL / Better Auth / Vercel AI SDK + Claude / Expo 52 / Electron 33 / Turborepo + Bun

### Project Tracking

Backlog capture, triage, PRD generation, and project status tracking.

| Command | Description |
|---------|-------------|
| `/x4:idea <idea>` | Capture a feature idea to the backlog |
| `/x4:plan-backlog` | Triage backlog → brainstorm → plan → write PRD |
| `/x4:init-tracker` | Scaffold STATUS.md, BACKLOG.md, `planning/{todo,in-progress,complete}/` |

### Agent Team Ops

Agent team coordination, feature dispatching, review cycles, and hook-based guardrails.

| Command | Description |
|---------|-------------|
| `/x4:work` | 7-phase pipeline: Orient → Setup → Build → Review+Verify → Ship → Memory Sweep → Cleanup |
| `/x4:run-tests` | Run configured test commands (unit, e2e, lint, typecheck) |
| `/x4:init-setup` | Interactive wizard to configure database, hosting, CI, tests |
| `/x4:init-agents` | Generate project-specific agent files from templates |
| `/x4:verify-local` | Run all checks with auto-fix (max 3 attempts) — mandatory ship gate |
| `/x4:pr-create` | Create branch + DB branch + draft PR + preview setup |
| `/x4:pr-status` | Check CI, preview URLs, and review state |
| `/x4:pr-cleanup` | Post-merge cleanup: delete DB branch + local branch |

**Agent Templates:**

| Agent | Role |
|-------|------|
| backend | Server-side code, database schema, API routes |
| frontend | UI code, components, pages, styling |
| reviewer | Read-only code review (security, architecture, quality) |
| tester | Unit tests and e2e tests |
| performance | Read-only performance audit (bundle, re-renders, memory, queries, cache) |

### LLMs.txt Management

Scan project dependencies, discover llms.txt documentation endpoints, download and manage AI-readable reference docs.

| Command | Description |
|---------|-------------|
| `/x4:llmstxt-init` | Scaffold download script, known-sources cache, docs directory, config |
| `/x4:llmstxt-update` | Full scan, discover, download, and sync (uses script if present) |
| `/x4:llmstxt-status` | Read-only status report of current docs |

---

## Configuration

Config files in `.claude/`:

| Feature | Config File | Generated By |
|---------|-------------|--------------|
| Project tracking | `.claude/project-tracker.config.md` | `/x4:init-tracker` |
| Agent team ops | `.claude/agent-team.config.md` | `/x4:init-setup` |
| LLMs.txt | `.llmstxt.json` | `/x4:llmstxt-init` |

All settings have sensible defaults. Configuration is optional to get started.

## External Plugin Dependencies

Some features integrate with official Claude plugins when installed:

| Plugin | Used By | For |
|--------|---------|-----|
| `superpowers@claude-plugins-official` | `/x4:plan-backlog` | Delegates to `/brainstorming` and `/writing-plans` |
| `code-simplifier@claude-plugins-official` | `/x4:work` Phase 4 | Simplifies complex code after review |

These are optional — features degrade gracefully with inline alternatives when plugins aren't installed.

## Auto-suggest the plugin for your team

Add this to your project's `.claude/settings.json` so team members are prompted to install:

```json
{
  "extraKnownMarketplaces": {
    "x4-agent-plugins": {
      "source": {
        "source": "github",
        "repo": "studiox4/x4-agent-plugins"
      }
    }
  },
  "enabledPlugins": {
    "x4@x4-agent-plugins": true
  }
}
```

## Local Development

```bash
# Test the marketplace locally
/plugin marketplace add ./path/to/x4-agent-plugins

# Validate marketplace structure
claude plugin validate .

# Run structural checks
bash tests/validate.sh

# Link the plugin for iterative development
claude plugin link ./plugins/x4
```

## License

Apache 2.0
