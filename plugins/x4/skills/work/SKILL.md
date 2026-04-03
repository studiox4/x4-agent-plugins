---
name: work
description: Pick up the next feature or task, dispatch an agent team, build it, review it, ship it. Supports auto-loop through multiple PRDs and parallel execution with agent teams.
version: 3.0.0
license: MIT
---

# /work -- Feature Dispatch Pipeline

A 7-phase pipeline that takes a feature from "ready to build" through to a
merged PR. Each phase has clear entry/exit criteria and conditional steps
that activate only when the relevant infrastructure is configured.

**Before starting:** Read `.claude/agent-team.config.md` to load all
project-specific settings. If the config file does not exist, inform the
user and offer to run `/init-setup` first.

---

## Phase 1 -- Orient

**Goal:** Determine what to build next.

### Steps

1. Read the status file (config: `status_file`, default: `docs/STATUS.md`).

2. Parse the **Feature Build Progress** table (or equivalent tracker).
   Categorize features into:
   - **READY TO BUILD** -- Has a PRD in `docs/planning/todo/`, all prerequisites met, not started.
   - **IN PROGRESS** -- Build started but not shipped. Show current state
     (which columns are complete), plus PR URL and preview URL if available.
   - **STANDALONE TASKS** -- Items that don't follow the full feature pipeline
     (e.g., "add tests for X", "refactor Y"). These may be listed in a
     separate section or tagged differently.
   - **BLOCKED** -- Has a PRD in `docs/planning/todo/` but has unmet
     dependencies on other PRDs or in-progress features.

2.5. **[If 2+ PRDs are READY TO BUILD] Dependency analysis.**
   Analyze the ready PRDs for dependencies and parallelism:

   a. **Extract metadata from each PRD.** Read each PRD file in `docs/planning/todo/`
      and look for:
      - Feature name (from title or filename)
      - Explicit dependencies: sections titled "Dependencies", "Requires",
        "Blocked by", or inline references to other PRD names/numbers
      - Affected domains: scan for keywords and file paths indicating backend,
        frontend, shared packages, database schema changes

   b. **Build a dependency graph.**
      - PRDs that explicitly reference each other → sequential (dependency first)
      - PRDs that both modify shared packages (same path in `shared_packages`
        config) → sequential (avoid merge conflicts)
      - PRDs that touch completely different domains with no shared state →
        parallel-safe
      - PRDs with no detected dependencies → parallel-safe

   c. **Group into execution waves.**
      - Wave 1: all PRDs with no unmet dependencies
      - Wave 2: PRDs whose dependencies are all in Wave 1
      - Wave N: PRDs whose dependencies are all in waves 1 through N-1
      - PRDs blocked by in-progress work (not in `todo/`) are flagged as
        blocked with the reason

   d. **Categorize READY TO BUILD PRDs further:**
      - Move any PRD with unmet dependencies to the **BLOCKED** category
      - Only truly unblocked PRDs remain in READY TO BUILD

3. Present a numbered menu to the user using `AskUserQuestion`:

## What should we work on?

### Ready to Build

1.  [Feature Name] -- [one-line description from PRD]
2.  [Feature Name] -- [one-line description from PRD]

### In Progress

3.  [Feature Name] -- [current state: Backend done, Frontend in progress]
    PR: <url> | Preview: <url> [if available]

### Standalone Tasks

4.  [Task description]

### Other

5.  Describe something else to work on

4. Wait for the user to pick a number or describe custom work.

5. **If nothing is ready to build:**
- **If `x4` plugin is installed:** Suggest running `/plan-backlog`
  to triage backlog items into buildable features.
- **If `x4` plugin is NOT installed:** Tell the user:
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

Delegate to the `/pr-create` skill with the feature name and type.

The `/pr-create` skill handles:
1. Creating the git branch
2. Creating a database branch (if configured)
3. Pushing and opening a draft PR
4. Waiting for preview environments (if configured)

**After `/pr-create` completes:**

1. **Move PRD from `todo/` to `in-progress/`.**
   If a PRD exists in `docs/planning/todo/` for this feature:
   ```
   git mv docs/planning/todo/<prd-file> docs/planning/in-progress/<prd-file>
   ```
   Update the PRD link in the status file's Planning Documents table.

2. **Update status file.**
   Mark the selected feature as "In Progress" in the status file.
   Add the branch name and PR number to the tracking table.

3. **Commit:** `docs: move PRD to in-progress, update status`

### Exit criteria
Branch exists, PR is open (draft or ready), database branch exists (if configured),
PRD moved to `in-progress/`, status file updated.

---

## Phase 3 -- Build (Agent Team)

**Goal:** Spawn an agent team to build the feature in parallel.

### Steps

1. **Determine team composition.**
- Read the `agents` config to know which roles are available.
- For a standard feature: spawn all non-reviewer, non-performance agents
  (typically backend, frontend, tester).
- For frontend-only work: spawn only frontend + tester.
- For backend-only work: spawn only backend + tester.
- The reviewer and performance agents run in Phase 4, NOT here.

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

