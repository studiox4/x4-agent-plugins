# Changelog

## x4

### 3.15.0 (2026-04-05)

- `/init-setup` Step 4b: new auto-release wizard — scaffolds `.github/workflows/release.yml` when GitHub Actions is selected; workflow triggers on merge to main, parses conventional commits for bump type (feat→minor, fix→patch, BREAKING→major), tags the commit, and creates a GitHub Release with auto-generated notes
- `/work` Phase 3: build agents now write conventional commit messages (`feat:`, `fix:`, `chore:`, `refactor:`) so the release workflow parses them correctly
- `/work` Phase 5: shows a note when `.github/workflows/release.yml` is present, informing the user that CI will auto-release on merge

### 3.14.1 (2026-04-05)

- `/work` Phase 3 & 4: explicit agent dispatch order — attempt `TeamCreate` (native agent teams) first, fall back to parallel `Agent` subagents if unavailable; never silently falls back to sequential execution

### 3.14.0 (2026-04-04)

- `/debt-scan`: new post-build technical debt audit skill — scans for TODOs, dead code, oversized files, complexity hotspots, and dependency drift; produces a prioritized debt register

### 3.13.4 (2026-04-05)

- `/idea`: improve description with concrete trigger phrases ("btw we should...", "I have an idea", "add to backlog", etc.) so it reliably activates on casual mid-conversation mentions

### 3.13.3 (2026-04-05)

- `/market-update` Step 5: clarify that section marker replacement discards existing content entirely — new copy is the full authoritative replacement, not an append
- `/deploy-setup` Step 0: existing `railway.toml` detection now shows explicit Update/Skip choice dialog instead of silently proceeding
- `/init-setup` Step 1: existing config detection now shows explicit Update/Cancel choice dialog instead of silently updating
- `/doctor`: unresolved agent template variables now classified as ⚠ WARN (not ✗ FAIL) — agents exist but may malfunction; suggests re-running `/x4:init-agents`
- `/upgrade` Step 1: fix stale hardcoded version reference in prose (was `3.13.0`, now reads from `CURRENT_VERSION` comment correctly)

### 3.13.2 (2026-04-04)

- `/e2e-setup` Step 5: when the `.claude/agent-team.config.md` write is blocked by a file-protection hook, print manual instructions instead of failing silently

### 3.13.1 (2026-04-04)

- `/plan-backlog` Step 1.5: Backlog Intelligence Pass — cross-item semantic analysis before the triage menu; detects duplicates (same feature, different wording), natural groupings (items that belong in one PRD), and already-covered items (existing PRD handles it); presents a lettered action panel only when findings exist; silent for clean backlogs; user merges/combines/removes before triage proceeds
- `/idea`: improved duplicate detection — now checks for semantic overlap in meaning and intent (not just title match); extends existing entry instead of creating a second one when overlap is found; confirmation line reports "Extended existing entry" when this occurs

### 3.13.0 (2026-04-04)

- `/plan-bridge`: new skill — converts any planning session into a PRD; detects context from plan mode output (`.claude/plans/`), superpowers `/brainstorming` or `/writing-plans` conversation output, or a manual description; confirms feature summary before writing; writes PRD to `docs/planning/todo/`, updates `STATUS.md`, removes item from `BACKLOG.md` if it originated there
- `hooks/plan-bridge-nudge.sh`: new PostToolUse hook on `ExitPlanMode` — fires after plan mode exits and nudges the user to run `/x4:plan-bridge` when `docs/planning/` or `docs/STATUS.md` is present
- `hooks/hooks.json`: added `ExitPlanMode` PostToolUse hook entry
- `/help`: added `/x4:plan-bridge` to Planning commands and "Anytime" journey entry
- `/upgrade` migration v3.13.0: informational — notes that plan bridge hook is now active

### 3.12.0 (2026-04-04)

- `/e2e-setup`: new skill — one-time Playwright scaffold wizard; detects `apps/web`, `apps/marketing`, `apps/desktop`; creates `packages/playwright-{type}` with tailored configs, starter tests, and Turborepo integration; each app type gets purpose-built setup (storageState auth for web, software-renderer canvas for marketing, `electron-playwright-helpers` for desktop)
- `/run-tests`: rewritten — now app-type-aware for e2e; loads `references/e2e-detection.md` to route each app to its correct strategy; loads per-type runtime reference (`e2e-web.md`, `e2e-marketing.md`, `e2e-desktop.md`) for prerequisite checks and failure triage; visual regression failures in marketing never auto-fix; backward compatible with legacy `test_commands.e2e`
- `skills/run-tests/references/`: five new reference files — `e2e-detection.md`, `e2e-web.md`, `e2e-marketing.md`, `e2e-desktop.md`, `e2e-turbo.md`; cover storageState auth, Three.js canvas baseline testing, Electron IPC/dialog testing, and Turborepo task structure
- `skills/e2e-setup/references/`: four scaffold templates — `scaffold-web.md`, `scaffold-marketing.md`, `scaffold-desktop.md`, `scaffold-shared-config.md`; complete with typed config files and starter test suites
- `/verify-local`: updated e2e failure handling — identifies suite type from output, loads reference file's failure triage table, never auto-fixes marketing snapshot mismatches
- `/init-setup` Step 7e: new conditional — offers `/e2e-setup` during project init when `apps/` directory is detected
- `/upgrade` migration v3.12.0: detects projects with `apps/` but no playwright packages, offers `/e2e-setup`

### 3.11.0 (2026-04-04)

- **Breaking:** Replace llms.txt system with [opensrc](https://github.com/vercel-labs/opensrc) — fetches actual npm package source code instead of docs; gives agents implementation-level context, not just API references
- `/opensrc-init`: new skill — detects key runtime dependencies, runs `npx opensrc` to clone their source at the installed version, updates CLAUDE.md with a Source Code References table; replaces `/llmstxt-init`
- `/opensrc-update`: new skill — diffs `package.json` against `opensrc/sources.json`, fetches new/outdated packages, removes orphaned source; replaces `/llmstxt-update`
- `/opensrc-status`: new skill — read-only report of fetched packages, version freshness vs lockfile, and missing coverage; replaces `/llmstxt-status`
- `session-start.sh`: replaced llms.txt staleness check with opensrc check — warns when `opensrc/sources.json` is 30+ days old, suggests init when package.json exists but opensrc is not set up
- All skills updated: `/doctor`, `/init-setup`, `/help`, `/dream`, `/init-agents`, `/onboard`, `/tour` now reference opensrc paths
- Removed `templates/download-ai-docs.py` — no longer needed

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
