---
description: One-time Railway deployment wizard — creates or links a Railway project, generates railway.toml for monorepo services, syncs environment variables, and walks through GitHub connection and PR preview setup. Run once per project before the first /work cycle or when preview deployments aren't working.
argument-hint: "[--project <name>]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/deploy-setup` skill to configure Railway deployments for this project.

Detects services from `apps/`, generates `railway.toml`, syncs environment
variables from `.env.local`, and guides through GitHub connection and PR
preview deployment setup.

**Arguments:**
- `--project <name>` — Railway project name (skips the name prompt)
