---
description: Apply x4 project migrations after a plugin update — detects gaps between the current plugin version and what's been applied to this project, and scaffolds only what's missing. Safe to run multiple times. Run this after updating x4 to a new version.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/upgrade` skill to bring this project up to date with the current x4 version.

Reads `.claude/x4-version` to detect what migrations have already been
applied, checks each new version's requirements against what exists on
disk, and creates or migrates only what's missing.
