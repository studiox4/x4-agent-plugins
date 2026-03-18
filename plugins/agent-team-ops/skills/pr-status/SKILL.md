---
name: pr-status
description: Check PR status — CI checks, preview URLs, review state — using gh CLI and configured commands
version: 2.0.0
license: MIT
---

# /pr-status — PR Status Check

Quick status check for the current branch's PR: CI state, preview URLs,
review status.

## Process

### Step 1: Get PR info

Run: `gh pr view --json number,title,state,statusCheckRollup,url,isDraft,reviewDecision`

If no PR exists for the current branch, report: "No PR found for branch
`<branch>`. Run `/pr-create` first."

### Step 2: CI status

**[If `ci.watch_command` is configured]:**
Run the configured watch command in non-blocking mode to get current status.

**Otherwise:**
Parse `statusCheckRollup` from the `gh pr view` output to show check states.

Report:

```
| Check | Status | Details |
|-------|--------|---------|
| build | PASS   | 2m 14s  |
| test  | FAIL   | 1 failure |
| lint  | PASS   | Clean   |
```

### Step 3: Preview URL

**[If `ci.preview_url_command` is configured]:**
Run the command and report the URL.

**Otherwise:** Skip. No mention of previews.

### Step 4: Review status

Parse `reviewDecision` from PR data:
- `APPROVED` → "Approved"
- `CHANGES_REQUESTED` → "Changes requested"
- `REVIEW_REQUIRED` → "Awaiting review"
- null → "No reviews yet"

### Step 5: Report

```
## PR Status: <title> (#<number>)

- **State:** Draft / Open / Merged / Closed
- **CI:** Passing / Failing / Pending
- **Preview:** <url> [if configured]
- **Reviews:** <status>
- **URL:** <pr-url>
```

## Rules

- Use `gh` CLI for all GitHub interactions
- Never cache PR status — always fetch fresh
- If `gh` is not authenticated, report and suggest `gh auth login`
