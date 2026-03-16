#!/usr/bin/env bash
cat <<'HOOK_MSG'
Project tracker is active. Key commands:
  /btw <idea>      — capture a feature idea to the backlog
  /plan-backlog    — triage backlog items into PRDs
  /init-tracker    — scaffold tracking files for a new project
Config: .claude/project-tracker.config.md
HOOK_MSG
