# Plugin Extraction Guide

This guide tells a Claude agent how to extract three reusable Claude Code plugins from the Daykeep project's workflow tooling and publish them in a single marketplace repo.

## What This Guide Produces

Three Claude Code plugins, packaged in `corbanbaxter/claude-workflow-plugins/`, that any project can install to get the same workflow automation currently hardcoded into Daykeep's `.claude/` directory:

1. **project-tracker** -- Backlog capture, triage, PRD generation, status tracking
2. **agent-team-ops** -- Feature dispatching, agent templates, test running, hooks
3. **llmstxt-manager** -- Dependency scanning, llms.txt discovery, download, reference updates

After extraction, Daykeep itself becomes a consumer of these plugins rather than the owner of their source code.

## Why Extract

- The workflow patterns (backlog capture, agent teams, llms.txt management) are project-agnostic. Other repos can use them.
- Keeping workflow logic in a separate repo allows versioning, testing, and sharing independently of any single project.
- Plugin consumers get updates without copy-pasting skill files between repos.

## Architecture Overview

```
corbanbaxter/claude-workflow-plugins/
├── .claude-plugin/
│   └── marketplace.json      # Registry of all 3 plugins (schema: anthropic.com/claude-code/marketplace.schema.json)
├── plugins/
│   ├── project-tracker/      # Plugin 1
│   ├── agent-team-ops/       # Plugin 2
│   └── llmstxt-manager/      # Plugin 3
├── LICENSE                   # Apache 2.0
└── README.md
```

The root `.claude-plugin/marketplace.json` registers all plugins for Claude Code's marketplace discovery. Each plugin listed includes `category`, `tags`, `source`, `homepage`, and `version` metadata.

Each plugin is a self-contained Claude Code plugin following the official plugin directory structure (see below). Plugins are independent -- installing one does not require the others -- but they complement each other:

```
llmstxt-manager          (standalone, no deps on other plugins)
       |
project-tracker          (standalone, no deps on other plugins)
       |
agent-team-ops           (references project-tracker skills for /work dispatch,
                          references llmstxt-manager for agent reference docs)
```

`agent-team-ops` has soft dependencies: it works without the other two, but its `/work` skill can invoke `project-tracker`'s `/plan-backlog` when the build queue is empty, and its agent templates reference docs managed by `llmstxt-manager`. These are graceful fallbacks, not hard requirements.

## Official Plugin Directory Structure

