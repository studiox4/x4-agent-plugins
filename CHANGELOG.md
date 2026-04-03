# Changelog

## x4

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
