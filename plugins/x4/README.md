# x4

Complete AI-powered development workflow plugin for Claude Code.

One plugin. One install. **Idea to shipped PR — with agent teams doing the work.**

## Install

```bash
/plugin marketplace add studiox4/x4-agent-plugins
/plugin install x4@x4-agent-plugins
/x4:onboard
```

---

## A Day in the Life

Here's what using x4 actually looks like for a developer building a real app.

### Day 1 — From zero to a working app

```
/x4:onboard
```
Checks for Bun, Node, Git, the GitHub CLI, Railway, Neon, Vercel, and your Anthropic API key. Walks through anything missing. Installs companion plugins. Takes a few minutes once.

```
/x4:create my-fitness-app
```
Picks a preset (`saas`, `full-stack`, `landing`, or `api-only`). Scaffolds a Turborepo monorepo with Next.js, Hono/tRPC, Drizzle, Neon, Better Auth, and Vercel AI SDK. Sets up your `.env`, runs the initial migration, and opens dev servers.

```
/x4:deploy-setup
```
Detects your apps, generates `railway.toml`, syncs env vars to Railway, and walks through GitHub connection and PR preview setup. After this, every PR gets a live preview URL automatically.

```
/x4:tour
```
Guided walkthrough — opens the app in your browser, tests login, tries the AI chat, sets up the GitHub remote.

### Day 1 (continued) — Planning everything you want to build

```
/x4:kickstart
```
One command kicks off a full planning session:
1. **Vision** — "I'm building a fitness tracker with AI coaching for busy professionals"
2. **Brainstorm** — Claude generates a categorized feature list, you refine interactively
3. **Prioritize** — features sequenced by dependency and value
4. **UI Design** — page layouts and component specs for each user-facing feature
5. **Batch PRDs** — a full Product Requirements Document generated for every feature
6. **Summary** — "You have 8 PRDs ready. Run `/work` to start building."

### Day 2 — Agent teams build your features

```
/x4:work
```
Picks up the next PRD, dispatches three agents in parallel — backend, frontend, tester — and two reviewers after:

```
Phase 1: Orient    — pick a PRD, analyze dependencies
Phase 2: Setup     — create feature branch, DB branch, draft PR
Phase 3: Build     — backend + frontend + tester work in parallel
Phase 4: Review    — reviewer + performance agents audit the code
Phase 5: Ship      — push, CI passes, PR preview live
Phase 6: Memory    — changelog entry written, lessons logged
Phase 7: Cleanup   — PRD moved to complete, branch cleaned up
```

**Auto-loop mode:** If you have multiple PRDs ready, `/work` asks:
```
You have 8 PRDs ready.
  1. Build the next one
  2. Build all of them — auto-loop through each
  3. Build independent PRDs in parallel (experimental)
```

Pick option 2, walk away, come back to 8 merged features and a real app.

### Week 2 — Discovering what to build next

```
/x4:gaps
```
Scans completed features and surfaces what's missing: "You have workout logging but no export or progress visualization. Users can log in but can't reset their password."

```
/x4:dream
```
Explores bigger ideas across three angles:
- **What if** — bold moves: "What if users could share workout plans publicly?"
- **What's next** — natural evolutions: "Workout streaks and achievement badges"
- **What's emerging** — untapped stack capabilities: "Neon branching + AI could power personalized plan generation per user"

Select the ideas you like → they go straight to the backlog.

```
/x4:plan-backlog
```
Triage the backlog, pick an item, brainstorm it, write a PRD. Then `/work` again.

### Ongoing — Brand updates

Your brand evolves. Open `brand/BRAND.md` in any editor and change what you need:
- Update the voice description as your tone matures
- Swap logo paths when you rebrand
- Add your Twitter handle or LinkedIn URL when ready
- Set your Resend audience ID after you create one

All marketing skills pick up the changes automatically next time they run.

### Ongoing — Announcing what shipped

After each batch of merged features, run the announce workflow:

```
/x4:market-update   → update the marketing site with new features (generates copy, optional screenshots)
/x4:market-email    → write a release email → review it → send to your list via Resend
/x4:market-linkedin → generate a LinkedIn post → copy → paste into LinkedIn
/x4:market-tweet    → generate an X/Twitter thread → copy → paste (or --post)
```

All four read from `docs/CHANGELOG.md` — the same file that `/work` writes to automatically after every feature ships. Each tracks its own sync date so you can run them independently.

### Ongoing — Keeping everything healthy

```
/x4:doctor          → health check: tools, config, agents, env, database, version, docs
/x4:upgrade         → apply migrations after updating the plugin (prompted by session-start)
/x4:opensrc-update  → refresh source code references after adding new libraries
/x4:market-update   → sync the marketing site with shipped features
/x4:status          → running apps, ports, git state at a glance
```

When you update the x4 plugin, the next session-start will show:
```
→ x4 updated to v3.10.0 (project on v3.9.0) — run /x4:upgrade
```
Run `/x4:upgrade` and it applies only what's missing — idempotent, safe to re-run.

---

## Brand Guide

Your project's brand identity lives in `brand/BRAND.md` — a plain markdown file at the project root that you can open and edit anytime. All marketing commands read from it automatically.

```
brand/
  BRAND.md          ← voice, tone, colors, tagline, social handles, email config
  assets/
    logo.svg        ← primary logo (light backgrounds)
    logo-dark.svg   ← dark backgrounds
    logo-icon.svg   ← favicon, avatar, app icon
    og-image.png    ← Open Graph image (1200×630)
    banner.png      ← Twitter/LinkedIn header
```

