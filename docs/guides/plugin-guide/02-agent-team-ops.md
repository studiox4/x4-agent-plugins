# Plugin 2: x4-agent-team-ops

Full specification for the `x4-agent-team-ops` Claude Code plugin. This is the most complex of the three plugins -- it extracts agent team coordination, feature dispatching, test running, review cycles, and hook-based guardrails into a project-agnostic system driven by a single config file.

---

## 1. Overview

The `x4-agent-team-ops` plugin provides:

- **`/work`** -- A 7-phase feature dispatch pipeline: orient, setup, build (agent team), review, ship, memory sweep, cleanup.
- **`/run-tests`** -- Runs unit and e2e test commands defined in config.
- **`/init-agents`** -- Generates project-specific agent `.md` files from bundled templates, using `CLAUDE.md` analysis to fill in project details.
- **`/init-setup`** -- Interactive wizard for configuring project tooling (test commands, formatters, CI provider, DB branching, etc.).
- **`/verify-local`** -- Verification gate with auto-fix: runs all configured test commands, lint, and typecheck locally, auto-fixing failures where possible.
- **`/pr-create`** -- Creates a PR from the current branch with conventional title and body derived from commits and PRD.
- **`/pr-status`** -- Checks CI status, review state, and merge readiness for the current PR.
- **`/pr-cleanup`** -- Cleans up after merge: deletes local/remote branch, database branch (if configured), and archives the PRD.
- **5 agent templates** -- Generic backend, frontend, reviewer, tester, and performance agents that read their domain boundaries from config.
- **3 hook types** -- PreToolUse (protected files), PostToolUse (auto-format), TeammateIdle (test gate).

Everything is config-driven. No project-specific paths, commands, or service names are hardcoded into the plugin. The plugin reads `.claude/agent-team.config.md` for all project-specific values.

### Soft dependencies

- If `x4-project-tracker` plugin is installed, `/work` Phase 1 can invoke `/plan-backlog` when the build queue is empty. Without it, `/work` simply tells the user there is nothing ready to build.
- If `x4-llmstxt-manager` plugin is installed, generated agent files include a "Reference Docs" section pointing to managed docs. Without it, agents skip that section.

---

## 2. Plugin Manifest

**File: `agent-team-ops/.claude-plugin/plugin.json`**

The manifest lives inside `.claude-plugin/` per the official plugins repo convention. It contains only identity metadata -- skills, commands, agents, and hooks are discovered by directory convention, not listed explicitly.

```json
{
  "name": "x4-agent-team-ops",
  "description": "Agent team coordination, feature dispatching, test running, review cycles, and hook-based guardrails for multi-agent development workflows",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

---

## 3. Directory Structure

```
agent-team-ops/
├── .claude-plugin/
│   └── plugin.json              # Minimal manifest (identity only)
├── commands/
│   ├── work.md                  # User-facing command stub for /work
│   └── init-agents.md           # Generates project-specific agents from templates
├── skills/
│   ├── work/
│   │   └── SKILL.md             # 7-phase feature dispatch pipeline
│   └── run-tests/
│       └── SKILL.md             # Config-driven test runner
├── agents/
│   ├── backend.md               # Template: backend agent
│   ├── frontend.md              # Template: frontend agent
│   ├── reviewer.md              # Template: reviewer agent
│   ├── tester.md                # Template: tester agent
│   └── performance.md           # Template: performance agent (read-only)
├── hooks/
│   ├── hooks.json               # PreToolUse, PostToolUse, TeammateIdle
│   ├── protected-files.sh       # Blocks edits to protected file patterns
│   ├── auto-format.sh           # Runs formatter after Edit/Write
│   └── teammate-idle.sh         # Runs test gate when teammate goes idle
├── LICENSE
└── README.md
```

---

## 4. Config Schema

**File (in consuming project): `.claude/agent-team.config.md`**

> **Note:** The `.claude/agent-team.config.md` config file is a custom pattern specific to this plugin. The official Claude Code plugins convention does not prescribe a config mechanism -- plugins are free to define their own. This plugin uses a Markdown file with YAML frontmatter so that it is both human-readable and parseable by shell scripts and hook commands.

This is the single source of truth for all project-specific values. The plugin reads this file at the start of every skill invocation. If the file does not exist, the plugin uses the defaults shown below and offers to create it.

### Complete template with all options

```markdown
---
# ============================================================
# Agent Team Ops Configuration
# ============================================================
# All paths are relative to the repository root.
# Optional sections can be omitted entirely -- defaults apply.

# ------ Agent Domains ------
# Maps each agent role to the directories it owns.
# Agents will only edit files within their owned directories.
# The "shared" key defines packages that require coordination.
agents:
  backend:
    owns:
      - "apps/api"
      - "packages/database"
      - "packages/auth"
    model: sonnet
  frontend:
    owns:
      - "apps/web"
    model: sonnet
  reviewer:
    owns: [] # Read-only -- owns nothing
    model: sonnet
    read_only: true
  performance:
    owns: [] # Read-only -- owns nothing
    model: sonnet
    read_only: true
  tester:
    owns:
      - "**/__tests__/**"
      - "**/*.test.*"
      - "**/*.spec.*"
      - "**/e2e/**"
    model: sonnet

# ------ Shared Package Coordination ------
# Directories that multiple agents may need to touch.
# owner: which agent writes first
# notify: which agents wait for the owner to finish
shared_packages:
  - path: "packages/shared"
    owner: backend
    notify:
      - frontend

# ------ Test Commands ------
# Commands the plugin runs for /run-tests and verification gates.
# Each key is a test type. "unit" and "e2e" are the standard types.
# Additional types (lint, typecheck, etc.) are optional.
test_commands:
  unit: "cd apps/api && bun test"
  e2e: "cd apps/web && bunx playwright test"
  lint: "bun lint"
  typecheck: "bun typecheck"

# ------ Protected Files ------
# Glob patterns for files that should NEVER be edited by agents.
# The PreToolUse hook blocks Edit/Write operations on these patterns.
protected_files:
  - "*.env"
  - "*.env.*"
  - "*/bun.lock"
  - "*/package-lock.json"
  - "*/yarn.lock"
  - "*/pnpm-lock.yaml"

