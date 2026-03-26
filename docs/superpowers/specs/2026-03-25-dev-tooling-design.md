# Dev Tooling: Validator Agent, Validate Skill, Release Skill

**Date:** 2026-03-25
**Status:** Approved

## Problem

The x4-agent-plugins repo lacks fast, in-session feedback during plugin development. Structural issues (missing SKILL.md, invalid JSON, broken cross-references) are only caught by CI on push. The previous git pre-commit hook for auto-bumping versions was too coarse — it mutated `plugin.json` on every commit regardless of intent.

## Solution

Three project-level automations in `.claude/`:

### 1. Plugin Validator Agent (`.claude/agents/plugin-validator.md`)

A read-only agent that performs comprehensive structural validation of the plugin marketplace.

**Checks performed:**
- `.claude-plugin/marketplace.json` (repo root) exists and is valid JSON
- Each plugin has `.claude-plugin/plugin.json` with required fields (`name`, `description`, `version`)
- Each plugin has `LICENSE` and `README.md`
- Every `skills/*/` directory contains a `SKILL.md`
- Name-based command/skill matching: `commands/foo.md` ↔ `skills/foo/SKILL.md` (and vice versa)
- Hook scripts (`.sh`) are executable
- No parent directory traversals (`../../`) in markdown files
- `plugin.json` version follows semver format
- `hooks.json` is valid JSON with expected structure: top-level `hooks` object keyed by event name (`PreToolUse`, `PostToolUse`, etc.), each containing an array of matcher/hooks pairs

**Design decisions:**
- Read-only — reports issues, never fixes them
- Can be dispatched in parallel via Agent tool
- Runs the existing `tests/validate.sh` as a baseline, then performs deeper cross-reference checks

### 2. Validate Skill (`.claude/skills/validate/SKILL.md`)

User-invocable via `/validate`. Provides a single command for the full validation workflow.

**Behavior:**
1. Run `bash tests/validate.sh` for baseline structural checks
2. Dispatch the plugin-validator agent for deeper analysis
3. Report combined results

**Design decisions:**
- User-only invocation (`disable-model-invocation: true`) — validation is an intentional action
- Delegates to agent for thorough checking rather than duplicating logic

### 3. Release Skill (`.claude/skills/release/SKILL.md`)

User-invocable via `/release`. Replaces the git pre-commit hook with intentional version management.

**Behavior:**
1. Run validation (invoke validate skill logic)
2. Ask user for bump type: patch (default), minor, or major
3. Read current version from `plugins/x4/.claude-plugin/plugin.json`
4. Bump version according to semver
5. Add changelog entry to root `./CHANGELOG.md` with date and summary
6. Stage and commit the version bump

**Design decisions:**
- User-only invocation — version bumps should be deliberate
- Validation gate — won't bump if validation fails
- Accepts optional argument for bump type (e.g., `/release minor`)

## Files Created

| File | Purpose |
|------|---------|
| `.claude/agents/plugin-validator.md` | Validator agent definition |
| `.claude/skills/validate/SKILL.md` | Validate command skill |
| `.claude/skills/release/SKILL.md` | Release command skill |

## What This Replaces

- Git pre-commit hook for auto-bumping version (was added in commit `498be56` and renamed in `b8b04e3`, but the hook file no longer exists in `.git/hooks/` — likely lost on clone since git hooks aren't tracked. No removal action needed.)
- Manual `bash tests/validate.sh` invocations during development
