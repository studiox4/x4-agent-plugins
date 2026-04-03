---
name: market-tweet
description: Use when the user wants to post about recently shipped features on X/Twitter. Reads CHANGELOG.md entries since the last post, generates a numbered thread with hook tweet, value tweets, and a CTA in the project's brand voice, presents a draft for review, then copies to clipboard. Optionally posts via X API if configured. Trigger for "write a tweet about this", "post this on X", "draft a Twitter thread", "tweet about what we shipped", "make a thread about this release", or after shipping features and wanting to share them on social media.
version: 1.0.0
license: MIT
---

# /market-tweet — X/Twitter Thread Generator

Reads `docs/CHANGELOG.md` for entries written by `/work`, generates a
numbered X/Twitter thread in your brand's voice, and copies it to clipboard.
Pass `--post` to trigger posting via the X API if `X_API_KEY` is configured.

**Arguments:**
- `--since YYYY-MM-DD` — override the auto-detected last-posted date
- `--dry-run` — show the draft without writing the sync marker
- `--post` — post via X API (requires X_API_KEY and x_api_key_env configured)

## Process

### Step 0: Load brand config

Check for `brand/BRAND.md` in the project root. This is the primary source.
If absent, fall back to the `brand:` section in `.claude/agent-team.config.md` (legacy).

If neither exists: "Brand not configured — run `/init-setup` to create `brand/BRAND.md`." Stop.

From `brand/BRAND.md`, extract:
- **Name** — from `## Identity` → `**Name:**`
- **Voice** — from `## Voice & Tone` → `**Voice:**`
- **Audience** — from `## Voice & Tone` → `**Audience:**`
- **Twitter handle** — from `## Social & Contact` → `**Twitter/X:**`
- **Hashtags** — from `## Social & Contact` → `**Hashtags:**`
- **X API key env var** — from `## X / Twitter API` → `**API key env var:**`

### Step 1: Read what's new

1. Check `docs/CHANGELOG.md` exists. If not: "No changelog yet — ship features with `/work` first." Stop.

2. Determine the since-date:
   - If `--since YYYY-MM-DD` was passed, use it.
   - Otherwise, parse `<!-- twitter-last-posted: YYYY-MM-DD -->` from the changelog header.
   - If `never` or absent, include all entries.

3. Parse all `<!-- changelog-entry ... -->` blocks. Filter to entries where `date > since-date`.

4. If nothing new: "No new changelog entries since {date}." Stop.

5. If multiple entries:

   ```
   ## Found N new entries since {date}

   Twitter threads work best when tightly focused. Options:
   1. One thread covering all features (good for a release announcement)
   2. Pick specific features — enter numbers (good for a focused highlight)
   ```

### Step 2: Generate the thread

Each tweet is 280 characters max. Threads are numbered (1/N, 2/N, etc.).
Strong developer threads on X are punchy, specific, and have personality.
The hook tweet is everything — if it doesn't earn a tap, the thread doesn't exist.

**Thread structure:**

```
Tweet 1/N — The hook
The single most compelling thing about what shipped. Not a summary — a specific
claim, a before/after, a surprising number, or a question. Under 240 chars
(leave room for the thread counter). No hashtags here.

Tweet 2/N — The problem (optional but powerful)
What was broken or annoying before? The more specific the better.
"Setting up Railway for a Turborepo monorepo meant: writing railway.toml by hand,
figuring out which jq path to use, manually configuring PR previews in 3 dashboard tabs."

Tweet 3/N - Tweet (N-1)/N — One idea per tweet
Each tweet covers one feature or one benefit. Lead with the most interesting
thing. Commands, file names, and specific numbers are your friends on dev Twitter.
Show the actual command if there is one.

Tweet N/N — The CTA
Where to go next. Install command, link to docs, or link to changelog.
1-2 hashtags from brand.social.hashtags here (not every tweet).
Tag the brand handle if different from the posting account.
```

**Tone calibration for X/Twitter:**
Shorter is better. Every word must earn its place. Developer Twitter responds to:
- Specific numbers ("29 commands, 5 agent templates, 1 install")
- Honest trade-offs ("LinkedIn's API requires Partner enrollment — so we just copy to clipboard")
- Direct commands you can copy-paste
- Personality — "set up Railway and walk away" lands better than "automated Railway configuration"

Apply `brand.voice` from config. When in doubt, cut the last sentence of each tweet.

**Character counting:**
Each tweet must be ≤ 280 characters including the thread counter (e.g., "1/6").
Count carefully. If a tweet is close (275+), flag it in the draft with a ⚠️.

### Step 3: Review draft

Present in a single `AskUserQuestion` block:

```
## Twitter/X Thread Draft ({N} tweets)

1/{N} ({chars} chars)
{tweet 1 text}

2/{N} ({chars} chars)
{tweet 2 text}

...

{N}/{N} ({chars} chars)
{final tweet text}

---

Review options:
1. Looks good — copy to clipboard
2. Punch up the hook (tweet 1)
3. Make it shorter — drop to {N-1} tweets
4. Make it longer — expand a specific tweet
5. Edit a specific tweet — tell me which one
6. Regenerate with a different angle
```

Keep iterating until approved.

### Step 4: Deliver

**Option A — Clipboard (default):**

Format the thread for easy posting (each tweet on its own block):
```bash
printf '{tweet1}\n\n---\n\n{tweet2}\n\n---\n...' | pbcopy   # macOS
# or: printf '...' | xclip -selection clipboard               # Linux
```

Print the delivery block:

```
## Ready to Post

✓ Thread copied to clipboard ({N} tweets)

### Steps
1. Open X: https://x.com/compose/post
2. Paste tweet 1, click the + to add tweet 2, repeat
3. Or use a thread tool like Typefully or Hypefury for easier threading

### Thread
{full thread reprinted for easy manual copy if clipboard fails}
```

Open the X compose URL:
```bash
open "https://x.com/compose/post"
```

**Option B — X API (only if `--post` flag AND `x_api_key_env` configured):**

Check if the env var is set: `echo $X_API_KEY` (print masked/present, not the value).

If set, show the user what will be posted and ask for explicit confirmation:
```
## Post via X API?

The following thread will be posted to {twitter_handle}:

{full thread}

This will post publicly. Confirm? (yes / no)
```

If confirmed, post each tweet in sequence using the X API v2 endpoint,
threading them by passing the previous tweet's ID as `reply.in_reply_to_tweet_id`.
Show each tweet ID as it's posted.

If the env var is not set, fall back to clipboard mode and note:
"X API not configured. Add `x_api_key_env` to `brand.social` in config and set the
env var to enable `--post`."

### Step 5: Update sync marker

Unless `--dry-run`:
Update `<!-- twitter-last-posted: YYYY-MM-DD -->` in `docs/CHANGELOG.md` header.
Add the comment if it doesn't exist.

Show the git command — do not commit:
```
git add docs/CHANGELOG.md && git commit -m "chore: mark twitter posted for {date}"
```

## Rules

- Never post automatically without `--post` flag AND explicit user confirmation
- Never print API key values — only check if the env var is set
- Character limits are hard — flag tweets over 278 chars before presenting the draft
- Put hashtags in the final tweet only, not every tweet (exception: 1 hashtag in tweet 1 is OK if it's part of the hook)
- If clipboard fails, always fall back to printing the full thread text in the conversation
- Threads should have personality — dry feature lists don't get engagement; developer stories do
