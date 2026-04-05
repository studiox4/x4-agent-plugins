---
name: work
description: Use when the user is ready to build — picks up the next PRD from the planning queue, dispatches an agent team (backend, frontend, tester), reviews, verifies, and ships. Trigger for "let's build", "start working", "build the next feature", "dispatch the team", or any request to begin development work. Supports auto-loop through all ready PRDs and parallel execution.
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

### Blocked

3.  [Feature Name] -- depends on [dependency] ([status])

### In Progress

4.  [Feature Name] -- [current state: Backend done, Frontend in progress]
    PR: <url> | Preview: <url> [if available]

### Standalone Tasks

5.  [Task description]

### Dependency Analysis

[Only shown when 2+ PRDs are ready]

PRDs 1 and 2 are independent -- can be built in parallel.
PRD 3 (Feature) is blocked until [dependency] ships.

### Build Options

6.  Pick one to build (enter a number above)
7.  Describe something else to work on
8.  Build all ready PRDs (auto-loop, pausing between each)
9.  Build independent PRDs in parallel (Wave 1 simultaneously)

Menu items are dynamically numbered based on the items above. The
"Blocked" section appears only when PRDs have unmet dependencies.
"Dependency Analysis" appears when 2+ PRDs are ready. Option 8
appears when 2+ unblocked PRDs exist. Option 9 appears only when
agent teams are enabled (config `team_mode` is `"auto"` or `"teams"`
with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set) AND 2+ parallel-safe
PRDs exist in the same wave.

4. Wait for the user to pick a number or describe custom work.

   - **If user picks a single PRD or standalone task:** existing behavior.
   - **If user picks "Describe something else":** existing behavior.
   - **If user picks "Build all ready PRDs" or "Build in parallel":**
     Show the execution plan for confirmation:

     ## Execution Plan

     Wave 1 (parallel): [Feature A] + [Feature B]
     Wave 2 (after [dependency] ships): [Feature C]

     Start building? (yes / adjust)

     If the user says "adjust," let them reorder, remove PRDs, or
     change parallel to sequential. Once confirmed, set the execution
     mode (`sequential` or `parallel`) and the ordered PRD list, then
     proceed to Phase 2 with the first PRD.

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

   **Dispatch method — try native agent teams first, fall back to subagents:**

   **Option A — Native agent teams (preferred):**
   Use `TeamCreate` to spawn the build team. If `TeamCreate` is available and
   succeeds, use it. Native teams can communicate via `SendMessage`, share
   task lists, and are coordinated by the TeammateIdle hook.

   ```
   TeamCreate({
     name: "x4-{feature-name-kebab}",
     agents: [
       { role: "backend",  file: ".claude/agents/backend.md",  tasks: [...] },
       { role: "frontend", file: ".claude/agents/frontend.md", tasks: [...] },
       { role: "tester",   file: ".claude/agents/tester.md",   tasks: [...] },
     ]
   })
   ```

   **Option B — Subagent fallback:**
   If `TeamCreate` is not available (tool not found, env flag not set, or
   returns an error), fall back to the `Agent` tool. Dispatch each role as a
   parallel `Agent` call with `run_in_background: true`. Each agent gets the
   same context as Option A.

   **Detection logic:**
   1. Attempt `TeamCreate`. If it succeeds → Option A, continue with team coordination.
   2. If `TeamCreate` throws "tool not found" or "feature not available" →
      immediately switch to Option B without re-prompting the user. Log:
      `"Agent teams unavailable — dispatching as parallel subagents."`
   3. Never silently fall through to single-agent sequential execution.

   **Context to pass each agent (both options):**
   - The agent's `.md` file (from `.claude/agents/<role>.md`)
   - The build plan tasks assigned to that role
   - The branch name to work on
   - **[If `db_branching` is configured]** The database connection string
   - `"You are the {role} agent for this feature. Your tasks are: {tasks}.
     Work on branch {branch}. Stay within your owned directories: {owned_dirs}.
     Do NOT edit files in: {off_limits_dirs}."`

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

   Use the same dispatch strategy as Phase 3 (native teams preferred, subagent
   fallback). Both agents run simultaneously to minimize review time.

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

7. **Write changelog entry.**
- Read the PRD from `docs/planning/complete/<prd-file>`.
- Extract the feature title and user stories section. Convert each user story
  to a user-facing bullet — lead with the value proposition, not the technical
  mechanism. ("Users can now export reports as CSV" not "Added CSV export endpoint".)
- Get PR number and URL: `gh pr view --json number,url`
- Get today's date: `date +%Y-%m-%d`
- Check if `docs/CHANGELOG.md` exists. If not, create it:
  ```markdown
  # Changelog

  <!-- marketing-last-synced: never -->

  All notable changes to this project are documented here.
  Each entry is generated automatically during the post-ship memory sweep.

  ---
  ```
