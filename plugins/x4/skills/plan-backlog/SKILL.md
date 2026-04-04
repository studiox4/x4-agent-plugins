---
name: plan-backlog
description: Use when the backlog has ideas that need to be turned into PRDs, or when /work says there's nothing ready to build. Presents a triage menu to plan or delete backlog items, runs brainstorming and planning, then writes a full PRD. Trigger for "plan a feature", "write a PRD", "triage the backlog", "plan something from my backlog", or any request to turn an idea into a buildable spec.
version: 1.0.0
license: MIT
---

# plan-backlog — Backlog Triage + PRD Creation

## Overview

Bridges backlog file -> planning directory -> status file. Presents a triage menu so the user
decides what to plan, what to delete, and what to leave. Never auto-selects.

## Process

### Step 0: Load config

Read `.claude/project-tracker.config.md` from the repo root. Parse YAML frontmatter. For any
missing key, use these defaults:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`
- `prd_pattern`: `NN-prd-<name>.md`
- `status_columns`: Backend, Frontend, Tested, Deployed
- `status_values.not_started`: Not Started
- `status_values.complete`: Complete
- `status_values.not_applicable`: —
- `prd_sections`: Overview, User Stories, Screens/Components, Data Model Changes,
  API/Endpoints, External APIs/Services, Open Questions, Out of Scope (v1) (with default prompts)
- `commits.prd_created`: `docs: add PRD for <feature>, update status`
- `commits.backlog_deleted`: `chore(backlog): remove "<title>" — no longer planned`

### Step 1: Parse the backlog

Read the backlog file. Extract each `##` entry as an item. For each item note:

- Title
- Scope (small / medium / large)
- "Fits after" value

Also read the status file's Feature Build Progress table to identify which backlog items
(if any) are already tracked — exclude those from the menu.

### Step 1.5: Backlog Intelligence Pass

Before presenting the triage menu, perform a cross-item analysis to surface duplicates,
groupings, and coverage overlaps. This gives the user a chance to clean up the backlog
before deciding what to plan. The user still decides everything — this step only surfaces
findings, never acts on them automatically.

**1.5a: Scan existing PRDs**

Read filenames from `docs/planning/todo/`, `docs/planning/in-progress/`, and
`docs/planning/complete/`. For each PRD, read only the title line (`# PRD: ...`) and the
`## Overview` section — skip everything else. This builds the coverage landscape quickly.

**1.5b: Analyze backlog items**

With all backlog items in memory and the PRD coverage landscape loaded, reason across the
full set to identify any of these patterns:

- **Semantic duplicates**: Two or more backlog items describing the same feature with
  different wording (e.g., "dark mode support" + "theme customization options"). Detect by
  meaning and intent, not keyword overlap alone.

- **Natural groupings**: Two or more small items that would clearly ship as one cohesive
  PRD — they share a data model, the same screen, or a user would naturally expect them
  together (e.g., "user profile page" + "avatar upload" + "bio editing" → one PRD).

- **Already covered**: A backlog item substantially addressed by an existing PRD in `todo/`
  (planned but not started), `in-progress/` (currently being built), or `complete/`
  (already shipped).

Only flag findings with meaningful confidence. Don't flag items as similar just because
they share one word. If the backlog is clean, proceed directly to Step 2 without showing
the analysis panel — no noise for noise's sake.

**1.5c: Present findings (only if any exist)**

Use `AskUserQuestion` to show a pre-triage analysis panel. Show only the categories that
have findings:

```
## Backlog Analysis — {N} items

⚠ Possible duplicates:
  A. "Dark mode support" + "Theme customization options"
     These look like the same feature described twice.
     → Merge into one entry?

↔ Could be combined into one PRD:
  B. "User profile page" + "Avatar upload" + "Bio editing"
     These are closely related — likely one feature.
     → Combine into one entry?

✓ Already covered by existing PRDs:
  C. "Search functionality" → PRD 03-prd-search.md [in-progress]
     → Remove from backlog?

Reply with letters to act on (e.g. "A, C"), or press enter to skip all and go to triage.
```

Wait for reply. For each letter the user confirms:

- **Merge (duplicates):** Combine the items' content into a single, better-written backlog
  entry — best title + merged description, retaining all unique details from both. Remove
  the originals. Write the updated backlog file.

- **Combine (groupings):** Merge the listed items into one entry with a broader title that
  captures the group (e.g., "User Profile" covers all three). Write the updated backlog file.

- **Remove (already covered):** Delete the entry from the backlog file. Note in your reply
  which PRD covers it.

After processing all confirmed actions, re-parse the updated backlog and continue to Step 2
with the cleaned item list.

**If the user skips all (or no findings were found):** Proceed directly to Step 2 as normal.

---

### Step 2: Present the triage menu

Use `AskUserQuestion` with this format:

```
Backlog has N items not yet planned. What would you like to do?

PLAN (writes PRD + adds to status file):
  1. <Title> — <scope>, fits after <fits-after>
  2. <Title> — <scope>, fits after <fits-after>
  ...

DELETE (removes from backlog permanently):
  D1. Delete: <Title>
  D2. Delete: <Title>
  ...

  S. Skip — nothing to plan right now
```

Wait for the user's response before doing anything.

### Step 3: Handle the response

**If user picks a number (plan):**
-> Go to Step 3.5: Brainstorm + Plan

**If user picks D + number (delete):**
-> Remove that `##` section from the backlog file (from the `##` heading through the next
   `---` separator)
