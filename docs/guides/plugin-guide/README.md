# x4-agent-plugins — Plugin Guide

Complete documentation for the x4-agent-plugins marketplace. These guides cover every plugin, skill, agent template, and hook in the system — plus setup guides and visual architecture references.

## Plugins

| # | Plugin | Guide | What it covers |
|---|--------|-------|----------------|
| 0 | **x4-scaffold** | [00-x4-scaffold.md](00-x4-scaffold.md) | `/x4-onboard`, `/x4-create`, `/x4-add`, `/x4-env` — project scaffolding with create-x4 CLI |
| 1 | **x4-project-tracker** | [01-project-tracker.md](01-project-tracker.md) | `/idea`, `/plan-backlog` (with brainstorming + planning), `/init-tracker`, planning folder lifecycle |
| 2 | **x4-agent-team-ops** | [02-agent-team-ops.md](02-agent-team-ops.md) | `/work` pipeline, `/init-setup`, `/init-agents`, `/verify-local`, `/pr-create`, `/pr-status`, `/pr-cleanup`, 5 agent templates, 3 hook types |
| 3 | **x4-llmstxt-manager** | [03-llmstxt-manager.md](03-llmstxt-manager.md) | `/llmstxt-init`, `/llmstxt-update`, `/llmstxt-status`, Python download script, known-sources cache |

## Workflow & Architecture

| # | Guide | What it covers |
|---|-------|----------------|
| 4 | [04-dev-workflow.md](04-dev-workflow.md) | Repo structure, local development, testing, versioning, publishing |
| 5 | [05-migration-guide.md](05-migration-guide.md) | Migrating from inline .claude/ skills to consuming plugins |
| 6 | [06-excalidraw-diagram.md](06-excalidraw-diagram.md) | Complete specification for building a visual architecture diagram in Excalidraw |

## Pipeline Overview

```
/x4-onboard → /x4-create → /init-tracker → /idea → /plan-backlog → /work → shipped PR
```

### Stage 1: Onboard + Scaffold (x4-scaffold)
- `/x4-onboard` — Check tools, accounts, CLIs
- `/x4-create` — Scaffold x4-mono project (presets: full-stack, saas, landing, api-only)
- `/x4-env` — Configure database, auth, AI keys
- `/x4-add` — Add mobile/web apps to existing projects

### Stage 2: Capture + Plan (x4-project-tracker)
- `/idea` — Capture feature ideas to backlog
- `/plan-backlog` — Brainstorm → implementation plan → write PRD to `docs/planning/todo/`

### Stage 3: Build Pipeline (x4-agent-team-ops)
- `/work` — 7-phase pipeline:
  1. **Orient** — Read status, pick work
  2. **Setup** — `/pr-create` (branch + DB branch + PR), move PRD to `in-progress/`
  3. **Build** — Spawn agent team (backend, frontend, tester)
  4. **Review + Verify** — Reviewer + performance agents (parallel), `/verify-local` gate
  5. **Ship** — Push, convert PR, `/pr-status` for CI/preview
  6. **Memory Sweep** — Move PRD to `complete/`, capture patterns
  7. **Cleanup** — `/pr-cleanup` for DB branch + local branch

### Reference Docs (x4-llmstxt-manager)
- `/llmstxt-init` — Scaffold Python download script + config
- `/llmstxt-update` — Scan deps, discover llms.txt, download, update references
- `/llmstxt-status` — Read-only health check

## Architecture

```
x4-scaffold              (standalone — scaffolds new projects)
       |
x4-project-tracker       (standalone — backlog + planning)
       |
x4-llmstxt-manager       (standalone — reference docs)
       |
x4-agent-team-ops        (soft deps on tracker + llmstxt for /work dispatch and agent docs)
```

All plugins are independent — installing one does not require the others. `x4-agent-team-ops` has soft dependencies: `/work` can invoke `/plan-backlog` when the build queue is empty, and agent templates reference docs managed by `x4-llmstxt-manager`. These degrade gracefully when the other plugins aren't installed.

## Current Versions

| Plugin | Version | Commands |
|--------|---------|----------|
| x4-scaffold | 1.0.0 | `/x4-onboard`, `/x4-create`, `/x4-add`, `/x4-env` |
| x4-project-tracker | 2.0.0 | `/idea`, `/plan-backlog`, `/init-tracker` |
| x4-agent-team-ops | 2.0.0 | `/work`, `/run-tests`, `/init-setup`, `/init-agents`, `/verify-local`, `/pr-create`, `/pr-status`, `/pr-cleanup` |
| x4-llmstxt-manager | 2.0.0 | `/llmstxt-init`, `/llmstxt-update`, `/llmstxt-status` |
