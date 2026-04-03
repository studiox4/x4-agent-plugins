---
name: verify-local
description: Use as the quality gate before shipping — runs all configured checks (unit, e2e, lint, typecheck), auto-fixes failures up to 3 attempts per check, and updates the status file. Trigger for "verify everything passes", "run all checks", "gate before ship", or when /work Phase 4 needs a full verification pass. More thorough than /run-tests — includes auto-fix.
version: 2.0.0
license: MIT
---

# /verify-local — Local Verification Gate

Runs all configured test commands, auto-fixes failures (max 3 attempts per
check), and updates the status file. This is the mandatory gate between
Phase 4 (Review+Verify) and Phase 5 (Ship) in the `/work` pipeline.

## Process

### Step 1: Load config

Read `.claude/agent-team.config.md`. Parse `test_commands` section.
If config doesn't exist, fall back to defaults from `/run-tests`.

### Step 2: Run all checks in sequence

Run each configured check in order. All must pass.

| Check | Command | Required |
|-------|---------|----------|
| Unit tests | `test_commands.unit` | Yes |
| E2E tests | `test_commands.e2e` | If configured |
| Lint | `test_commands.lint` | If configured |
| Typecheck | `test_commands.typecheck` | If configured |

For each check:

1. Run the command via Bash.
2. **If PASS** — record result, move to next check.
3. **If FAIL** — enter auto-fix loop (Step 3).

### Step 3: Auto-fix loop (max 3 attempts per check)

When a check fails:

**Attempt 1-3:**
1. Analyze the failure output.
2. Determine the fix:
   - **Lint/typecheck failures:** Apply auto-fix directly (the errors point to
     exact files and lines).
   - **Unit test failures:** Read the failing test and the code under test.
     Fix the code (not the test) unless the test itself is wrong.
   - **E2E test failures:** Read the test, check selectors and expected values.
     Fix if the issue is clear; otherwise escalate.
3. Apply the fix and commit: `fix: resolve <check> failure — <brief description>`
4. Re-run the same check.
5. If still failing, increment attempt counter and retry.

**After 3 failed attempts:**
- STOP auto-fixing that check.
- Report the persistent failure to the user with full output.
- Ask whether to: (a) continue with remaining checks, (b) stop entirely.

### Step 4: Report results

```
## Verification Results

| Check     | Status | Attempts | Details              |
|-----------|--------|----------|----------------------|
| Unit      | PASS   | 1        | 42 passed, 0 failed  |
| E2E       | PASS   | 2        | Fixed selector issue  |
| Lint      | PASS   | 1        | Clean                 |
| Typecheck | PASS   | 1        | Clean                 |

All checks passed. Ready for Phase 5 (Ship).
```

### Step 5: Update status (if in /work pipeline context)

If running as part of the `/work` pipeline:
- Update the status file: set the "Tested" column to "Complete" for the
  current feature.

## Rules

- Never skip a configured check — all must run
- Fix code, not tests (unless the test is clearly wrong)
- Max 3 auto-fix attempts per check — then escalate to user
- Always show full failure output so the user can diagnose if needed
- If no test commands are configured at all, tell the user to run `/init-setup`
