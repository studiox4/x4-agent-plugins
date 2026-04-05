# x4 Plugin Backlog

Ideas and features captured for future planning.

---

## Ideas

### Skill Quality Pass — Skill-Creator Evals for All Skills
**Captured:** 2026-04-04

Every x4 skill should be validated through the Anthropic skill-creator workflow (snapshot → test prompts → with-skill vs baseline runs → eval viewer → iterate). Only `plan-backlog` has been through this process so far.

**Tier 1 — High impact, complex (do first)**

| Skill | Focus area |
|---|---|
| `work` | Core 7-phase pipeline, agent spawning, phase transitions |
| `e2e-setup` | 3-app-type wizard branches, scaffold output correctness |
| `run-tests` | Multi-strategy routing logic (web/marketing/desktop detection) |
| `plan-bridge` | Plan mode context detection, PRD output quality |
| `verify-local` | Gate logic, auto-fix limits, escalation behavior |
| `opensrc-init` | Gitignore-before-fetch ordering, CLAUDE.md update quality |

**Tier 2 — Important, moderate complexity**

`kickstart`, `market-update`, `init-setup`, `deploy-setup`, `doctor`, `upgrade`

**Tier 3 — Simpler; description-optimizer pass more valuable than full evals**

`opensrc-update`, `opensrc-status`, `market-email`, `market-linkedin`, `market-tweet`, `market-subscribe`, `pr-create`, `pr-status`, `pr-cleanup`, `gaps`, `dream`, `add`, `create`, `onboard`, `tour`, `env`, `help`, `idea`, `init-agents`, `init-tracker`, `status`

**Process per skill:**
1. Snapshot current skill (baseline = old, new = current)
2. Write 3 realistic test prompts in `skill-creator-workspace/<skill>/evals/evals.json`
3. Run with-skill + baseline in parallel via skill-creator agent
4. Grade, aggregate, generate static HTML viewer
5. Review and iterate if pass rate < 80%
6. Run description optimizer last

Workspace: `skill-creator-workspace/<skill-name>/`

---

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
