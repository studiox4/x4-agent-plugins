---
name: plan-bridge
description: Use when the user just finished any planning session and wants to capture it in the x4 workflow — Claude plan mode (ExitPlanMode), superpowers /brainstorming or /writing-plans, or a planning conversation. Converts the plan into a PRD in docs/planning/todo/, updates STATUS.md, and removes the item from BACKLOG.md if it came from there. Trigger for "turn this plan into a PRD", "save this as a PRD", "add this to the backlog as a feature", "I just finished planning — what now?", after ExitPlanMode fires, or any time the user has finished thinking through a feature and wants to lock it into the build queue. Always invoke this skill when the user exits plan mode or after /brainstorming or /writing-plans completes.
version: 1.0.0
license: MIT
---

# /plan-bridge — Planning Output → x4 PRD

Converts any planning session into a formal PRD and routes it into the x4 lifecycle.
Works regardless of how the planning happened: Claude plan mode, superpowers skills,
or a free-form conversation.

## Step 0: Load config

Read `.claude/project-tracker.config.md` if it exists. Use these defaults for any missing key:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`
- `prd_pattern`: `NN-prd-<name>.md`
- `status_columns`: Backend, Frontend, Tested, Deployed

Check that `docs/planning/todo/` exists. If neither `docs/planning/` nor `docs/STATUS.md`
exist, tell the user to run `/x4:init-tracker` first and stop.

## Step 1: Gather the planning context

The goal here is to reconstruct what was planned so you can write a solid PRD.
Work through these sources in order — stop at the first one that yields enough content:

**Source A — Active plan mode session:**
Check if a plan file was just written by reading `.claude/plans/` for recently modified
`.md` files (use `ls -t .claude/plans/*.md 2>/dev/null | head -5`). If a plan file
exists and was clearly the focus of this conversation, read it. This is the richest
source — it contains the full structured plan the user approved.

**Source B — Superpowers output in conversation:**
If `/brainstorming` or `/writing-plans` was used in this session, the output is already
in the conversation context. Extract: the feature name, goals, user stories, and any
implementation steps that emerged.

**Source C — Arguments provided:**
If the user passed text to `/plan-bridge` (via `$ARGUMENTS`), treat that as a brief
description of the planned feature. You'll need to ask a few clarifying questions.

**Source D — Nothing structured yet:**
Ask the user to describe what they just planned in a sentence or two. Then proceed.

If multiple sources are available (e.g., both a plan file AND conversation context from
brainstorming), merge them — the plan file usually has the more structured output.

## Step 2: Extract and confirm the feature summary

From whatever context you gathered, extract:

1. **Feature name** — a short title (3-6 words)
2. **One-sentence summary** — what this feature does for the user
3. **Key user stories** — what the user can do once it's shipped (2-5 bullets)
4. **Scope estimate** — small / medium / large (use your judgment from the plan complexity)
5. **Backlog origin** — does this correspond to an entry in `docs/BACKLOG.md`? If so, note
   which one (you'll remove it after writing the PRD).

Present a quick confirmation to the user:

```
## Ready to write PRD

Feature: <name>
Summary: <one sentence>
Scope: <small | medium | large>
<Backlog item: "<title>" will be removed after PRD is written.>

Write PRD now? (yes / edit / cancel)
```

If the user wants to edit, let them correct the summary inline before proceeding.
If they cancel, stop — nothing is written.

## Step 3: Write the PRD

**3a. Determine the PRD number**

Scan `docs/planning/` (including `todo/`, `in-progress/`, `complete/` subdirs) for
existing PRD files matching `NN-prd-*.md`. Find the next available number. If no PRDs
exist yet, start at `01`.

**3b. Draft the PRD content**

Use the planning context from Step 1 to fill in each section. The goal is a spec that
an agent team can build from — not a business document, not a vague wish list.

```markdown
# PRD: <Feature Name>

> Status: Draft
> Dependencies: <other features this builds on, or "none">
> Scope estimate: <small | medium | large>

## Overview

<2-4 sentences. What is this feature? Why does it exist? Who benefits?>

## User Stories

<User-facing outcomes. "As a [user], I can [action] so that [benefit]."
Pull from brainstorm/plan output. Aim for 3-6 stories.>

## Screens / Components

<What UI changes or new screens are needed? If backend-only, note that.>

## Data Model Changes

<New tables, columns, schema changes. "None" if not applicable.>

## API / Endpoints

<New routes or mutations needed. "None" if not applicable.>

## External APIs / Services

<Third-party integrations, webhooks, or external dependencies. "None" if not applicable.>

## Implementation Notes

<Key technical decisions, constraints, or approach from the planning session.
This is where plan mode output and /writing-plans output is especially valuable.>

## Open Questions

<Anything unresolved that the implementer should watch for.>

## Out of Scope (v1)

<Explicitly call out what is NOT in this version to prevent scope creep.>
```

If existing PRDs are present in the planning directory, read one to match their tone
and depth before writing.

**3c. Write the file**

Create `docs/planning/todo/<NN>-prd-<kebab-case-name>.md` with the PRD content.

**3d. Update STATUS.md**

If `docs/STATUS.md` exists, add a row to the Feature Build Progress table:

```
| <Feature Name> | Complete | Not Started | Not Started | Not Started | Not Started |
```

And add a row to the Planning Documents table:

```
| NN | [PRD: <Feature Name>](docs/planning/todo/NN-prd-<name>.md) | **Complete** | <deps> | <summary> |
```

If STATUS.md doesn't follow a standard table format, append the PRD reference at the
bottom of the file with a brief note.

**3e. Remove from BACKLOG.md (if applicable)**

If this feature came from a `docs/BACKLOG.md` entry (identified in Step 2), remove that
`##` section from the file (from the `##` heading through the next `---` separator or
end of file). The feature now lives in the planning directory.

## Step 4: Commit and report

Stage and commit the new files:

```bash
git add docs/planning/todo/<prd-file> docs/STATUS.md docs/BACKLOG.md
git commit -m "docs: add PRD for <feature name>, update status"
```

Only stage files that actually changed. If STATUS.md or BACKLOG.md weren't modified,
leave them out of the commit.

Report to the user:

```
PRD written: docs/planning/todo/NN-prd-<name>.md

Next: run /x4:work to start building, or /x4:plan-backlog to plan another feature.
```

## Rules

- Never write a PRD without confirming the feature name and summary with the user first —
  the plan context might be ambiguous (e.g., a plan that covered multiple features)
- If no planning context exists at all, offer to run `/x4:plan-backlog` instead — that
  skill is better suited for brainstorming from scratch
- Match the PRD format of existing PRDs in the project if any are present
- Don't add the feature back to BACKLOG.md after writing the PRD — it would create a
  duplicate. The PRD in `todo/` IS the backlog item now.
- If the user passed a very thin description (just a few words), ask at least: "What
  should a user be able to do once this is built?" before writing the PRD — you need
  at least one concrete user story to write a useful spec
