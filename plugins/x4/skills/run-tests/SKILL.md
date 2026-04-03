---
name: run-tests
description: Use when the user wants to run tests — reads test commands from agent-team config and runs unit, e2e, lint, and/or typecheck. Trigger for "run tests", "run unit tests", "check lint", "run e2e", or any request to execute the project's test suite. Pass a specific type (unit/e2e/lint/typecheck) or run all.
argument-hint: "[unit|e2e|lint|typecheck]"
version: 2.0.0
license: MIT
---

# /run-tests

Run test commands as defined in `.claude/agent-team.config.md`.

## Behavior

1. **Read config.** Load `.claude/agent-team.config.md` and parse the
   `test_commands` section from YAML frontmatter.

2. **If no arguments provided**, run ALL configured test types in order:
   - `unit` (required -- always runs)
   - `e2e` (if configured and non-empty)
   - `lint` (if configured and non-empty)
   - `typecheck` (if configured and non-empty)

3. **If an argument is provided** (e.g., `/run-tests unit` or `/run-tests e2e`),
   run only that specific test type.

4. **For each test type**, run the configured command via Bash:

$ {test_commands.<type>}

Show the full output. Report pass/fail status.

5. **Summary:**

## Test Results

| Type      | Status | Details             |
| --------- | ------ | ------------------- |
| unit      | PASS   | 42 passed, 0 failed |
| e2e       | FAIL   | 3 passed, 1 failed  |
| lint      | PASS   | No warnings         |
| typecheck | SKIP   | Not configured      |

6. **If any test fails**, show the failure output and suggest which files
likely need fixing based on the error messages.

## Fallback

If `.claude/agent-team.config.md` does not exist, try common defaults:
- Unit: `npm test`
- E2E: skip
- Lint: `npm run lint` (if `lint` script exists in package.json)
- Typecheck: `npx tsc --noEmit` (if `tsconfig.json` exists)

If no config and no defaults apply, tell the user to create the config file
or provide the test command directly.
