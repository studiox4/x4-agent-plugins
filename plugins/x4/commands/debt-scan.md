---
description: Audit the codebase for technical debt introduced by agent team builds — duplicated utilities, naming drift, dead exports, and misplaced shared code.
argument-hint: "[--since <branch>] [--full] [--fix]"
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion
---

Run the `/debt-scan` skill to audit for post-build technical debt.

$ARGUMENTS
