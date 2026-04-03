---
description: Generate a release email campaign from recent changelog entries — reads CHANGELOG.md since last send, writes a subject line, preview text, and email body in your brand's voice, presents a draft for review, then outputs the Resend-ready content for you to send.
argument-hint: "[--since YYYY-MM-DD] [--dry-run]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/market-email` skill to generate a release email from recently shipped features.

Reads `docs/CHANGELOG.md` for entries since the last email, generates
subject line options, preview text, and an email body in your brand's voice,
then presents a full draft for review before outputting the send-ready content.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-sent date
- `--dry-run` — show the draft without writing the sync marker
