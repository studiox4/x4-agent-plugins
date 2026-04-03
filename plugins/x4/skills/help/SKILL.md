---
name: help
description: Show an overview of the x4 plugin — what it does, how to get started, and all available commands organized by workflow stage
version: 1.0.0
license: MIT
---

# /help — x4 Plugin Guide

Show the user what x4 can do and how to get started. Adapts based on project state.

## Process

### 1. Detect project state

Quick scan to determine where the user is in the workflow:

- **No project:** No `package.json`, no `CLAUDE.md` → suggest `/x4:onboard` + `/x4:create`
- **Project exists, not set up for x4:** Has `package.json` but no `.claude/agent-team.config.md`, no `docs/STATUS.md` → suggest `/x4:init-setup` + `/x4:init-tracker`
- **Set up, no PRDs:** Has config files but `docs/planning/todo/` is empty and backlog is empty → suggest `/x4:kickstart` or `/x4:idea`
- **Ready to build:** Has PRDs in `docs/planning/todo/` → suggest `/x4:work`
- **Active build:** Has PRDs in `docs/planning/in-progress/` → suggest `/x4:work` to resume

### 2. Show the guide

Present using this format:

```
## x4 — AI-Powered Development Workflow

Version: {version from plugin.json}
Project: {project name or "no project detected"}
Status: {detected state from step 1}
Docs: https://px4.dev

### Quick Start

{Contextual suggestion based on detected state — 1-2 sentences}

### The Pipeline

  Onboard → Scaffold → Tour → Kickstart → Build → Ship
                                ↑                   ↓
                           /gaps + /dream → backlog → plan

### Commands by Stage

**Getting Started**
  /x4:onboard     Check tools, accounts, CLIs
  /x4:create      Scaffold a new project
  /x4:tour        Guided project walkthrough
  /x4:add         Add a mobile or web app
  /x4:env         Set up environment variables
  /x4:status      Project health dashboard

**Planning**
  /x4:kickstart   Brainstorm features, design UI, generate PRDs
  /x4:idea        Capture an idea to the backlog
  /x4:plan-backlog Triage backlog into PRDs

**Discovery**
  /x4:gaps        Find product gaps in shipped features
  /x4:dream       Explore big ideas for your project

**Building**
  /x4:work        Build pipeline — auto-loops through all ready PRDs
  /x4:run-tests   Run test commands
  /x4:verify-local Full check suite with auto-fix
  /x4:pr-create   Create branch + PR
  /x4:pr-status   Check CI and preview
  /x4:pr-cleanup  Post-merge cleanup

**Setup (run once)**
  /x4:init-setup  Configure database, hosting, CI, tests
  /x4:init-tracker Scaffold STATUS.md, BACKLOG.md, planning dirs
  /x4:init-agents Generate project-specific agent files

**Reference Docs**
  /x4:llmstxt-init   Scaffold llms.txt system
  /x4:llmstxt-update Refresh reference docs
  /x4:llmstxt-status Check docs health

**Other**
  /x4:help        This guide
  /x4:doctor      Diagnose project setup issues
```

### 3. Offer next step

Based on the detected state, end with a specific suggestion:

- No project → "Run `/x4:onboard` to get started."
- Not set up → "Run `/x4:init-setup` to configure your project for x4."
- No PRDs → "Run `/x4:kickstart` to brainstorm features, or `/x4:idea` to capture one."
- Ready to build → "Run `/x4:work` to start building. You have {N} PRDs ready."
- Active build → "Run `/x4:work` to resume your in-progress feature."

## Rules

- Keep it concise — this is a reference card, not documentation
- Adapt to the user's current state — don't show scaffolding steps to someone who already has a project
- Always show the full command list — even if some aren't relevant yet
- Do not run any setup commands — only suggest them