Each plugin follows the conventions from [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official):

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required manifest (see below)
├── commands/                 # Slash commands (auto-discovered)
│   └── command-name.md
├── skills/                   # Autonomous capabilities (auto-discovered)
│   └── skill-name/
│       └── SKILL.md
├── agents/                   # Spawned AI agents (auto-discovered)
│   └── agent-name.md
├── hooks/                    # Lifecycle hooks
│   ├── hooks.json
│   └── *.sh                 # Hook scripts
├── LICENSE                   # Apache 2.0
└── README.md
```

**Key points:**

- The manifest lives at `.claude-plugin/plugin.json` inside each plugin directory, not at the plugin root.
- Claude auto-discovers `commands/`, `skills/`, `agents/`, and `hooks/` from the directory structure. The manifest does NOT need `skills`, `commands`, `agents`, or `hooks` arrays.
- Hook shell scripts use `${CLAUDE_PLUGIN_ROOT}` for path resolution.
- Each plugin must include a `LICENSE` (Apache 2.0) and `README.md`.

### plugin.json Schema

The manifest is minimal -- only `name`, `description`, and `author` are required:

```json
{
  "name": "project-tracker",
  "description": "Backlog capture, triage, PRD generation, and status tracking for Claude Code projects",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

`version` is optional in `plugin.json`. Version metadata for marketplace purposes goes in the root `marketplace.json` instead.

### Frontmatter Conventions

**Command frontmatter** (in `commands/*.md`):

```yaml
---
description: Short description of the command
argument-hint: "<required-arg>" # optional
allowed-tools: "Edit,Write,Bash" # optional, restricts tool access
model: "opus" # optional, request a specific model
---
```

**Skill frontmatter** (in `skills/*/SKILL.md`):

```yaml
---
name: skill-name
description: What the skill does
version: "1.0.0" # optional
license: Apache-2.0 # optional
disable-model-invocation: false # optional
user-invocable: true # optional
---
```

**Agent frontmatter** (in `agents/*.md`):

```yaml
---
name: agent-name
description: What the agent does
model: "sonnet" # which model to use
---
```

## Plugin Map

### Plugin 1: project-tracker

| Component         | Type            | Source in Daykeep                                                 |
| ----------------- | --------------- | ----------------------------------------------------------------- |
| `/btw`            | Command + Skill | `.claude/commands/btw.md`, `.claude/skills/btw/SKILL.md`          |
| `/plan-backlog`   | Skill           | `.claude/skills/plan-backlog/SKILL.md`                            |
| `/prd-generate`   | Skill (new)     | Logic currently embedded in plan-backlog Step 4                   |
| SessionStart hook | Hook            | New -- reads STATUS.md on session start, prints current phase     |
| Status tracking   | Convention      | Operates on `docs/STATUS.md` and `docs/BACKLOG.md` (user's files) |

### Plugin 2: agent-team-ops

| Component               | Type              | Source in Daykeep                                                      |
| ----------------------- | ----------------- | ---------------------------------------------------------------------- |
| `/work`                 | Skill             | `.claude/skills/work/SKILL.md`                                         |
| `/run-tests`            | Skill             | `.claude/skills/run-tests/SKILL.md`                                    |
| `/init-agents`          | Command (new)     | Generates agent .md files from templates on first setup                |
| Agent templates         | Templates         | `.claude/agents/backend.md`, `frontend.md`, `reviewer.md`, `tester.md` |
| Protected files hook    | PreToolUse hook   | `.claude/settings.json` hooks.PreToolUse                               |
| Auto-format hook        | PostToolUse hook  | `.claude/settings.json` hooks.PostToolUse                              |
| Teammate idle test gate | TeammateIdle hook | `.claude/settings.json` hooks.TeammateIdle                             |

### Plugin 3: llmstxt-manager

| Component         | Type           | Source in Daykeep                                              |
| ----------------- | -------------- | -------------------------------------------------------------- |
| `/llmstxt-update` | Skill          | `.claude/skills/llmstxt-update/SKILL.md`                       |
| `/llmstxt-status` | Command (new)  | Shows current state of docs/llms-txt/ vs dependencies          |
| Download script   | Generated file | `scripts/download-ai-docs.ts` (generated/updated by the skill) |

## How to Use This Guide

Build the plugins in this order (simplest to most complex):

| Order | Doc                                            | Covers                                                                              |
| ----- | ---------------------------------------------- | ----------------------------------------------------------------------------------- |
| 1     | [01-project-tracker.md](01-project-tracker.md) | Backlog capture, triage, PRD generation, status tracking, SessionStart hook         |
| 2     | [02-agent-team-ops.md](02-agent-team-ops.md)   | Feature dispatch, agent templates, /init-agents, test running, all three hook types |
| 3     | [03-llmstxt-manager.md](03-llmstxt-manager.md) | Dep scanning, llms.txt discovery and download, reference updating, /llmstxt-status  |
| 4     | [04-dev-workflow.md](04-dev-workflow.md)       | Repo setup, local testing, manifest format, publishing to marketplace               |
| 5     | [05-migration-guide.md](05-migration-guide.md) | How to migrate Daykeep from inline skills/hooks to consuming the published plugins  |

Each doc is self-contained. The building agent should read 04 (dev workflow) first to understand the repo structure and manifest format, then build plugins in order 3, 1, 2.

**Recommended build order: llmstxt-manager first** (smallest surface area, no agent templates, no hooks), **then project-tracker** (skills + commands + one hook, no agent templates), **then agent-team-ops** (skills + commands + hooks + agent templates + the `/work` orchestration logic).

## What Stays Project-Specific vs What Gets Extracted

### Extracted into plugins (generic, reusable)

- Skill logic (the workflow steps, menu formats, file update patterns)
- Command stubs that invoke skills
- Hook definitions (protected files, auto-format, teammate idle gate)
- Agent templates (generic backend/frontend/reviewer/tester skeletons)
- llms.txt discovery and download logic

### Stays in each consuming project (project-specific)

| Item                                       | Why it stays                                                                            |
| ------------------------------------------ | --------------------------------------------------------------------------------------- |
| `docs/STATUS.md` content                   | Every project has different features and build phases                                   |
| `docs/BACKLOG.md` content                  | Every project has different ideas                                                       |
| `docs/planning/*.md` PRDs                  | Generated per-project by the plugin, but owned by the project                           |
| `CLAUDE.md` content                        | Project-specific instructions, tech stack, conventions                                  |
| `.claude/agents/*.md` (after /init-agents) | Generated once from templates, then customized per-project                              |
| Memory files                               | Accumulated project-specific patterns and decisions                                     |
| `docs/llms-txt/*.txt` files                | Downloaded per-project based on that project's dependencies                             |
| `scripts/download-ai-docs.ts`              | Generated per-project by llmstxt-manager                                                |
| Hook command details                       | e.g., which test command to run, which files to protect -- configured via plugin config |

## Config Pattern: Markdown Config Files (Custom Convention)

> **Note:** Official plugins in `anthropics/claude-plugins-official` do not use `.config.md` files. This is a custom pattern for our workflow plugins that provides richer per-project configuration. It is not part of the official Claude Code plugin spec.

Each plugin reads its configuration from a markdown file with YAML frontmatter at `.claude/<plugin-name>.config.md`. This pattern was chosen because:

- Claude agents already parse markdown natively
- YAML frontmatter provides structured key-value config
- The markdown body provides free-form context the agent can reason about
- No JSON schema validation needed -- the agent interprets the config
- Users can add comments and explanations inline

### Example: `.claude/project-tracker.config.md`

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

The Feature Build Progress table uses these columns:
| Feature | PRD | Backend | Frontend | Tested | Deployed |

## Scope Definitions

- **small**: Single router + single page, no new DB tables
- **medium**: New DB table(s), multiple screens, possible external API
- **large**: New external service, significant schema changes, multiple agent domains
```

### Example: `.claude/agent-team-ops.config.md`

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
---

# Agent Team Ops Config

## Branch Naming

Feature branches: `feat/<feature-name>`
Fix branches: `fix/<description>`

## packages/shared/ Coordination

Backend agent owns all writes to the shared package first.
Backend must message frontend when shared types are committed.
Frontend waits for that message before importing from shared.

## Teammate Idle Rules

The tester agent must pass all unit tests before going idle.
If tests fail, the tester must fix them -- it cannot claim "done" with failures.
```

### Example: `.claude/llmstxt-manager.config.md`

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
prefer_full: true
---

# LLMs.txt Manager Config

## Agent Reference Doc Mapping

Which agents should reference which doc categories:

- **frontend**: framework, ui, state, validation
- **backend**: api, database, auth, validation, runtime
- **tester**: runtime, database, api, testing
- **reviewer**: none (read-only agent)
```

When a config file does not exist, the plugin uses sensible defaults and optionally creates the config file on first run.

## File Mapping: Daykeep Source to Plugin Destination

This table maps every relevant file in the current Daykeep `.claude/` directory to where it ends up after extraction.

| Current Daykeep Path                     | Plugin          | Destination in Plugin Repo                               | Notes                                                                                                   |
| ---------------------------------------- | --------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `.claude/skills/btw/SKILL.md`            | project-tracker | `plugins/project-tracker/skills/btw/SKILL.md`            | Generalized (remove Daykeep-specific scope definitions)                                                 |
| `.claude/commands/btw.md`                | project-tracker | `plugins/project-tracker/commands/btw.md`                | Unchanged                                                                                               |
| `.claude/skills/plan-backlog/SKILL.md`   | project-tracker | `plugins/project-tracker/skills/plan-backlog/SKILL.md`   | Generalized                                                                                             |
| `.claude/skills/work/SKILL.md`           | agent-team-ops  | `plugins/agent-team-ops/skills/work/SKILL.md`            | Heavily generalized -- remove Daykeep-specific agent prompts, Railway/Neon references; read from config |
| `.claude/skills/run-tests/SKILL.md`      | agent-team-ops  | `plugins/agent-team-ops/skills/run-tests/SKILL.md`       | Generalized -- test command comes from config                                                           |
| `.claude/agents/backend.md`              | agent-team-ops  | `plugins/agent-team-ops/templates/backend.md`            | Template with placeholders, not a ready-to-use agent                                                    |
| `.claude/agents/frontend.md`             | agent-team-ops  | `plugins/agent-team-ops/templates/frontend.md`           | Template with placeholders                                                                              |
| `.claude/agents/reviewer.md`             | agent-team-ops  | `plugins/agent-team-ops/templates/reviewer.md`           | Template with placeholders                                                                              |
| `.claude/agents/tester.md`               | agent-team-ops  | `plugins/agent-team-ops/templates/tester.md`             | Template with placeholders                                                                              |
| `.claude/settings.json` (hooks section)  | agent-team-ops  | `plugins/agent-team-ops/hooks/`                          | Hooks extracted; commands read from config instead of hardcoded                                         |
| `.claude/skills/llmstxt-update/SKILL.md` | llmstxt-manager | `plugins/llmstxt-manager/skills/llmstxt-update/SKILL.md` | Generalized -- paths and agent mapping come from config                                                 |
| `scripts/download-ai-docs.ts`            | llmstxt-manager | Not in plugin -- generated per-project                   | The skill generates/updates this file in the consuming project                                          |
| (new)                                    | project-tracker | `plugins/project-tracker/.claude-plugin/plugin.json`     | Required manifest -- name, description, author only                                                     |
| (new)                                    | agent-team-ops  | `plugins/agent-team-ops/.claude-plugin/plugin.json`      | Required manifest -- name, description, author only                                                     |
| (new)                                    | llmstxt-manager | `plugins/llmstxt-manager/.claude-plugin/plugin.json`     | Required manifest -- name, description, author only                                                     |
| (new)                                    | all             | `plugins/*/LICENSE`                                      | Apache 2.0 license required per official convention                                                     |
| (new)                                    | all             | `plugins/*/README.md`                                    | Plugin readme required per official convention                                                          |
| (new)                                    | repo root       | `.claude-plugin/marketplace.json`                        | Marketplace registry listing all 3 plugins with category, tags, source, homepage, version               |

## Key Design Decisions

1. **Single repo, three plugins.** Easier to maintain, test, and version together. Each plugin has its own `.claude-plugin/plugin.json` manifest and can be installed independently. The root `.claude-plugin/marketplace.json` registers all three for marketplace discovery.

2. **Official structure, custom config.** Plugin directory layout (`commands/`, `skills/`, `agents/`, `hooks/`, `.claude-plugin/plugin.json`) follows the `anthropics/claude-plugins-official` conventions exactly. The `.config.md` pattern is our custom addition for richer per-project configuration -- it is not part of the official spec.

3. **Minimal manifests.** Each `plugin.json` contains only `name`, `description`, and `author`. Claude auto-discovers commands, skills, agents, and hooks from the directory structure -- no need to enumerate them in the manifest.

4. **Templates, not copies.** Agent .md files are templates in the plugin. `/init-agents` generates project-specific agents from them once. After that, the project owns the agent files and can customize freely.

5. **Soft dependencies between plugins.** `agent-team-ops` can call `project-tracker`'s `/plan-backlog` if installed, but works without it (just skips the auto-triage step). Same for llmstxt-manager references in agent templates.

6. **Config-driven hooks.** The current Daykeep hooks hardcode `bun test`, `prettier`, and specific protected file patterns. The plugins read these from config so any project can define its own test command, formatter, and protected file list. Hook scripts use `${CLAUDE_PLUGIN_ROOT}` for path resolution.

7. **Build order: 3, 1, 2.** `llmstxt-manager` has the smallest surface area (two skills, no hooks, no agent templates). `project-tracker` adds hooks and the backlog/PRD workflow. `agent-team-ops` is the most complex (orchestration, agent templates, three hook types, cross-plugin references).
