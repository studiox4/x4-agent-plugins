# Changelog

## x4-scaffold

### 1.0.0 (2026-03-18)

- Initial release: `/x4-create`, `/x4-add`, `/x4-env`
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
