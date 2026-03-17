# x4-project-tracker Plugin — Full Spec

A Claude Code plugin that provides backlog capture, triage, PRD generation, and status tracking for any software project. Extracted and generified from the Daykeep project's `/btw` and `/plan-backlog` workflows.

---

## 1. Overview

The x4-project-tracker plugin gives any project three capabilities:

1. **`/btw` (Backlog Capture)** — Quickly capture a feature idea, improvement, or note into a structured backlog file without interrupting active work. The agent reads just enough project context to make the entry useful.

2. **`/plan-backlog` (Triage + PRD Creation)** — Present unplanned backlog items as a menu. The user picks items to plan (generates a PRD and updates the status file) or delete. Never auto-selects.

3. **`/init-tracker` (Scaffold)** — One-time setup that creates the STATUS.md, BACKLOG.md, and planning directory for a new project.

4. **SessionStart hook** — Reminds the agent about the project tracking system on every conversation start.

All paths, PRD template sections, scope definitions, and status table format are configurable via a single config file.

---

## 2. Plugin Manifest

**File: `project-tracker/.claude-plugin/plugin.json`**

The manifest follows the official Claude Code plugins convention: minimal metadata only. Claude auto-discovers skills, commands, and hooks from the directory structure — do not list them in the manifest.

```json
{
  "name": "x4-project-tracker",
  "description": "Backlog capture, triage, PRD generation, and project status tracking for any software project",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

---

## 3. Directory Structure

```
project-tracker/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── btw.md
│   └── init-tracker.md
├── skills/
│   ├── btw/
│   │   └── SKILL.md
│   └── plan-backlog/
│       └── SKILL.md
├── hooks/
│   ├── hooks.json
│   └── session-start.sh
├── LICENSE
└── README.md
```

---

## 4. Config Schema

The plugin reads its configuration from `.claude/project-tracker.config.md` in the project root. If the file does not exist, every value falls back to the defaults shown below.

> **Note:** This config file pattern is a custom convention beyond what the official Claude Code plugin system provides. Official plugins rely on environment variables, command arguments, and frontmatter for configuration. This approach adds project-level customization that persists across sessions.

**File: `.claude/project-tracker.config.md`**

The file uses YAML frontmatter (between `---` delimiters) for all configuration values. The body of the file is ignored — only the frontmatter matters.

**Default contents:**

```yaml
# Paths (relative to repo root)
status_file: "docs/STATUS.md"
backlog_file: "docs/BACKLOG.md"
planning_dir: "docs/planning/"

# PRD filename pattern — NN is auto-incremented, <name> is kebab-cased
prd_pattern: "NN-prd-<name>.md"

# Scope definitions — customize what small/medium/large mean for your project
scope:
  small: "Single module or endpoint, no new data models"
  medium: "New data models, multiple screens or endpoints, possible external integration"
  large: "New external service, significant schema changes, crosses multiple system boundaries"

# Status table columns (Feature name + Planning are always implicit first two columns)
status_columns:
  - "Backend"
  - "Frontend"
  - "Tested"
  - "Deployed"

# Valid values for status columns
status_values:
  not_started: "Not Started"
  in_progress: "In Progress"
  complete: "Complete"
  not_applicable: "—"

# PRD template sections — each becomes a ## heading in the generated PRD
prd_sections:
  - heading: "Overview"
    prompt: "What this feature does and why it matters to the project"
  - heading: "User Stories"
    prompt: "Who benefits and how — use the format: As a <role>, I want <goal>, so that <benefit>"
  - heading: "Screens / Components"
    prompt: "List of screens, pages, or UI components involved"
  - heading: "Data Model Changes"
    prompt: "New tables, columns, types, or schema changes needed"
  - heading: "API / Endpoints"
    prompt: "New API routes, procedures, or service methods"
  - heading: "External APIs / Services"
    prompt: "Any third-party integrations required (or 'None')"
  - heading: "Open Questions"
    prompt: "Unresolved decisions that must be answered before implementation"
  - heading: "Out of Scope (v1)"
    prompt: "What we are explicitly not building in the first pass"

