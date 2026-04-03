---
name: doctor
description: Use when something isn't working, when the user wants to verify their x4 project setup, or before starting a build session. Checks prerequisites, config files, agents, environment variables, database, companion plugins, and llms.txt docs. Trigger for "is my setup correct?", "why isn't X working?", "check my project health", or any setup/configuration question.
version: 1.0.0
license: MIT
---

# /doctor — Project Health Diagnostic

Run a comprehensive check of the project's x4 setup and report what's
healthy, what's misconfigured, and what's missing. Does not fix anything
automatically — only diagnoses and suggests fixes.

## Process

### 1. Check prerequisites

Verify the tools from `/x4:onboard` are available:

| Check | Command | Pass |
|-------|---------|------|
| Bun | `bun --version` | >= 1.1 |
| Node.js | `node --version` | >= 18 |
| Git | `git --version` | Any |
| GitHub CLI | `gh --version` | Any |
| gh auth | `gh auth status` | Authenticated |

For each: report PASS with version, or FAIL with install suggestion.

### 2. Check project structure

| Check | How | Pass |
|-------|-----|------|
| package.json exists | Read file | Exists |
| CLAUDE.md exists | Read file | Exists |
| Git remote configured | `git remote -v` | Has origin |
| On a branch | `git branch --show-current` | Not detached HEAD |

### 3. Check x4 configuration

| Check | How | Pass |
|-------|-----|------|
| Agent team config | Read `.claude/agent-team.config.md` | Exists and parseable |
| Project tracker config | Read `.claude/project-tracker.config.md` | Exists and parseable |
| Status file | Read configured `status_file` | Exists |
| Backlog file | Read configured `backlog_file` | Exists |
| Planning directories | Check `todo/`, `in-progress/`, `complete/` | All three exist |

For missing configs: suggest the setup command (e.g., "Run `/x4:init-setup`").
For missing tracking files: suggest `/x4:init-tracker`.

### 4. Check agents

| Check | How | Pass |
|-------|-----|------|
| Agent files exist | Glob `.claude/agents/*.md` | At least backend.md, frontend.md, tester.md |
| Template variables resolved | Grep for `{{` in agent files | No unresolved `{{placeholders}}` |
| Reviewer is read-only | Check reviewer.md frontmatter | No Write/Edit in tools |
| Performance is read-only | Check performance.md frontmatter | No Write/Edit in tools |

For missing agents: suggest `/x4:init-agents`.
For unresolved templates: suggest re-running `/x4:init-agents`.

### 5. Check environment

| Check | How | Pass |
|-------|-----|------|
| .env file exists | Read `.env` or `.env.local` | Exists |
| DATABASE_URL set | Check env file | Non-empty |
| Auth secret set | Check for BETTER_AUTH_SECRET or similar | Non-empty |
| AI API key set | Check for ANTHROPIC_API_KEY | Non-empty |

Do NOT print the values — just report whether they're set.
For missing env vars: suggest `/x4:env`.

### 6. Check database connectivity (if configured)

Only if `db_branching` is configured in agent-team config:

| Check | How | Pass |
|-------|-----|------|
| Can connect | `neon branches list` or test connection | No error |
| Branch exists | Check for feature branch | If on a feature branch |

### 7. Check companion plugins

| Check | How | Pass |
|-------|-----|------|
| superpowers | Check if plugin is enabled in settings | Installed |
| code-simplifier | Check if plugin is enabled | Installed |
| frontend-design | Check if plugin is enabled | Installed |

For missing: report as OPTIONAL with what it enables.

### 8. Check x4 project version

| Check | How | Pass |
|-------|-----|------|
| `.claude/x4-version` exists | Read file | Exists (set by `/init-setup` or `/upgrade`) |
| Version is current | Compare with `CURRENT_VERSION` in `upgrade/SKILL.md` | Matches |

If `.claude/x4-version` is missing but `.claude/agent-team.config.md` exists:
  WARN: "Project was configured before version tracking — run `/x4:upgrade` to apply any missed migrations."

If version is present but outdated:
  WARN: "Project is on v{project_version}, plugin is v{current_version} — run `/x4:upgrade`."

If version matches: PASS.

**Also scan for common migration gaps directly** (catches issues even if version file is current):

| Gap | Check | Fix |
|-----|-------|-----|
| `brand/BRAND.md` | File exists when brand config is present | `/x4:upgrade` |
| `brand/assets/` | Directory exists | `/x4:upgrade` |
| `railway.toml` | Exists when Railway is configured in CI | `/x4:deploy-setup` |

### 9. Check llms.txt docs

| Check | How | Pass |
|-------|-----|------|
| .llmstxt.json exists | Read file | Exists (optional) |
| Docs directory exists | Check configured docs dir | Has files |
| Docs are fresh | Check file modification dates | None older than 30 days |

For stale docs: suggest `/x4:llmstxt-update`.
For no docs: suggest `/x4:llmstxt-init`.

### 10. Report

Present as a structured diagnostic:

```
## x4 Doctor — Project Health Report

### Prerequisites
  ✓ Bun 1.1.38
  ✓ Node.js 22.4.0
  ✓ Git 2.45.0
  ✓ GitHub CLI 2.62.0 (authenticated as @username)

### Project Structure
  ✓ package.json
  ✓ CLAUDE.md
  ✓ Git remote: origin → github.com/user/project
  ✓ Branch: feat/user-dashboard

### x4 Configuration
  ✓ Agent team config
  ✓ Project tracker config
  ✓ Status file: docs/STATUS.md
  ✓ Backlog file: docs/BACKLOG.md
  ✓ Planning directories

### Agents
  ✓ 5 agent files (backend, frontend, tester, reviewer, performance)
  ✓ All templates resolved
  ✓ Reviewer and performance are read-only

### Environment
  ✓ DATABASE_URL set
  ✓ BETTER_AUTH_SECRET set
  ✗ ANTHROPIC_API_KEY not set — run /x4:env to configure

### Database
  ✓ Neon connected (project: my-app)

### Companion Plugins
  ✓ superpowers
  ✓ code-simplifier
  ○ frontend-design (optional — enhances /kickstart UI design)

### Reference Docs
  ✓ 8 docs in docs/llms-txt/
  ⚠ 2 docs older than 30 days — run /x4:llmstxt-update

### Summary
  18 passed, 1 failed, 1 warning

  Fix: Run /x4:env to set ANTHROPIC_API_KEY
  Refresh: Run /x4:llmstxt-update to update stale docs
```

Use ✓ for pass, ✗ for fail, ⚠ for warning, ○ for optional/skipped.

## Rules

- Read-only — never modify any files or settings
- Never print secret values — only report whether they are set
- Skip checks that don't apply (e.g., skip database if no db_branching configured)
- Keep the report concise — one line per check
- End with a summary and actionable fix suggestions
- If everything passes: "All checks passed — your project is ready for `/x4:work`."