`/init-setup` creates `brand/BRAND.md` and walks you through the initial setup. After that, just edit the file directly — no commands needed to update your brand voice, swap a logo, or change your social handles.

---

## The Pipeline

```
Onboard → Create → Deploy Setup → Tour → Kickstart → Work → Ship
                                            ↑                   ↓
                                      gaps + dream → idea → plan-backlog
```

Every stage feeds the next. Enter anywhere — scaffolding is optional if you already have a project. Planning is optional if you already have PRDs.

---

## Commands

### Getting Started

| Command | What it does |
|---------|-------------|
| `/x4:onboard` | Check tools, accounts, CLIs — set up your dev environment |
| `/x4:create [name]` | Scaffold a new project (saas, full-stack, landing, api-only) |
| `/x4:deploy-setup` | Configure Railway services and PR preview deployments |
| `/x4:tour` | Guided walkthrough — test login, try AI chat, set up git |
| `/x4:add` | Add a mobile or web app to an existing project |
| `/x4:env` | Set up environment variables (database, auth, AI keys) |
| `/x4:status` | Quick project health dashboard |

### Planning

| Command | What it does |
|---------|-------------|
| `/x4:kickstart` | Brainstorm features, design UI, prioritize, batch-generate PRDs |
| `/x4:idea <idea>` | Capture a feature idea to the backlog |
| `/x4:plan-backlog` | Triage backlog → brainstorm → write PRD |
| `/x4:init-tracker` | Scaffold STATUS.md, BACKLOG.md, planning folders |

### Discovery

| Command | What it does |
|---------|-------------|
| `/x4:gaps` | Find product gaps — dead ends, missing connections, incomplete flows |
| `/x4:dream` | Explore big ideas — bold features, natural evolutions, untapped stack |

### Building

| Command | What it does |
|---------|-------------|
| `/x4:work` | 7-phase build pipeline with auto-loop — Orient → Build → Review → Ship |
| `/x4:run-tests` | Run configured test commands (unit, e2e, lint, typecheck) |
| `/x4:verify-local` | Run all checks with auto-fix — mandatory ship gate |
| `/x4:pr-create` | Create branch + DB branch + draft PR |
| `/x4:pr-status` | Check CI, preview URLs, review state |
| `/x4:pr-cleanup` | Post-merge cleanup |

### Setup (run once)

| Command | What it does |
|---------|-------------|
| `/x4:init-setup` | Configure database, hosting, CI, tests, marketing |
| `/x4:init-agents` | Generate project-specific agent files from templates |

### Source Code References (opensrc)

| Command | What it does |
|---------|-------------|
| `/x4:opensrc-init` | Fetch source code for key dependencies (run once per machine) |
| `/x4:opensrc-update` | Refresh after adding new libraries or when source is stale |
| `/x4:opensrc-status` | Read-only status — coverage, freshness, missing packages |

### Marketing & Announcements

| Command | What it does |
|---------|-------------|
| `/x4:market-update` | Sync marketing site with shipped features — generates copy, optional screenshots, TSX updates |
| `/x4:market-email` | Generate release email from changelog — subject, preview text, full body, Resend snippet |
| `/x4:market-linkedin` | Generate LinkedIn post — hook/body/CTA/hashtags, link in first comment, copies to clipboard |
| `/x4:market-tweet` | Generate X/Twitter thread — 280-char enforced, clipboard default, `--post` for X API |
| `/x4:market-subscribe` | Scaffold email capture form + `/api/subscribe` route into the marketing site |

### Utility

| Command | What it does |
|---------|-------------|
| `/x4:help` | Contextual guide — detects project state, suggests next step |
| `/x4:doctor` | Health diagnostic — tools, config, agents, env, database, version, docs |
| `/x4:upgrade` | Apply migrations after updating the plugin — versioned registry, safe to re-run |
| `/x4:deploy-setup` | One-time Railway wizard — generate railway.toml, sync env vars, configure PR previews |

---

## Agent Team

Five specialized agents dispatched during `/x4:work`:

| Agent | Role | Mode |
|-------|------|------|
| **backend** | API routes, database schema, server code | Read/Write |
| **frontend** | Pages, components, styling, client state | Read/Write |
| **tester** | Unit tests, e2e tests | Read/Write |
| **reviewer** | Security, architecture, code quality audits | Read-only |
| **performance** | Bundle size, re-renders, memory, queries | Read-only |

Agents have ownership boundaries — frontend can't touch API code, backend can't touch UI. Reviewer and performance are read-only. When Claude Code agent teams are enabled, they message each other directly (backend notifies when types change, tester reports results to the team).

---

## Companion Plugins

x4 degrades gracefully when companions aren't installed, but the experience is better with them.

| Plugin | Used by | What it adds |
|--------|---------|-------------|
| `superpowers` | `/kickstart`, `/plan-backlog` | Structured brainstorming + plan writing |
| `code-simplifier` | `/work` Phase 4 | Code quality pass after review |
| `frontend-design` | `/kickstart`, frontend agent | UI design patterns, accessibility |
| `playwright` | Tester agent, `/market-update` | e2e tests + marketing screenshots |

Install all companions via `/x4:onboard`.

---

## Hooks

Four hooks fire automatically during Claude Code sessions:

| Hook | Trigger | What it does |
|------|---------|-------------|
| **protected-files** | Before Edit/Write | Blocks edits to lock files and configs |
| **auto-format** | After Edit/Write | Runs the project formatter on changed files |
| **teammate-idle** | Tester goes idle | Runs the test gate |
| **session-start** | New session | Shows key commands, warns if llms.txt docs are stale, prompts to upgrade when plugin version is newer than project version |

---

## License

Apache 2.0
