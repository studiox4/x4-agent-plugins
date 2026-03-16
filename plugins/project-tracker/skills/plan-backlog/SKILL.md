---
name: plan-backlog
description: Use when the status file has no ready-to-build features and the backlog has unplanned items — presents a menu to plan or delete backlog items, then writes the PRD and updates the status file
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
-> Go to Step 4: Write the PRD

**If user picks D + number (delete):**
-> Remove that `##` section from the backlog file (from the `##` heading through the next
   `---` separator)
-> Commit using the configured `commits.backlog_deleted` template
-> Re-present the updated menu (go back to Step 2)

**If user picks S (skip):**
-> Respond: "Nothing planned. Backlog untouched." Done.

**If user picks multiple (e.g. "D1, D2, then plan 3"):**
-> Execute deletions first, then proceed to plan the chosen item.

### Step 4: Write the PRD

**4a. Read context**

- Scan the planning directory — note the next available PRD number (e.g. if 01-08 exist,
  next is 09 — but check for gaps first)
- Read the 1-2 most relevant existing PRDs to match format and depth
- Re-read the full backlog entry for the chosen item
- If no existing PRDs exist yet, use the template below as-is

**4b. Write the PRD file**

Create `<planning_dir>/<prd_pattern>` where NN is the next number and `<name>` is kebab-cased
from the feature title.

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
backlog entry, the project's existing PRDs, and the status file.

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
| NN | [PRD: <Feature Name>](<planning_dir>/NN-prd-<feature-name>.md) | **Complete** | <deps> | <one-line summary> |
```

**4d. Remove the item from the backlog file**

Delete the planned item's full section (from `##` heading through the `---` separator).
It now lives in the planning directory.

**4e. Commit**

```
git add <planning_dir>/NN-prd-<feature-name>.md <status_file> <backlog_file>
git commit -m "<commits.prd_created template with <feature> replaced>"
```

### Step 5: Respond

```
PRD written: <planning_dir>/NN-prd-<feature-name>.md
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
  respond: "Backlog is empty or fully planned. Use `/btw` to capture new ideas."
