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
- **If `pr.draft` is true:**
  ```
  gh pr create --draft --title "<Feature Name>" --body "WIP: <one-line description>"
  ```
- **If `pr.draft` is false:**
  ```
  gh pr create --title "<Feature Name>" --body "<one-line description>"
  ```
- Apply labels from `pr.labels` if any.

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

1. **Spawn reviewer agent.**
- Use the reviewer's `.md` file from `.claude/agents/reviewer.md`.
- Provide context: "Review all changes on branch {branch} since it diverged
  from {base_branch}. Check the full diff, not just the latest commit."
- The reviewer agent has read-only tools (no Write/Edit).

2. **Reviewer executes checklists.**
The reviewer's agent file contains its checklists (security, architecture,
quality). It reports findings as:

## Review Findings

### Blockers (must fix before merge)

- [SECURITY] {file}:{line} -- {description}
- [BUG] {file}:{line} -- {description}

### Warnings (should fix, not blocking)

- [QUALITY] {file}:{line} -- {description}

### Notes (informational)

- [STYLE] {description}

3. **Address blockers.**
- If the reviewer found blockers:
  - Route each blocker to the appropriate agent (based on file ownership).
  - The agent fixes the issue and commits.
  - Re-run the reviewer on the fixed files (or the relevant subset).
- Repeat until no blockers remain.

4. **Verification gate.**
Run ALL configured test commands in sequence. Each must pass with evidence.

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

## Verification Complete

- Unit tests: PASS (X passed, 0 failed)
- E2E tests: PASS (Y passed, 0 failed) [if configured]
- Lint: PASS [if configured]
- Typecheck: PASS [if configured]
- Reviewer: No blockers remaining

Ready to ship?

### Exit criteria
All tests pass, reviewer has no blockers, user confirms ready to ship.

---

## Phase 5 -- Ship

**Goal:** Push final changes, convert PR to ready, watch CI.

### Steps

1. **Push all commits.**

git push origin <branch-name>

2. **[If `pr.convert_on_ship` is true] Convert draft PR to ready.**

gh pr ready

**If `pr.convert_on_ship` is false:** Leave PR in its current state.

3. **[If `ci.watch_command` is configured] Watch CI.**
- Run the CI watch command:
  ```
  $ {ci.watch_command}
  ```
- Wait for CI to complete.
- **If CI passes:** Proceed to reporting.
- **If CI fails:**
  - Analyze the failure output.
  - Route the fix to the appropriate agent.
  - Agent fixes, commits, pushes.
  - Re-watch CI.
  - Repeat until CI passes (max 3 attempts, then escalate to user).
- **If `ci.watch_command` is NOT configured:** Skip CI watching. Report
  that the PR is pushed and ready.

4. **Report to user.**
Always include:
- **GitHub PR URL:** from `gh pr view --json url -q .url`
- **[If `ci.preview_url_command` is configured] Preview URLs:**
  Run `ci.preview_url_command` and include the output.
  **If NOT configured:** No preview URL section.

## Shipped!

- **PR:** https://github.com/<owner>/<repo>/pull/<number>
- **Preview:** https://preview-url.example.com [if configured]
- **CI:** Passing [if configured]

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

### Exit criteria
Status file updated, patterns captured in memory.

---

## Phase 7 -- Cleanup

**Goal:** Clean up temporary resources.

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

## Work Complete

Feature: {feature_name}
Branch: {branch_name}
PR: {pr_url}
Status: Shipped, awaiting merge

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
