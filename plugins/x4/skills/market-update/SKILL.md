---
name: market-update
description: Use when the user wants to sync the marketing site with recently shipped features. Reads CHANGELOG.md entries since the last sync, generates marketing copy per page, optionally captures screenshots via Playwright, and applies updates after user review. Trigger for "update marketing", "sync the site", "write about what we shipped", "update the marketing copy", or after shipping a batch of features and wanting to reflect them publicly.
version: 1.0.0
license: MIT
---

# /market-update — Sync Marketing Site with Shipped Features

Reads `docs/CHANGELOG.md` for entries written by `/work`, generates
user-friendly marketing copy for each configured page, optionally captures
screenshots of the running app, and applies updates after user review.

**Arguments:**
- `--screenshots` — force screenshot capture (requires dev server on port 3001)
- `--dry-run` — show proposed changes without writing any files
- `--since YYYY-MM-DD` — override the auto-detected last-synced date

## Process

### Step 0: Load config

Read `.claude/agent-team.config.md`. Extract the `marketing` section:

```yaml
marketing:
  enabled: true
  site_dir: apps/marketing
  screenshots_dir: apps/marketing/public/screenshots
  pages:
    features: app/features/page.tsx
    changelog: app/changelog/page.tsx
    landing: app/page.tsx
```

Defaults when keys are absent:
- `site_dir`: `apps/marketing`
- `screenshots_dir`: `apps/marketing/public/screenshots`
- `pages`: `{}` (empty — skill will auto-discover)

**If the `marketing` section is absent or `enabled: false`:**
Respond: "Marketing site not configured. Add a `marketing` section to `.claude/agent-team.config.md` or run `/init-setup` to configure it." Stop.

Also check for `brand/BRAND.md`. If present, read it and extract:
- **Voice** — from `## Voice & Tone` → `**Voice:**` (used to calibrate generated copy tone)
- **Logo path** — from `## Logo & Visual Assets` (for any image references in generated content)

Brand info is optional for market-update — the skill works without it but produces better-calibrated copy when the brand guide is present.

### Step 1: Read what's new

1. Check if `docs/CHANGELOG.md` exists. If not:
   "No changelog found. Ship some features with `/work` first, then run `/market-update`."
   Stop.

2. Read `docs/CHANGELOG.md`.

3. Determine the last-synced date:
   - If `--since YYYY-MM-DD` was passed, use that date.
   - Otherwise, parse `<!-- marketing-last-synced: YYYY-MM-DD -->` from the file header.
   - If the value is `never` or the comment is absent, process all entries.

4. Parse all `<!-- changelog-entry ... -->` comment blocks. Extract the `date` field
   from each. Filter to entries where `date > last-synced-date`.

5. If no new entries:
   "Marketing site is up to date — no new changelog entries since {last-synced}."
   Stop.

6. Present the new entries for confirmation via `AskUserQuestion`:

   ```
   ## Found N new entries since {last-synced-date}

   - {Feature Name} ({date}, PR #{number})
   - {Feature Name} ({date}, PR #{number})

   Proceed with generating marketing copy? (yes / --dry-run to preview / no)
   ```

   Wait for response. If no: stop. If `--dry-run`: set dry-run flag and continue.

### Step 2: Read marketing site structure

1. Check if `{site_dir}` exists on disk.
   - **If it doesn't exist:**
     Ask via `AskUserQuestion`: "Marketing site at `{site_dir}` doesn't exist yet.
     1. Create a basic changelog page with the new content
     2. Skip marketing updates (still mark changelog as synced)
     If user picks 2: jump to Step 6 (update sync marker only).

2. For each page key in `marketing.pages`:
   - Check if `{site_dir}/{page_path}` exists.
   - If it exists, read its content and check for
     `{/* market-update:<section>:start */}` / `{/* market-update:<section>:end */}` markers.
   - Note whether markers are present (targeted replacement) or absent (append mode).

3. If `marketing.pages` is empty, scan `{site_dir}/app/` for `page.tsx` files in
   directories named `features`, `changelog`, `whats-new`, `updates`, or `landing`.
   Present discovered files via `AskUserQuestion` and ask which to update before continuing.

### Step 3: Generate content updates

For each new changelog entry × each target page, generate marketing copy.
This is the AI judgment step — transform technical feature descriptions into
language that connects with the product's users.

**Per page type:**

- **Features page** (`features`, `landing`): Convert user stories into
  benefit-led bullets. Lead with what the user gets, not what was built.
  Example: "Added export endpoint" → "Download your data as CSV with one click."

- **Changelog / What's New page** (`changelog`, `whats-new`, `updates`):
  Keep factual but conversational. Date + 2-3 sentence summary per entry.
  Read like a product blog update, not a commit log.

- **Landing hero** (`landing`): Only propose hero copy changes if the feature
  is significant enough to be a headline. Always show the current headline
  alongside the proposed replacement so the user can compare.

Present ALL proposed copy in a single `AskUserQuestion` block before writing anything:

