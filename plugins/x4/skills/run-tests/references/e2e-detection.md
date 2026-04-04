# E2E App Type Detection

Used by `/run-tests` and `/e2e-setup` to determine which apps are present
and whether their e2e suites are configured.

## Detection Signals

| Signal | App Type | How to Check |
|--------|----------|--------------|
| `apps/web/` exists + `next` in `apps/web/package.json` | web | `Glob apps/web/package.json` |
| `apps/marketing/` exists + `next` in `apps/marketing/package.json` | marketing | `Glob apps/marketing/package.json` |
| `apps/desktop/` exists + `electron` in `apps/desktop/package.json` | desktop | `Glob apps/desktop/package.json` |
| `packages/playwright-web/playwright.config.ts` exists | web configured | `Glob packages/playwright-web/playwright.config.ts` |
| `packages/playwright-marketing/playwright.config.ts` exists | marketing configured | `Glob packages/playwright-marketing/playwright.config.ts` |
| `packages/playwright-desktop/playwright.config.ts` exists | desktop configured | `Glob packages/playwright-desktop/playwright.config.ts` |

## States

**Detected, configured** — app dir exists AND playwright package exists with `playwright.config.ts`.
→ Ready to run. Load the corresponding runtime reference file.

**Detected, not configured** — app dir exists but playwright package does not.
→ Surface as a gap. Offer `/e2e-setup` before running.

**Not detected** — app dir does not exist.
→ Skip silently. Do not mention it.

## Fallback: Legacy Config

If no `packages/playwright-*` directories are found anywhere but `test_commands.e2e`
is set in `.claude/agent-team.config.md`, treat it as a single uncategorized e2e suite
and run the command directly (backward compatible). Do not apply app-type routing.

## Monorepo Root vs Single App

If the project has no `apps/` directory but has a `playwright.config.ts` in the root
or a `test_commands.e2e` command, treat as a single-app project and run that command
directly. The Turborepo multi-app routing only applies when `apps/` exists.