# ------ Formatter ------
# Command to auto-format files after every Edit/Write.
# $FILE is replaced with the actual file path.
# Set to "" or omit to disable auto-formatting.
formatter: "npx prettier --write $FILE"

# ------ Branch Strategy ------
# Prefix patterns for git branch names.
branch_prefixes:
  feature: "feat/"
  fix: "fix/"
  chore: "chore/"

# ------ Status File ------
# Path to the project status/tracker file that /work reads.
# Must contain a "Feature Build Progress" table (or equivalent).
status_file: "docs/STATUS.md"

# ------ CI / Preview Settings (optional) ------
# If omitted, /work skips CI watching and preview URL reporting.
ci:
  provider: "github-actions" # github-actions | gitlab-ci | circleci | none
  watch_command: "gh run watch" # Command to watch CI status after push
  # preview_url_command: Command that outputs preview URLs after deploy.
  # Example for Railway:
  #   preview_url_command: "railway status --json | jq -r '.services[].url'"
  # Example for Vercel:
  #   preview_url_command: "vercel inspect --json | jq -r '.url'"
  # Omit if no preview environments are configured.
  preview_url_command: ""

# ------ DB Branching (optional) ------
# If omitted, /work skips database branch creation/cleanup.
# Supported providers: neon, planetscale, none
db_branching:
  provider: "neon"
  # create_command: MCP tool call or CLI command to create a DB branch.
  # The string {branch_name} is replaced with the git branch name.
  create_command: "mcp__Neon__create_branch with branch name {branch_name}"
  # env_var: The environment variable to inject with the new branch's connection string.
  env_var: "DATABASE_URL"
  # cleanup: How DB branches are cleaned up.
  # "github-action" = GitHub Actions deletes on PR close (user provides the action)
  # "manual" = user deletes manually
  # "none" = no cleanup mentioned
  cleanup: "github-action"

# ------ PR Settings ------
pr:
  draft: true # Open PRs as draft initially
  convert_on_ship: true # Convert draft to ready in Ship phase
  # labels: Labels to apply to PRs (optional)
  labels: []

# ------ Teammate Idle Rules ------
# Commands to run when a teammate goes idle.
# If the command exits non-zero, the teammate is told to fix the issue.
# $AGENT_ROLE is replaced with the agent's role name.
teammate_idle_gates:
  tester: "cd apps/api && bun test"
---

# Agent Team Ops Config

## Build Team Composition

The standard build team for a feature is: **backend**, **frontend**, **tester**.
The **reviewer** is spawned after the build team finishes.

Adjust the agent list above to match your project. For a frontend-only project,
you might only have `frontend`, `tester`, and `reviewer`. For a CLI tool, you
might replace `frontend` with a `cli` agent.

## Shared Package Coordination Protocol

When a shared package is configured:

1. The **owner** agent makes all changes to the shared package first.
2. The owner sends a message to the **notify** agents: "Shared types updated in {path} -- you can now import from it."
3. The notified agents wait for this message before importing from the shared package.
4. If both agents need to change the shared package, the owner goes first and the other agent requests changes through the owner.

## Teammate Idle Rules

When a teammate goes idle (signals it has completed its work), the idle gate
command runs. If it fails (non-zero exit), the teammate receives the output
and must fix the issue before it can truly go idle.

This is most commonly used for the tester agent: it must pass all tests before
claiming "done." But you can add gates for any agent role.

## Verification Gate

Before the Ship phase, ALL configured test commands must pass. The verification
gate runs each test type in sequence:

1. Unit tests
2. E2E tests (if configured)
3. Lint (if configured)
4. Typecheck (if configured)

All must pass with evidence (command output shown) before proceeding to Ship.

## Post-Ship Reporting

After pushing and CI passes, always report:

- GitHub PR URL
- Preview environment URLs (if CI preview_url_command is configured)
```

### Config defaults (when no config file exists)

| Key                       | Default                                                                                                                                                                                                         |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `agents`                  | `{ backend: { owns: ["src/"], model: "sonnet" }, frontend: { owns: ["src/"], model: "sonnet" }, reviewer: { owns: [], model: "sonnet", read_only: true }, tester: { owns: ["**/*.test.*"], model: "sonnet" } }` |
| `shared_packages`         | `[]`                                                                                                                                                                                                            |
| `test_commands.unit`      | `"npm test"`                                                                                                                                                                                                    |
| `test_commands.e2e`       | `""` (disabled)                                                                                                                                                                                                 |
| `protected_files`         | `["*.env", "*.env.*"]`                                                                                                                                                                                          |
| `formatter`               | `""` (disabled)                                                                                                                                                                                                 |
| `branch_prefixes.feature` | `"feat/"`                                                                                                                                                                                                       |
| `branch_prefixes.fix`     | `"fix/"`                                                                                                                                                                                                        |
| `status_file`             | `"docs/STATUS.md"`                                                                                                                                                                                              |
| `ci`                      | not set (skipped)                                                                                                                                                                                               |
| `db_branching`            | not set (skipped)                                                                                                                                                                                               |
| `pr.draft`                | `true`                                                                                                                                                                                                          |
| `teammate_idle_gates`     | `{}` (none)                                                                                                                                                                                                     |

---

## 5. `/init-agents` Command

**File: `agent-team-ops/commands/init-agents.md`**

```markdown
---
description: Generate project-specific agent files from templates. Reads CLAUDE.md to fill in project details.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /init-agents

Generate project-specific agent `.md` files in `.claude/agents/` from the
bundled agent templates. This command should be run once during project setup.

## Steps

1. **Read config.** Read `.claude/agent-team.config.md`. If it does not exist,
   create it with defaults and ask the user to review before continuing.

2. **Read CLAUDE.md.** Parse the project's `CLAUDE.md` to extract:
   - Tech stack (languages, frameworks, libraries)
   - Monorepo structure (if any)
   - Key conventions (naming, patterns, tooling)
   - Path aliases
   - Package manager (npm, yarn, pnpm, bun)
   - Existing commands (dev, build, test, lint)

3. **Check for existing agents.** If `.claude/agents/` already contains agent
   files, ask the user whether to overwrite or skip each one.

