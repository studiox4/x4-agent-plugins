# 06 — Excalidraw Architecture Diagram Specification

This document is a complete specification for building a visual architecture diagram of the x4-agent-plugins system in Excalidraw. Give this to an agent with Excalidraw MCP access to generate the diagram.

---

## Instructions for the Diagram Agent

Create a comprehensive visual diagram in Excalidraw showing the complete x4-agent-plugins workflow system. The diagram should have **four main sections** arranged top-to-bottom, with clear flow arrows between them. Use the color scheme and layout described below.

---

## 1. Overall Layout

**Canvas size:** ~2400 x 1800 pixels
**Flow direction:** Top-to-bottom (onboard/scaffold at top, shipping at bottom)
**Background:** White or transparent

### Four horizontal bands:

| Band | Y range | Label | Color theme |
|------|---------|-------|-------------|
| 1 | 0-350 | **Onboard + Scaffold** (x4-scaffold) | Blue/teal |
| 2 | 400-700 | **Capture + Plan** (x4-project-tracker) | Green/mint |
| 3 | 750-1500 | **Build Pipeline** (x4-agent-team-ops) | Orange/amber |
| 4 | 1550-1800 | **Reference Docs** (x4-llmstxt-manager) | Purple/violet |

Each band should have a subtle colored background rectangle with rounded corners and low opacity (~10%).

---

## 2. Band 1: Onboard + Scaffold (x4-scaffold)

### Elements

**Left group — `/x4-onboard`:**
Draw a rounded rectangle labeled `/x4-onboard` with a checklist inside:
```
Onboard Checklist:
☑ Bun >= 1.1
☑ Node.js >= 18
☑ Git + GitHub CLI
☐ Neon account
☐ Railway account
☐ Anthropic API key
☐ Claude Code plugins
```

**Center group — `/x4-create`:**
Draw a large rounded rectangle labeled `/x4-create` containing:
- A diamond (decision) labeled "Preset?"
- Four branches from the diamond:
  - "full-stack" → box listing: Web + API + Mobile + Desktop + AI + Marketing + Docs
  - "saas" → box listing: Web + API + AI
  - "landing" → box listing: Web + API + Marketing
  - "api-only" → box listing: Hono + tRPC
- Below the branches: a box labeled `bunx create-x4 <name> --yes [flags]`

**Right group — `/x4-env`:**
Draw a rounded rectangle labeled `/x4-env` with:
```
Environment Setup:
→ DATABASE_URL (Neon)
→ JWT_SECRET (auto-gen)
→ BETTER_AUTH_SECRET
→ ANTHROPIC_API_KEY
→ App URLs
```

**Arrows:**
- `/x4-onboard` → `/x4-create` (labeled "environment ready")
- `/x4-create` → `/x4-env` (labeled "scaffold complete")
- `/x4-env` → Band 2 (labeled "project ready")

---

## 3. Band 2: Capture + Plan (x4-project-tracker)

### Elements

**Left — `/idea`:**
Rounded rectangle with:
```
/idea <text>
→ Read STATUS.md context
→ Append to BACKLOG.md
→ Scope: small/medium/large
```

**Center — `/plan-backlog`:**
Larger rounded rectangle showing the flow:
```
/plan-backlog
1. Parse BACKLOG.md
2. Present triage menu
3. User picks item
   ↓
4. Brainstorm (inline or /brainstorming)
5. Implementation Plan (inline or /writing-plans)
6. Write PRD → docs/planning/todo/
7. Update STATUS.md
8. Remove from BACKLOG.md
```

**Right — Planning Folder Lifecycle:**
Three stacked folder icons:
```
📁 docs/planning/
  📂 todo/        ← PRD created here
  📂 in-progress/ ← moved by /work Phase 2
  📂 complete/    ← moved by /work Phase 6
```

**Arrows:**
- `/idea` → `BACKLOG.md` (labeled "append")
- `BACKLOG.md` → `/plan-backlog` (labeled "triage")
- `/plan-backlog` → `todo/` folder (labeled "PRD written")
- `todo/` → Band 3 (labeled "ready to build")

---

## 4. Band 3: Build Pipeline (x4-agent-team-ops)

This is the largest band. Show the 7 phases of `/work` as a horizontal pipeline.

### Phase boxes (left to right):

**Phase 1 — Orient:**
Small box:
```
Read STATUS.md
Present menu
User picks work
```

**Phase 2 — Setup:**
Box labeled `/pr-create`:
```
git branch
DB branch (Neon)
Draft PR (gh)
Preview URL
git mv PRD: todo/ → in-progress/
```

**Phase 3 — Build:**
Larger box with agent icons inside:
```
Spawn Agent Team:
🔧 Backend
🎨 Frontend
🧪 Tester

(parallel work on feature branch)
```
Note: reviewer and performance NOT here.

**Phase 4 — Review + Verify:**
Box with two parallel tracks:
```
Parallel:
┌─────────────┐  ┌──────────────┐
│ 📋 Reviewer  │  │ ⚡ Performance │
│ (read-only)  │  │  (read-only)  │
└─────────────┘  └──────────────┘
         ↓
  Fix blockers
         ↓
┌────────────────┐
│ /verify-local  │
│ Unit → E2E →   │
│ Lint → Types   │
│ (auto-fix x3)  │
└────────────────┘
```

