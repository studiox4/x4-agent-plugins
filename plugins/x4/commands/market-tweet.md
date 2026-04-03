---
description: Generate an X/Twitter thread from recently shipped features — reads CHANGELOG.md since last post, writes a numbered thread in your brand's voice, presents a draft for review, then copies to clipboard. Optionally posts via X API if configured.
argument-hint: "[--since YYYY-MM-DD] [--dry-run] [--post]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/market-tweet` skill to generate an X/Twitter thread from recently shipped features.

Reads `docs/CHANGELOG.md` for new entries, generates a numbered thread
optimized for X/Twitter (hook → value tweets → CTA), presents a draft for
review, then copies the thread to clipboard. Pass `--post` to trigger
posting via the X API if `X_API_KEY` is configured.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-posted date
- `--dry-run` — show the draft without writing the sync marker
- `--post` — post via X API (requires X_API_KEY in environment)
