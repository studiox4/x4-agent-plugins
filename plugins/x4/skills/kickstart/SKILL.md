---
name: kickstart
description: Brainstorm app vision, design UI, prioritize features, and batch-generate PRDs to kickstart a new project
version: 1.0.0
license: MIT
---

# /kickstart — Project Kickstart

Interactive planning session for a newly scaffolded project. Takes the user
from "I want to build X" to a fully planned backlog with PRDs, UI design
specs, and a prioritized build order — ready for `/work` to start building.

Run this after `/create` + `/init-setup` (or `/tour`). This is the bridge
between "I have a project" and "I'm building features."

## Prerequisites

1. Must be inside an x4-mono project (check for `turbo.json`).
2. Project tracker must be initialized (check for `docs/BACKLOG.md` or
   configured backlog file). If not, run `/init-tracker` first.
3. Planning directory must exist (`docs/planning/todo/`). If not, create it.

## Process

### Step 1: Vision

Use `AskUserQuestion`:

```
## What are you building?

Describe your app in a few sentences. What does it do? Who is it for?
What problem does it solve?

Examples:
- "A SaaS dashboard for tracking fitness goals with AI coaching"
- "An internal tool for our sales team to manage leads and proposals"
- "A marketplace for freelance designers to sell templates"

Your vision:
```

Save the response as `VISION` — this context feeds into every step that follows.

### Step 2: Feature Brainstorm

Use the vision to generate an initial feature list, then refine it with
the user interactively.

**If `superpowers@claude-plugins-official` is installed:**
- Delegate to `/brainstorming` with the vision as input.
- Frame the brainstorm around: "What features does this app need for a
  useful v1 launch?"
- Use the brainstorming output as the starting feature list.

**If NOT installed (inline brainstorm):**
- Generate a feature list covering:
  - Core features (the minimum for the app to be useful)
  - Auth & user management (signup, login, roles, profile)
  - Data features (CRUD, search, filtering, dashboards)
  - AI features (if the project includes `packages/ai-integrations/`)
  - Integrations (payments, email, notifications, third-party APIs)
  - Marketing & growth (landing page, onboarding flow, analytics)

Present via `AskUserQuestion`:

```
## Feature Brainstorm

Based on your vision, here's a starting feature list for v1:

### Core
1. <feature> — <one-line description>
2. <feature> — <one-line description>
3. <feature> — <one-line description>

### User Management
4. <feature> — <one-line description>
5. <feature> — <one-line description>

### Data & Dashboard
6. <feature> — <one-line description>
7. <feature> — <one-line description>

### AI Features [if applicable]
8. <feature> — <one-line description>

### Integrations [if applicable]
9. <feature> — <one-line description>

What would you like to change?

1. Looks good — continue with these
2. Add features — I want to add more
3. Remove features — cut some of these
4. Edit features — change descriptions or scope
5. Start over — rethink the feature list
```

Loop until the user confirms the list. Each round, re-present the updated
list with the same format.

Save the confirmed list as `FEATURES`.

### Step 3: Prioritize and Sequence

Present the confirmed features and ask the user to define build order.

Use `AskUserQuestion`:

```
## Build Order

Let's sequence these features. Which ones should be built first?

Think about:
- What depends on what? (auth before dashboard, schema before API)
- What delivers value earliest? (core features before nice-to-haves)
- What's riskiest? (build risky things early to learn fast)

Here's a suggested order based on dependencies:

### Phase 1 — Foundation
1. <feature> — needed by everything else
2. <feature> — core data model

### Phase 2 — Core Experience
3. <feature> — the main thing users do
4. <feature> — supporting workflow

### Phase 3 — Polish & Growth
5. <feature> — nice-to-have
6. <feature> — growth feature

Adjust this order?

1. Looks good — use this sequence
2. Reorder — I want to change the sequence
3. Add phases — split differently
```

Loop until confirmed. Save as `BUILD_ORDER`.

### Step 4: UI Design

For each user-facing feature, generate UI design direction. This step
creates design specs that feed into the PRDs and guide the frontend agent.

**If `frontend-design@claude-plugins-official` is installed:**
- For each user-facing feature in `FEATURES`, delegate to the
  `frontend-design` skill to generate:
  - Page/screen layout description
  - Key components needed
  - Interaction patterns (forms, modals, navigation)
  - Responsive behavior
  - Design tokens / style direction
- Collect all design output as `UI_SPECS`.

**If NOT installed (inline design):**
- For each user-facing feature, generate a design brief covering:
  - Pages/screens involved
  - Key UI components (cards, tables, forms, modals, etc.)
  - User flow (step-by-step what the user does)
  - Layout approach (sidebar, dashboard grid, wizard, etc.)
  - Mobile considerations (if mobile app is included)

Present a summary of all UI specs via `AskUserQuestion`:

