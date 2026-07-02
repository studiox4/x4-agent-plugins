# E2E Turborepo Structure

Canonical structure and `turbo.json` task shape for multi-app e2e suites.

## Package Layout

```
packages/
  playwright-config/        ← shared base config (timeouts, reporters, browsers)
    package.json
    base.config.ts          ← exported base Playwright config
  playwright-web/           ← web app e2e suite
    package.json
    playwright.config.ts    ← extends base, sets webServer for apps/web
    e2e/
      auth.setup.ts
      tests/
  playwright-marketing/     ← marketing site e2e suite
    package.json
    playwright.config.ts    ← extends base, webServer runs next start (built)
    e2e/
      tests/
    snapshots/              ← committed visual baselines
  playwright-desktop/       ← electron e2e suite
    package.json
    playwright.config.ts    ← no webServer, launches Electron directly
    electron-helpers.ts
    e2e/
      tests/
```

## `turbo.json` e2e Task

```json
{
  "tasks": {
    "e2e": {
      "cache": false,
      "dependsOn": ["^build"],
      "passThroughEnv": ["PLAYWRIGHT_BROWSERS_PATH", "CI", "TEST_USER_EMAIL", "TEST_USER_PASSWORD"],
      "outputs": ["test-results/**", "playwright-report/**"]
    }
  }
}
```

`cache: false` is required — test results must never be served from cache.
`dependsOn: ["^build"]` ensures apps are built before e2e suites run against them.

## Port Allocation (avoid collisions when running in parallel)

| App | Dev port | E2E test port |
|-----|----------|---------------|
| web | 3000 | 3000 |
| marketing | 3001 | 3010 |
| desktop | — | — (Electron, no port) |

## Run Commands

```bash
# All suites
turbo run e2e

# Single suite
turbo run e2e --filter=playwright-web
turbo run e2e --filter=playwright-marketing
turbo run e2e --filter=playwright-desktop

# Skip build if already built
turbo run e2e --filter=playwright-web --only
```

## CI GitHub Actions Pattern

```yaml
- name: Install Playwright browsers
  run: npx playwright install chromium --with-deps
  working-directory: packages/playwright-web

- name: Run e2e
  run: turbo run e2e

- name: Upload Playwright report
  uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: playwright-report
    path: packages/*/playwright-report/
```

## `packages/playwright-config/base.config.ts`

```typescript
import { defineConfig } from '@playwright/test'

export const baseConfig = defineConfig({
  testDir: './e2e/tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['list']],
})
```
