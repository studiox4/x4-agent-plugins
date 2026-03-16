---
description: Pick up the next piece of work, dispatch an agent team, and ship it. Reads from your project's status file.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebFetch, AskUserQuestion
---

Run the `/work` skill to start the feature dispatch pipeline.

Read `.claude/agent-team.config.md` for project-specific configuration.
If the config file does not exist, offer to create it with defaults.

Then follow the 7-phase pipeline defined in the work skill.