4. **Generate agent files.** For each agent role defined in `agents` config:
   a. Read the corresponding template from the plugin's `agents/` directory.
   b. Replace template placeholders with project-specific values:
   - `{{OWNED_DIRS}}` -- from config `agents.<role>.owns`
   - `{{MODEL}}` -- from config `agents.<role>.model`
   - `{{TECH_STACK}}` -- extracted from CLAUDE.md
   - `{{CONVENTIONS}}` -- extracted from CLAUDE.md
   - `{{PATH_ALIASES}}` -- extracted from CLAUDE.md
   - `{{PACKAGE_MANAGER}}` -- extracted from CLAUDE.md
   - `{{TEST_COMMAND}}` -- from config `test_commands.unit`
   - `{{E2E_COMMAND}}` -- from config `test_commands.e2e`
   - `{{SHARED_PACKAGE}}` -- from config `shared_packages[0].path` (if set)
   - `{{SHARED_OWNER}}` -- from config `shared_packages[0].owner` (if set)
   - `{{OFF_LIMITS_DIRS}}` -- directories owned by OTHER agents (agent must not touch these)
   - `{{REFERENCE_DOCS}}` -- if llmstxt-manager is installed and `docs/llms-txt/` exists,
     generate a table mapping relevant docs to this agent's domain. Otherwise omit.
     c. Write the generated file to `.claude/agents/<role>.md`.

5. **Summary.** Print which agent files were created and remind the user they
   can customize them freely -- the generated files are owned by the project,
   not the plugin.

## Notes

- If the user has custom agent roles not in the templates (e.g., `cli`, `devops`),
  generate a minimal agent file with owned dirs and conventions, using the
  `backend.md` template as a base.
- The reviewer and performance agents always get `read_only: true` in their frontmatter and never
  receive Write/Edit tools.
- Re-running `/init-agents` after initial setup is safe -- it asks before overwriting.
```

---

## 6. `/work` Skill -- Complete 7-Phase Pipeline

**File: `agent-team-ops/skills/work/SKILL.md`**

```markdown
---
description: Pick up the next feature or task, dispatch an agent team, build it, review it, ship it.
---

# /work -- Feature Dispatch Pipeline

A 7-phase pipeline that takes a feature from "ready to build" through to a
merged PR. Each phase has clear entry/exit criteria and conditional steps
that activate only when the relevant infrastructure is configured.

**Before starting:** Read `.claude/agent-team.config.md` to load all
project-specific settings. If the config file does not exist, inform the
user and offer to run `/init-agents` first.

---

## Phase 1 -- Orient

**Goal:** Determine what to build next.

### Steps

1. Read the status file (config: `status_file`, default: `docs/STATUS.md`).

2. Parse the **Feature Build Progress** table (or equivalent tracker).
   Categorize features into:
   - **READY TO BUILD** -- Has a PRD, all prerequisites met, not started.
   - **IN PROGRESS** -- Build started but not shipped. Show current state
     (which columns are complete).
   - **STANDALONE TASKS** -- Items that don't follow the full feature pipeline
     (e.g., "add tests for X", "refactor Y"). These may be listed in a
     separate section or tagged differently.

