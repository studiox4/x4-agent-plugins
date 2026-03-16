# agent-team-ops

A Claude Code plugin for agent team coordination, feature dispatching, test running, review cycles, and hook-based guardrails.

## Commands

### `/work`

7-phase feature dispatch pipeline: Orient, Setup, Build (agent team), Review + Verify, Ship, Memory Sweep, Cleanup.

### `/run-tests [unit|e2e|lint|typecheck]`

Run configured test commands. Runs all if no argument provided.

### `/init-agents`

Generate project-specific agent `.md` files from bundled templates by analyzing your CLAUDE.md.

## Agent Templates

- **backend** — Server-side code, database schema, API routes
- **frontend** — UI code, components, pages, styling
- **reviewer** — Read-only code review with security/architecture/quality checklists
- **tester** — Unit tests and e2e tests

## Hooks

- **PreToolUse** — Blocks edits to protected files (`.env`, lock files)
- **PostToolUse** — Auto-formats files after Edit/Write
- **TeammateIdle** — Runs test gate when a teammate goes idle

## Configuration

Place `.claude/agent-team.config.md` in your project root with YAML frontmatter. See the spec for all options.

## Installation

```bash
claude plugin install corbanbaxter/x4-agent-plugins/agent-team-ops
```

## License

Apache 2.0