```
## Proposed Marketing Updates

### {page path}

{Proposed copy for this page — new feature cards, changelog entries, or hero copy}

---

### {page path}

{Proposed copy for this page}

---

Apply these updates?
1. Yes — write all pages
2. Edit a section — tell me which one to change
3. Skip a page — enter the page name to skip
4. Dry run — show me the file diffs instead of writing
```

If the user wants to edit a section, incorporate their changes and re-present
before writing. Keep iterating until the user approves or skips.

### Step 4: [Conditional] Screenshot capture

Skip this step if ANY of the following is true:
- `playwright@claude-plugins-official` is not in the installed plugins list
- `CI` environment variable is set (any non-empty value)
- `--screenshots` flag was NOT passed AND the affected pages do NOT include `landing` or `features`
- Marketing dev server is NOT running: `lsof -i :3001 -t 2>/dev/null` returns no output

When all conditions pass:

1. Create `{screenshots_dir}` if it doesn't exist.

2. For each approved page, determine the corresponding route on port 3001:
   - `features` → `http://localhost:3001/features`
   - `changelog` → `http://localhost:3001/changelog` (or `/whats-new`, `/updates`)
   - `landing` → `http://localhost:3001/`
   - Custom pages → ask the user for the route if not obvious from the file path.

3. Using Playwright, take a full-page screenshot of each route.
   Save as:
   - `{screenshots_dir}/{page-name}-{YYYY-MM-DD}.png` — dated snapshot
   - `{screenshots_dir}/{page-name}-latest.png` — overwritten each run for easy reference

4. Note the screenshot filenames for use in Step 5 content (as `<Image>` `src` props).

**If the server is not running on port 3001:**
Note in the Step 6 report: "Screenshots skipped — marketing dev server not running on
port 3001. Start the server (`cd apps/marketing && bun dev`) and re-run with
`--screenshots` to capture them."

### Step 5: Apply updates

Skip entirely if `--dry-run` — instead print the complete proposed file content for
each page to the console and stop before Step 6.

For each page in the approved write queue:

1. Read the current file content (re-read, in case it was modified since Step 2).

2. **If section markers are present** (`{/* market-update:<section>:start */}` /
   `{/* market-update:<section>:end */}`):
   Replace the content between the markers with the new copy. Leave the markers in place.

3. **If no markers are present:**
   Append new content before the closing JSX tag of the page component, wrapped in markers:
   ```tsx
   {/* market-update:new-content:start */}
   {/* New content added by /market-update — reposition in your page layout as needed */}
   {new copy here}
   {/* market-update:new-content:end */}
   ```
   Warn the user: "Added content to `{file}` without section markers — you may want
   to reposition it in the page layout."

4. If screenshots were taken in Step 4, include `<Image>` references in the relevant
   sections using the `latest.png` path for stability:
   ```tsx
   <Image src="/screenshots/{page-name}-latest.png" alt="{feature name} screenshot" />
   ```

5. Write the updated file.

6. After all writes, if `test_commands.lint` is configured, run the linter on only
   the modified files and auto-fix any formatting issues.

7. Validate each modified file: if `test_commands.typecheck` is configured and
   `tsc --noEmit` fails on the modified file, revert that file and report:
   "Could not safely update `{file}` — TypeScript errors after write. The proposed
   copy is shown below — apply it manually."

### Step 6: Report + update sync marker

1. Update the `<!-- marketing-last-synced: ... -->` comment in `docs/CHANGELOG.md`
   to today's date. Use a targeted regex replacement on the first occurrence:
   replace `<!-- marketing-last-synced: .* -->` with `<!-- marketing-last-synced: YYYY-MM-DD -->`.

2. Print a structured summary:

   ```
   ## Marketing Update Complete

   ### Processed Changelog Entries
   - {Feature Name} (PR #{number}) — {date}
   - {Feature Name} (PR #{number}) — {date}

   ### Pages Updated
   - {site_dir}/app/features/page.tsx — N new feature cards added
   - {site_dir}/app/changelog/page.tsx — N new entries prepended

   ### Screenshots
   - {screenshots_dir}/features-{date}.png
   - {screenshots_dir}/features-latest.png
   [OR: Screenshots skipped — {reason}]

   ### Skipped Pages
   - {page} — {reason (user skipped / TypeScript error / not found)}

   ### Next Steps
   - Review changes: git diff {site_dir}/
   - Preview: http://localhost:3001
   - Commit when satisfied:
       git add {site_dir}/ docs/CHANGELOG.md
       git commit -m "marketing: sync with shipped features"
   ```

   Note: the skill does NOT commit. Marketing copy should be reviewed in a browser
   before committing — the exact command is shown so the user can run it when ready.

## Rules

- Never write to TSX files without user approval from Step 3
- Never commit — always show the commit command and let the user run it
- Never print secret values or full connection strings
- If TypeScript validation fails after a write, revert the file and report it
- Screenshot step is always conditional — never block on it
- The `marketing-last-synced` marker is updated even when pages are skipped,
  so re-running doesn't re-process already-reviewed entries