# Backlog entry template — sections included in each /btw entry
backlog_sections:
  - heading: "What"
    prompt: "2-4 sentences. What is this feature? What problem does it solve?"
  - heading: "How it fits"
    prompt: "1-3 sentences. What already exists that this builds on? Which areas of the codebase are involved?"
  - heading: "Open decisions"
    prompt: "Bullet list of choices that need to be made before this can be planned"

# Commit message templates
commits:
  prd_created: "docs: add PRD for <feature>, update status"
  backlog_deleted: 'chore(backlog): remove "<title>" — no longer planned'
  init: "docs: initialize project tracking files"
```

### Config resolution

1. Read `.claude/project-tracker.config.md` — parse YAML frontmatter.
2. For any missing key, use the default shown above.
3. All paths are resolved relative to the repository root.

---

## 5. `/init-tracker` Command

**File: `project-tracker/commands/init-tracker.md`**

<pre><code>---
description: Scaffold project tracking files (STATUS.md, BACKLOG.md, planning directory)
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

Initialize the project tracker for this repository.

## Process

1. **Read config** — load `.claude/project-tracker.config.md`. If it does not exist, use all defaults.

2. **Check for existing files** — if the status file, backlog file, or planning directory already exist, list them and ask the user before overwriting. Never silently overwrite.

3. **Create the config file** if `.claude/project-tracker.config.md` does not exist:
   - Write the default config template (from the Config Schema section of this plugin's spec)
   - Tell the user they can customize it

4. **Create the status file** at the configured `status_file` path with this template:

   # &lt;Project Name&gt; — Project Status

   &gt; Last updated: &lt;YYYY-MM-DD&gt;

   ---

   ## Current Focus

   *Set your current focus here.*

   ---

   ## Planning Documents

   | # | Document | Status | Dependencies | Notes |
   |---|----------|--------|--------------|-------|

   ## Feature Build Progress

   | Feature | Planning | &lt;status_columns[0]&gt; | &lt;status_columns[1]&gt; | ... |
   |---------|----------|---------------------|---------------------|-----|

   ---

   ## Key Decisions

   | Decision | Choice | Status | See |
   |----------|--------|--------|-----|

   Use the project name from `package.json` `name` field, the repo directory name, or ask the user. The `&lt;col&gt;` headers come from the configured `status_columns`.

5. **Create the backlog file** at the configured `backlog_file` path:

   # &lt;Project Name&gt; — Backlog & Ideas

   Captured during development. Review during planning sessions.

   ---

6. **Create the planning directory** at the configured `planning_dir` path (`mkdir -p`).

7. **Commit all created files:**

   git add &lt;all created files&gt;
   git commit -m "&lt;commits.init from config&gt;"

8. **Respond:**

   &gt; Project tracker initialized.
   &gt; - Status: `&lt;status_file&gt;`
   &gt; - Backlog: `&lt;backlog_file&gt;`
   &gt; - Planning: `&lt;planning_dir&gt;`
   &gt; - Config: `.claude/project-tracker.config.md`
   &gt;
   &gt; Customize your config, then use `/btw` to capture ideas and `/plan-backlog` to turn them into PRDs.
</code></pre>

---

## 6. `/btw` Command + Skill

### Command

**File: `project-tracker/commands/btw.md`**

<pre><code>---
description: Add an idea or feature to the project backlog with project context
argument-hint: "&lt;your idea or note&gt;"
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

Use the btw skill to add the following to the backlog:

$ARGUMENTS
</code></pre>

### Skill

**File: `project-tracker/skills/btw/SKILL.md`**

<pre><code>---
name: btw
description: Use when the user wants to capture a feature idea, improvement, or note into the project backlog without interrupting active work
version: 1.0.0
license: MIT
---

# /btw — Context-Aware Backlog Capture

## Overview

Takes a raw idea and writes a structured, project-aware backlog entry to the backlog file. Reads just enough project context to make the entry useful to future-you — not a voice memo, a real plan seed.

## Process

**0. Load config**

Read `.claude/project-tracker.config.md` from the repo root. Parse YAML frontmatter. For any missing key, use these defaults:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`
- `scope.small`: Single module or endpoint, no new data models
- `scope.medium`: New data models, multiple screens or endpoints, possible external integration
- `scope.large`: New external service, significant schema changes, crosses multiple system boundaries
- `backlog_sections`: What, How it fits, Open decisions (with default prompts)