3. Present a numbered menu to the user using `AskUserQuestion`:
```

## What should we work on?

### Ready to Build

1.  [Feature Name] -- [one-line description from PRD]
2.  [Feature Name] -- [one-line description from PRD]

### In Progress

3.  [Feature Name] -- [current state: Backend done, Frontend in progress]

### Standalone Tasks

4.  [Task description]

### Other

5.  Describe something else to work on

````

4. Wait for the user to pick a number or describe custom work.

5. **If nothing is ready to build:**
- **If `x4-project-tracker` plugin is installed:** Suggest running `/plan-backlog`
  to triage backlog items into buildable features.
- **If `x4-project-tracker` plugin is NOT installed:** Tell the user:
  "No features are marked as ready to build in {status_file}. Add a feature
  to the build progress table with status READY, or describe what you'd like
  to work on."

6. Once the user selects work, confirm the scope:
- Read the PRD (if one exists) for the selected feature.
- Summarize what will be built: which agents are needed, estimated scope.
- Ask: "Ready to start? I'll create a branch and spin up the team."

### Exit criteria
User has confirmed a piece of work to build.

---

## Phase 2 -- Setup

**Goal:** Create the development environment for this feature.

### Steps

1. **Create git branch.**
- Feature work: `{branch_prefixes.feature}<feature-slug>`
- Fix work: `{branch_prefixes.fix}<description-slug>`
- Chore work: `{branch_prefixes.chore}<description-slug>`
- Slugify the feature name (lowercase, hyphens, no special chars).
- Run: `git checkout -b <branch-name>`

2. **[If `db_branching` is configured] Create database branch.**
- Execute the `db_branching.create_command` with `{branch_name}` replaced.
- If using Neon MCP: call `mcp__Neon__create_branch` with the branch name
  derived from the git branch.
- Capture the connection string from the output.
- Inject it into the environment variable specified by `db_branching.env_var`.
- **If `db_branching` is NOT configured:** Skip entirely. No mention of
  database branching.

3. **Push branch and open draft PR.**
- `git push -u origin <branch-name>`
- Delegate PR creation to `/pr-create`, which handles draft mode, labels, and body generation.

3a. **Move PRD to in-progress.**
- If the selected feature has a PRD in `<planning_dir>/todo/`, move it:
  `git mv <planning_dir>/todo/<prd-file> <planning_dir>/in-progress/<prd-file>`
- Commit the move.

4. **[If `ci.preview_url_command` is configured] Wait for preview environment.**
- After pushing, wait for the preview environment to be provisioned.
- Run `ci.preview_url_command` to retrieve preview URLs.
- Report the URLs to the user.
- **If `ci.preview_url_command` is NOT configured:** Skip entirely. No
  mention of preview environments.

5. **Update status file.**
- Mark the selected feature as "In Progress" in the status file.
- Add the branch name and PR number to the tracking table.

### Exit criteria
Branch exists, PR is open (draft or ready), database branch exists (if configured),
status file updated.

---

## Phase 3 -- Build (Agent Team)

**Goal:** Spawn an agent team to build the feature in parallel.

### Steps

1. **Determine team composition.**
- Read the `agents` config to know which roles are available.
- For a standard feature: spawn all non-reviewer agents (typically backend,
  frontend, tester).
- For frontend-only work: spawn only frontend + tester.
- For backend-only work: spawn only backend + tester.
- The reviewer is NEVER part of the build team -- it runs in Phase 4.

2. **Generate build plan.**
- Based on the PRD (or user description), break the work into tasks per agent:
  - **Backend tasks:** Schema changes, API routes, business logic.
  - **Frontend tasks:** Pages, components, client-side state, stories.
  - **Tester tasks:** Unit tests, e2e tests, test data/fixtures.
- Present the plan to the user for approval:
  ```
  ## Build Plan

  ### Backend
  - [ ] Add <table> to schema
  - [ ] Create <router> with CRUD procedures
  - [ ] Add seed data

  ### Frontend
  - [ ] Create <page> route
  - [ ] Build <Component> with stories
  - [ ] Wire up tRPC queries

  ### Tester
  - [ ] Unit tests for <router>
  - [ ] E2E tests for <page>

  Approve this plan? (yes / suggest changes)
  ```
- Wait for user approval. Adjust plan if user suggests changes.

3. **Spawn teammates.**
- For each agent in the build team, spawn a teammate with:
  - The agent's `.md` file (from `.claude/agents/<role>.md`)
  - The build plan tasks assigned to that role
  - The branch name to work on
  - **[If `db_branching` is configured]** The database connection string
  - Context: "You are the {role} agent for this feature. Your tasks are: {tasks}.
    Work on branch {branch}. Stay within your owned directories: {owned_dirs}.
    Do NOT edit files in: {off_limits_dirs}."

4. **[If `shared_packages` is configured] Shared package coordination.**
- Include coordination instructions in teammate prompts:
  - **Owner agent** (e.g., backend): "If you need to add/change types in
    {shared_package_path}, do it first and commit. Then message the team:
    'Shared types updated -- {description of changes}.'"
  - **Notify agents** (e.g., frontend): "Do NOT import new types from
    {shared_package_path} until the {owner} agent has committed them and
    messaged you. If you need a type that doesn't exist yet, message the
    {owner} agent to request it."
- **If `shared_packages` is NOT configured:** No coordination instructions.
  Each agent works independently.

5. **Monitor the team.**
- Watch for teammate messages and progress.
- If a teammate is blocked, provide guidance or adjust the plan.
- If a teammate finishes early, acknowledge and let it go idle.
- The TeammateIdle hook (if configured) will gate agents that try to go
  idle with failing tests.

6. **Collect results.**
- When all teammates signal completion (or idle), gather:
  - Files changed by each agent
  - Any notes or warnings from agents
  - Test results (from tester agent)

### Exit criteria
All build teammates have completed their tasks and gone idle. Code is committed
on the feature branch.

---

## Phase 4 -- Review + Verify

**Goal:** Quality gate before shipping.

### Steps

1. **Spawn reviewer and performance agents (in parallel).**
- Use the reviewer's `.md` file from `.claude/agents/reviewer.md`.
- Use the performance agent's `.md` file from `.claude/agents/performance.md`.
- Both agents run in parallel. Provide context: "Review all changes on branch
  {branch} since it diverged from {base_branch}. Check the full diff, not just
  the latest commit."
- Both agents have read-only tools (no Write/Edit).
- The performance agent checks: bundle size impact, unnecessary re-renders,
  memory leaks, query patterns, caching opportunities.

2. **Reviewer executes checklists.**
The reviewer's agent file contains its checklists (security, architecture,
quality). It reports findings as:
````

## Review Findings

### Blockers (must fix before merge)

- [SECURITY] {file}:{line} -- {description}
- [BUG] {file}:{line} -- {description}

### Warnings (should fix, not blocking)

- [QUALITY] {file}:{line} -- {description}

### Notes (informational)

- [STYLE] {description}

````

3. **Address blockers.**
- If the reviewer found blockers:
  - Route each blocker to the appropriate agent (based on file ownership).
  - The agent fixes the issue and commits.
  - Re-run the reviewer on the fixed files (or the relevant subset).
- Repeat until no blockers remain.

4. **Verification gate (mandatory — delegates to `/verify-local`).**
Run ALL configured test commands in sequence via `/verify-local`. Each must pass with evidence. `/verify-local` will auto-fix lint and typecheck failures where possible.

a. **Unit tests:** Run `test_commands.unit` (required).
   ```
   $ {test_commands.unit}
   [show output -- must see pass count and zero failures]
   ```

b. **[If `test_commands.e2e` is configured] E2E tests:**
   ```
   $ {test_commands.e2e}
   [show output -- must see pass count and zero failures]
   ```
   **If NOT configured:** Skip. No mention of e2e tests.

c. **[If `test_commands.lint` is configured] Lint:**
   ```
   $ {test_commands.lint}
   [show output -- must be clean]
   ```
   **If NOT configured:** Skip.

d. **[If `test_commands.typecheck` is configured] Type check:**
   ```
   $ {test_commands.typecheck}
   [show output -- must be clean]
   ```
   **If NOT configured:** Skip.

5. **If any verification step fails:**
- Route the failure to the appropriate agent (tester for test failures,
  the agent that owns the failing file for lint/typecheck).
- Agent fixes the issue and commits.
- Re-run the failed verification step.
- Repeat until all steps pass.

6. **Final confirmation.**
Report to the user:
````

## Verification Complete

- Unit tests: PASS (X passed, 0 failed)
- E2E tests: PASS (Y passed, 0 failed) [if configured]
- Lint: PASS [if configured]
- Typecheck: PASS [if configured]
- Reviewer: No blockers remaining

Ready to ship?

```

### Exit criteria
All tests pass, reviewer has no blockers, user confirms ready to ship.

---

## Phase 5 -- Ship

**Goal:** Push final changes, convert PR to ready, watch CI.

### Steps

1. **Push all commits.**
```

git push origin <branch-name>

```

