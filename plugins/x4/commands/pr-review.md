---
description: Review an open PR — runs code review and security audit in parallel, reports blockers before merge.
argument-hint: "[pr-number|url]"
allowed-tools: Read, Bash, Glob, Grep, Agent
---

Run the `/pr-review` skill to review the current (or specified) pull request.

Accepts an optional PR number or GitHub URL. When omitted, uses the PR for
the current branch.
