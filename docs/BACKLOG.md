# x4 Plugin Backlog

Ideas and features captured for future planning.

---

## Ideas

### Plan Mode Workflow Bridge
**Captured:** 2026-04-04

When a user enters Claude's plan mode (or uses superpowers `/brainstorming`, or any structured planning tool), x4 should recognize this context and tie it into the PRD/backlog workflow automatically. This is a wrapper/bridge so that regardless of how the user does their planning — Claude plan mode, superpowers brainstorm, writing-plans, etc. — the output gets properly routed into `docs/planning/todo/` as a PRD, STATUS.md gets updated, and the standard x4 lifecycle kicks in. The user shouldn't have to manually copy plan outputs into x4 structures.

Key behaviors:
- Detect when plan mode is active or a planning skill just completed
- Offer to convert the plan output into a x4 PRD
- Write the PRD to `docs/planning/todo/` with correct frontmatter
- Update STATUS.md / BACKLOG.md to reflect the new item
- Could also work as a hook: `PostToolUse` on plan-related tool events

---
