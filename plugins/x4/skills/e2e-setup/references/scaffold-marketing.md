# Scaffold: packages/playwright-marketing

Files to create for the marketing site e2e suite.
Tests run against a production build — never the dev server.

Ask the user before writing:
- "What port should the marketing test server use?" → default: `3010`

## Files to Create

### `packages/playwright-marketing/package.json`

```json
{
  "name": "@repo/playwright-marketing",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "e2e": "playwright test",
    "e2e:update-snapshots": "playwright test --update-snapshots",
    "e2e:ui": "playwright test --ui"
  },
  "dependencies": {
    "@repo/playwright-config": "workspace:*"
  },
  "devDependencies": {
    "@playwright/test": "latest"
  }
}
```

### `packages/playwright-marketing/playwright.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test'
import { baseConfig } from '@repo/playwright-config'

export default defineConfig({
  ...baseConfig,
  testDir: './e2e/tests',
  snapshotDir: './snapshots',
  // Snapshots are compared with tolerance to handle minor rendering diffs
  expect: {
    toHaveScreenshot: { threshold: 0.1, maxDiffPixelRatio: 0.02 },
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Software renderer for deterministic canvas output (Three.js)
        launchOptions: {
          args: ['--use-angle=swiftshader', '--disable-gpu'],
        },
      },
    },
  ],
  webServer: {
    // Always test against a production build
    command: 'bun run start',
    cwd: '../../apps/marketing',
    port: {{MARKETING_PORT}},
    reuseExistingServer: !process.env.CI,
    // Ensure the app is built before starting
    // Developer must run: turbo run build --filter=marketing
  },
})
```

Replace `{{MARKETING_PORT}}` with the user's answer.

### `packages/playwright-marketing/e2e/tests/canvas.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  // Disable animations for deterministic screenshots
  await page.addStyleTag({
    content: '*, *::before, *::after { animation: none !important; transition: none !important; }'
  })
})

test.describe('Three.js canvas', () => {
  test('hero canvas renders (not blank)', async ({ page }) => {
    await page.goto('/')
    await page.waitForLoadState('networkidle')
    const canvas = page.locator('canvas').first()
    await expect(canvas).toBeVisible()
    await expect(canvas).toHaveScreenshot('hero-canvas.png')
  })
})
```

### `packages/playwright-marketing/e2e/tests/responsive.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

const VIEWPORTS = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 },
  { name: 'wide', width: 1440, height: 900 },
]

test.beforeEach(async ({ page }) => {
  await page.addStyleTag({
    content: '*, *::before, *::after { animation: none !important; transition: none !important; }'
  })
})

for (const viewport of VIEWPORTS) {
  test(`landing page — ${viewport.name} (${viewport.width}px)`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height })
    await page.goto('/')
    await page.waitForLoadState('networkidle')
    await expect(page).toHaveScreenshot(`home-${viewport.name}.png`)
  })
}
```

### `packages/playwright-marketing/e2e/tests/metadata.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

const ROUTES = ['/', '/features', '/pricing']

for (const route of ROUTES) {
  test(`OG tags present on ${route}`, async ({ page }) => {
    await page.goto(route)
    
    const ogTitle = await page.$eval('meta[property="og:title"]', el => el.getAttribute('content'))
    const ogDescription = await page.$eval('meta[property="og:description"]', el => el.getAttribute('content'))
    const ogImage = await page.$eval('meta[property="og:image"]', el => el.getAttribute('content'))
    const twitterCard = await page.$eval('meta[name="twitter:card"]', el => el.getAttribute('content'))
    
    expect(ogTitle).toBeTruthy()
    expect(ogDescription).toBeTruthy()
    expect(ogImage).toBeTruthy()
    expect(twitterCard).toBeTruthy()
  })
}

test('no-JS fallback: critical content visible without JavaScript', async ({ page }) => {
  await page.route('**/*.js', route => route.abort())
  await page.goto('/')
  // Critical content must be server-rendered
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
  await expect(page.getByRole('link', { name: /get started/i })).toBeVisible()
})
```

### `packages/playwright-marketing/e2e/tests/email-capture.spec.ts`

```typescript
import { test, expect } from '@playwright/test'

test.describe('email capture form', () => {
  test('valid email shows success state', async ({ page }) => {
    await page.goto('/')
    const emailInput = page.getByPlaceholder(/email/i)
    await emailInput.fill('hello@example.com')
    await page.getByRole('button', { name: /subscribe|notify|join/i }).click()
    await expect(page.getByText(/thank you|you're in|check your inbox/i)).toBeVisible()
  })

  test('invalid email shows validation error', async ({ page }) => {
    await page.goto('/')
    const emailInput = page.getByPlaceholder(/email/i)
    await emailInput.fill('notanemail')
    await emailInput.blur()
    await expect(page.getByText(/valid email|invalid/i)).toBeVisible()
  })
})
```

### `packages/playwright-marketing/snapshots/.gitkeep`

Empty file to ensure the snapshots directory is committed.

## `.gitignore` Additions

```
playwright-report/
test-results/
```

**Do NOT gitignore `snapshots/`** — baselines are committed intentionally.

## After Scaffolding

Tell the user:
1. Run `bun install` from repo root
2. Run `npx playwright install chromium` from `packages/playwright-marketing/`
3. Run `turbo run build --filter=marketing` to create the initial build
4. Generate initial baselines: `turbo run e2e --filter=playwright-marketing -- --update-snapshots`
5. Commit the generated `snapshots/*.png` files — they are the visual source of truth
