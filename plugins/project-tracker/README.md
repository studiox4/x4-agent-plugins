# x4-project-tracker

A Claude Code plugin that provides backlog capture, triage, PRD generation, and status tracking for any software project.

## Commands

### `/idea <idea>`

Quickly capture a feature idea, improvement, or note into a structured backlog file without interrupting active work.

### `/plan-backlog`

Present unplanned backlog items as a menu. Pick items to plan — includes brainstorming (requirements, edge cases, dependencies) and implementation planning before writing the PRD. Delegates to `superpowers@claude-plugins-official` `/brainstorming` and `/writing-plans` if installed, otherwise runs inline.

PRDs are written to `docs/planning/todo/` and move through the lifecycle:
- `todo/` — Planned, ready to build
- `in-progress/` — Currently being built (managed by `/work`)
- `complete/` — Shipped and merged (managed by `/work`)

### `/init-tracker`

One-time setup that creates STATUS.md, BACKLOG.md, and the planning directory structure (`todo/`, `in-progress/`, `complete/`) for a new project.

## Hooks

- **SessionStart** — Reminds the agent about the project tracking system on every conversation start.

## Configuration

Place `.claude/project-tracker.config.md` in your project root with YAML frontmatter to customize paths, PRD sections, scope definitions, and status columns.

All settings have sensible defaults. No configuration required to get started.

## Installation

```bash
claude plugin install studiox4/x4-agent-plugins/x4-project-tracker
```

## License

Apache 2.0
