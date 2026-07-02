# 07 — x4 Plugin: Complete Reference Guide (v3.0.0)

The `x4` plugin is a single Claude Code plugin that provides the complete AI-powered development workflow: project scaffolding, backlog management, agent team coordination, llms.txt reference documentation, and hook-based guardrails.

> **v3.0.0 Breaking Change:** Four separate plugins (`x4-scaffold`, `x4-project-tracker`, `x4-agent-team-ops`, `x4-llmstxt-manager`) have been consolidated into a single `x4` plugin. All commands now live under the `/x4:` namespace.

---

## 1. Installation

```bash
# Add the x4 marketplace
/plugin marketplace add studiox4/x4-agent-plugins

# Install the x4 plugin (one install — everything included)
/plugin install x4@x4-agent-plugins
```

### Auto-suggest for teams

Add to your project's `.claude/settings.json` so teammates are prompted to install:

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

---

## 2. The Pipeline

The plugin provides a complete pipeline from idea to shipped PR:

```
/x4:onboard → /x4:create → /x4:init-tracker → /x4:idea → /x4:plan-backlog → /x4:work → shipped PR
```

| Stage | Command | What happens |
|-------|---------|--------------|
| **Onboard** | `/x4:onboard` | Check tools, accounts, CLI access — get your machine ready |
| **Scaffold** | `/x4:create my-app` | Create a full-stack TypeScript monorepo (Next.js, Hono, Expo, etc.) |
| **Track** | `/x4:init-tracker` | Scaffold STATUS.md, BACKLOG.md, and planning directory |
| **Capture** | `/x4:idea <idea>` | Drop a feature idea into a structured backlog |
| **Plan** | `/x4:plan-backlog` | Brainstorm, create implementation plan, write PRD |
| **Build** | `/x4:work` | Dispatch an agent team, build, review, verify, ship |

Each stage is independently useful. You don't need to use the full pipeline — pick the commands that fit your workflow.

---

## 3. All Commands

### Scaffolding

