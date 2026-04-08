---
name: pr-review
description: Use when the user wants to review an open pull request — fetches the PR diff, dispatches code reviewer and security reviewer agents in parallel, and consolidates findings into a merge-readiness report. Trigger for "review this PR", "check the PR for security issues", "run a code review", or after /pr-create ships a branch.
version: 1.0.0
license: MIT
---

# /pr-review — Post-PR Review

Fetches an open pull request's full diff and runs a parallel code + security
review, then produces a consolidated merge-readiness report.

## Arguments

- `[pr-number|url]` — Optional. PR number (e.g. `42`) or GitHub URL. Defaults
  to the PR for the current branch.

---

## Process

### Step 1: Resolve the PR

1. If an argument was provided:
   - If it looks like a number, run: `gh pr view <number> --json number,title,headRefName,baseRefName,url`
   - If it looks like a URL, run: `gh pr view <url> --json number,title,headRefName,baseRefName,url`
2. If no argument was provided:
   - Run: `gh pr view --json number,title,headRefName,baseRefName,url`
   - If that fails (no PR for current branch), stop and tell the user:
     "No open PR found for the current branch. Pass a PR number or URL, or
     run `/pr-create` first."

Extract and record:
- `pr_number` — PR number
- `pr_title` — PR title
- `pr_url` — PR URL
- `head_branch` — source branch
- `base_branch` — target branch

### Step 2: Fetch the diff

Run:

```
gh pr diff <pr_number>
```

Save the output. If the diff is empty, report "PR has no changes — nothing to
review." and stop.

Also gather the file list:

```
gh pr view <pr_number> --json files -q '.files[].path'
```

### Step 3: Load config

Read `.claude/agent-team.config.md` if it exists. Extract:
- `tech_stack` (used to populate agent context)
- `conventions` (used to populate agent context)

If the file does not exist, proceed with empty values — the agents will infer
from the diff.

### Step 4: Dispatch reviewers in parallel

Spawn both agents simultaneously using the `Agent` tool with
`run_in_background: false` (wait for both before continuing).

**Code reviewer agent:**

Use `.claude/agents/reviewer.md` if it exists. Otherwise use the built-in
`x4:reviewer` subagent type.

Prompt:
```
Review PR #<pr_number> "<pr_title>" (<head_branch> → <base_branch>).

Full diff:
<diff output>

Changed files:
<file list>

Tech stack: <tech_stack>
Conventions: <conventions>

Check ALL changed files. Report findings using the standard format:
- [SECURITY] file:line -- description
- [BUG] file:line -- description
- [QUALITY] file:line -- description
- [STYLE] file:line -- description

Separate blockers (must fix before merge) from warnings (should fix) from
notes (informational). You are read-only — report only, do not fix.
```

**Security reviewer agent:**

Use `.claude/agents/security-reviewer.md` if it exists. Otherwise use the
built-in `x4:security-reviewer` subagent type.

Prompt:
```
Security audit for PR #<pr_number> "<pr_title>" (<head_branch> → <base_branch>).

Full diff:
<diff output>

Changed files:
<file list>

Tech stack: <tech_stack>

Audit for:
- Secrets, API keys, or credentials in committed code
- Authentication and authorization gaps
- Input validation at API boundaries
- SQL injection and XSS vectors
- CORS misconfiguration
- Insecure session or token handling
- Exposed environment variables (NEXT_PUBLIC_ / VITE_ secrets)

Report only confirmed issues with file:line references. Use tags:
- [AUTH] -- authentication/authorization issue
- [EXPOSURE] -- secret or credential leak
- [INJECTION] -- SQL/XSS/command injection risk
- [VALIDATION] -- missing input validation
- [CORS] -- CORS misconfiguration
- [SESSION] -- insecure session or token handling

Separate blockers from warnings. You are read-only — report only, do not fix.
```

**If `pr-review-toolkit@claude-plugins-official` is installed:**
Use `/pr-review-toolkit:code-reviewer` and `/pr-review-toolkit:security-reviewer`
instead of the above agent dispatches. Pass the PR number and diff as context.
These plugins run more specialized parallel passes and produce richer output.

### Step 5: Consolidate findings

Merge both agents' outputs. Deduplicate overlapping findings (same file:line
reported by both agents). Security findings take priority — list them first.

Count findings by category:
- Blockers (must fix before merge)
- Warnings (should fix)
- Notes (informational)

### Step 6: Report

```
## PR Review — #<pr_number>: <pr_title>

**Branch:** <head_branch> → <base_branch>
**PR:** <pr_url>
**Files changed:** <count>

---

### Blockers — must fix before merge

- [SECURITY] path/to/file.ts:42 — Description
- [BUG] path/to/file.ts:88 — Description

### Warnings — should fix

- [QUALITY] path/to/file.ts:15 — Description
- [AUTH] path/to/file.ts:30 — Description

### Notes

- [STYLE] General observation

---

### Summary

| Category | Blockers | Warnings | Notes |
|----------|----------|----------|-------|
| Security | N        | N        | N     |
| Code     | N        | N        | N     |
| **Total**| **N**    | **N**    | **N** |

### Merge readiness

[READY TO MERGE] No blockers found.
   — or —
[BLOCKERS PRESENT] X blocker(s) must be resolved before merge.
  Fix the items above, then re-run `/pr-review` to verify.
```

If there are no findings at all:

```
No issues found — this PR looks clean. Ready to merge.
```

---

## Rules

- Always wait for both agents to complete before consolidating.
- Never attempt to fix issues — report only. The developer fixes; they can
  re-run `/pr-review` to verify.
- If an agent returns no findings, include "No issues found" in that section
  rather than omitting the section entirely.
- Security blockers always appear before code blockers in the report.
- If `gh` CLI is unavailable, stop and tell the user to install it.