2. **[If `pr.convert_on_ship` is true] Convert draft PR to ready.**
```

gh pr ready

````
**If `pr.convert_on_ship` is false:** Leave PR in its current state.

3. **[If `ci.watch_command` is configured] Watch CI via `/pr-status`.**
- Delegate CI status checking to `/pr-status`.
- Wait for CI to complete.
- **If CI passes:** Proceed to reporting.
- **If CI fails:** Handle according to the failure table:

  | Failure type | Action |
  | --- | --- |
  | Lint errors | Auto-fix, commit, push, re-watch |
  | TypeScript type errors | Auto-fix, commit, push, re-watch |
  | Single failing unit test | Diagnose, fix, commit, push, re-watch |
  | E2E / build / logic errors | Stop and notify user with error summary |

  - Max 3 retry attempts, then escalate to user.
- **If `ci.watch_command` is NOT configured:** Skip CI watching. Report
  that the PR is pushed and ready.

4. **Report to user.**
Always include:
- **GitHub PR URL:** from `gh pr view --json url -q .url`
- **[If `ci.preview_url_command` is configured] Preview URLs:**
  Run `ci.preview_url_command` and include the output.
  **If NOT configured:** No preview URL section.

````

## Shipped!

- **PR:** https://github.com/<owner>/<repo>/pull/<number>
- **Preview:** https://preview-url.example.com [if configured]
- **CI:** Passing [if configured]

```

### Exit criteria
PR is pushed, ready for review (or draft if not converting), CI passes (if
configured), URLs reported to user.

---

## Phase 6 -- Post-Ship Memory Sweep

**Goal:** Capture patterns and learnings from the build.

### Steps

1. **Review teammate activity.**
- Look at what each teammate did: files changed, patterns used, any
  difficulties encountered.

2. **Scan for reusable patterns.**
Look for:
- New conventions that emerged (naming patterns, file structures).
- Gotchas discovered (mock shapes, API quirks, test setup requirements).
- Architecture decisions made during the build.
- Common mistakes that were caught by the reviewer.

3. **Write to memory.**
- If the project uses Claude memory (`.claude/` memory files or auto-memory),
  write notable patterns and gotchas.
- Format as concise, actionable notes that will help future builds.

4. **Update status file.**
- Mark completed columns in the Feature Build Progress table.
- Update the feature's status to reflect what was shipped.
- Record the PR number for reference.

5. **Move PRD to complete.**
- If the feature's PRD is in `<planning_dir>/in-progress/`, move it:
  `git mv <planning_dir>/in-progress/<prd-file> <planning_dir>/complete/<prd-file>`
- Commit the move.

### Exit criteria
Status file updated, PRD moved to complete, patterns captured in memory.

---

## Phase 7 -- Cleanup

**Goal:** Clean up temporary resources. Delegates to `/pr-cleanup`.

### Steps

1. **[If `db_branching` is configured]**
- **If `db_branching.cleanup` is `"github-action"`:**
  Report: "Database branch will be automatically deleted when the PR is
  merged/closed (via GitHub Actions)."
- **If `db_branching.cleanup` is `"manual"`:**
  Report: "Remember to delete the database branch `{branch_name}` after
  the PR is merged."
- **If `db_branching.cleanup` is `"none"`:**
  No mention of cleanup.
- **If `db_branching` is NOT configured:** Skip entirely.

2. **Report final summary.**
```

## Work Complete

Feature: {feature_name}
Branch: {branch_name}
PR: {pr_url}
Status: Shipped, awaiting merge

```

### Exit criteria
User has all the information they need. Pipeline complete.

---

## Error Handling (All Phases)

- **Git conflicts:** If a push fails due to conflicts, pull and rebase. If
rebase has conflicts, report to the user with the conflicting files.
- **Agent failures:** If a teammate crashes or produces no output, report
the failure and ask the user whether to retry or handle manually.
- **Network failures:** If MCP calls or CLI commands fail due to network
issues, retry once. If still failing, report and ask the user.
- **User cancellation:** If the user says "stop" or "cancel" at any phase,
gracefully stop. Do NOT delete the branch or PR -- leave everything in
its current state for the user to resume later.
```

---

## 7. `/run-tests` Skill

**File: `agent-team-ops/skills/run-tests/SKILL.md`**

```markdown
---
description: Run project tests using commands from agent-team config. Supports unit, e2e, lint, and typecheck.
argument-hint: "[unit|e2e|lint|typecheck]"
---

# /run-tests

Run test commands as defined in `.claude/agent-team.config.md`.

## Behavior

1. **Read config.** Load `.claude/agent-team.config.md` and parse the
   `test_commands` section from YAML frontmatter.

2. **If no arguments provided**, run ALL configured test types in order:
   - `unit` (required -- always runs)
   - `e2e` (if configured and non-empty)
   - `lint` (if configured and non-empty)
   - `typecheck` (if configured and non-empty)

3. **If an argument is provided** (e.g., `/run-tests unit` or `/run-tests e2e`),
   run only that specific test type.

4. **For each test type**, run the configured command via Bash:
```

$ {test_commands.<type>}

```

Show the full output. Report pass/fail status.

5. **Summary:**

```

## Test Results

| Type      | Status | Details             |
| --------- | ------ | ------------------- |
| unit      | PASS   | 42 passed, 0 failed |
| e2e       | FAIL   | 3 passed, 1 failed  |
| lint      | PASS   | No warnings         |
| typecheck | SKIP   | Not configured      |

```

6. **If any test fails**, show the failure output and suggest which files
likely need fixing based on the error messages.

## Fallback

If `.claude/agent-team.config.md` does not exist, try common defaults:
- Unit: `npm test`
- E2E: skip
- Lint: `npm run lint` (if `lint` script exists in package.json)
- Typecheck: `npx tsc --noEmit` (if `tsconfig.json` exists)

If no config and no defaults apply, tell the user to create the config file
or provide the test command directly.
```

---

## 8. `/work` Command Stub

**File: `agent-team-ops/commands/work.md`**

```markdown
---
description: Pick up the next piece of work, dispatch an agent team, and ship it. Reads from your project's status file.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebFetch, AskUserQuestion
---

Run the `/work` skill to start the feature dispatch pipeline.

Read `.claude/agent-team.config.md` for project-specific configuration.
If the config file does not exist, offer to create it with defaults.

