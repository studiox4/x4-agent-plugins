# Changelog

## x4

### 3.10.0 (2026-04-03)

- `/upgrade`: new skill — applies x4 project migrations after a plugin update; reads `.claude/x4-version` to detect what's been applied, runs versioned migration registry, presents findings before touching anything, updates version file on completion
- `session-start.sh`: version check — compares `X4_VERSION` constant against `.claude/x4-version`; shows one-line upgrade prompt when they differ; fires for projects set up before version tracking was introduced
- `.claude/x4-version`: new project file — one-line version tracker written by `/init-setup` and updated by `/upgrade`; used by session-start hook to detect when migrations are available
- `/init-setup` Step 8: now writes `.claude/x4-version` at the end of setup
- `/doctor` Step 8: new version and migration gap checks — flags outdated version file, missing `brand/BRAND.md`, missing `brand/assets/`, missing `railway.toml` when Railway is configured
- `/release`: new Step 5.5 — updates `X4_VERSION` in `session-start.sh` and `CURRENT_VERSION` in `upgrade/SKILL.md` as part of every release

### 3.9.0 (2026-04-03)

- `brand/BRAND.md` — new human-editable brand guide scaffolded at project root by `/init-setup`; all marketing skills read from it (voice, tone, colors, logos, social handles, email config); assets go in `brand/assets/`
- All marketing skills (`market-update`, `market-email`, `market-linkedin`, `market-tweet`, `market-subscribe`) updated to read `brand/BRAND.md` first, fall back to legacy `brand:` YAML config
- `/init-setup` Step 6c rewired — now creates `brand/BRAND.md` from a rich template instead of writing a `brand:` YAML block to `agent-team.config.md`
- Template stored in `plugins/x4/skills/init-setup/references/brand-template.md` with `{{PLACEHOLDER}}` tokens for pre-filling
- `brand/assets/` README generated with asset size/format guidance
- README updated with brand guide section and day-in-the-life brand update workflow
- `/help` updated to surface `brand/BRAND.md` and `brand/assets/` as directly editable resources

### 3.8.1 (2026-04-03)

- `/market-subscribe`: new skill — scaffolds email capture into the marketing site; generates `SubscribeForm` React component and `/api/subscribe` Next.js route handler wired to Resend or Loops; inserts form into configured page using section markers; adds env var placeholders to `.env.local`
- `/init-setup` Step 6b: offer to run `/market-subscribe` after brand+email config is written
- `/init-setup` Step 7d: new conditional step — delegates to `/market-subscribe` if opted in

### 3.8.0 (2026-04-03)

- `/market-email`: new skill — generates release email campaigns from CHANGELOG.md entries; produces subject line options, preview text, and full email body in brand voice; outputs Resend-ready send snippet; never auto-sends — always review first
- `/market-linkedin`: new skill — generates LinkedIn-optimized posts from CHANGELOG.md; hook → body → CTA → hashtags format; puts external links in first comment (not post body, per LinkedIn algorithm); copies to clipboard and opens compose
- `/market-tweet`: new skill — generates numbered X/Twitter threads from CHANGELOG.md; 280-char enforcement per tweet; optional `--post` flag for X API posting if `X_API_KEY` configured
- `/init-setup`: new Step 6c — brand & marketing channels configuration; collects brand voice, audience, email provider (Resend/Loops), social handles, hashtags, optional X API key env var; writes `brand` block to config
- `/work` Phase 7: expanded marketing reminder block — shows all four marketing commands (`market-update`, `market-email`, `market-linkedin`, `market-tweet`) when marketing or brand is configured
- `/help`: new "Marketing & Announcements" section in command list

### 3.7.0 (2026-04-02)

- `/deploy-setup`: new skill — one-time Railway deployment wizard; detects monorepo services, generates `railway.toml` with per-service config, syncs env vars from `.env.local`, walks through GitHub connection and PR preview setup in the Railway dashboard
- `/init-setup` Step 3: when Railway is selected, offers to run `/deploy-setup` immediately for first-time configuration
- `/init-setup`: fix incorrect `preview_url_command` default — was `.deployments[0].url` (invalid path), now `.services[]?` which correctly lists all service URLs for multi-service monorepos
- `/help`: updated command list to include `/x4:deploy-setup`

### 3.6.0 (2026-04-03)

- `/market-update`: new skill — syncs the marketing site with recently shipped features; reads `docs/CHANGELOG.md` entries since last sync, generates marketing copy per page, optionally captures screenshots via Playwright, presents draft for user review, then applies updates with TSX section marker support
- `/work` Phase 6: now writes a structured `docs/CHANGELOG.md` entry after every shipped feature — feature title, user-facing bullets from PRD user stories, PR number/URL, date
- `/work` Phase 7: adds `/market-update` reminder to the Work Complete report when marketing is configured
- `/init-setup`: new Step 6b — detects and configures marketing site pages for `/market-update`
- `/help`: updated command list to include `/x4:market-update`

### 3.5.1 (2026-04-03)

- Improve all 28 skill descriptions for better triggering — each now includes "Use when..." context and concrete example phrases so Claude invokes the right skill from natural language
- Update workflow diagram image
- Fix `/update-briefs` to be user-invocable as a slash command

