# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin marketplace containing the `x4` plugin — a complete AI-powered development workflow for project scaffolding, backlog management, agent team coordination, and reference documentation.

## Commands

```bash
# Validate marketplace structure
bash tests/validate.sh

# Validate with deeper cross-reference checks
/validate

# Link plugin for local iterative development
claude plugin link ./plugins/x4

# Test marketplace locally
/plugin marketplace add ./path/to/x4-agent-plugins

# Release a new version (replaces pre-commit hook)
/release [patch|minor|major]
```

## Architecture

### Marketplace Root

`.claude-plugin/marketplace.json` defines the marketplace. Each plugin lives under `plugins/<name>/` with its own `.claude-plugin/plugin.json` manifest.

### Plugin Anatomy (`plugins/x4/`)

```
commands/*.md          → User-facing entry points (/x4:work, /x4:create, etc.)
skills/*/SKILL.md      → Implementation logic for each command
agents/*.md            → Role-specific agent templates (backend, frontend, reviewer, tester, performance)
hooks/hooks.json       → Hook registration (PreToolUse, PostToolUse, TeammateIdle, SessionStart)
hooks/*.sh             → Hook script implementations
templates/             → Reusable utilities (e.g., download-ai-docs.py)
```

**Key relationship:** Commands and skills are name-matched — `commands/foo.md` must have a corresponding `skills/foo/SKILL.md`. The validator checks this.

### How the Pieces Connect

Commands invoke skills. Skills may spawn agents (during `/x4:work` builds). Hooks fire on tool events (protect files, auto-format, gate idle agents). Agent templates use substitution variables (`{{OWNED_DIRS}}`, `{{TECH_STACK}}`, etc.) filled by the orchestrating skill.

### Project-Level Dev Tooling (`.claude/`)

This repo's own development automations:

- `.claude/agents/plugin-validator.md` — Read-only structural validation agent
- `.claude/skills/validate/SKILL.md` — `/validate` command for full marketplace checks
- `.claude/skills/release/SKILL.md` — `/release` for intentional version bumps

## File Conventions

### Command Files (`commands/*.md`)

YAML frontmatter with `description`, `argument-hint` (optional), `allowed-tools`. Body is plain markdown with usage instructions.

### Skill Files (`skills/*/SKILL.md`)

YAML frontmatter with `name`, `description`. Body is a detailed multi-step specification with process flows, exit criteria, and error handling. May delegate to other skills or companion plugins.

### Agent Templates (`agents/*.md`)

YAML frontmatter with `name`, `description`, `model`. Body uses template variables for project-specific context. Include a Rules section with agent constraints.

### Hook Scripts (`hooks/*.sh`)

Must be executable (`chmod +x`). Registered in `hooks.json` under event keys: `PreToolUse`, `PostToolUse`, `TeammateIdle`, `SessionStart`.

## Version Management

- Version lives in both `.claude-plugin/marketplace.json` and `plugins/x4/.claude-plugin/plugin.json` — keep them in sync
- Use `/release` to bump versions with validation and changelog updates
- `CHANGELOG.md` at repo root tracks all releases, organized by plugin name

## Validation

`tests/validate.sh` checks:
- Plugin manifests have required fields (`name`, `description`)
- Every skill directory has a `SKILL.md`
- Every command file exists
- Hook scripts are executable
- No parent directory traversals in markdown

The `/validate` skill adds deeper checks: JSON validity, command/skill cross-references, hooks.json structure, and semver format.

## CI

GitHub Actions (`.github/workflows/validate.yml`) runs on push and PR:
- `bash tests/validate.sh`
- JSON validation of all manifests
- Changelog update warning on PRs that touch plugin files

## Companion Plugins

The x4 plugin integrates with these when installed (degrades gracefully without them):
- `superpowers@claude-plugins-official` — `/brainstorming` and `/writing-plans` in `/x4:plan-backlog`
- `code-simplifier@claude-plugins-official` — Code quality in `/x4:work` Phase 4
