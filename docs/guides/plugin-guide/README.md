# x4-agent-plugins — Plugin Guide

Complete documentation for the x4-agent-plugins marketplace. These guides cover every command, skill, agent template, and hook in the consolidated `x4` plugin — plus setup guides and visual architecture references.

> **Note:** As of v3.0.0, all four former plugins have been consolidated into a single `x4` plugin. All commands now live under the `/x4:` namespace.

## Plugin

| # | Area | Guide | What it covers |
|---|------|-------|----------------|
| 0 | **Scaffolding** | [00-x4-scaffold.md](00-x4-scaffold.md) | `/x4:onboard`, `/x4:create`, `/x4:add`, `/x4:env` — project scaffolding with create-x4 CLI |
| 1 | **Project Tracking** | [01-project-tracker.md](01-project-tracker.md) | `/x4:idea`, `/x4:plan-backlog` (with brainstorming + planning), `/x4:init-tracker`, planning folder lifecycle |
| 2 | **Agent Team Ops** | [02-agent-team-ops.md](02-agent-team-ops.md) | `/x4:work` pipeline, `/x4:init-setup`, `/x4:init-agents`, `/x4:verify-local`, `/x4:pr-create`, `/x4:pr-status`, `/x4:pr-cleanup`, 5 agent templates, 3 hook types |
| 3 | **LLMs.txt Management** | [03-llmstxt-manager.md](03-llmstxt-manager.md) | `/x4:llmstxt-init`, `/x4:llmstxt-update`, `/x4:llmstxt-status`, Python download script, known-sources cache |

## Workflow & Architecture

| # | Guide | What it covers |
|---|-------|----------------|
| 4 | [04-dev-workflow.md](04-dev-workflow.md) | Repo structure, local development, testing, versioning, publishing |
| 5 | [05-migration-guide.md](05-migration-guide.md) | Migrating from inline .claude/ skills to consuming the plugin |
| 6 | [06-excalidraw-diagram.md](06-excalidraw-diagram.md) | Complete specification for building a visual architecture diagram in Excalidraw |
| 7 | [07-consolidated-plugin-guide.md](07-consolidated-plugin-guide.md) | **Complete v3.0.0 reference** — all 16 commands, 15 skills, 5 agents, 4 hooks, config, migration, quick start |

## Pipeline Overview

```
/x4:onboard → /x4:create → /x4:init-tracker → /x4:idea → /x4:plan-backlog → /x4:work → shipped PR
```

### Stage 1: Onboard + Scaffold
- `/x4:onboard` — Check tools, accounts, CLIs
- `/x4:create` — Scaffold x4-mono project (presets: full-stack, saas, landing, api-only)
- `/x4:env` — Configure database, auth, AI keys
- `/x4:add` — Add mobile/web apps to existing projects

### Stage 2: Capture + Plan
- `/x4:idea` — Capture feature ideas to backlog
- `/x4:plan-backlog` — Brainstorm → implementation plan → write PRD to `docs/planning/todo/`

### Stage 3: Build Pipeline
- `/x4:work` — 7-phase pipeline:
  1. **Orient** — Read status, pick work
  2. **Setup** — `/x4:pr-create` (branch + DB branch + PR), move PRD to `in-progress/`
  3. **Build** — Spawn agent team (backend, frontend, tester)
  4. **Review + Verify** — Reviewer + performance agents (parallel), `/x4:verify-local` gate
  5. **Ship** — Push, convert PR, `/x4:pr-status` for CI/preview
  6. **Memory Sweep** — Move PRD to `complete/`, capture patterns
  7. **Cleanup** — `/x4:pr-cleanup` for DB branch + local branch

### Reference Docs
- `/x4:llmstxt-init` — Scaffold Python download script + config
- `/x4:llmstxt-update` — Scan deps, discover llms.txt, download, update references
- `/x4:llmstxt-status` — Read-only health check

## Installation

```bash
# Add the marketplace
/plugin marketplace add studiox4/x4-agent-plugins

# Install the x4 plugin (single install replaces former 4 separate plugins)
/plugin install x4@x4-agent-plugins
```

## Current Version

| Plugin | Version | Commands |
|--------|---------|----------|
| x4 | 3.0.0 | `/x4:onboard`, `/x4:create`, `/x4:add`, `/x4:env`, `/x4:idea`, `/x4:plan-backlog`, `/x4:init-tracker`, `/x4:work`, `/x4:run-tests`, `/x4:init-setup`, `/x4:init-agents`, `/x4:verify-local`, `/x4:pr-create`, `/x4:pr-status`, `/x4:pr-cleanup`, `/x4:llmstxt-init`, `/x4:llmstxt-update`, `/x4:llmstxt-status` |