```
## UI Design Overview

Here's the UI direction for each feature:

### <Feature 1>
- **Pages:** /dashboard, /dashboard/[id]
- **Layout:** Sidebar nav + main content grid
- **Key components:** StatsCard, ActivityFeed, FilterBar
- **User flow:** Login → Dashboard → Click item → Detail view → Edit

### <Feature 2>
- **Pages:** /settings, /settings/profile, /settings/billing
- **Layout:** Tabbed settings page
- **Key components:** ProfileForm, BillingCard, PlanSelector
- **User flow:** Nav → Settings → Select tab → Edit → Save

... (one section per user-facing feature)

Feedback?

1. Looks good — use these designs
2. Change a feature's design — tell me which one
3. Add design details — I have specific ideas
```

Loop until confirmed. Save as `UI_SPECS`.

### Step 5: Batch Generate PRDs

For each feature in `BUILD_ORDER`, generate a full PRD.

**5a. Load context**

- Read `.claude/project-tracker.config.md` for PRD config
- Use defaults if not configured (same as `/plan-backlog` Step 0)
- Read existing PRDs in `docs/planning/` to match format (if any exist)

**5b. Generate PRDs**

For each feature, in build order:

1. Assign the next available PRD number (NN).
2. Write the PRD to `docs/planning/todo/NN-prd-<kebab-name>.md` using
   the configured `prd_sections`.
3. Include in the PRD:
   - The vision context (`VISION`)
   - The feature description from `FEATURES`
   - The UI spec from `UI_SPECS` (if it's a user-facing feature) as
     a "Screens/Components" or "UI Design" section
   - Dependencies on other features (from `BUILD_ORDER` sequencing)
   - Implementation plan with agent assignments:
     - Backend agent: schema, API routes, tRPC procedures
     - Frontend agent: pages, components, styling
     - Tester agent: test plan for this feature
   - The brainstorm context if superpowers was used

PRD header format:

```markdown
# PRD: <Feature Name>

> Status: Draft
> Priority: Phase <N> — Feature <M> of <total>
> Dependencies: <list of features this depends on, or "None">
> Scope estimate: <small | medium | large>
> UI spec: <Yes | No (backend-only feature)>
```

**5c. Update STATUS.md**

Add ALL features to the Feature Build Progress table at once:

```
| <Feature Name> | Complete | <not_started for each status_column> |
```

Add ALL PRDs to the Planning Documents table:

```
| NN | [PRD: <Feature Name>](docs/planning/todo/NN-prd-<name>.md) | **Complete** | <deps> | <summary> |
```

**5d. Clear backlog entries**

If any of the planned features match existing backlog entries, remove
them from BACKLOG.md (they now live as PRDs).

**5e. Commit**

```bash
git add docs/planning/todo/ docs/STATUS.md docs/BACKLOG.md
git commit -m "docs: kickstart — add PRDs for <N> features, update status"
```

### Step 6: Summary

Present the final output via `AskUserQuestion`:

```
## Kickstart Complete!

### Vision
<1-2 sentence summary>

### Features Planned: <N>
| # | Feature | Phase | Scope | PRD |
|---|---------|-------|-------|-----|
| 1 | <name>  | 1     | medium| docs/planning/todo/01-prd-<name>.md |
| 2 | <name>  | 1     | small | docs/planning/todo/02-prd-<name>.md |
| 3 | <name>  | 2     | large | docs/planning/todo/03-prd-<name>.md |
...

### UI Specs
- <N> features have UI design direction in their PRDs

### Build Order
- Phase 1: <feature>, <feature> (foundation)
- Phase 2: <feature>, <feature> (core experience)
- Phase 3: <feature>, <feature> (polish)

### What's Next
- Review your PRDs in docs/planning/todo/
- Edit any PRD to adjust scope or requirements
- Run /work to start building Phase 1, Feature 1

Ready to start building? Run:
  /work
```

## Rules

- Always use `AskUserQuestion` for every decision point. Never assume.
- Loop on each step until the user explicitly confirms.
- Respect the user's pace — they may want to think between steps.
- If `superpowers` is installed, delegate brainstorming to it. If
  `frontend-design` is installed, delegate UI design to it. Always
  fall back to inline alternatives if plugins aren't available.
- PRD numbering must be sequential and gap-free across all planning
  subdirectories (todo, in-progress, complete).
- Every PRD must include agent assignments so `/work` can dispatch
  without additional planning.
- User-facing features must include UI specs in their PRDs. Backend-only
  features (schema migrations, API-only endpoints) skip the UI section.
- If the project has no `packages/ai-integrations/`, skip AI feature
  suggestions in the brainstorm.
- If the project has no `apps/mobile*`, skip mobile considerations in
  UI design.
- Keep each PRD focused — one feature per PRD, not a monolithic spec.
- The entire kickstart session should feel like a conversation, not a
  form to fill out.
