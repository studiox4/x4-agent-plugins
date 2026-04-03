---
name: market-email
description: Use when the user wants to write or send a release email to their users about recently shipped features. Reads CHANGELOG.md entries since the last email send, generates subject line options, preview text, and a full email body in the project's brand voice, presents a draft for review, then outputs Resend-ready content for the user to send. Trigger for "write a release email", "send an email about what we shipped", "draft our newsletter", "announce this version to users", or after shipping features and wanting to reach the email list.
version: 1.0.0
license: MIT
---

# /market-email — Release Email Generator

Reads `docs/CHANGELOG.md` for entries written by `/work`, generates a
release email in your brand's voice, and presents a draft for review.
You decide when to send — the skill never sends automatically.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-sent date
- `--dry-run` — show the draft without writing the sync marker

## Process

### Step 0: Load brand config

Read `.claude/agent-team.config.md`. Extract the `brand` section:

```yaml
brand:
  name: "Your Product"
  tagline: "Your tagline."
  voice: "developer-first, direct, show-don't-tell"
  audience: "developers building X with Y"
  email:
    provider: resend          # or loops
    api_key_env: RESEND_API_KEY
    from: "updates@yourdomain.com"
    audience_id: "..."        # Resend audience ID or Loops list ID
```

If the `brand` section is absent: "Brand not configured — run `/init-setup` to add brand and email settings." Stop.
If `brand.email` is absent: proceed but note that sending will be manual (no API config).

### Step 1: Read what's new

1. Check `docs/CHANGELOG.md` exists. If not: "No changelog yet — ship features with `/work` first." Stop.

2. Determine the since-date:
   - If `--since YYYY-MM-DD` was passed, use it.
   - Otherwise, parse `<!-- email-last-sent: YYYY-MM-DD -->` from the changelog header.
   - If the value is `never` or the comment is absent, include all entries.

3. Parse all `<!-- changelog-entry ... -->` comment blocks. Filter to entries where `date > since-date`.

4. If nothing new: "No new changelog entries since {date} — nothing to email about yet." Stop.

5. If multiple entries, present them and ask which to include:

   ```
   ## Found N new entries since {date}

   1. ✓ {Feature Name} ({date}, PR #{number})
   2. ✓ {Feature Name} ({date}, PR #{number})
   3.   {Feature Name} ({date}, PR #{number})

   Which features to include in this email? (all / numbers like "1 2" / skip)
   ```

### Step 2: Generate email content

Transform the selected changelog entries into a release email. The goal is
to communicate value clearly to the target audience — not to restate what was
built, but to convey what it means for them.

**Brand voice principles for email:**
- Lead with the user's gain, not the feature's mechanism
- Be specific: "Deploy Railway services in one command" beats "improved deployment"
- One idea per sentence
- CTA is a single clear action — don't offer multiple links
- Tone from `brand.voice` in config — apply it consistently

Generate all of these:

**Subject line (3 options, vary the angle):**
- Option A: Direct / product-focused ("x4 v3.8: Deploy setup, email + social announce")
- Option B: Outcome-focused ("Your Railway previews configure themselves now")
- Option C: Question or intrigue ("How many steps does it take to set up Railway PR previews?")

**Preview text (1 option, 90 chars max):**
Complements the subject without repeating it.

**Email body:**

```
Hi there,

{1-2 sentence intro that sets context — what shipped, why it matters}

{For each included feature:}
## {Feature Name}

{2-3 sentences in brand voice. Lead with the user benefit. Follow with
 one concrete detail about how it works. End with what it replaces or why
 it's better than before.}

{If the feature changes a workflow: show the before/after command or flow}

---

{Closing paragraph — 1-2 sentences. What to do next (CTA).}

{CTA button text} → {URL — changelog page, docs, or marketing site}

{Sign-off}
{Brand name}
```

### Step 3: Review draft

Present everything in a single `AskUserQuestion` block:

```
## Email Draft

### Subject line options
A: {subject A}
B: {subject B}
C: {subject C}

### Preview text
{preview text}

### Body
---
{full email body}
---

Review options:
1. Looks good — generate send-ready output
2. Change the subject — tell me which option or write your own
3. Edit a section — tell me what to change
4. Regenerate in a different tone
5. Dry run — show output without saving sync marker
```

Keep iterating until the user approves.

### Step 4: Output send-ready content

Present the final output the user needs to actually send:

```
## Ready to Send

### Subject
{chosen subject}

### Preview text
{preview text}

### Body (Markdown)
{full body}

---

### Send via Resend

If you have Resend configured, run this from your project:

\`\`\`typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.{api_key_env});

await resend.emails.send({
  from: '{from}',
  to: resend.audiences.members.list('{audience_id}'), // or your list logic
  subject: '{chosen subject}',
  text: `{plain text version}`,
  // html: use React Email to render the body above
});
\`\`\`

Or paste the Markdown body into your email tool of choice.

### Next Steps
- Review the email in your Resend dashboard or email client before sending
- Update your email list / audience if needed
- Send when ready
```

If `brand.email.provider` is `loops`, show the equivalent Loops API call instead.

If no email config is present, just show the content and note: "Add `brand.email` to your config to get the send snippet."

### Step 5: Update sync marker

Unless `--dry-run`:
Update `<!-- email-last-sent: YYYY-MM-DD -->` in `docs/CHANGELOG.md` header to today's date.
Add the comment if it doesn't exist (after `<!-- marketing-last-synced: ... -->`).

Do NOT commit — show the user the git command:
```
git add docs/CHANGELOG.md
git commit -m "chore: mark email sent for {date}"
```

## Rules

- Never send email automatically — always show the draft first and wait for approval
- Never print API key values — only reference the env var name
- Never auto-commit — show the git command and let the user run it
- If brand voice changes between iterations, regenerate from scratch rather than patching
