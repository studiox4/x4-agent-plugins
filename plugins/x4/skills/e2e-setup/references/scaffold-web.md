# Scaffold: packages/playwright-web

Files to create for the Next.js web app e2e suite.

Ask the user before writing:
- "What port does apps/web run on?" → default: `3000`
- "What email should I use for the test user?" → default: `test@example.com`

## Files to Create

### `packages/playwright-web/package.json`

```json
{
  "name": "@repo/playwright-web",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "e2e": "playwright test",
    "e2e:ui": "playwright test --ui",
    "e2e:headed": "playwright test --headed"
  },
  "dependencies": {
    "@repo/playwright-config": "workspace:*"
  },
  "devDependencies": {
    "@playwright/test": "latest"
  }
}
```

### `packages/playwright-web/playwright.config.ts`

```typescript
import { defineConfig } from '@playwright/test'
import { baseConfig } from '@repo/playwright-config'

export default defineConfig({
  ...baseConfig,
  testDir: './e2e/tests',
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: '.playwright/storageState.json',
      },
      dependencies: ['setup'],
    },
  ],
  webServer: {
    command: 'bun run dev',
    cwd: '../../apps/web',
    port: {{WEB_PORT}},
    reuseExistingServer: !process.env.CI,
    env: {
      ...(process.env.TEST_USER_EMAIL && {
        TEST_USER_EMAIL: process.env.TEST_USER_EMAIL,
        TEST_USER_PASSWORD: process.env.TEST_USER_PASSWORD ?? '',
      }),
    },
  },
})
```

Replace `{{WEB_PORT}}` with the user's answer.

### `packages/playwright-web/e2e/auth.setup.ts`

```typescript
import { test as setup, expect } from '@playwright/test'
import path from 'path'

const authFile = path.join(__dirname, '../.playwright/storageState.json')

setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL ?? 'test@example.com')
  await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD ?? '')
  await page.getByRole('button', { name: /sign in/i }).click()
  await page.waitForURL(url => !url.pathname.includes('/login'))
  await page.context().storageState({ path: authFile })
})
```

### `packages/playwright-web/e2e/tests/auth.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

test.describe('authentication', () => {
  test('authenticated user can reach dashboard', async ({ page }) => {
    await page.goto('/dashboard')
    await expect(page).not.toHaveURL(/login/)
  })

  test('unauthenticated user is redirected to login', async ({ browser }) => {
    const context = await browser.newContext({ storageState: undefined })
    const page = await context.newPage()
    await page.goto('/dashboard')
    await expect(page).toHaveURL(/login/)
    await context.close()
  })

  test('redirects back after login', async ({ browser }) => {
    const context = await browser.newContext({ storageState: undefined })
    const page = await context.newPage()
    await page.goto('/dashboard')
    await expect(page).toHaveURL(/login/)
    await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL ?? '')
    await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD ?? '')
    await page.getByRole('button', { name: /sign in/i }).click()
    await expect(page).toHaveURL('/dashboard')
    await context.close()
  })
})
```

### `packages/playwright-web/e2e/tests/trpc.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

test.describe('API routes', () => {
  test('tRPC request succeeds for authenticated user', async ({ page, request }) => {
    // Verify a basic tRPC endpoint responds
    const response = await request.get('/api/trpc/user.me')
    expect(response.status()).not.toBe(401)
  })

  test('tRPC returns 401 without session', async ({ browser }) => {
    const context = await browser.newContext({ storageState: undefined })
    const request = context.request
    const response = await request.get('/api/trpc/user.me')
    expect(response.status()).toBe(401)
    await context.close()
  })
})
```

## `.gitignore` Additions

Add to the root `.gitignore` (or `packages/playwright-web/.gitignore`):
```
.playwright/storageState.json
.playwright/adminState.json
playwright-report/
test-results/
```

## `.env.test` (create at project root if it doesn't exist)

```
TEST_USER_EMAIL={{TEST_USER_EMAIL}}
TEST_USER_PASSWORD=
```

Replace `{{TEST_USER_EMAIL}}` with the user's answer. Tell the user to set
`TEST_USER_PASSWORD` before running tests.

## After Scaffolding

Tell the user:
1. Set `TEST_USER_PASSWORD` in `.env.test`
2. Ensure a test user with that email exists in the dev database (seed or create manually)
3. Run `bun install` from repo root to link the workspace package
4. Run `npx playwright install chromium` from `packages/playwright-web/`