- Prepend the new entry after the header block (before the first `## ` heading,
  or at end of file if no prior entries exist):
  ```markdown
  ## [Feature Name] — YYYY-MM-DD

  <!-- changelog-entry
  feature: Feature Name
  date: YYYY-MM-DD
  pr: <number>
  pr_url: <url>
  status: shipped
  -->

  ### What's New

  - <user-facing bullet from PRD user story>
  - <user-facing bullet from PRD user story>

  ---
  ```
- Stage `docs/CHANGELOG.md`.

8. **Commit all docs together.**
Stage all modified docs files (PRD location, status file, CHANGELOG.md) and commit:
`docs: move PRD to complete, update status and changelog`

### Exit criteria
PRD moved to `complete/`, status file updated, changelog entry written, patterns captured in memory.

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

[If `marketing.enabled: true` OR `brand` section exists in config, show this block:]

## Announce What Shipped

  /x4:market-update    → update the marketing site with new features
  /x4:market-email     → write a release email for your list
  /x4:market-linkedin  → generate a LinkedIn post
  /x4:market-tweet     → generate an X/Twitter thread

Run them together after shipping a batch, or one at a time as needed.

### Exit criteria
User has all the information they need. Pipeline complete.

---

## Auto-Loop Wrapper

**Applies when:** The user selected "Build all ready PRDs" or "Build in
parallel" in Phase 1, and there are more PRDs remaining in the execution plan.

**Does NOT apply when:** The user picked a single PRD (existing behavior --
pipeline ends after Phase 7 as before).

### Sequential Auto-Loop

After Phase 7 completes for the current PRD:

1. Print a checkpoint summary using `AskUserQuestion`:

   ## Completed: {feature_name} ({N}/{total})

   PR: {pr_url} -- merged
   Next up: {next_feature_name}
   Remaining: {remaining_count} ({blocked_count} blocked)

   Continue to next PRD? (yes / stop)

2. If the user replies "stop" or "no," end the loop normally.
3. If the user confirms (or replies empty/yes), set the next PRD as the
   work target and run Phases 2-7 again (skip Phase 1's selection menu).
4. Skip any PRDs that are still blocked by unshipped dependencies.
5. After the last PRD completes (or all remaining are blocked), print
   a final summary:

   ## Work Complete

   | PRD | Status | PR |
   |-----|--------|----|
   | {name} | Shipped | #{number} |
   | {name} | Blocked ({reason}) | -- |

   {shipped_count} shipped, {blocked_count} blocked.
   Run /x4:work again after blocked dependencies merge.

### Parallel Execution

Requires agent teams (`team_mode: "auto"` or `"teams"` with
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set). If not available, this
mode does not appear in the Phase 1 menu.

**Wave execution:**

1. For each PRD in the current wave, create a separate agent team:
   - Team name: `x4-{feature-name-kebab}-{prd-number}`
   - Each team runs on its own feature branch
   - Each team has its own build agents (backend, frontend, tester)
   - Each team runs the full Phase 2-7 cycle independently
2. The lead (main `/work` session) monitors all teams simultaneously
   via shared task lists and automatic teammate messages.
3. When all teams in a wave complete, print a wave checkpoint:

   ## Wave {N} Complete ({shipped}/{total} shipped)

   | PRD | Status | PR |
   |-----|--------|----|
   | {name} | Shipped | #{number} |
   | {name} | Failed ({reason}) | #{number} |

   Wave {N+1}: {next_features} -- checking if dependencies are met...

4. Re-evaluate blocked PRDs: if their dependencies shipped in this wave,
   unblock them and proceed to the next wave.
5. Same final summary as sequential mode after the last wave.

**Merge strategy:**
- Parallel PRDs ship their PRs sequentially, not simultaneously.
- The lead coordinates merge order.
- After the first PR in a wave merges, subsequent PRs rebase onto the
  updated main branch before merging.
- If a rebase produces conflicts, pause that PR and report to the user
  at the wave checkpoint.

**Guardrails:**
- Maximum concurrent teams: 3 (to manage token costs).
- If a wave has more than 3 parallel-safe PRDs, split into sub-waves of 3.
- If any PRD's build fails or needs user input, pause that PRD and
  continue with others. Report at the wave checkpoint.
- If a PRD's CI fails after 3 auto-fix attempts, mark as failed and
  continue. Do not block the entire wave.
- Each team runs its own review cycle (Phase 4) independently.

### Edge Cases

- If the execution plan becomes empty (all PRDs moved/deleted between
  confirmation and execution), report "No PRDs remaining" and end normally.
- If the plan shrinks to 1 PRD, run it as a single-PRD build (no loop).
- If the user stops the loop mid-way, no state is persisted. Re-running
  `/work` presents a fresh Phase 1 menu -- shipped PRDs will have moved
  out of `todo/` so the menu naturally reflects remaining work.

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
