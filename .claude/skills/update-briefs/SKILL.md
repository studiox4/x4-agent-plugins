---
name: update-briefs
description: Regenerate all brief documents in .briefs/ to reflect the current state of the plugin — run this as part of every release
disable-model-invocation: true
---

# /update-briefs — Refresh Brief Documents

Regenerate all brief documents in `.briefs/` to reflect the current state of the x4 plugin. Should be run as part of every release.

## Process

### 1. Read current plugin state

Gather the current state of the plugin:
- Read `plugins/x4/.claude-plugin/plugin.json` for version
- Read `CHANGELOG.md` for recent changes
- List all skills: `plugins/x4/skills/*/SKILL.md`
- List all commands: `plugins/x4/commands/*.md`
- List all agents: `plugins/x4/agents/*.md`
- Read `plugins/x4/hooks/hooks.json` for hook configuration
- Read `README.md` for project overview

### 2. Update `.briefs/x4-architecture-and-user-flow.md`

Regenerate the architecture and user flow brief with:
- Current version number
- Current date
- Accurate skill/command/agent/hook counts
- All commands listed in the reference table
- Any new stages, phases, or pipeline changes
- Updated typical user journey

Preserve the document structure and section headings. Update content to match current plugin state.

### 3. Update `.briefs/marketing-site-brief.md`

Regenerate the marketing brief with:
- Current version number
- Accurate command counts and references
- Updated pipeline table (any new stages)
- Updated command reference (all commands, organized by category)
- Updated changelog highlights (add latest version)
- Updated key stats/numbers
- Any new visual suggestions for new features

Preserve the document structure, tone guidelines, and content guidelines. Update factual content to match current plugin state.

### 4. Report

> Briefs updated for v{version}:
> - .briefs/x4-architecture-and-user-flow.md
> - .briefs/marketing-site-brief.md

## Rules

- Read the actual plugin files — do not guess at counts or names
- Preserve document structure and formatting style
- Do not change tone guidelines or content guidelines in the marketing brief
- Do not commit — briefs are gitignored
- If a new brief file is needed (e.g., a new audience), suggest it but don't create it without user confirmation
