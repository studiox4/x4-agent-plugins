#!/usr/bin/env bash
cat <<'HOOK_MSG'
x4 plugin is active. Key commands:
  /x4:idea <idea>     — capture a feature idea to the backlog
  /x4:work            — dispatch agent team to build next feature
  /x4:plan-backlog    — triage backlog items into PRDs
  /x4:create <name>   — scaffold a new x4-mono project
  /x4:llmstxt-update  — refresh llms.txt reference docs
Config: .claude/project-tracker.config.md, .claude/agent-team.config.md
HOOK_MSG
