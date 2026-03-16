# project-tracker

A Claude Code plugin that provides backlog capture, triage, PRD generation, and status tracking for any software project.

## Commands

### `/btw <idea>`

Quickly capture a feature idea, improvement, or note into a structured backlog file without interrupting active work.

### `/plan-backlog`

Present unplanned backlog items as a menu. Pick items to plan (generates a PRD and updates the status file) or delete.

### `/init-tracker`

One-time setup that creates STATUS.md, BACKLOG.md, and a planning directory for a new project.

## Hooks

- **SessionStart** — Reminds the agent about the project tracking system on every conversation start.

## Configuration

Place `.claude/project-tracker.config.md` in your project root with YAML frontmatter to customize paths, PRD sections, scope definitions, and status columns.

All settings have sensible defaults. No configuration required to get started.

## Installation

```bash
claude plugin install corbanbaxter/x4-agent-plugins/project-tracker
```

## License

Apache 2.0