-> Commit using the configured `commits.backlog_deleted` template
-> Re-present the updated menu (go back to Step 2)

**If user picks S (skip):**
-> Respond: "Nothing planned. Backlog untouched." Done.

**If user picks multiple (e.g. "D1, D2, then plan 3"):**
-> Execute deletions first, then proceed to plan the chosen item.

### Step 3.5a: Brainstorm

Before writing the PRD, brainstorm the feature to flesh out requirements.

**If `superpowers@claude-plugins-official` is installed:**
- Delegate to `/brainstorming` with the backlog entry as input.
- Use the brainstorming output as input for the next step.

**If NOT installed (inline brainstorm):**
- Generate a brainstorm covering:
  - Core requirements and user stories
  - Edge cases and error scenarios
  - Dependencies on existing features or infrastructure
  - Open questions that need answers before building
- Present the brainstorm to the user via `AskUserQuestion`:
  ```
  ## Brainstorm: <Feature Name>

  ### Requirements
  - ...

  ### Edge Cases
  - ...

  ### Dependencies
  - ...

  ### Open Questions
  - ...

  Looks good? (yes / edit / skip brainstorming)
  ```
- Wait for confirmation. If the user edits, incorporate changes.

### Step 3.5b: Implementation Plan

After brainstorming, create an implementation plan.

**If `superpowers@claude-plugins-official` is installed:**
- Delegate to `/writing-plans` with the brainstorm output + backlog entry.
- Use the plan output as input for the PRD.

**If NOT installed (inline plan):**
- Generate a plan covering:
  - Ordered implementation steps
  - Agent assignments (which agent handles which step, if using agent-team-ops)
  - Risks and mitigations
  - Estimated scope per step
- Present the plan to the user via `AskUserQuestion`:
  ```
  ## Implementation Plan: <Feature Name>

  ### Steps
  1. ...
  2. ...

  ### Agent Assignments
  - Backend: ...
  - Frontend: ...
  - Tester: ...

  ### Risks
  - ...

  Approve this plan? (yes / edit / skip planning)
  ```
- Wait for confirmation.

### Step 4: Write the PRD

**4a. Read context**

- Scan the planning directory (including `todo/`, `in-progress/`, `complete/` subdirs) —
  note the next available PRD number across all subdirs (e.g. if 01-08 exist, next is 09 —
  but check for gaps first)
- Read the 1-2 most relevant existing PRDs to match format and depth
- Re-read the full backlog entry for the chosen item
- Gather the brainstorm output (Step 3.5a) and implementation plan (Step 3.5b) if available
- If no existing PRDs exist yet, use the template below as-is

**4b. Write the PRD file**

Ensure the `todo/` subdirectory exists: `mkdir -p <planning_dir>/todo`

Create `<planning_dir>/todo/<prd_pattern>` where NN is the next number and `<name>` is
kebab-cased from the feature title.

Use the configured `prd_sections` array to generate the PRD. The file structure:

```
# PRD: <Feature Name>

> Status: Draft
> Dependencies: <features from status file this builds on>
> Scope estimate: <small | medium | large>

## <prd_sections[0].heading>

<content guided by prd_sections[0].prompt, informed by the backlog entry>

## <prd_sections[1].heading>

<content guided by prd_sections[1].prompt>

...repeat for all configured sections...
```

Render every section from `prd_sections` in order. Each section becomes a `##` heading.
Use the section's `prompt` as guidance for what to write. Pull concrete details from the
backlog entry, the brainstorm output (Step 3.5a), the implementation plan (Step 3.5b),
the project's existing PRDs, and the status file.

If brainstorming was done, incorporate the requirements, edge cases, and open questions
into the relevant PRD sections. If an implementation plan was created, include it as an
additional "Implementation Plan" section at the end of the PRD.

If there are existing PRDs in the planning directory, match their tone and depth.

**4c. Update the status file**

Add a new row to the Feature Build Progress table:

```
| <Feature Name> | Complete | <not_started for each status_column> |
```

The "Planning" column is set to "Complete" (because we just wrote the PRD). All other columns
from `status_columns` are set to the configured `status_values.not_started`.

Add a new entry to the Planning Documents table:

```
| NN | [PRD: <Feature Name>](<planning_dir>/todo/NN-prd-<feature-name>.md) | **Complete** | <deps> | <one-line summary> |
```

**4d. Remove the item from the backlog file**

Delete the planned item's full section (from `##` heading through the `---` separator).
It now lives in the planning directory.

**4e. Commit**

```
git add <planning_dir>/todo/NN-prd-<feature-name>.md <status_file> <backlog_file>
git commit -m "<commits.prd_created template with <feature> replaced>"
```

### Step 5: Respond

```
PRD written: <planning_dir>/todo/NN-prd-<feature-name>.md
Status file updated — <Feature Name> is now in the build queue.
```

## Rules

- Always ask before planning or deleting — never assume
- Never auto-select the "most logical" item — the user decides priority
- Re-show the menu after each delete so the user can chain actions
- PRDs must match existing format if prior PRDs exist — read at least one before writing
- Remove the item from the backlog file once it becomes a PRD — no duplicates
- If the backlog file does not exist, tell the user to run `/init-tracker` first
- If the backlog file is empty or all items are already tracked in the status file,
  respond: "Backlog is empty or fully planned. Use `/idea` to capture new ideas."