**1. Read context (fast scan only)**

Read these — do not deep-read, just scan for relevance to the idea:

- The status file — current build phase, what is complete, build order
- The planning directory — skim filenames, open the one most relevant to the idea (if any)
- Check if a related entry already exists in the backlog file — if so, consider extending it instead of creating a duplicate

**2. Write the entry**

Append to the backlog file in this format:

    ## &lt;short, specific title&gt;

    &gt; Added: &lt;YYYY-MM-DD&gt;
    &gt; Scope: &lt;small | medium | large&gt;
    &gt; Fits after: &lt;feature name from status file build order, or "anytime"&gt;

    ### &lt;backlog_sections[0].heading&gt;

    &lt;content guided by backlog_sections[0].prompt&gt;

    ### &lt;backlog_sections[1].heading&gt;

    &lt;content guided by backlog_sections[1].prompt&gt;

    ### &lt;backlog_sections[2].heading&gt;

    &lt;content guided by backlog_sections[2].prompt&gt;

    ---

Render all sections from the configured `backlog_sections` array in order. Each section becomes a `###` heading under the `##` entry.

**3. Respond with one line**

&gt; Added to backlog: "&lt;title&gt;" (scope: &lt;small|medium|large&gt;)

No summary, no follow-up questions. Done.

## Scope Guide

Use the scope definitions from the config. If config is missing, use:

| Scope  | What it means                                                                      |
| ------ | ---------------------------------------------------------------------------------- |
| small  | Single module or endpoint, no new data models                                      |
| medium | New data models, multiple screens or endpoints, possible external integration      |
| large  | New external service, significant schema changes, crosses multiple system boundaries |

## Rules

- Never deep-read the whole codebase — scan only what is relevant
- If the idea duplicates something already in the backlog file, extend the existing entry rather than creating a second one
- Do not ask clarifying questions — write the best entry possible from what was given, note unknowns in the open decisions section
- Do not interrupt active work — this is a capture command, not a planning session
- If the backlog file does not exist, tell the user to run `/init-tracker` first
</code></pre>

---

## 7. `/plan-backlog` Skill

**File: `project-tracker/skills/plan-backlog/SKILL.md`**

<pre><code>---
name: plan-backlog
description: Use when the status file has no ready-to-build features and the backlog has unplanned items — presents a menu to plan or delete backlog items, then writes the PRD and updates the status file
version: 1.0.0
license: MIT
---

# plan-backlog — Backlog Triage + PRD Creation

## Overview

Bridges backlog file -&gt; planning directory -&gt; status file. Presents a triage menu so the user decides what to plan, what to delete, and what to leave. Never auto-selects.

## Process

### Step 0: Load config

Read `.claude/project-tracker.config.md` from the repo root. Parse YAML frontmatter. For any missing key, use these defaults:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`
- `prd_pattern`: `NN-prd-&lt;name&gt;.md`
- `status_columns`: Backend, Frontend, Tested, Deployed
- `status_values.not_started`: Not Started
- `status_values.complete`: Complete
- `status_values.not_applicable`: —
- `prd_sections`: Overview, User Stories, Screens/Components, Data Model Changes, API/Endpoints, External APIs/Services, Open Questions, Out of Scope (v1) (with default prompts)
- `commits.prd_created`: `docs: add PRD for &lt;feature&gt;, update status`
- `commits.backlog_deleted`: `chore(backlog): remove "&lt;title&gt;" — no longer planned`

### Step 1: Parse the backlog

Read the backlog file. Extract each `##` entry as an item. For each item note:

- Title
- Scope (small / medium / large)
- "Fits after" value

Also read the status file's Feature Build Progress table to identify which backlog items (if any) are already tracked — exclude those from the menu.

### Step 2: Present the triage menu

Use `AskUserQuestion` with this format:

    Backlog has N items not yet planned. What would you like to do?

    PLAN (writes PRD + adds to status file):
      1. &lt;Title&gt; — &lt;scope&gt;, fits after &lt;fits-after&gt;
      2. &lt;Title&gt; — &lt;scope&gt;, fits after &lt;fits-after&gt;
      ...

    DELETE (removes from backlog permanently):
      D1. Delete: &lt;Title&gt;
      D2. Delete: &lt;Title&gt;
      ...

      S. Skip — nothing to plan right now

Wait for the user's response before doing anything.

### Step 3: Handle the response

**If user picks a number (plan):**
-&gt; Go to Step 4: Write the PRD

**If user picks D + number (delete):**
-&gt; Remove that `##` section from the backlog file (from the `##` heading through the next `---` separator)
-&gt; Commit using the configured `commits.backlog_deleted` template
-&gt; Re-present the updated menu (go back to Step 2)

**If user picks S (skip):**
-&gt; Respond: "Nothing planned. Backlog untouched." Done.

**If user picks multiple (e.g. "D1, D2, then plan 3"):**
-&gt; Execute deletions first, then proceed to plan the chosen item.

### Step 4: Write the PRD

**4a. Read context**

- Scan the planning directory — note the next available PRD number (e.g. if 01-08 exist, next is 09 — but check for gaps first)
- Read the 1-2 most relevant existing PRDs to match format and depth
- Re-read the full backlog entry for the chosen item
- If no existing PRDs exist yet, use the template below as-is

**4b. Write the PRD file**

Create `&lt;planning_dir&gt;/&lt;prd_pattern&gt;` where NN is the next number and `&lt;name&gt;` is kebab-cased from the feature title.

Use the configured `prd_sections` array to generate the PRD. The file structure:

    # PRD: &lt;Feature Name&gt;

    &gt; Status: Draft
    &gt; Dependencies: &lt;features from status file this builds on&gt;
    &gt; Scope estimate: &lt;small | medium | large&gt;

    ## &lt;prd_sections[0].heading&gt;

    &lt;content guided by prd_sections[0].prompt, informed by the backlog entry&gt;

    ## &lt;prd_sections[1].heading&gt;

    &lt;content guided by prd_sections[1].prompt&gt;

    ...repeat for all configured sections...

Render every section from `prd_sections` in order. Each section becomes a `##` heading. Use the section's `prompt` as guidance for what to write. Pull concrete details from the backlog entry, the project's existing PRDs, and the status file.

If there are existing PRDs in the planning directory, match their tone and depth.

**4c. Update the status file**

Add a new row to the Feature Build Progress table:

    | &lt;Feature Name&gt; | Complete | &lt;not_started for each status_column&gt; |

The "Planning" column is set to "Complete" (because we just wrote the PRD). All other columns from `status_columns` are set to the configured `status_values.not_started`.

Add a new entry to the Planning Documents table:

    | NN | [PRD: &lt;Feature Name&gt;](&lt;planning_dir&gt;/NN-prd-&lt;feature-name&gt;.md) | **Complete** | &lt;deps&gt; | &lt;one-line summary&gt; |

**4d. Remove the item from the backlog file**

Delete the planned item's full section (from `##` heading through the `---` separator). It now lives in the planning directory.

**4e. Commit**

    git add &lt;planning_dir&gt;/NN-prd-&lt;feature-name&gt;.md &lt;status_file&gt; &lt;backlog_file&gt;
    git commit -m "&lt;commits.prd_created template with &lt;feature&gt; replaced&gt;"

### Step 5: Respond

    PRD written: &lt;planning_dir&gt;/NN-prd-&lt;feature-name&gt;.md
    Status file updated — &lt;Feature Name&gt; is now in the build queue.