Then follow the 7-phase pipeline defined in the work skill.
```

---

## 9. Agent Templates

These are TEMPLATE agents bundled with the plugin. The `/init-agents` command copies and customizes them for the project, writing the final versions to `.claude/agents/`. Templates contain `{{PLACEHOLDER}}` values that get replaced during generation.

Agent frontmatter uses three keys: `name`, `description`, and `model` (e.g., `sonnet`). Tools are not listed in frontmatter -- they are determined by the runtime based on the agent's role.

### 9.1 Backend Agent Template

**File: `agent-team-ops/agents/backend.md`**

```markdown
---
name: backend
description: Server-side code, database schema, API routes, and authentication logic
model: sonnet
---

# Backend Agent

You are the backend agent for this project. You own the server-side code,
database schema, API routes, and authentication logic.

## Owned Directories

You may ONLY create and edit files within these directories:

{{OWNED_DIRS}}

## Off-Limits

Do NOT edit files in these directories (owned by other agents):

{{OFF_LIMITS_DIRS}}

## Tech Stack

{{TECH_STACK}}

## Conventions

{{CONVENTIONS}}

## Path Aliases

{{PATH_ALIASES}}

## Package Manager

Use `{{PACKAGE_MANAGER}}` for all package operations.

## Shared Package Coordination

{{SHARED_PACKAGE_SECTION}}

## Reference Docs

{{REFERENCE_DOCS}}

## Rules

1. Stay within your owned directories. Never touch frontend code.
2. Use the project's established patterns for new code (check existing files
   for examples before creating new ones).
3. Validate inputs with Zod at API boundaries. Trust internal types.
4. Include proper error handling -- use the project's error class/pattern.
5. Add database indexes on foreign keys and frequently queried columns.
6. When you finish your tasks, commit your changes and go idle.
```

### 9.2 Frontend Agent Template

**File: `agent-team-ops/agents/frontend.md`**

```markdown
---
name: frontend
description: UI code, components, pages, styling, client-side state, and component stories
model: sonnet
---

# Frontend Agent

You are the frontend agent for this project. You own the UI code,
components, pages, styling, client-side state, and component stories.

## Owned Directories

You may ONLY create and edit files within these directories:

{{OWNED_DIRS}}

## Off-Limits

Do NOT edit files in these directories (owned by other agents):

{{OFF_LIMITS_DIRS}}

## Tech Stack

{{TECH_STACK}}

## Conventions

{{CONVENTIONS}}

## Path Aliases

{{PATH_ALIASES}}

## Package Manager

Use `{{PACKAGE_MANAGER}}` for all package operations.

## Shared Package Coordination

{{SHARED_PACKAGE_SECTION}}

## Reference Docs

{{REFERENCE_DOCS}}

## Rules

1. Stay within your owned directories. Never touch API or database code.
2. Use existing UI components before creating new ones.
3. Co-locate component stories (`.stories.tsx`) with components.
4. Use the project's state management pattern (check existing pages for
   examples of data fetching).
5. Follow the project's styling conventions (check existing components).
6. When you finish your tasks, commit your changes and go idle.
```

### 9.3 Reviewer Agent Template

**File: `agent-team-ops/agents/reviewer.md`**

```markdown
---
name: reviewer
description: Read-only code review -- security, architecture, and quality audits
model: sonnet
---

# Reviewer Agent

You are the reviewer agent. You have READ-ONLY access to the entire codebase.
You do NOT have Write or Edit tools. Your job is to review changes and report
findings.

## Tech Stack

{{TECH_STACK}}

## Conventions

{{CONVENTIONS}}

## Security Checklist

- [ ] No secrets, API keys, or credentials in committed code
- [ ] No `.env` files committed
- [ ] Input validation at all API boundaries
- [ ] Authentication checks on protected routes/procedures
- [ ] No SQL injection vectors (parameterized queries only)
- [ ] No XSS vectors (proper output encoding)
- [ ] Rate limiting on public endpoints (if applicable)
- [ ] CORS configuration is restrictive (not `*` in production)

## Architecture Checklist

- [ ] New code follows existing patterns (check similar files)
- [ ] No circular dependencies introduced
- [ ] Database schema changes include proper indexes
- [ ] API changes are backward-compatible (or breaking change is intentional)
- [ ] Shared package changes don't break consumers
- [ ] File/directory ownership boundaries are respected

## Quality Checklist

- [ ] No dead code or commented-out blocks
- [ ] Error cases are handled (not just happy path)
- [ ] TypeScript types are specific (no unnecessary `any`)
- [ ] Functions are reasonably sized (< 50 lines preferred)
- [ ] Variable/function names are descriptive
- [ ] No duplicated logic that should be extracted

## Output Format

Report findings with severity and location:
```

## Review Findings

### Blockers (must fix before merge)

- [SECURITY] path/to/file.ts:42 -- Description of the issue

### Warnings (should fix, not blocking)

- [QUALITY] path/to/file.ts:15 -- Description of the issue

### Notes (informational)

- [STYLE] General observation

```

## Rules

1. You are read-only. Do not attempt to fix issues -- report them.
2. Review ALL changes on the branch, not just the latest commit.
3. Use `git diff <base>...HEAD` to see the full diff.
4. Be specific: include file paths and line numbers.
5. Distinguish blockers (must fix) from warnings (nice to fix).
```

### 9.4 Tester Agent Template

**File: `agent-team-ops/agents/tester.md`**

```markdown
---
name: tester
description: Unit tests and end-to-end tests -- writes and maintains test files only
model: sonnet
---

# Tester Agent

You are the tester agent. You write and maintain tests -- both unit tests
and end-to-end tests. You own test files but do NOT refactor production code.

## Owned Directories / File Patterns

You may ONLY create and edit files matching these patterns:

{{OWNED_DIRS}}

## Off-Limits

Do NOT edit production source files. If you find a bug in production code,
report it to the appropriate agent -- do not fix it yourself.

## Tech Stack

{{TECH_STACK}}

## Test Commands

- **Unit tests:** `{{TEST_COMMAND}}`
- **E2E tests:** `{{E2E_COMMAND}}`

## Conventions

{{CONVENTIONS}}

