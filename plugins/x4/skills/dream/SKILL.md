---
name: dream
description: Explore visionary ideas for the project — bold features, natural evolutions, and untapped capabilities from the tech stack. Interactive discussion that captures selected ideas to the backlog.
version: 1.0.0
license: MIT
---

# /dream — Visionary Ideas Generator

Step back from the day-to-day and think big. What could this product become?
Informed by the project's tech stack and ecosystem, not limited to what's
already planned. Interactive — the user chooses what to capture.

## Process

### 0. Load config

Read `.claude/project-tracker.config.md` from the repo root. For any missing
key, use defaults:

- `status_file`: `docs/STATUS.md`
- `backlog_file`: `docs/BACKLOG.md`
- `planning_dir`: `docs/planning/`

### 1. Read project context

Read all planning artifacts (same as `/gaps`):

- Completed PRDs in `{planning_dir}/complete/`
- In-progress PRDs in `{planning_dir}/in-progress/`
- Todo PRDs in `{planning_dir}/todo/`
- Backlog at `{backlog_file}`
- Status file at `{status_file}`
- CLAUDE.md

**Additionally**, read ecosystem context:
- llms.txt reference docs in `docs/llms-txt/` (if the directory exists)
- Use general knowledge of the tech stack's ecosystem and modern patterns

If no PRDs exist and the backlog is empty, still proceed — dream can
work from CLAUDE.md alone. But note: "I'm working from your project
overview since there aren't completed features yet. Ideas will be more
targeted after you've shipped a few features."

### 2. Generate ideas

Think across three dimensions:

**What if** — Bold features that would change the product's value
proposition. Not incremental improvements — genuine leaps. These should
make the user think "that would be a game changer."

**What's next** — Natural evolutions of what's already built, taken
further than the current plan. Follow the trajectory of existing features
to their logical next step.

**What's emerging** — Capabilities unlocked by the tech stack that the
project isn't using yet. Check reference docs for features of libraries
and frameworks that the project has installed but hasn't leveraged.

Generate 5-8 ideas across the three dimensions. For each idea:
- One-line pitch
- Why it matters (2-3 sentences)
- How it connects to what already exists
- Rough scope tag: `small` / `medium` / `large` / `epic`

**Anti-noise rule:** Every idea MUST connect back to something that exists
in the project — a feature, a library, an architectural pattern, or a user
flow. No generic suggestions like "add AI features" or "implement analytics"
unless tied to a specific part of the existing project.

**Quality over quantity.** 5 great ideas beat 8 mediocre ones. Cut anything
that feels generic or disconnected.

### 3. Present ideas conversationally

Do NOT present as a numbered action list. Present as a conversation — you're
sharing ideas you're excited about:

```
Here are some directions I think are interesting for this project...

**What if: [One-line pitch]**
[Why it matters — 2-3 sentences]. Connects to [existing feature/library].
Scope: [tag]

**What's next: [One-line pitch]**
[Why it matters]. Connects to [existing feature].
Scope: [tag]

**What's emerging: [One-line pitch]**
[Why it matters — reference specific library capability]. Connects to
[existing usage of that library].
Scope: [tag]

...

Any of these spark something? Pick the ones you'd like to capture,
or let's riff on any of them.
```

### 4. Interactive discussion

Handle the user's response:

- **User picks ideas to capture** → Write backlog entries (step 5)
- **User wants to discuss an idea** → Have a brief conversation to
  refine the idea, then ask if they want to capture the refined version
- **User riffs with their own spin** → Incorporate their direction,
  then ask if they want to capture it
- **User says "none"** → End gracefully: "No worries. Run `/dream`
  anytime you want to think big."

### 5. Capture selected ideas

For each idea the user selects, write a backlog entry to `{backlog_file}`
using the same format as `/idea`:

```
## <idea title>

> Added: <YYYY-MM-DD>
> Scope: <small | medium | large | epic>
> Fits after: <connected feature, or "anytime">

### What

<one-line pitch expanded into a clear description>

### How it fits

<how this connects to existing features and the project's direction>

### Open decisions

<key questions that need answering before this could be built>

---
```

### 6. Report

> Added N ideas to backlog.

If no ideas were captured, no report needed (the "no worries" message
from step 4 is sufficient).

## Tone

- **Enthusiastic but grounded** — show genuine excitement for ideas that
  fit the project, not generic hype
- **Opinionated** — have a point of view on which ideas are strongest
- **Collaborative** — treat this as a conversation, not a presentation
- **Concise** — each idea is a pitch, not an essay

## Rules

- Read-only on all project artifacts — only write to the backlog file
- Every idea must connect to something existing in the project
- Do not overwhelm — 5-8 ideas maximum, fewer is fine
- Do not repeat ideas already in the backlog — check first
- If the backlog file does not exist, tell the user to run `/init-tracker` first
- Never push the user to capture ideas — their choice entirely
