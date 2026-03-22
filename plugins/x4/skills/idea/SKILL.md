---
name: idea
description: Use when the user wants to capture a feature idea, improvement, or note into the project backlog without interrupting active work
version: 1.0.0
license: MIT
---

# /idea — Context-Aware Backlog Capture

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