## Package Manager

Use `{{PACKAGE_MANAGER}}` for all package operations.

## Reference Docs

{{REFERENCE_DOCS}}

## Rules

1. Only edit test files. Never modify production source code.
2. Run tests frequently to verify your work: `{{TEST_COMMAND}}`
3. Write tests that cover both happy paths and error cases.
4. Use descriptive test names that explain what is being tested.
5. Mock external dependencies (databases, APIs, file system) -- do not
   make real network calls in unit tests.
6. For e2e tests, use `data-testid` attributes for element selection.
7. ALL tests must pass before you go idle. If tests fail, fix them.
8. When you finish your tasks, run the full test suite one final time
   to confirm everything passes, then go idle.
```

### 9.5 Performance Agent Template

**File: `agent-team-ops/agents/performance.md`**

```markdown
---
name: performance
description: Read-only performance analysis -- bundle size, re-renders, memory leaks, query patterns, caching
model: sonnet
---

# Performance Agent

You are the performance agent. You have READ-ONLY access to the entire codebase.
You do NOT have Write or Edit tools. Your job is to analyze changes for
performance implications and report findings.

## Tech Stack

{{TECH_STACK}}

## Conventions

{{CONVENTIONS}}

## Performance Checklist

- [ ] Bundle size impact: new dependencies, large imports, tree-shaking issues
- [ ] Unnecessary re-renders: missing memoization, unstable references in props
- [ ] Memory leaks: event listeners not cleaned up, subscriptions not unsubscribed
- [ ] Query patterns: N+1 queries, missing indexes, unoptimized joins
- [ ] Caching opportunities: repeated expensive computations, cacheable API responses
- [ ] Lazy loading: large components or routes that should be code-split

## Output Format

Report findings with severity and location:

## Performance Findings

### Blockers (must fix before merge)

- [PERF] path/to/file.ts:42 -- Description of the issue

### Warnings (should fix, not blocking)

- [PERF] path/to/file.ts:15 -- Description of the issue

### Opportunities (nice to have)

- [PERF] General optimization suggestion

## Rules

1. You are read-only. Do not attempt to fix issues -- report them.
2. Review ALL changes on the branch, not just the latest commit.
3. Use `git diff <base>...HEAD` to see the full diff.
4. Be specific: include file paths and line numbers.
5. Focus on measurable performance impacts, not style preferences.
```

---

## 10. Hooks

**File: `agent-team-ops/hooks/hooks.json`**

```json
{
  "description": "Agent team workflow hooks: protected files, auto-format, teammate idle gates",
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
            "statusMessage": "Auto-formatting"
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
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/teammate-idle.sh",
            "statusMessage": "Running test gate"
          }
        ]
      }
    ]
  }
}
```

Hook logic lives in separate `.sh` scripts rather than inline commands. Each script uses `${CLAUDE_PLUGIN_ROOT}` for path resolution, so the plugin works regardless of where it is installed. The scripts read project-specific values from `.claude/agent-team.config.md` at runtime.

### Hook scripts

#### `hooks/protected-files.sh` -- PreToolUse

```bash
#!/bin/bash
# Blocks Edit/Write on files matching protected patterns from config.
# $CLAUDE_FILE_PATH is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
PROTECTED_DEFAULT="*.env *.env.*"

if [ -f "$CONFIG_FILE" ]; then
  PROTECTED=$(sed -n '/^protected_files:/,/^[^ ]/{ /^  - /s/^  - ["'\'']*\([^"'\'']*\)["'\'']*$/\1/p }' "$CONFIG_FILE")
else
  PROTECTED="$PROTECTED_DEFAULT"
fi

FILE="$CLAUDE_FILE_PATH"
for pattern in $PROTECTED; do
  case "$FILE" in
    $pattern)
      echo "BLOCK: Editing $FILE is not allowed (matches protected pattern: $pattern)"
      exit 1
      ;;
  esac
done
```

**Behavior:**

1. Reads `protected_files` from `.claude/agent-team.config.md`.
2. If no config file exists, falls back to `*.env *.env.*`.
3. Checks `$CLAUDE_FILE_PATH` against each protected pattern using shell glob matching.
4. If any pattern matches, prints `BLOCK: Editing <file> is not allowed` and exits 1 (which blocks the tool call).
5. If no pattern matches, exits 0 (allows the tool call).

#### `hooks/auto-format.sh` -- PostToolUse

```bash
#!/bin/bash
# Runs the configured formatter on the file that was just edited/written.
# $CLAUDE_FILE_PATH is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
FORMATTER=""

if [ -f "$CONFIG_FILE" ]; then
  FORMATTER=$(grep '^formatter:' "$CONFIG_FILE" | sed "s/^formatter: *[\"']*\([^\"']*\)[\"']*$/\1/" | sed 's/^ *//')
fi

if [ -n "$FORMATTER" ] && [ "$FORMATTER" != '""' ] && [ "$FORMATTER" != "''" ]; then
  CMD=$(echo "$FORMATTER" | sed "s|\$FILE|$CLAUDE_FILE_PATH|g")
  eval "$CMD" 2>/dev/null || true
fi
```

**Behavior:**

1. Reads `formatter` from `.claude/agent-team.config.md`.
2. If no config file exists or `formatter` is empty/unset, exits silently (no formatting).
3. Replaces `$FILE` in the formatter command with `$CLAUDE_FILE_PATH`.
4. Runs the formatter command. Errors are suppressed (`|| true`) -- a formatter failure should not block work.

#### `hooks/teammate-idle.sh` -- TeammateIdle

```bash
#!/bin/bash
# Runs idle gate command for the teammate's role.
# $CLAUDE_AGENT_ROLE is provided by the hook context.

CONFIG_FILE=".claude/agent-team.config.md"
ROLE="$CLAUDE_AGENT_ROLE"

if [ -z "$ROLE" ]; then exit 0; fi
if [ ! -f "$CONFIG_FILE" ]; then exit 0; fi

GATE_CMD=$(sed -n "/^teammate_idle_gates:/,/^[^ ]/{/^  $ROLE:/s/^  $ROLE: *[\"']*\([^\"']*\)[\"']*$/\1/p}" "$CONFIG_FILE")
if [ -z "$GATE_CMD" ]; then exit 0; fi