**Phase 5 — Ship:**
Box labeled `/pr-status`:
```
git push
Convert PR → ready
CI check
Preview URL

Failure handling:
Lint/Type → auto-fix
Unit test → diagnose
E2E/Build → STOP
```

**Phase 6 — Memory Sweep:**
Small box:
```
git mv PRD:
in-progress/ → complete/
Update STATUS.md
Write to memory
Clean scratch files
```

**Phase 7 — Cleanup:**
Small box:
```
/pr-cleanup
Delete DB branch
Delete local branch
```

### Arrows between phases:
Phase 1 → 2 → 3 → 4 → 5 → 6 → 7, with labels:
- 1→2: "work confirmed"
- 2→3: "branch + PR ready"
- 3→4: "build complete"
- 4→5: "all checks pass"
- 5→6: "CI green"
- 6→7: "status updated"

### Agent Templates (below the pipeline):

Draw 5 small card-like rectangles:

| Agent | Label | Color | Access |
|-------|-------|-------|--------|
| backend | `🔧 Backend` | Blue | Read/Write: apps/api/, packages/ |
| frontend | `🎨 Frontend` | Pink | Read/Write: apps/web/ |
| tester | `🧪 Tester` | Green | Read/Write: test files only |
| reviewer | `📋 Reviewer` | Yellow | Read-only |
| performance | `⚡ Performance` | Orange | Read-only |

---

## 5. Band 4: Reference Docs (x4-llmstxt-manager)

### Elements

**Left — `/llmstxt-init`:**
```
Scaffold:
→ scripts/download-ai-docs.py
→ docs/llms-txt/
→ known-sources.json
→ .llmstxt.json
```

**Center — Discovery Pipeline:**
Draw as a flowchart:
```
Package name
  → Check cache (known-sources.json)
    → Hit? → Download
    → Miss? → npm/PyPI registry lookup
      → Probe URLs (/llms-full.txt, /llms.txt)
        → Found? → Download
        → Not found? → GitHub raw content
          → Found? → Download
          → Not found? → Aggregator sites
            → Found? → Download
            → Not found? → Skip
```

**Right — `/llmstxt-update` + `/llmstxt-status`:**
```
Update:
→ Run script --json
→ Download new/updated docs
→ Update CLAUDE.md table
→ Update agent file refs

Status:
→ Current / Missing / Orphaned / Stale
```

**Bottom — Ecosystems supported:**
Five small icons/badges:
```
JS/Bun | Python | Rust | Go | Ruby
```

---

## 6. Cross-cutting Elements

### Config Files (draw as a sidebar on the right)

```
Configuration:
├── .claude/agent-team.config.md  ← /init-setup
├── .claude/project-tracker.config.md  ← /init-tracker
├── .llmstxt.json  ← /llmstxt-init
└── .env.local  ← /x4-env
```

### External Plugin Integrations (draw as a small box bottom-right)

```
Optional Integrations:
→ superpowers (brainstorming, writing-plans)
→ code-simplifier (Phase 4)
→ Neon MCP (DB branches)
```

---

## 7. Color Scheme

| Element | Fill Color | Border | Text |
|---------|-----------|--------|------|
| x4-scaffold band | #E0F7FA (light teal) | #00897B | #004D40 |
| x4-project-tracker band | #E8F5E9 (light green) | #43A047 | #1B5E20 |
| x4-agent-team-ops band | #FFF3E0 (light orange) | #FB8C00 | #E65100 |
| x4-llmstxt-manager band | #F3E5F5 (light purple) | #8E24AA | #4A148C |
| Decision diamonds | #FFF9C4 (light yellow) | #F9A825 | #000 |
| Agent cards | Match their band | Darker shade | #000 |
| Arrows | — | #546E7A | #546E7A |
| Config sidebar | #ECEFF1 (light gray) | #78909C | #263238 |

---

## 8. Text Styling

| Element | Font Size | Weight | Style |
|---------|-----------|--------|-------|
| Band titles | 24px | Bold | — |
| Skill names (`/x4-create`) | 18px | Bold | Monospace |
| Phase labels | 16px | Bold | — |
| Body text | 14px | Normal | — |
| Arrow labels | 12px | Normal | Italic |
| Agent template names | 14px | Bold | — |

---

## 9. Key Relationships to Show with Arrows

1. `/x4-onboard` → `/x4-create` → `/x4-env` (sequential setup)
2. `/x4-create` → `/init-tracker` + `/init-setup` (optional post-scaffold)
3. `/idea` → `BACKLOG.md` → `/plan-backlog` → `docs/planning/todo/` (capture to plan)
4. `todo/` → `/work` Phase 2 → `in-progress/` → Phase 6 → `complete/` (PRD lifecycle)
5. `/work` Phase 3 → spawns backend + frontend + tester agents
6. `/work` Phase 4 → spawns reviewer + performance agents (parallel)
7. `/work` Phase 4 → `/verify-local` (mandatory gate)
8. `/work` Phase 5 → `/pr-status` (CI/preview check)
9. `/work` Phase 7 → `/pr-cleanup` (manual cleanup)
10. `/llmstxt-update` → agent files (reference doc updates)
11. Config files → all skills (read by skills at runtime)

---

## 10. Summary Stats (optional info box, top-right corner)

```
x4-agent-plugins v2.0

4 plugins | 16 commands | 5 agent templates
3 hook types | 5 ecosystems supported

Workflow: Onboard → Scaffold → Capture → Plan → Build → Ship
```
