---
description: Generate a LinkedIn post from recently shipped features — reads CHANGELOG.md since last post, writes a hook, body, and hashtags in your brand's voice, presents a draft for review, then copies to clipboard and opens LinkedIn compose.
argument-hint: "[--since YYYY-MM-DD] [--dry-run]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/market-linkedin` skill to generate a LinkedIn post from recently shipped features.

Reads `docs/CHANGELOG.md` for new entries, generates a post optimized for
LinkedIn's format (hook → value → CTA → hashtags), presents a draft for review,
then copies the final post to clipboard and opens the LinkedIn compose page.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-posted date
- `--dry-run` — show the draft without writing the sync marker