OUTPUT_FILE=$(mktemp)
eval "$GATE_CMD" > "$OUTPUT_FILE" 2>&1
CODE=$?
tail -10 "$OUTPUT_FILE"
rm -f "$OUTPUT_FILE"

if [ $CODE -ne 0 ]; then
  echo "Idle gate failed for $ROLE. Fix all issues before going idle."
  exit 2
fi
```

**Behavior:**

1. Reads `$CLAUDE_AGENT_ROLE` to determine which agent is going idle.
2. Looks up `teammate_idle_gates.<role>` in `.claude/agent-team.config.md`.
3. If no gate is configured for this role, exits 0 (agent can go idle).
4. If a gate command exists, runs it and captures output.
5. Shows the last 10 lines of output.
6. If the command exits non-zero, prints "Idle gate failed for {role}" and exits 2, which tells the agent it must fix the issues before going idle.
7. If the command exits 0, the agent is allowed to go idle.

---

## 11. Complete File Contents Summary

Every file in the plugin and its purpose:

| File                         | Size (approx) | Purpose                                                |
| ---------------------------- | ------------- | ------------------------------------------------------ |
| `.claude-plugin/plugin.json` | Section 2     | Minimal manifest -- plugin identity metadata           |
| `skills/work/SKILL.md`       | Section 6     | 7-phase feature dispatch pipeline                      |
| `skills/run-tests/SKILL.md`  | Section 7     | Config-driven test runner                              |
| `commands/work.md`           | Section 8     | User-facing command stub that invokes the work skill   |
| `commands/init-agents.md`    | Section 5     | Generates project-specific agents from templates       |
| `agents/backend.md`          | Section 9.1   | Template: backend agent with placeholders              |
| `agents/frontend.md`         | Section 9.2   | Template: frontend agent with placeholders             |
| `agents/reviewer.md`         | Section 9.3   | Template: reviewer agent (read-only) with placeholders |
| `agents/tester.md`           | Section 9.4   | Template: tester agent with placeholders               |
| `agents/performance.md`     | Section 9.5   | Template: performance agent (read-only) with placeholders |
| `hooks/hooks.json`           | Section 10    | Hook definitions using `${CLAUDE_PLUGIN_ROOT}` paths   |
| `hooks/protected-files.sh`   | Section 10    | PreToolUse: blocks edits to protected file patterns    |
| `hooks/auto-format.sh`       | Section 10    | PostToolUse: runs configured formatter after edits     |
| `hooks/teammate-idle.sh`     | Section 10    | TeammateIdle: runs test gate when teammate goes idle   |
| `LICENSE`                    | --            | License file                                           |
| `README.md`                  | --            | Plugin overview and installation instructions          |

### Config file (in consuming project, not in plugin)

| File                           | Purpose                                    |
| ------------------------------ | ------------------------------------------ |
| `.claude/agent-team.config.md` | Section 4 -- all project-specific settings |

The config file is created by `/init-agents` on first run or manually by the user. The plugin never ships a config file -- it ships templates and defaults.

---

## 12. How It All Fits Together

### First-time setup (new project adopting the plugin)

1. User installs the plugin.
2. User runs `/init-agents`.
3. Plugin reads `CLAUDE.md`, asks a few questions, generates:
   - `.claude/agent-team.config.md` (config file)
   - `.claude/agents/backend.md` (from template)
   - `.claude/agents/frontend.md` (from template)
   - `.claude/agents/reviewer.md` (from template)
   - `.claude/agents/tester.md` (from template)
   - `.claude/agents/performance.md` (from template)
4. User reviews and customizes the generated files.
5. Hooks are active immediately (they read from config).

### Day-to-day usage

1. User runs `/work`.
2. Phase 1 reads status file, presents menu.
3. User picks a feature.
4. Phase 2 creates branch, DB branch (if configured), opens PR.
5. Phase 3 spawns agent team, builds feature in parallel.
6. Phase 4 spawns reviewer, runs verification gate.
7. Phase 5 pushes, converts PR, watches CI (if configured).
8. Phase 6 captures patterns in memory.
9. Phase 7 reports cleanup instructions (if configured).

### Quick test run (without full /work pipeline)

User runs `/run-tests` to execute all configured test commands and see results.

---

## 13. Conditional Feature Matrix

Quick reference for which features activate based on config presence:

| Feature                  | Config Key                                                   | If Present                                      | If Absent                          |
| ------------------------ | ------------------------------------------------------------ | ----------------------------------------------- | ---------------------------------- |
| DB branching             | `db_branching`                                               | Create/cleanup DB branch in Phase 2/7           | Skip entirely, no mention          |
| Preview URLs             | `ci.preview_url_command`                                     | Report preview URLs in Phase 2/5                | Skip entirely, no mention          |
| CI watching              | `ci.watch_command`                                           | Watch CI in Phase 5, retry on failure           | Skip, just report PR is pushed     |
| Auto-format              | `formatter`                                                  | Format files after every Edit/Write             | No formatting                      |
| E2E tests                | `test_commands.e2e`                                          | Run e2e in verification gate                    | Skip, only run unit tests          |
| Lint check               | `test_commands.lint`                                         | Run lint in verification gate                   | Skip                               |
| Type check               | `test_commands.typecheck`                                    | Run typecheck in verification gate              | Skip                               |
| Shared pkg coordination  | `shared_packages`                                            | Include coordination protocol in agent prompts  | Agents work independently          |
| Teammate idle gates      | `teammate_idle_gates.<role>`                                 | Run gate command when agent goes idle           | Agent can go idle freely           |
| PR draft mode            | `pr.draft`                                                   | Open as draft, convert in Phase 5               | Open as ready immediately          |
| PR labels                | `pr.labels`                                                  | Apply labels on PR creation                     | No labels                          |
| Plan-backlog fallback    | `x4-project-tracker` plugin installed                           | Invoke `/plan-backlog` when queue empty         | Tell user to add features manually |
| Reference docs in agents | `x4-llmstxt-manager` plugin installed + `docs/llms-txt/` exists | Include reference doc table in generated agents | Omit reference docs section        |