### 3.5.0 (2026-04-02)

- `/help`: contextual plugin guide — detects project state, shows all commands, suggests next step
- `/doctor`: project health diagnostic — checks prerequisites, config, agents, env vars, database, plugins, llms.txt docs

### 3.4.0 (2026-04-02)

- `/gaps`: product gap finder — scans features for dead ends, missing connections, incomplete flows, stale backlog items
- `/dream`: visionary ideas generator — interactive exploration of big ideas informed by tech stack and ecosystem

### 3.3.0 (2026-04-02)

- `/work` auto-loop: build all ready PRDs sequentially with checkpoint prompts between each
- `/work` parallel execution: build independent PRDs simultaneously using agent teams (experimental)
- PRD dependency analysis in Phase 1: detects inter-PRD dependencies, groups into execution waves
- Enhanced Phase 1 menu with Blocked section, Dependency Analysis, and Build Options
- Work skill bumped to v3.0.0

### 3.2.0 (2026-04-02)

- Add missing skills for 3 orphan commands: `llmstxt-status`, `init-tracker`, `init-agents`
- Make all 4 thick commands thin wrappers (including pre-existing `llmstxt-update`)
- Normalize all 21 skill names to bare format (remove `x4-` prefix)
- Add missing `name`, `version`, and `license` fields across all skills
- Remove pre-commit auto-bump hook — version management now via `/release` skill

### 3.0.0 (2026-03-19)

- **BREAKING:** Consolidate 4 plugins (`x4-scaffold`, `x4-project-tracker`, `x4-agent-team-ops`, `x4-llmstxt-manager`) into a single `x4` plugin
- All commands now live under the `/x4:` namespace (e.g., `/x4:work`, `/x4:idea`, `/x4:create`)
- Scaffold commands renamed: `/x4-create` → `/x4:create`, `/x4-add` → `/x4:add`, `/x4-env` → `/x4:env`, `/x4-onboard` → `/x4:onboard`
- Merged hooks from agent-team-ops and project-tracker into single `hooks.json`
- Single install: `/plugin install x4@x4-agent-plugins`

---

## x4-scaffold

### 1.0.0 (2026-03-18)

- `/x4-onboard`: developer environment setup wizard — checks tools (Bun, Node, Git, gh), walks through accounts (Neon, Railway, Vercel, Anthropic), installs missing plugins
- `/x4-create`: interactive wizard wrapping `bunx create-x4` with presets (full-stack, saas, landing, api-only), platform selection, env setup, post-scaffold init
- `/x4-add`: add mobile (Expo 52) or web (Next.js 15) apps to existing projects
- `/x4-env`: database setup (Neon auto-create or paste), auth secret generation, AI key config

## project-tracker

### 2.0.0 (2026-03-18)

- `/plan-backlog`: Add brainstorming and implementation plan steps before PRD writing
- `/plan-backlog`: Delegate to superpowers `/brainstorming` and `/writing-plans` if installed
- `/plan-backlog`: Write PRDs to `docs/planning/todo/` instead of flat planning dir
- `/init-tracker`: Create `todo/`, `in-progress/`, `complete/` subdirectories
- Planning folder lifecycle: todo → in-progress → complete (managed by `/work`)

### 1.0.0 (2026-03-16)

- Initial release: `/btw`, `/plan-backlog`, `/init-tracker`, SessionStart hook

## agent-team-ops

### 2.0.0 (2026-03-18)

- Add `/init-setup` interactive wizard for configurable tooling (DB, hosting, CI, tests)
- Add `/verify-local` skill: run all checks with auto-fix (max 3 attempts), mandatory ship gate
- Add `/pr-create` skill: branch + DB branch + draft PR + preview setup
- Add `/pr-status` skill: CI checks, preview URLs, review state via gh CLI
- Add `/pr-cleanup` skill: post-merge DB branch + local branch cleanup
- Add performance agent template (bundle size, re-renders, memory leaks, queries, caching)
- `/work` Phase 2: delegate to `/pr-create`, add PRD `git mv` from `todo/` → `in-progress/`
- `/work` Phase 4: spawn performance agent alongside reviewer (parallel), delegate verification to `/verify-local`
- `/work` Phase 4: run `code-simplifier` if installed
- `/work` Phase 5: add CI failure handling table (auto-fix vs STOP+notify)
- `/work` Phase 6: `git mv` PRD from `in-progress/` → `complete/`, clean up scratch files
- `/work` Phase 7: reference `/pr-cleanup` for manual cleanup
- `/init-agents`: add performance agent to read_only rule

### 1.0.0 (2026-03-16)

- Initial release: `/work`, `/run-tests`, `/init-agents`, all hooks

## llmstxt-manager

### 2.0.0 (2026-03-18)

- Add `/llmstxt-init` skill: scaffolds Python download script, known-sources cache, docs directory, config
- Add `templates/download-ai-docs.py`: pure Python 3 stdlib script for dependency discovery and download
- `/llmstxt-update`: add script mode (runs `download-ai-docs.py --json` when present) alongside standalone mode
- Support `extra_packages` and `script` fields in `.llmstxt.json` config

### 1.0.0 (2026-03-16)

- Initial release: `/llmstxt-update`, `/llmstxt-status`
