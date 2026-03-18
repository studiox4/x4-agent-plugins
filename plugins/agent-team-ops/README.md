# x4-agent-team-ops

A Claude Code plugin for agent team coordination, feature dispatching, test running, review cycles, and hook-based guardrails.

## Commands

### `/work`

7-phase feature dispatch pipeline: Orient, Setup, Build (agent team), Review + Verify, Ship, Memory Sweep, Cleanup. Delegates to sub-skills (`/pr-create`, `/verify-local`, `/pr-status`) and manages PRD lifecycle across `todo/` → `in-progress/` → `complete/`.

### `/init-setup`

Interactive wizard to configure project tooling. Auto-detects package manager, test framework, and CI provider, then walks through database, hosting, and preview configuration. Writes `.claude/agent-team.config.md`.

### `/run-tests [unit|e2e|lint|typecheck]`

Run configured test commands. Runs all if no argument provided.

### `/init-agents`

Generate project-specific agent `.md` files from bundled templates by analyzing your CLAUDE.md.

### `/verify-local`

Run all configured checks (unit, e2e, lint, typecheck) with auto-fix (max 3 attempts per check). Mandatory gate between Review and Ship phases in the `/work` pipeline.

### `/pr-create <name> [--type feature|fix|chore]`

Create a git branch, database branch (if configured), push, open a draft PR, and wait for preview environments. Standalone or called by `/work` Phase 2.

### `/pr-status`

Check the current branch's PR status: CI checks, preview URLs, and review state via `gh` CLI.

### `/pr-cleanup [branch-name]`

Post-merge cleanup: delete database branch (if configured) and remove local git branch.

## Agent Templates

- **backend** — Server-side code, database schema, API routes
- **frontend** — UI code, components, pages, styling
- **reviewer** — Read-only code review with security/architecture/quality checklists
- **tester** — Unit tests and e2e tests
- **performance** — Read-only performance audit: bundle size, re-renders, memory leaks, query patterns, caching

## Hooks

- **PreToolUse** — Blocks edits to protected files (`.env`, lock files)
- **PostToolUse** — Auto-formats files after Edit/Write
- **TeammateIdle** — Runs test gate when a teammate goes idle

## Configuration

Run `/init-setup` for interactive configuration, or place `.claude/agent-team.config.md` in your project root with YAML frontmatter. See the spec for all options.

## Installation

```bash
claude plugin install studiox4/x4-agent-plugins/x4-agent-team-ops
```

## License

Apache 2.0