Scaffold and manage [x4-mono](https://github.com/corbanb/x4-mono) full-stack TypeScript monorepo projects using the `create-x4` CLI.

| Command | Description |
|---------|-------------|
| `/x4:onboard` | Check local dev environment, walk through tool + account setup |
| `/x4:create [name]` | Scaffold a new project (presets: full-stack, saas, landing, api-only) |
| `/x4:add` | Add a mobile or web app to an existing project |
| `/x4:env` | Set up or update `.env.local` (database, auth, AI keys) |

#### Presets

| Preset | Platforms Included |
|--------|-------------------|
| **full-stack** | Web + API + Mobile + Desktop + AI + Marketing + Docs |
| **saas** | Web + API + AI (most common) |
| **landing** | Web + API + Marketing |
| **api-only** | Hono + tRPC API server only |
| **custom** | Pick platforms individually |

#### Tech stack created

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

#### Requirements

The onboarding wizard (`/x4:onboard`) checks all of these automatically:

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

---

### Project Tracking

Backlog capture, triage, PRD generation, and project status tracking for any software project.

| Command | Description |
|---------|-------------|
| `/x4:idea <idea>` | Capture a feature idea to the backlog with project context |
| `/x4:plan-backlog` | Triage backlog → brainstorm → implementation plan → write PRD |
| `/x4:init-tracker` | Scaffold STATUS.md, BACKLOG.md, `planning/{todo,in-progress,complete}/` |

#### How `/x4:idea` works

1. Reads project context (STATUS.md, existing backlog, planning docs)
2. Writes a structured entry with scope estimate, "fits after" ordering, and sections configured in your config
3. Responds with a one-line confirmation — no interruption to your flow

#### How `/x4:plan-backlog` works

1. Parses unplanned backlog items
2. Presents a triage menu — you pick what to plan or delete
3. Runs a brainstorming session (3-5 approaches with trade-offs)
4. Drafts an implementation plan with agent roles
5. Writes a full PRD to `docs/planning/todo/`
6. Updates STATUS.md with the new feature

#### Planning folder lifecycle

```
docs/planning/todo/        → created by /x4:plan-backlog
docs/planning/in-progress/ → moved by /x4:work Phase 2
docs/planning/complete/    → moved by /x4:work Phase 6
```

---

### Agent Team Ops

Agent team coordination, feature dispatching, review cycles, and hook-based guardrails for multi-agent development workflows.

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

#### The `/x4:work` Pipeline

| Phase | Name | What happens |
|-------|------|-------------|
| 1 | **Orient** | Read STATUS.md, present menu of ready-to-build features, user picks work |
| 2 | **Setup** | Create git branch, DB branch (if Neon configured), open draft PR, move PRD to `in-progress/` |
| 3 | **Build** | Spawn agent team (backend, frontend, tester) in parallel with shared-package coordination |
| 4 | **Review + Verify** | Spawn reviewer + performance agents (parallel), run `/x4:verify-local` gate — all tests must pass |
| 5 | **Ship** | Push, convert draft PR to ready, watch CI, handle failures (auto-fix lint/types, escalate others) |
| 6 | **Memory Sweep** | Move PRD to `complete/`, capture patterns and learnings to memory |
| 7 | **Cleanup** | Report DB branch cleanup instructions, final summary |

#### Agent Templates

The plugin bundles 5 agent templates. Run `/x4:init-agents` to generate project-specific versions in `.claude/agents/`.

| Agent | Role | Access |
|-------|------|--------|
| **backend** | Server-side code, database schema, API routes, auth | Read + Write (owned dirs) |
| **frontend** | UI code, components, pages, styling, stories | Read + Write (owned dirs) |
| **tester** | Unit tests and e2e tests | Read + Write (test files only) |
| **reviewer** | Security, architecture, and quality audit | Read-only |
| **performance** | Bundle size, re-renders, memory leaks, queries, caching | Read-only |

Agents are confined to their owned directories. The reviewer and performance agents are always read-only.

#### Shared Package Coordination

When `shared_packages` is configured:

1. The **owner** agent (e.g., backend) writes to the shared package first
2. Owner sends a message to **notify** agents when shared types are committed
3. Notify agents (e.g., frontend) wait before importing from the shared package

#### CI Failure Handling

| Failure type | Action |
|-------------|--------|
| Lint errors | Auto-fix, commit, push, re-watch |
| TypeScript type errors | Auto-fix, commit, push, re-watch |
| Single failing unit test | Diagnose, fix, commit, push, re-watch |
| E2E / build / logic errors | Stop and notify user with error summary |

Max 3 retry attempts, then escalate to user.

---

### LLMs.txt Management

Scan project dependencies, discover llms.txt documentation endpoints, download and manage AI-readable reference docs.

| Command | Description |
|---------|-------------|
| `/x4:llmstxt-init` | Scaffold Python download script, known-sources cache, docs directory, config |
| `/x4:llmstxt-update` | Full scan, discover, download, and sync (script mode or standalone mode) |
| `/x4:llmstxt-status` | Read-only status report — current, stale, missing, orphaned docs |

#### Supported ecosystems

| Ecosystem | Manifests detected |
|-----------|-------------------|
| JavaScript / Bun / Node | `**/package.json` (excluding `node_modules/`) |
| Python | `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg` |
| Rust | `**/Cargo.toml` |
| Go | `**/go.mod` |
| Ruby | `**/Gemfile` |

#### How `/x4:llmstxt-update` works

1. **Scan** — Reads all dependency manifests, deduplicates across workspaces
2. **Discover** — Queries package registries for homepage URLs, probes `llms-full.txt` and `llms.txt` endpoints, checks aggregator sites
3. **Download** — Saves validated docs to `docs/llms-txt/` with normalized filenames
4. **Sync** — Updates the reference docs table in CLAUDE.md and agent files
5. **Report** — Summary of new, updated, unchanged, failed, and orphaned docs

#### Script mode vs. standalone mode

- **Script mode** (when `script` path is configured in `.llmstxt.json`): Delegates downloads to the bundled Python script (`templates/download-ai-docs.py`) which handles caching and multi-ecosystem support
- **Standalone mode** (default): The skill handles URL probing and downloading directly

---

## 4. Hooks

The plugin provides 4 hooks that activate automatically on installation:

| Hook | Trigger | What it does |
|------|---------|-------------|
| **Protected Files** | PreToolUse (Edit/Write) | Blocks edits to files matching protected patterns (`.env`, lock files) |
| **Auto-Format** | PostToolUse (Edit/Write) | Runs configured formatter (e.g., Prettier) on edited files |
| **Teammate Idle Gate** | TeammateIdle (tester) | Runs test suite when tester agent tries to go idle — blocks if tests fail |
| **Session Start** | SessionStart | Displays key x4 commands as a reminder |

All hooks read project-specific values from `.claude/agent-team.config.md` at runtime.

---

## 5. Configuration

All configuration is optional — sensible defaults apply. Three config files customize behavior:

| Feature | Config File | Generated By |
|---------|-------------|--------------|
| Project tracking | `.claude/project-tracker.config.md` | `/x4:init-tracker` |
| Agent team ops | `.claude/agent-team.config.md` | `/x4:init-setup` |
| LLMs.txt | `.llmstxt.json` | `/x4:llmstxt-init` |

### Agent Team Config (`.claude/agent-team.config.md`)

Controls the most features. Key settings:

| Setting | Purpose | Default |
|---------|---------|---------|
| `agents` | Agent roles, owned directories, models | backend + frontend + reviewer + tester |
| `shared_packages` | Shared package coordination rules | none |
| `test_commands` | Unit, e2e, lint, typecheck commands | `npm test` |
| `protected_files` | Glob patterns blocked from editing | `*.env`, `*.env.*` |
| `formatter` | Auto-format command (`$FILE` placeholder) | disabled |
| `branch_prefixes` | Git branch naming (`feat/`, `fix/`, `chore/`) | `feat/`, `fix/`, `chore/` |
| `status_file` | Path to project status file | `docs/STATUS.md` |
| `ci` | CI provider, watch command, preview URL command | disabled |
| `db_branching` | DB branch provider and commands (Neon, PlanetScale) | disabled |
| `pr` | Draft mode, convert on ship, labels | draft: true |
| `teammate_idle_gates` | Commands that must pass before agent goes idle | none |

### Project Tracker Config (`.claude/project-tracker.config.md`)

| Setting | Purpose | Default |
|---------|---------|---------|
| `status_file` | Path to STATUS.md | `docs/STATUS.md` |
| `backlog_file` | Path to BACKLOG.md | `docs/BACKLOG.md` |
| `planning_dir` | Path to planning directory | `docs/planning/todo/` |
| `prd_pattern` | PRD filename pattern | `NN-prd-<name>.md` |
| `scope` | Scope definitions (small/medium/large) | standard definitions |
| `status_columns` | Columns in Feature Build Progress table | Backend, Frontend, Tested, Deployed |
| `prd_sections` | Sections included in generated PRDs | 8 standard sections |
| `backlog_sections` | Sections included in backlog entries | What, How it fits, Open decisions |

### LLMs.txt Config (`.llmstxt.json`)

| Setting | Purpose | Default |
|---------|---------|---------|
| `docs_dir` | Directory for downloaded docs | `docs/llms-txt/` |
| `skip` | Package names/patterns to skip | `[]` |
| `claude_md` | Path to CLAUDE.md | `CLAUDE.md` |
| `agent_dir` | Path to agent files | `.claude/agents/` |
| `extra_packages` | Additional packages to scan | `[]` |
| `script` | Path to Python download script | disabled |

### Conditional features

Features activate only when the relevant config is present — no dead code paths:

| Feature | Activates when | If absent |
|---------|---------------|-----------|
| DB branching | `db_branching` configured | Skipped entirely |
| Preview URLs | `ci.preview_url_command` set | No mention |
| CI watching | `ci.watch_command` set | Just reports PR is pushed |
| Auto-format | `formatter` set | No formatting |
| E2E tests | `test_commands.e2e` set | Only unit tests run |
| Shared package coordination | `shared_packages` set | Agents work independently |
| Teammate idle gates | `teammate_idle_gates.<role>` set | Agent can go idle freely |

---

## 6. External Plugin Dependencies

Some features optionally integrate with official Claude plugins:

| Plugin | Used By | For |
|--------|---------|-----|
| `superpowers@claude-plugins-official` | `/x4:plan-backlog` | Delegates to `/brainstorming` and `/writing-plans` |
| `code-simplifier@claude-plugins-official` | `/x4:work` Phase 4 | Simplifies complex code after review |

These are optional. Features degrade gracefully with inline alternatives when the plugins aren't installed.

---

## 7. Migration from v2 (4 separate plugins)

### Command mapping

| Old (v2) | New (v3) |
|----------|----------|
| `/x4-agent-team-ops:work` | `/x4:work` |
| `/x4-agent-team-ops:init-setup` | `/x4:init-setup` |
| `/x4-agent-team-ops:init-agents` | `/x4:init-agents` |
| `/x4-agent-team-ops:verify-local` | `/x4:verify-local` |
| `/x4-agent-team-ops:pr-create` | `/x4:pr-create` |
| `/x4-agent-team-ops:pr-status` | `/x4:pr-status` |
| `/x4-agent-team-ops:pr-cleanup` | `/x4:pr-cleanup` |
| `/x4-project-tracker:idea` | `/x4:idea` |
| `/x4-project-tracker:init-tracker` | `/x4:init-tracker` |
| `/x4-llmstxt-manager:llmstxt-init` | `/x4:llmstxt-init` |
| `/x4-llmstxt-manager:llmstxt-update` | `/x4:llmstxt-update` |
| `/x4-llmstxt-manager:llmstxt-status` | `/x4:llmstxt-status` |
| `/x4-scaffold:x4-create` | `/x4:create` |
| `/x4-scaffold:x4-add` | `/x4:add` |
| `/x4-scaffold:x4-env` | `/x4:env` |
| `/x4-scaffold:x4-onboard` | `/x4:onboard` |

### Migration steps

1. Uninstall the 4 old plugins
2. Install the single `x4` plugin: `/plugin install x4@x4-agent-plugins`
3. Update `.claude/settings.json` `enabledPlugins` to use `"x4@x4-agent-plugins": true`
4. No config file changes needed — all config files are the same
5. No agent file changes needed — generated agents are project-owned

---

## 8. Quick Start

### New project

```bash
/x4:onboard                                     # Check your environment
/x4:create my-app                               # Scaffold a project
cd my-app
/x4:init-tracker                                 # Set up tracking files
/x4:idea "Add user authentication"               # Capture first feature
/x4:plan-backlog                                  # Plan it into a PRD
/x4:work                                          # Build it with an agent team
```

### Existing project

```bash
/x4:init-setup                                   # Configure tooling
/x4:init-agents                                   # Generate agent files
/x4:init-tracker                                  # Scaffold tracking files
/x4:llmstxt-init                                  # Set up reference docs
/x4:llmstxt-update                                # Download docs for your deps
/x4:idea "Add rate limiting to API"               # Start capturing work
```

---

## 9. Plugin Structure

```
plugins/x4/
├── .claude-plugin/
│   └── plugin.json          # name: "x4", version: "3.0.0"
├── commands/                 # 16 command stubs
│   ├── work.md              ├── init-setup.md       ├── init-agents.md
│   ├── verify-local.md      ├── pr-create.md        ├── pr-status.md
│   ├── pr-cleanup.md        ├── idea.md             ├── init-tracker.md
│   ├── llmstxt-init.md      ├── llmstxt-update.md   ├── llmstxt-status.md
│   ├── create.md            ├── add.md              ├── env.md
│   └── onboard.md
├── skills/                   # 15 skill definitions
│   ├── work/                 ├── init-setup/         ├── verify-local/
│   ├── pr-create/            ├── pr-status/          ├── pr-cleanup/
│   ├── run-tests/            ├── idea/               ├── plan-backlog/
│   ├── llmstxt-init/         ├── llmstxt-update/     ├── create/
│   ├── add/                  ├── env/                └── onboard/
├── agents/                   # 5 agent templates
│   ├── backend.md            ├── frontend.md         ├── performance.md
│   ├── reviewer.md           └── tester.md
├── hooks/
│   ├── hooks.json            # 4 hook definitions (PreToolUse, PostToolUse, TeammateIdle, SessionStart)
│   ├── protected-files.sh    ├── auto-format.sh
│   ├── teammate-idle.sh      └── session-start.sh
└── templates/
    └── download-ai-docs.py   # Python 3 script for llms.txt discovery + download
```

---

## 10. License

Apache 2.0
