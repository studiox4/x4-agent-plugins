---
name: gaps
description: Scan completed and in-progress features to find product gaps — dead ends, missing connections, incomplete flows, and stale backlog items. Adds selected gaps to the backlog.
version: 1.0.0
license: MIT
---

# /gaps — Product Gap Finder

Analyze what's been built and planned to surface practical improvements the
user hasn't thought of yet. Anti-bloat by design — only finds gaps in what
already exists, never suggests new feature categories.

## Process

### 0. Load config

Read `.claude/project-tracker.config.md` from the repo root. For any missing
key, use defaults:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`

### 1. Read project context

Read these planning artifacts (do not scan source code):

- **Completed PRDs** in `{planning_dir}/complete/` — what was built
- **In-progress PRDs** in `{planning_dir}/in-progress/` — what's being built
- **Todo PRDs** in `{planning_dir}/todo/` — what's planned
- **Backlog** at `{backlog_file}` — captured ideas
- **Status file** at `{status_file}` — current project state
- **CLAUDE.md** — project overview and architecture

If no PRDs exist and the backlog is empty, tell the user:
"Not enough project context to find gaps. Build some features first, then
run `/gaps` to see what's missing."

### 2. Analyze for gaps

Search across four categories:

**Dead ends** — Features that were built but have no follow-through.
Look for: completed PRDs whose features have obvious next steps that
aren't in the backlog or any other PRD. Examples: auth exists but no
password reset, dashboard exists but no data export.

**Missing connections** — Features that should integrate but don't
reference each other. Look for: pairs of completed features that would
naturally connect but have no PRD or backlog item linking them.
Examples: notifications + billing but no payment failure alerts.

**Incomplete flows** — User journeys that start but don't finish.
Look for: features that create a setup/configuration step but have no
corresponding edit/update mechanism. Examples: onboarding wizard but
no settings page to change choices.

**Stale gaps** — Backlog items captured more than 2 weeks ago that
are now more relevant given recently completed features. Look for:
backlog items whose "Fits after" feature has since shipped.

**Anti-bloat rule:** Every gap MUST point to a specific existing feature
it extends. Do NOT suggest new feature categories. If a gap cannot
reference a concrete existing feature, it is not a gap — discard it.

### 3. Present gaps

Present findings as a numbered list using `AskUserQuestion`:

```
## Product Gaps Found

### Dead Ends
1. **[Title]** — [2-3 sentence description of what exists and what's missing]
   Connects to: [Feature name] ([PRD reference, status])

### Missing Connections
2. **[Title]** — [description]
   Connects to: [Feature A] + [Feature B]

### Incomplete Flows
3. **[Title]** — [description]
   Connects to: [Feature name]

### Stale Gaps
4. **[Title]** — [description of why this is now more relevant]
   Connects to: [Recently completed feature]

Add any of these to the backlog? (enter numbers, "all", or "none")
```

Omit any category that has no findings. If no gaps are found at all:
"No product gaps found — your feature coverage looks solid. Run `/dream`
to explore bigger ideas."

### 4. Capture selected gaps

For each gap the user selects, write a backlog entry to `{backlog_file}`
using the same format as `/idea`:

```
## <gap title>

> Added: <YYYY-MM-DD>
> Scope: <small | medium | large>
> Fits after: <connected feature name>

### What

<description of the gap and what building it would accomplish>

### How it fits

<which existing features this connects to and why the gap matters>

### Open decisions

<what needs to be figured out before building>

---
```

Scope inference:
- Dead ends → usually `small` (extending an existing feature)
- Missing connections → usually `medium` (integrating two systems)
- Incomplete flows → usually `small` to `medium`
- Stale gaps → use the scope from the original backlog entry

### 5. Report

> Added N gaps to backlog.

## Rules

- Read-only on all project artifacts — only write to the backlog file
- Never scan source code — this is a product-level tool, not a linter
- Never suggest features that don't connect to something already built
- If the backlog file does not exist, tell the user to run `/init-tracker` first
- Keep the gap list concise — aim for 3-8 high-quality gaps, not an exhaustive list
