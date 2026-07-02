---
name: market-linkedin
description: Use when the user wants to post about recently shipped features on LinkedIn. Reads CHANGELOG.md entries since the last post, generates a LinkedIn-optimized post with hook, body, and hashtags in the project's brand voice, presents a draft for review, then copies to clipboard and opens the LinkedIn compose page. Trigger for "write a LinkedIn post", "post about this release on LinkedIn", "announce this on LinkedIn", "draft our LinkedIn update", or after shipping a batch of features and wanting to share them professionally.
version: 1.0.0
license: MIT
---

# /market-linkedin — LinkedIn Post Generator

Reads `docs/CHANGELOG.md` for entries written by `/work`, generates a
LinkedIn-optimized post in your brand's voice, and copies it to your
clipboard. LinkedIn's API requires Partner Program enrollment, so the skill
handles the creative work and you paste it in.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-posted date
- `--dry-run` — show the draft without writing the sync marker

## Process

### Step 0: Load brand config

Check for `brand/BRAND.md` in the project root. This is the primary source.
If absent, fall back to the `brand:` section in `.claude/agent-team.config.md` (legacy).

If neither exists: "Brand not configured — run `/init-setup` to create `brand/BRAND.md`." Stop.

From `brand/BRAND.md`, extract:
- **Name** — from `## Identity` → `**Name:**`
- **Voice** — from `## Voice & Tone` → `**Voice:**`
- **Audience** — from `## Voice & Tone` → `**Audience:**`
- **LinkedIn URL** — from `## Social & Contact` → `**LinkedIn:**`
- **Hashtags** — from `## Social & Contact` → `**Hashtags:**`
- **Logo path** — from `## Logo & Visual Assets` table, "Logo (light bg)" row
- **Banner path** — from `## Logo & Visual Assets` table, "Social Banner" row

If social fields are absent, proceed with no hashtags and no LinkedIn URL.

### Step 1: Read what's new

1. Check `docs/CHANGELOG.md` exists. If not: "No changelog yet — ship features with `/work` first." Stop.

2. Determine the since-date:
   - If `--since YYYY-MM-DD` was passed, use it.
   - Otherwise, parse `<!-- linkedin-last-posted: YYYY-MM-DD -->` from the changelog header.
   - If `never` or absent, include all entries.

3. Parse all `<!-- changelog-entry ... -->` blocks. Filter to entries where `date > since-date`.

4. If nothing new: "No new changelog entries since {date}." Stop.

5. If multiple entries, present them:

   ```
   ## Found N new entries since {date}

   LinkedIn works best with a focused narrative. Which features to cover?

   1. ✓ {Feature Name} ({date})
   2. ✓ {Feature Name} ({date})

   Recommendation: bundle these into one post (LinkedIn rewards recency over frequency).
   1. Bundle all into one post
   2. Pick specific features — enter numbers
   ```

### Step 2: Generate the post

LinkedIn has a 3,000 character limit. The most effective developer-audience posts on LinkedIn share a story or insight, not a feature list. Transform the changelog into something worth reading.

**LinkedIn post structure:**

```
{Hook — 1-2 lines that make someone stop scrolling.
 Great hooks: a surprising fact, a before/after, a question, a bold claim.
 The first line is all they see before "see more" — make it earn the click.}

{Empty line}

{Body — 3-5 short paragraphs or a mix of prose + bullets.
 Each paragraph is 1-3 sentences max. White space is your friend.
 Tell the story: what problem existed → what you built → why it matters.
 Be specific. Name the thing. Show the command or the workflow.}

{Empty line}

{CTA — 1-2 lines. What should they do next?
 Install it, read the changelog, try it on their project.}

{Empty line}

{Hashtags — 3-5 from brand.social.hashtags. Keep them relevant.}
```

**Tone calibration for LinkedIn:**
LinkedIn allows slightly more narrative than Twitter — you can tell a story, share
the "why we built this" angle, or frame it as a lesson learned. Still apply the
brand voice from config, but LinkedIn readers expect more context than Twitter.
Avoid corporate buzzwords. Developers on LinkedIn appreciate honesty about trade-offs.

**First comment (optional but recommended):**
LinkedIn's algorithm deprioritizes posts with external links. Put the changelog URL
or product link in the first comment instead of the post body. Generate this too.

### Step 3: Review draft

Present in a single `AskUserQuestion` block:

```
## LinkedIn Draft

### Post ({N} characters / 3,000 max)
---
{full post text}
---

### First comment (paste this immediately after posting)
{changelog URL or product link with 1-sentence context}

Review options:
1. Looks good — copy to clipboard
2. Change the hook
3. Make it shorter / longer
4. Adjust the tone — more technical / more story-driven
5. Edit a specific section
```

Keep iterating until approved.

### Step 4: Deliver

1. Copy the post to clipboard:
   ```bash
   echo '{post text}' | pbcopy   # macOS
   # or: echo '{post text}' | xclip -selection clipboard   # Linux
   ```

2. Print the delivery block:

   ```
   ## Ready to Post

   ✓ Post copied to clipboard ({N} characters)

   ### Steps
   1. Open LinkedIn: https://www.linkedin.com/post/new/
   2. Paste the post (Cmd+V / Ctrl+V)
   3. Add any images or documents if relevant
   4. Post — then immediately paste the first comment below

   ### First comment (paste right after posting)
   {first comment text}

   ### Your LinkedIn page
   {brand.social.linkedin_url if configured}
   ```

3. Open the LinkedIn new post URL:
   ```bash
   open "https://www.linkedin.com/post/new/"
   ```

### Step 5: Update sync marker

Unless `--dry-run`:
Update `<!-- linkedin-last-posted: YYYY-MM-DD -->` in `docs/CHANGELOG.md` header.
Add the comment if it doesn't exist.

Show the git command — do not commit:
```
git add docs/CHANGELOG.md && git commit -m "chore: mark linkedin posted for {date}"
```

## Rules

- LinkedIn's API requires Partner Program enrollment — programmatic posting is not supported; always guide to manual paste
- Never post automatically — the user always reviews and pastes
- Keep hashtags minimal (3-5 max) — hashtag stuffing hurts LinkedIn reach
- Put external links in first comment, not the post body — LinkedIn deprioritizes posts with outbound links
- If the clipboard copy fails (Linux without xclip), print the full post text so the user can copy manually
