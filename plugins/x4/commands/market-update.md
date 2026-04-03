---
description: Sync the marketing site with recently shipped features — reads CHANGELOG.md entries since the last sync, generates marketing copy, optionally captures screenshots, and updates marketing pages after user review.
argument-hint: "[--screenshots] [--dry-run] [--since YYYY-MM-DD]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/market-update` skill to sync the marketing site with what's shipped.

Reads `docs/CHANGELOG.md` for entries since the last sync, generates
user-friendly marketing copy per page, presents a draft for review, then
applies updates to the configured marketing site pages.

**Arguments:**
- `--screenshots` — capture screenshots via Playwright (requires dev server running on port 3001)
- `--dry-run` — show proposed changes without writing any files
- `--since YYYY-MM-DD` — override the auto-detected last-synced date
