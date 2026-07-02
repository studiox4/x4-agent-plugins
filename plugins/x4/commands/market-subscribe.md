---
description: Scaffold an email capture form into the marketing site — generates a SubscribeForm component, a /api/subscribe Next.js route handler, and wires it to Resend or Loops. Run once after configuring brand.email in init-setup. Also callable when adding email capture to an existing marketing site.
argument-hint: "[--provider resend|loops] [--page landing|features|custom]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

Run the `/market-subscribe` skill to add an email capture form to the marketing site.

Generates a `SubscribeForm` React component, a `/api/subscribe` Next.js route
handler, and optionally inserts the form into an existing page. Wires to
Resend audiences or Loops contacts based on your brand config.

**Arguments:**
- `--provider resend|loops` — override the auto-detected provider from brand config
- `--page landing|features|custom` — which page to insert the form into (default: landing)