## Rules

- Always ask before planning or deleting — never assume
- Never auto-select the "most logical" item — the user decides priority
- Re-show the menu after each delete so the user can chain actions
- PRDs must match existing format if prior PRDs exist — read at least one before writing
- Remove the item from the backlog file once it becomes a PRD — no duplicates
- If the backlog file does not exist, tell the user to run `/init-tracker` first
- If the backlog file is empty or all items are already tracked in the status file, respond: "Backlog is empty or fully planned. Use `/btw` to capture new ideas."
</code></pre>

---

## 8. SessionStart Hook

**File: `project-tracker/hooks/hooks.json`**

The hooks schema follows the official Claude Code plugin format. The `${CLAUDE_PLUGIN_ROOT}` variable resolves to the plugin's root directory at runtime.

```json
{
  "description": "Project tracking session reminders",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**File: `project-tracker/hooks/session-start.sh`**

```bash
#!/usr/bin/env bash
cat <<'HOOK_MSG'
Project tracker is active. Key commands:
  /btw <idea>      — capture a feature idea to the backlog
  /plan-backlog    — triage backlog items into PRDs
  /init-tracker    — scaffold tracking files for a new project
Config: .claude/project-tracker.config.md
HOOK_MSG
```

---

## 9. Complete File Contents — Copy-Ready

Every file in the plugin is reproduced below in its final, ready-to-copy form. The sections above (5-8) describe the behavior; the blocks below are the literal file contents.

### `project-tracker/.claude-plugin/plugin.json`

```json
{
  "name": "x4-project-tracker",
  "description": "Backlog capture, triage, PRD generation, and project status tracking for any software project",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

### `project-tracker/commands/btw.md`

    ---
    description: Add an idea or feature to the project backlog with project context
    argument-hint: "<your idea or note>"
    allowed-tools: [Read, Write, Edit, Glob, Grep]
    ---

    Use the btw skill to add the following to the backlog:

    $ARGUMENTS

### `project-tracker/commands/init-tracker.md`

    ---
    description: Scaffold project tracking files (STATUS.md, BACKLOG.md, planning directory)
    allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
    ---

    Initialize the project tracker for this repository.

    ## Process

    1. **Read config** — load `.claude/project-tracker.config.md`. If it does not exist, use all defaults.

    2. **Check for existing files** — if the status file, backlog file, or planning directory already exist,
       list them and ask the user before overwriting. Never silently overwrite.

    3. **Create the config file** if `.claude/project-tracker.config.md` does not exist:
       - Write the default config template (from the Config Schema section of this plugin's spec)
       - Tell the user they can customize it

    4. **Create the status file** at the configured `status_file` path with this template:

       ```
       # <Project Name> — Project Status

       > Last updated: <YYYY-MM-DD>

       ---

       ## Current Focus

       *Set your current focus here.*

       ---

       ## Planning Documents

       | # | Document | Status | Dependencies | Notes |
       |---|----------|--------|--------------|-------|

       ## Feature Build Progress

       | Feature | Planning | <status_columns[0]> | <status_columns[1]> | ... |
       |---------|----------|---------------------|---------------------|-----|

       ---

       ## Key Decisions

       | Decision | Choice | Status | See |
       |----------|--------|--------|-----|
       ```

       Use the project name from `package.json` name field, the repo directory name, or ask the user.
       The `<col>` headers come from the configured `status_columns`.

    5. **Create the backlog file** at the configured `backlog_file` path:

       ```
       # <Project Name> — Backlog & Ideas

       Captured during development. Review during planning sessions.

       ---
       ```

    6. **Create the planning directory** at the configured `planning_dir` path (`mkdir -p`).

    7. **Commit all created files:**

       ```
       git add <all created files>
       git commit -m "<commits.init from config>"
       ```

    8. **Respond:**

       > Project tracker initialized.
       > - Status: `<status_file>`
       > - Backlog: `<backlog_file>`
       > - Planning: `<planning_dir>`
       > - Config: `.claude/project-tracker.config.md`
       >
       > Customize your config, then use `/btw` to capture ideas and `/plan-backlog` to turn them into PRDs.

### `project-tracker/skills/btw/SKILL.md`

    ---
    name: btw
    description: Use when the user wants to capture a feature idea, improvement, or note into the project backlog without interrupting active work
    version: 1.0.0
    license: MIT
    ---

    # /btw — Context-Aware Backlog Capture

    ## Overview

    Takes a raw idea and writes a structured, project-aware backlog entry to the backlog file.
    Reads just enough project context to make the entry useful to future-you — not a voice memo,
    a real plan seed.

    ## Process

    **0. Load config**

    Read `.claude/project-tracker.config.md` from the repo root. Parse YAML frontmatter. For any
    missing key, use these defaults:

    - `status_file`: `docs/STATUS.md`
    - `backlog_file`: `docs/BACKLOG.md`
    - `planning_dir`: `docs/planning/`
    - `scope.small`: Single module or endpoint, no new data models
    - `scope.medium`: New data models, multiple screens or endpoints, possible external integration
    - `scope.large`: New external service, significant schema changes, crosses multiple system boundaries
    - `backlog_sections`: What, How it fits, Open decisions (with default prompts)

    **1. Read context (fast scan only)**

    Read these — do not deep-read, just scan for relevance to the idea:

    - The status file — current build phase, what is complete, build order
    - The planning directory — skim filenames, open the one most relevant to the idea (if any)
    - Check if a related entry already exists in the backlog file — if so, consider extending it
      instead of creating a duplicate

    **2. Write the entry**

    Append to the backlog file in this format:

    ```
    ## <short, specific title>

    > Added: <YYYY-MM-DD>
    > Scope: <small | medium | large>
    > Fits after: <feature name from status file build order, or "anytime">

    ### <backlog_sections[0].heading>

    <content guided by backlog_sections[0].prompt>

    ### <backlog_sections[1].heading>

    <content guided by backlog_sections[1].prompt>

    ### <backlog_sections[2].heading>

    <content guided by backlog_sections[2].prompt>

    ---
    ```

    Render all sections from the configured `backlog_sections` array in order. Each section becomes
    a `###` heading under the `##` entry.

    **3. Respond with one line**

    > Added to backlog: "<title>" (scope: <small|medium|large>)

    No summary, no follow-up questions. Done.

    ## Scope Guide

    Use the scope definitions from the config. If config is missing, use:

    | Scope  | What it means                                                                      |
    | ------ | ---------------------------------------------------------------------------------- |
    | small  | Single module or endpoint, no new data models                                      |
    | medium | New data models, multiple screens or endpoints, possible external integration      |
    | large  | New external service, significant schema changes, crosses multiple system boundaries |

    ## Rules

    - Never deep-read the whole codebase — scan only what is relevant
    - If the idea duplicates something already in the backlog file, extend the existing entry
      rather than creating a second one
    - Do not ask clarifying questions — write the best entry possible from what was given,
      note unknowns in the open decisions section
    - Do not interrupt active work — this is a capture command, not a planning session
    - If the backlog file does not exist, tell the user to run `/init-tracker` first

### `project-tracker/skills/plan-backlog/SKILL.md`

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

### `project-tracker/hooks/hooks.json`

```json
{
  "description": "Project tracking session reminders",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### `project-tracker/hooks/session-start.sh`

```bash
#!/usr/bin/env bash
cat <<'HOOK_MSG'
Project tracker is active. Key commands:
  /btw <idea>      — capture a feature idea to the backlog
  /plan-backlog    — triage backlog items into PRDs
  /init-tracker    — scaffold tracking files for a new project
Config: .claude/project-tracker.config.md
HOOK_MSG
```

### `project-tracker/LICENSE`

Include an MIT license (or your preferred license).

### `project-tracker/README.md`

Include a README with installation instructions, usage examples, and configuration reference.