1. **Spawn reviewer and performance agents in parallel.**

   **Reviewer agent:**
   - Use the reviewer's `.md` file from `.claude/agents/reviewer.md`.
   - Provide context: "Review all changes on branch {branch} since it diverged
     from {base_branch}. Check the full diff, not just the latest commit."
   - The reviewer agent has read-only tools (no Write/Edit).

   **Performance agent:**
   - Use the performance agent's `.md` file from `.claude/agents/performance.md`.
   - Provide context: "Audit all changes on branch {branch} for performance
     issues. Check bundle size, re-renders, memory leaks, query patterns,
     and cache configuration."
   - The performance agent has read-only tools (no Write/Edit).

   Both agents run simultaneously to minimize review time.

2. **Agents execute checklists.**
   Each agent reports findings in the standard format:
   Blockers / Warnings / Notes with `[SECURITY]`, `[BUG]`, `[QUALITY]`,
   `[PERF]` tags and file:line references.

3. **[If `code-simplifier@claude-plugins-official` is installed] Run code simplifier.**
   After review agents complete, run the code simplifier on changed files
   to identify unnecessary complexity.

4. **Address blockers.**
- If either agent found blockers:
  - Route each blocker to the appropriate build agent (based on file ownership).
  - The agent fixes the issue and commits.
  - Re-run the relevant reviewer on the fixed files (or the relevant subset).
- Repeat until no blockers remain.

5. **Verification gate — delegate to `/verify-local`.**
   Run the `/verify-local` skill as the mandatory gate. This runs all configured
   checks (unit, e2e, lint, typecheck) with auto-fix (max 3 attempts per check).

   `/verify-local` handles:
   - Running all test commands in sequence
   - Auto-fixing failures (lint/typecheck auto-fix, test failure diagnosis)
   - Escalating persistent failures to the user
   - Updating the status file's "Tested" column

6. **Final confirmation.**
Report to the user:

## Verification Complete

- Unit tests: PASS (X passed, 0 failed)
- E2E tests: PASS (Y passed, 0 failed) [if configured]
- Lint: PASS [if configured]
- Typecheck: PASS [if configured]
- Reviewer: No blockers remaining
- Performance: No blockers remaining

Ready to ship?

### Exit criteria
All tests pass, reviewer and performance agents have no blockers, user confirms
ready to ship.

---

## Phase 5 -- Ship

**Goal:** Push final changes, convert PR to ready, watch CI.

### Steps

1. **Push all commits.**

git push origin <branch-name>

2. **[If `pr.convert_on_ship` is true] Convert draft PR to ready.**

gh pr ready

**If `pr.convert_on_ship` is false:** Leave PR in its current state.

3. **Check CI and preview status — use `/pr-status`.**
   Run the `/pr-status` skill to get current CI state and preview URLs.

4. **Handle CI failures.**
   If CI is failing, diagnose based on the failure type:

   | Failure Type | Action |
   |-------------|--------|
   | Lint / Typecheck | Auto-fix directly, commit, push |
   | Unit test | Diagnose root cause, fix code (not test), commit, push |
   | E2E / Build / Logic error | **STOP** — notify user with full failure output |

   For auto-fixable failures: fix, commit, push, re-check (max 3 attempts).
   For non-auto-fixable failures: stop and present the failure to the user
   with context about what went wrong and suggested next steps.

5. **Report to user.**
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

1. **Move PRD to `complete/`.**
   ```
   git mv docs/planning/in-progress/<prd-file> docs/planning/complete/<prd-file>
   ```
   Update the PRD link in the status file's Planning Documents table.

2. **Clean up scratch files.**
   Delete any implementation plan scratch files created during the build
   that are no longer needed (temporary notes, draft plans, etc.).

3. **Review teammate activity.**
- Look at what each teammate did: files changed, patterns used, any
  difficulties encountered.

4. **Scan for reusable patterns.**
Look for:
- New conventions that emerged (naming patterns, file structures).
- Gotchas discovered (mock shapes, API quirks, test setup requirements).
- Architecture decisions made during the build.
- Common mistakes that were caught by the reviewer.

5. **Write to memory.**
- If the project uses Claude memory (`.claude/` memory files or auto-memory),
  write notable patterns and gotchas.
- Format as concise, actionable notes that will help future builds.

6. **Update status file.**
- Mark completed columns in the Feature Build Progress table.
- Update the feature's status to reflect what was shipped.
- Record the PR number for reference.
- Commit: `docs: move PRD to complete, update status, memory sweep`

### Exit criteria
PRD moved to `complete/`, status file updated, patterns captured in memory.

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
  the PR is merged. You can run `/pr-cleanup` to handle this."
- **If `db_branching.cleanup` is `"none"`:**
  No mention of cleanup.
- **If `db_branching` is NOT configured:** Skip entirely.

2. **Reference `/pr-cleanup` for manual cleanup.**
   If the user prefers to clean up now (or later), they can run `/pr-cleanup`
   to delete the database branch and local git branch after the PR is merged.

3. **Report final summary.**

## Work Complete

Feature: {feature_name}
Branch: {branch_name}
PR: {pr_url}
Status: Shipped, awaiting merge

Run `/pr-cleanup` after merge to clean up branches.

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
