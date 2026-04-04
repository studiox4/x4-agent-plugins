# E2E — Marketing Site

Runtime guidance for running Playwright against `apps/marketing`
(Next.js + Three.js, static-heavy, visual regression).

## Prerequisites

Before running, verify:

- [ ] `packages/playwright-marketing/playwright.config.ts` exists
- [ ] `apps/marketing/.next/` exists (a production build is required)
- [ ] `packages/playwright-marketing/snapshots/` exists (visual baselines committed)
- [ ] `apps/marketing` dependencies are installed

If `.next/` is missing or stale, run the build before the suite:
`turbo run build --filter=marketing`

**Never test marketing against `next dev`.** Hot module replacement makes
Three.js canvas output non-deterministic. Always test against a built artifact.

## Environment Setup

`playwright.config.ts` should run:
```typescript
webServer: {
  command: 'next start',
  cwd: '../../apps/marketing',
  port: 3010,
  reuseExistingServer: !process.env.CI,
}
```

Port 3010 avoids collision with `apps/web` running on 3000.

Launch options (required for deterministic canvas in headless mode):
```typescript
use: {
  launchOptions: {
    args: ['--use-angle=swiftshader', '--disable-gpu'],
  },
}
```

`--use-angle=swiftshader` forces software rendering so Three.js canvas output
is identical across machines and CI environments without a GPU.

## Run Command

```bash
turbo run build --filter=marketing && turbo run e2e --filter=playwright-marketing
```

Or if the build is already current:
```bash
turbo run e2e --filter=playwright-marketing --only
```

## Core Test Scenarios

### 1. Core Web Vitals / LCP
Assert LCP < 2.5s, CLS < 0.1 on the landing page. Use Playwright's CDP session
to access performance metrics, or integrate `playwright-lighthouse`:
```typescript
const { lcp } = await playAudit({ page, thresholds: { 'largest-contentful-paint': 2500 } })
```
Run this test only on production builds. Gate in CI on marketing page changes.

### 2. Three.js / canvas baseline
```typescript
// Disable animations before snapshotting
await page.addStyleTag({
  content: '*, *::before, *::after { animation: none !important; transition: none !important; }'
})
await page.waitForLoadState('networkidle')
const canvas = page.locator('canvas').first()
await expect(canvas).toHaveScreenshot('hero-canvas.png', { threshold: 0.1 })
```
Baselines are committed in `snapshots/`. Update with `--update-snapshots` when
intentional visual changes are made.

### 3. Responsive layout breakpoints
```typescript
for (const viewport of [{ width: 375, height: 812 }, { width: 768, height: 1024 }, { width: 1280, height: 800 }]) {
  await page.setViewportSize(viewport)
  await expect(page).toHaveScreenshot(`home-${viewport.width}.png`)
}
```

### 4. Email capture form
- Submit valid email → assert success message / confirmation state
- Submit invalid email → assert inline validation error
- Submit with honeypot field filled → assert no success (bot protection)
- Assert form is not present after successful submission (no re-submit)

### 5. OG tags and metadata
```typescript
const ogImage = await page.$eval('meta[property="og:image"]', el => el.getAttribute('content'))
expect(ogImage).toBeTruthy()
expect(ogImage).not.toBe('')
```
Check `og:title`, `og:description`, `og:image`, `twitter:card` on every key route.

### 6. No-JS fallback (SSR/SSG completeness)
```typescript
await page.route('**/*.js', route => route.abort())
await page.goto('/')
await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
await expect(page.getByRole('link', { name: /get started/i })).toBeVisible()
```
Critical content must be visible without JavaScript. This validates SSG completeness.

### 7. Static content integrity
Follow all navigation links and assert HTTP 200. Assert footer links resolve.
No broken links in the nav or hero CTAs.

## Updating Visual Baselines

When an intentional UI change is made, regenerate snapshots:
```bash
npx playwright test --update-snapshots
```
Then commit the new `snapshots/*.png` files. Always review the diff before committing.

## Failure Triage

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `Screenshot comparison failed` | **DO NOT AUTO-FIX** — escalate to user | Review diff in `playwright-report/`. If change is intentional, run `--update-snapshots` and commit new baseline |
| `canvas element is empty / black` | `--use-angle=swiftshader` missing from launch args | Add to `launchOptions.args` in `playwright.config.ts` |
| `ERR_CONNECTION_REFUSED` on port 3010 | Build artifact missing or `next start` failed | Run `turbo run build --filter=marketing` first |
| LCP assertion failed | Slow page or large unoptimized image | Check `next/image` usage; verify images have explicit `width`/`height` |
| Screenshot flaky across runs | CSS animations not disabled | Add `page.addStyleTag` to disable animations in `beforeEach` |
| OG image 404 | Tested against dev server | Must test against production build (`next build && next start`) |

## Important: Visual Regression Auto-Fix Policy

**Never auto-fix a snapshot mismatch.** Automatically updating baselines would
silently hide real visual regressions. When `/verify-local` encounters a marketing
e2e failure, it must escalate to the user rather than attempting a fix. Always
show the path to the `playwright-report/` diff for manual review.
