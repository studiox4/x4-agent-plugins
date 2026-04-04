# Scaffold: packages/playwright-config

Shared base Playwright configuration reused by all app-specific suites.
Create this before scaffolding any individual app suite.

## Files to Create

### `packages/playwright-config/package.json`

```json
{
  "name": "@repo/playwright-config",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": "./base.config.ts"
  },
  "devDependencies": {
    "@playwright/test": "latest"
  }
}
```

### `packages/playwright-config/base.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test'

export const baseConfig = defineConfig({
  testDir: './e2e/tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI
    ? [['github'], ['html', { open: 'never' }]]
    : [['html', { open: 'on-failure' }], ['list']],
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
})

export { devices }
```

## After Creating

Run `bun install` (or the project's package manager) from the repo root to
link the new workspace package before any app-specific suites are scaffolded.
