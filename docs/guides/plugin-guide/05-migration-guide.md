# Migration Guide: Local Skills to Extracted Plugins

This guide walks through migrating the Daykeep project from its current inline `.claude/` workflow (skills, commands, hooks, agent files) to consuming the three extracted plugins from `corbanbaxter/claude-workflow-plugins`. It also covers how a brand-new project would adopt the plugins from scratch.

---

## Table of Contents

1. [Pre-Migration Checklist](#1-pre-migration-checklist)
2. [Migration Order](#2-migration-order)
3. [Step-by-Step: llmstxt-manager](#3-step-by-step-llmstxt-manager)
4. [Step-by-Step: project-tracker](#4-step-by-step-project-tracker)
5. [Step-by-Step: agent-team-ops](#5-step-by-step-agent-team-ops)
6. [CLAUDE.md Updates](#6-claudemd-updates)
7. [Rollback Plan](#7-rollback-plan)
8. [Post-Migration Cleanup](#8-post-migration-cleanup)
9. [Adapting for Other Projects](#9-adapting-for-other-projects)

---

## 1. Pre-Migration Checklist

Before touching anything, verify the current state and document what you have.

### 1a. Verify current setup works

Run each skill and confirm it behaves correctly:

```bash
# Verify /btw captures to backlog
# (invoke in Claude Code): /btw "test idea for migration verification"

# Verify /llmstxt-update runs
# (invoke in Claude Code): /llmstxt-update

# Verify /work shows the dispatch menu
# (invoke in Claude Code): /work

# Verify hooks fire
echo "test" > /tmp/hook-test.env
# PreToolUse should block editing .env files
# PostToolUse should run Prettier after edits
```

Confirm unit tests pass:

```bash
cd apps/api && bun test
```

### 1b. Document local customizations

Check each file for any Daykeep-specific logic that diverges from what the README describes. Record anything non-standard:

```bash
# List all local skill and command files
ls -R .claude/skills/ .claude/commands/ .claude/agents/
```

Current Daykeep local files that will be affected:

| File                                     | Action                                                       | Plugin          |
| ---------------------------------------- | ------------------------------------------------------------ | --------------- |
| `.claude/skills/btw/SKILL.md`            | Remove (replaced by plugin)                                  | project-tracker |
| `.claude/skills/plan-backlog/SKILL.md`   | Remove (replaced by plugin)                                  | project-tracker |
| `.claude/commands/btw.md`                | Remove (replaced by plugin)                                  | project-tracker |
| `.claude/skills/work/SKILL.md`           | Remove (replaced by plugin)                                  | agent-team-ops  |
| `.claude/skills/run-tests/SKILL.md`      | Remove (replaced by plugin)                                  | agent-team-ops  |
| `.claude/skills/llmstxt-update/SKILL.md` | Remove (replaced by plugin)                                  | llmstxt-manager |
| `.claude/agents/backend.md`              | Keep (locally owned, regenerated once by `/init-agents`)     | agent-team-ops  |
| `.claude/agents/frontend.md`             | Keep                                                         | agent-team-ops  |
| `.claude/agents/reviewer.md`             | Keep                                                         | agent-team-ops  |
| `.claude/agents/tester.md`               | Keep                                                         | agent-team-ops  |
| `.claude/settings.json` (hooks section)  | Migrate hook config to plugin, remove local hook definitions | agent-team-ops  |
| `CLAUDE.md`                              | Update references                                            | all             |

### 1c. Create a migration branch

```bash
git checkout -b chore/migrate-to-plugins
```

This keeps all changes reversible until you are confident the plugins work.

---

## 2. Migration Order

Install plugins from simplest to most complex. Each step is independently verifiable before moving to the next.

| Order | Plugin          | Risk   | Why this order                                                               |
| ----- | --------------- | ------ | ---------------------------------------------------------------------------- |
| 1     | llmstxt-manager | Low    | One skill, no hooks, no agent templates. Isolated.                           |
| 2     | project-tracker | Low    | Two skills + one command. No hooks that affect other plugins.                |
| 3     | agent-team-ops  | Medium | Touches hooks in settings.json, agent files, cross-references other plugins. |

Never install agent-team-ops before the other two. Its `/work` skill can invoke project-tracker's `/plan-backlog`, and its agent templates reference docs managed by llmstxt-manager. Those soft dependencies work best when the other plugins are already in place.

---

## 3. Step-by-Step: llmstxt-manager

### 3a. Install the plugin

In `.claude/settings.json`, add to the `enabledPlugins` section:

```json
{
  "enabledPlugins": {
    "llmstxt-manager@corbanbaxter/claude-workflow-plugins": true
  }
}
```

Or install via Claude Code CLI if supported:

```bash
claude plugin install corbanbaxter/claude-workflow-plugins/plugins/llmstxt-manager
```

### 3b. Verify plugin manifest

Confirm the plugin has a valid `.claude-plugin/plugin.json` manifest. After installation, verify the plugin shows up in `/help` or skill listings within Claude Code.

### 3c. Create the config file

Create `.claude/llmstxt-manager.config.md` with Daykeep-specific settings:

> **Note:** The `.claude/llmstxt-manager.config.md` file is a custom configuration pattern used by this workflow plugin -- not an official Claude Code plugin convention. Official plugins typically use environment variables and frontmatter in their `.claude-plugin/plugin.json` manifest.

```markdown
---
docs_dir: docs/llms-txt
download_script: scripts/download-ai-docs.ts
claude_md: CLAUDE.md
agents_dir: .claude/agents
skip_packages:
  - "@types/*"
  - "esbuild"
  - "typescript"
  - "eslint"
  - "eslint-*"
  - "@eslint/*"
  - "postcss"
  - "autoprefixer"
prefer_full: true
---

# LLMs.txt Manager Config — Daykeep

## Agent Reference Doc Mapping

Which agents should reference which doc categories:

- **frontend**: framework (nextjs, react), ui (shadcn-ui, tailwind), state (tanstack), validation (zod)
- **backend**: api (hono, trpc), database (drizzle, neon), auth (better-auth), validation (zod), runtime (bun)
- **tester**: runtime (bun), database (drizzle), api (trpc), testing (playwright)
- **reviewer**: none (read-only agent, does not need reference docs)

## Monorepo Package.json Locations

Scan all of these for dependencies:

- Root package.json
- apps/web/package.json
- apps/api/package.json
- apps/marketing/package.json
- apps/storybook/package.json
- packages/shared/package.json
- packages/database/package.json
- packages/auth/package.json
```

### 3d. Test the plugin

Invoke `/llmstxt-update` in Claude Code. Verify it:

- Scans all workspace package.json files
- Discovers and downloads llms.txt files to `docs/llms-txt/`
- Updates the CLAUDE.md reference docs table
- Updates agent files with correct doc references

### 3e. Remove the local skill file

```bash
rm -rf .claude/skills/llmstxt-update/
```

### 3f. Verify again

Run `/llmstxt-update` once more. It should work identically through the plugin. If it fails, check that the config file path is correct and the plugin is enabled in settings.json.

### 3g. Commit

```bash
git add .claude/settings.json .claude/llmstxt-manager.config.md
git rm -r .claude/skills/llmstxt-update/
git commit -m "chore: migrate llmstxt-update skill to llmstxt-manager plugin"
```

---

## 4. Step-by-Step: project-tracker

### 4a. Install the plugin

Add to `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "project-tracker@corbanbaxter/claude-workflow-plugins": true
  }
}
```

### 4b. Create the config file

Create `.claude/project-tracker.config.md` with Daykeep-specific settings:

> **Note:** The `.claude/project-tracker.config.md` file is a custom configuration pattern used by this workflow plugin -- not an official Claude Code plugin convention. Official plugins typically use environment variables and frontmatter in their `.claude-plugin/plugin.json` manifest.

```markdown
---
backlog_file: docs/BACKLOG.md
status_file: docs/STATUS.md
planning_dir: docs/planning
prd_template: default
scope_labels:
  - small
  - medium
  - large
commit_convention: conventional
---

# Project Tracker Config — Daykeep

## Status File Format

The Feature Build Progress table in STATUS.md uses these columns:

| Feature | PRD | Backend | Frontend | Tested | Deployed |

Values: Not Started, In Progress, Complete, N/A

## Suggested Build Order

The STATUS.md file contains a "Suggested Build Order" section that /work reads to determine
which features are ready to build next. Dependencies between features are expressed there.

## Scope Definitions

These scope labels are used in BACKLOG.md entries and PRDs:

- **small**: Single router + single page, no new DB tables
- **medium**: New DB table(s), multiple screens, possible external API
- **large**: New external service, significant schema changes, multiple agent domains

## PRD Format

PRDs follow the structure in docs/planning/. Each PRD includes:

- Overview, User Stories (per persona: Dad, Mom, Son 12, Daughter 4.5)
- Screens/Components, Data Model Changes, tRPC Routers
- External APIs/Services, Open Questions, Out of Scope (v1)

The next PRD number is determined by scanning docs/planning/ for the highest existing
number and incrementing. Check for gaps first (e.g., if 01-08 exist, next is 09).

## Context Files for /btw

When capturing a backlog idea, the skill scans these files for context:

- docs/STATUS.md — current build phase
- docs/planning/ — skim filenames for relevance
- docs/BACKLOG.md — check for duplicate/related entries
```

### 4c. Test the plugin skills

Test `/btw` first:

```
/btw "test migration entry — delete after verifying"
```

Verify it:

- Reads STATUS.md and planning docs for context
- Appends a structured entry to docs/BACKLOG.md
- Uses the correct scope labels and format

Then test `/plan-backlog`:

```
/plan-backlog
```

Verify it:

- Parses BACKLOG.md entries correctly
- Presents the triage menu
- Skip (choose S) to avoid making changes during testing

After testing, remove the test entry from BACKLOG.md.

### 4d. Remove local skill and command files

```bash
rm -rf .claude/skills/btw/
rm -rf .claude/skills/plan-backlog/
rm -f .claude/commands/btw.md
```

### 4e. Verify STATUS.md and BACKLOG.md access

Run `/btw "verify plugin reads backlog correctly"` and confirm the entry appears in `docs/BACKLOG.md` with proper formatting. Remove the test entry afterward.

### 4f. Commit

```bash
git add .claude/settings.json .claude/project-tracker.config.md
git rm -r .claude/skills/btw/ .claude/skills/plan-backlog/ .claude/commands/btw.md
git commit -m "chore: migrate btw and plan-backlog skills to project-tracker plugin"
```

---

## 5. Step-by-Step: agent-team-ops

This is the most involved migration. It touches hooks, agent files, and the `/work` orchestration pipeline.

### 5a. Install the plugin

Add to `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "agent-team-ops@corbanbaxter/claude-workflow-plugins": true
  }
}
```

### 5b. Create the config file

Create `.claude/agent-team-ops.config.md` with the full Daykeep configuration:

> **Note:** The `.claude/agent-team-ops.config.md` file is a custom configuration pattern used by this workflow plugin -- not an official Claude Code plugin convention. Official plugins typically use environment variables and frontmatter in their `.claude-plugin/plugin.json` manifest.

```markdown
---
test_command: "cd apps/api && bun test"
e2e_command: "cd apps/web && bunx playwright test"
protected_files:
  - "*.env"
  - "*.env.*"
  - "*/bun.lock"
formatter: "npx prettier --write"
agent_templates:
  - backend
  - frontend
  - reviewer
  - tester
commit_convention: conventional
shared_package: packages/shared
shared_package_owner: backend
branch_prefix_feature: "feat/"
branch_prefix_fix: "fix/"
status_file: docs/STATUS.md
backlog_file: docs/BACKLOG.md
planning_dir: docs/planning
---

# Agent Team Ops Config — Daykeep

## Project Context

Daykeep is a family dashboard kiosk app. Monorepo with Bun + Turborepo.
Next.js 15 web app (apps/web), Hono + tRPC API (apps/api), Neon Postgres + Drizzle (packages/database).

## Agent Domains

- **backend**: apps/api/, packages/database/, packages/auth/, packages/shared/ (owns shared writes)
- **frontend**: apps/web/
- **tester**: test files only (**tests**/, e2e/, _.test.ts, _.spec.ts)
- **reviewer**: read-only, no file edits

## Branch Setup

Feature branches: `feat/<feature-name>` (kebab-case)
Fix branches: `fix/<description>`

On branch creation:

1. Create git branch
2. Create Neon database branch (same name as git branch — required for cleanup workflow)
3. Push + open draft PR to main
4. Wait for Railway preview environment
5. Inject Neon branch DATABASE_URL into Railway preview (both web and api services)

## packages/shared/ Coordination Protocol

Backend agent owns all writes to packages/shared/ first.
Backend must SendMessage to frontend agent when shared types are committed.
Frontend waits for that message before importing from packages/shared/.

## Test Running Rules

Unit tests MUST run from apps/api/ — never from workspace root.
Why: bunfig.toml in apps/api/ configures the test preload (setup.ts).
Running from workspace root skips setup.ts and Neon client throws "No database connection string".

E2E tests require a running dev server with seeded data (bun db:seed first).

Specific test file: cd apps/api && bun test src/routers/**tests**/<file>.test.ts
Pattern match: cd apps/api && bun test --testNamePattern "<pattern>"

## Teammate Idle Rules

The tester agent must pass all unit tests before going idle.
The idle hook command:
```

cd apps/api && bun test > /tmp/daykeep-test-results.txt 2>&1; code=$?; tail -5 /tmp/daykeep-test-results.txt; if [ $code -ne 0 ]; then echo 'Unit tests are failing. Fix all failing tests before going idle.'; exit 2; fi

```

## Protected Files

These patterns are blocked from Edit/Write operations:
- *.env, *.env.* — secrets, never committed
- */bun.lock — generated lockfile, never hand-edited

## Auto-Format

After every Edit/Write, run: npx prettier --write "$CLAUDE_FILE_PATH"
Silently ignore failures (file types Prettier doesn't handle).

## CI Failure Handling

| Failure type | Action |
| --- | --- |
| Lint errors | Auto-fix, commit, push, re-watch |
| TypeScript type errors | Auto-fix, commit, push, re-watch |
| Single failing unit test | Diagnose, fix, commit, push, re-watch |
| E2E / build / logic errors | Stop and notify user with error summary |

## Post-Build

After all agents complete and CI passes:
1. Spawn reviewer agent for code review
2. Run code-simplifier on changed files
3. Fix blocker-severity issues
4. Convert draft PR to ready
5. Watch CI, handle failures per table above
6. Post GitHub PR URL + Railway preview URLs

## Memory Sweep

After CI passes, scan commits and teammate messages for new patterns.
Write confirmed patterns to memory files.
Update STATUS.md to mark feature columns as Complete.

## Ralph Loop Commands

For standalone grinding work (not full features), present these commands:

Test coverage:
/ralph-loop "Write unit tests for all tRPC routers in apps/api/src/routers/ that are missing coverage. Always run: cd apps/api && bun test. Mock all database calls. Test public, protected, and admin procedure auth levels. One commit per router tested. Output <promise>TESTS COMPLETE</promise> when all routers have passing tests." --max-iterations 20

Storybook stories:
/ralph-loop "Add .stories.tsx files for every component in apps/web/src/components/ that is missing one. Follow existing story patterns. Run bun storybook --ci after each iteration to verify. Output <promise>STORIES COMPLETE</promise> when all components have stories." --max-iterations 10

Schema tables:
/ralph-loop "Implement all remaining Drizzle tables from docs/planning/09-data-model.md in packages/database/src/schema.ts. Follow existing patterns (uuid PKs, createdAt/updatedAt, relations, indexes on foreign keys). Run bun db:generate after each change. Output <promise>SCHEMA COMPLETE</promise> when all tables match the spec and migrations generate cleanly." --max-iterations 15
```

### 5c. Run /init-agents to regenerate agent files

The plugin provides `/init-agents` which generates agent .md files from its templates, customized with values from the config file.

```
/init-agents
```

This generates new versions of:

- `.claude/agents/backend.md`
- `.claude/agents/frontend.md`
- `.claude/agents/reviewer.md`
- `.claude/agents/tester.md`

**Before accepting the generated files**, diff them against the current ones:

```bash
# init-agents writes to .claude/agents/ — diff before committing
git diff .claude/agents/
```

Review the diff carefully. The generated agents should be functionally equivalent to the current ones but with config-driven values instead of hardcoded Daykeep references. If you have added custom instructions to any agent file (beyond what the original template had), merge those customizations into the generated files manually.

After reviewing, keep the generated files. The project now owns these agent files locally — future customizations are made directly in `.claude/agents/`, not in the plugin templates.

### 5d. Test /work

```
/work
```

Verify it:

- Reads STATUS.md and parses the Feature Build Progress table
- Shows the READY TO BUILD / IN PROGRESS / STANDALONE TASKS menu
- Correctly identifies which features have incomplete columns
- Skip (choose S or a standalone task) to avoid spawning a full team during testing

### 5e. Migrate hooks from settings.json to plugin

The current `.claude/settings.json` has three hook sections. After installing agent-team-ops, the plugin provides these hooks via its `.claude-plugin/plugin.json` manifest. You need to remove the local hook definitions from settings.json to avoid duplication.

In the official plugin convention, hooks are defined in the plugin's `.claude-plugin/plugin.json` and reference shell scripts stored in the plugin's `hooks/` directory using `${CLAUDE_PLUGIN_ROOT}`:

```json
{
  "description": "Agent team operations — hooks for protected files, formatting, and test gates",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/protected-files.sh",
            "statusMessage": "Checking protected files"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-format.sh",
            "statusMessage": "Formatting with Prettier"
          }
        ]
      }
    ],
    "TeammateIdle": [
      {
        "matcher": "tester",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/tester-idle-gate.sh",
            "statusMessage": "Verifying unit tests pass before tester goes idle"
          }
        ]
      }
    ]
  }
}
```

The hook scripts (e.g., `hooks/protected-files.sh`, `hooks/auto-format.sh`, `hooks/tester-idle-gate.sh`) live inside the plugin's directory and contain the same logic that was previously inline in settings.json. Using `${CLAUDE_PLUGIN_ROOT}` ensures the paths resolve correctly regardless of where the plugin is installed.

**Before (current settings.json hooks section):**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "case \"$CLAUDE_FILE_PATH\" in *.env|*.env.*|*/bun.lock) echo 'BLOCK: Do not edit .env or lock files' && exit 1;; esac",
            "statusMessage": "Checking protected files"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write \"$CLAUDE_FILE_PATH\" 2>/dev/null || true",
            "statusMessage": "Formatting with Prettier"
          }
        ]
      }
    ],
    "TeammateIdle": [
      {
        "matcher": "tester",
        "hooks": [
          {
            "type": "command",
            "command": "cd apps/api && bun test > /tmp/daykeep-test-results.txt 2>&1; code=$?; tail -5 /tmp/daykeep-test-results.txt; if [ $code -ne 0 ]; then echo 'Unit tests are failing. Fix all failing tests before going idle.'; exit 2; fi",
            "statusMessage": "Verifying unit tests pass before tester goes idle"
          }
        ]
      }
    ]
  }
}
```

**After (hooks removed from settings.json -- plugin provides them via `.claude-plugin/plugin.json`):**

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "hooks": {},
  "enabledPlugins": {
    "llmstxt-manager@corbanbaxter/claude-workflow-plugins": true,
    "project-tracker@corbanbaxter/claude-workflow-plugins": true,
    "agent-team-ops@corbanbaxter/claude-workflow-plugins": true,
    "feature-dev@claude-code-plugins": true,
    "frontend-design@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true,
    "railway@railway-skills": true
  }
}
```

The `agent-team-ops` plugin defines its hooks in `.claude-plugin/plugin.json` using shell scripts in its `hooks/` directory. The hook behavior is identical to the old inline commands -- the logic is the same, just packaged as standalone scripts referenced via `${CLAUDE_PLUGIN_ROOT}` instead of hardcoded in settings.json. The plugin's config file (`.claude/agent-team-ops.config.md`) provides project-specific values that the hook scripts read at runtime.

### 5f. Remove local skill files

```bash
rm -rf .claude/skills/work/
rm -rf .claude/skills/run-tests/
```

### 5g. Keep agent .md files

Do NOT delete `.claude/agents/`. Those files are now locally owned by the project. They were generated once by `/init-agents` and can be customized freely. The plugin templates are the upstream source; the local files are the working copies.

### 5h. Verify the full workflow

Run through the complete pipeline:

1. `/btw "integration test idea"` — should work via project-tracker plugin
2. `/work` — should show dispatch menu via agent-team-ops plugin
3. Make a small edit to any `.ts` file — Prettier hook should fire (via plugin)
4. Try to edit a `.env` file — should be blocked (via plugin)
5. `/llmstxt-update` — should work via llmstxt-manager plugin

### 5i. Verify plugin manifests are detected

Confirm that all three plugins have valid `.claude-plugin/plugin.json` manifests and that Claude Code recognizes them:

1. Run `/help` in Claude Code and verify the plugin-provided skills (`/btw`, `/plan-backlog`, `/work`, `/run-tests`, `/init-agents`, `/llmstxt-update`) appear in the skill listings.
2. Make a small edit to a `.ts` file and confirm the Prettier hook fires (provided by the agent-team-ops plugin's `.claude-plugin/plugin.json`).
3. Attempt to edit a `.env` file and confirm it is blocked by the PreToolUse hook.

If any plugin does not appear, check that:

- The plugin directory contains a valid `.claude-plugin/plugin.json`
- The plugin identifier in `enabledPlugins` matches the installed plugin name
- The plugin was installed from the correct path (`corbanbaxter/claude-workflow-plugins/plugins/<name>`)

### 5j. Commit

```bash
git add .claude/settings.json .claude/agent-team-ops.config.md .claude/agents/
git rm -r .claude/skills/work/ .claude/skills/run-tests/
git commit -m "chore: migrate work, run-tests skills and hooks to agent-team-ops plugin"
```

---

## 6. CLAUDE.md Updates

After all three plugins are installed, update CLAUDE.md to reference plugins instead of local skills.

### Sections that change

**Agent Teams section** — Update the "Available Agents" note:

Before:

```markdown
### Available Agents (`.claude/agents/`)
```

After:

```markdown
### Available Agents (`.claude/agents/`, generated by agent-team-ops plugin)
```

**`/work` reference** — Update the description:

Before:

```markdown
### `/work` — Work Dispatcher

Run `/work` to pick up the next piece of work. It reads `docs/STATUS.md`...
```

After:

```markdown
### `/work` — Work Dispatcher (agent-team-ops plugin)

Run `/work` to pick up the next piece of work. Provided by the `agent-team-ops` plugin.
Reads `docs/STATUS.md`...
Config: `.claude/agent-team-ops.config.md`
```

**Commands section** — Add plugin reference:

Before:

````markdown
## Commands

```bash
bun dev              # Start all workspaces (web:3000, api:3002)
...
```
````

After:

````markdown
## Commands

```bash
bun dev              # Start all workspaces (web:3000, api:3002)
...
```
````

## Workflow Plugins

Three plugins from `corbanbaxter/claude-workflow-plugins` provide the project workflow:

| Plugin          | Skills                                | Config                              |
| --------------- | ------------------------------------- | ----------------------------------- |
| project-tracker | `/btw`, `/plan-backlog`               | `.claude/project-tracker.config.md` |
| agent-team-ops  | `/work`, `/run-tests`, `/init-agents` | `.claude/agent-team-ops.config.md`  |
| llmstxt-manager | `/llmstxt-update`, `/llmstxt-status`  | `.claude/llmstxt-manager.config.md` |

Hooks (protected files, auto-format, teammate idle gate) are provided by agent-team-ops
and configured in `.claude/agent-team-ops.config.md`.

````

**Reference Docs section** — Add note about llmstxt-manager:

Before:
```markdown
## Reference Docs (llms.txt)

Library documentation lives in `docs/llms-txt/`. Read the relevant file when you need API details...
Refresh with `bun setup:ai-docs` or run `/llmstxt-update` to discover new docs.
````

After:

```markdown
## Reference Docs (llms.txt)

Library documentation lives in `docs/llms-txt/`. Read the relevant file when you need API details...
Refresh with `/llmstxt-update` (provided by the llmstxt-manager plugin).
Config: `.claude/llmstxt-manager.config.md`
```

### Commit the CLAUDE.md update

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md to reference workflow plugins instead of local skills"
```

---

## 7. Rollback Plan

If anything breaks during or after migration, you can revert cleanly.

### Quick rollback: disable plugins, restore local files

```bash
# 1. Revert to the pre-migration state of the branch
git log --oneline  # find the commit before migration started
git revert HEAD~N..HEAD  # revert N migration commits (creates new commits, safe)

# Or if you want to just go back to main:
git checkout main
git branch -D chore/migrate-to-plugins
```

### Selective rollback: revert one plugin at a time

If only one plugin is causing issues, revert just its changes:

```bash
# Example: revert agent-team-ops but keep the other two
git revert <commit-hash-of-agent-team-ops-migration>
```

Then manually:

1. Remove the plugin from `enabledPlugins` in settings.json
2. Restore the local skill files from git history
3. Restore the hooks section in settings.json from git history

### Safety net: keep local files in a branch

Before deleting any local skill files, the migration branch preserves the full history. As long as you do not delete the branch (or the commits are on main), you can always recover:

```bash
# Recover a deleted file from before the migration
git show chore/migrate-to-plugins~3:.claude/skills/work/SKILL.md > .claude/skills/work/SKILL.md
```

### Recommended approach

1. Do all migration work on the `chore/migrate-to-plugins` branch
2. Test thoroughly on that branch
3. Only merge to main when all three plugins are verified working
4. Keep the branch for 2 weeks after merge as insurance
5. Delete the branch after you are confident everything works:

```bash
git branch -d chore/migrate-to-plugins
git push origin --delete chore/migrate-to-plugins
```

---

## 8. Post-Migration Cleanup

After all three plugins are installed, verified, and the migration branch is merged:

### 8a. Remove empty skill directories

```bash
# After removing all skill subdirectories, the parent should be empty
rmdir .claude/skills/ 2>/dev/null || echo "skills/ not empty — check for remaining files"
ls .claude/skills/ 2>/dev/null  # should show nothing or "No such file or directory"
```

If `.claude/skills/use-railway` (a symlink) still exists, leave it — that belongs to the Railway plugin, not to the workflow plugins.

```bash
# Only remove the skills dir if it's truly empty (no symlinks either)
# If use-railway symlink remains, the directory stays
ls -la .claude/skills/
```

### 8b. Remove the old btw command

The `.claude/commands/btw.md` file was already removed in step 4d. Verify:

```bash
ls .claude/commands/
# Should be empty or contain only non-workflow commands
```

### 8c. Verify no hook duplication

The most dangerous post-migration issue is hooks firing twice (once from the local settings.json, once from the plugin). Verify:

```bash
# Check settings.json has empty hooks
cat .claude/settings.json | grep -A 1 '"hooks"'
# Should show: "hooks": {}
```

Test by editing a TypeScript file — Prettier should run exactly once, not twice.

### 8d. Update documentation references

Search for any remaining references to local skills in documentation:

```bash
# Search docs/ for old skill paths
grep -r ".claude/skills/" docs/ || echo "No stale references found"
grep -r "local skill" docs/ || echo "No stale references found"
```

Update any hits to reference the plugin instead.

### 8e. Test the full /work pipeline end-to-end

This is the most comprehensive verification. Run `/work` and walk through at least Phase 1 (Orient) completely:

1. `/work` shows the correct dispatch menu
2. Feature status from STATUS.md is parsed correctly
3. Agent domain assignments match the config
4. Selecting a standalone task suggests the correct Ralph Loop command
5. (Optional) Select a real feature and verify the full Phase 2-6 pipeline

If all of this works, the migration is complete.

### 8f. Final commit

```bash
# Clean up any remaining empty directories
git add -A
git status  # verify only cleanup changes
git commit -m "chore: post-migration cleanup — remove empty skill directories"
```

---

## 9. Adapting for Other Projects

This section covers how a NEW project (not Daykeep) would adopt these plugins from scratch. No migration needed — just install and configure.

### Minimal setup

For a project that wants the full workflow:

```bash
# 1. Install all three plugins (note: plugins live under the plugins/ subdirectory)
claude plugin install corbanbaxter/claude-workflow-plugins/plugins/llmstxt-manager
claude plugin install corbanbaxter/claude-workflow-plugins/plugins/project-tracker
claude plugin install corbanbaxter/claude-workflow-plugins/plugins/agent-team-ops
```

Or add them to `.claude/settings.json` manually:

```json
{
  "enabledPlugins": {
    "llmstxt-manager@corbanbaxter/claude-workflow-plugins": true,
    "project-tracker@corbanbaxter/claude-workflow-plugins": true,
    "agent-team-ops@corbanbaxter/claude-workflow-plugins": true
  }
}
```

### One-time initialization

```
# Generate project-specific agent files from templates
/init-agents

# Scan dependencies and download llms.txt reference docs
/llmstxt-update
```

The `/init-agents` command will create `.claude/agents/` with backend, frontend, reviewer, and tester agents customized for the project's config.

After installation, verify each plugin is recognized by checking that its `.claude-plugin/plugin.json` manifest is detected -- the plugin skills should appear in `/help` or skill listings.

### Required project files

The plugins expect these files to exist (they will tell you if they are missing):

| File              | Created by                                         | Purpose                         |
| ----------------- | -------------------------------------------------- | ------------------------------- |
| `docs/STATUS.md`  | You (or `/init-tracker` if the plugin provides it) | Feature build progress tracking |
| `docs/BACKLOG.md` | You                                                | Ideas and future features       |
| `docs/planning/`  | `/plan-backlog` creates PRDs here                  | PRD documents                   |
| `CLAUDE.md`       | You                                                | Project instructions            |

### Config files to create

Each plugin reads from a markdown config file. Create them based on your project:

> **Note:** These `.config.md` files are a custom configuration pattern used by these workflow plugins -- not an official Claude Code plugin convention. Official plugins typically use environment variables and frontmatter in their `.claude-plugin/plugin.json` manifest.

#### `.claude/project-tracker.config.md` (minimal)

```markdown
---
backlog_file: docs/BACKLOG.md
status_file: docs/STATUS.md
planning_dir: docs/planning
prd_template: default
scope_labels:
  - small
  - medium
  - large
---

# Project Tracker Config

## Status File Format

| Feature | PRD | Backend | Frontend | Tested | Deployed |
```

#### `.claude/agent-team-ops.config.md` (minimal)

```markdown
---
test_command: "npm test"
e2e_command: "npx playwright test"
protected_files:
  - "*.env"
  - "*.env.*"
  - "package-lock.json"
formatter: "npx prettier --write"
agent_templates:
  - backend
  - frontend
  - reviewer
  - tester
commit_convention: conventional
---

# Agent Team Ops Config

## Agent Domains

- **backend**: src/api/, src/db/, src/models/
- **frontend**: src/pages/, src/components/, src/styles/
- **tester**: test files only (**tests**/, e2e/, _.test.ts, _.spec.ts)
- **reviewer**: read-only, no file edits
```

#### `.claude/llmstxt-manager.config.md` (minimal)

```markdown
---
docs_dir: docs/llms-txt
download_script: scripts/download-ai-docs.ts
claude_md: CLAUDE.md
agents_dir: .claude/agents
skip_packages:
  - "@types/*"
prefer_full: true
---

# LLMs.txt Manager Config

## Agent Reference Doc Mapping

- **frontend**: framework, ui, state
- **backend**: api, database, validation
- **tester**: testing, database
- **reviewer**: none
```

### Example: Express + PostgreSQL project

Here is what a simple Express + PostgreSQL project would look like after adopting the plugins.

#### Project structure

```
my-api/
  src/
    routes/
    models/
    middleware/
  tests/
  e2e/
  docs/
    STATUS.md
    BACKLOG.md
    planning/
    llms-txt/
  .claude/
    settings.json
    agents/
      backend.md      (generated by /init-agents)
      frontend.md     (generated by /init-agents — may be N/A for API-only)
      reviewer.md     (generated by /init-agents)
      tester.md       (generated by /init-agents)
    project-tracker.config.md     (custom config — not official plugin convention)
    agent-team-ops.config.md      (custom config — not official plugin convention)
    llmstxt-manager.config.md     (custom config — not official plugin convention)
  CLAUDE.md
  package.json
```

Each installed plugin contains a `.claude-plugin/plugin.json` manifest in its own directory (managed by the plugin system, not by the project).

#### `.claude/settings.json`

```json
{
  "hooks": {},
  "enabledPlugins": {
    "llmstxt-manager@corbanbaxter/claude-workflow-plugins": true,
    "project-tracker@corbanbaxter/claude-workflow-plugins": true,
    "agent-team-ops@corbanbaxter/claude-workflow-plugins": true
  }
}
```

#### `.claude/agent-team-ops.config.md`

```markdown
---
test_command: "npm test"
e2e_command: "npx jest --config jest.e2e.config.js"
protected_files:
  - "*.env"
  - "*.env.*"
  - "package-lock.json"
formatter: "npx prettier --write"
agent_templates:
  - backend
  - tester
  - reviewer
commit_convention: conventional
---

# Agent Team Ops Config — My API

## Project Context

Express 5 API with PostgreSQL. Single-package repo (no monorepo).
Sequelize ORM. Jest for unit tests, Supertest for integration.

## Agent Domains

- **backend**: src/ (routes, models, middleware, services)
- **tester**: tests/, e2e/
- **reviewer**: read-only

No frontend agent needed — this is an API-only project.

## Test Running Rules

Unit tests: npm test (runs Jest from project root)
E2E tests: npx jest --config jest.e2e.config.js (requires running server)

## Teammate Idle Rules

Tester must pass all unit tests before going idle.
```

#### Workflow after setup

```
/btw "add rate limiting to auth endpoints"     # Captures idea to backlog
/plan-backlog                                    # Triages backlog, writes PRD
/work                                            # Dispatches agent team to build
/llmstxt-update                                  # Refreshes reference docs
```

The plugins handle all the workflow orchestration. The project only needs to maintain its config files, CLAUDE.md, STATUS.md, BACKLOG.md, and the generated agent files.

### Partial adoption

Not every project needs all three plugins. They are independent:

- **Just backlog tracking?** Install only `project-tracker`. Get `/btw` and `/plan-backlog`.
- **Just reference docs?** Install only `llmstxt-manager`. Get `/llmstxt-update`.
- **Full workflow?** Install all three. The `/work` skill in `agent-team-ops` will automatically detect and use the other plugins when they are available.
