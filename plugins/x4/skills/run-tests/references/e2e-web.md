# E2E — Next.js Web App

Runtime guidance for running Playwright against `apps/web` (Next.js 15,
Better Auth, tRPC, Drizzle, Neon).

## Prerequisites

Before running, verify:

- [ ] `packages/playwright-web/playwright.config.ts` exists
- [ ] `.env.test` exists with `TEST_USER_EMAIL` and `TEST_USER_PASSWORD`
- [ ] `packages/playwright-web/.playwright/storageState.json` is in `.gitignore`
- [ ] `apps/web` dependencies are installed (`bun install`)

If any are missing, report specifically before attempting to run.

## Environment Setup

The web app must be running during tests. Playwright's `webServer` config
handles this — it starts `next dev` (or `next start` for built tests) on
the configured port before running tests.

Source `.env.test` for the test run:
- `TEST_USER_EMAIL` — the test user's email address
- `TEST_USER_PASSWORD` — the test user's password
- `NEXTAUTH_URL` or `BETTER_AUTH_BASE_URL` — must match the test server port

## Run Command

```bash
turbo run e2e --filter=playwright-web
```

For a single test file: `npx playwright test auth.spec.ts` from `packages/playwright-web/`.

## Core Test Scenarios

### 1. Authentication flow
Sign up → email verify (mocked) → sign in → sign out.
Uses `page.context().storageState()` to cache session for reuse in other tests.

### 2. Route protection
Unauthenticated user hits `/dashboard` → redirected to `/login`.
After login, redirected back to original URL (check `?callbackUrl` param behavior).

### 3. tRPC happy path
Authenticated user triggers a tRPC mutation or query. Assert the response
shape and that the UI reflects the result. Use `page.route('**/api/trpc/**')`
to intercept if mocking — or use a seeded test DB for real calls.

### 4. tRPC error path
Force a 401/403 response via `page.route`. Assert the error UI state renders
(toast, error banner, redirect) rather than a blank or broken page.

### 5. Form submission with validation
Fill a form with invalid data → assert inline validation errors appear.
Fill with valid data → submit → assert success state.

### 6. Session expiry / re-auth
Delete the session cookie mid-test. Trigger an authenticated action. Assert
the app redirects to login or surfaces a re-auth prompt.

## Authentication Setup Pattern

```typescript
// e2e/auth.setup.ts — runs once before all tests
import { test as setup } from '@playwright/test'

setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL!)
  await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD!)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.waitForURL('/dashboard')
  await page.context().storageState({ path: '.playwright/storageState.json' })
})
```

```typescript
// playwright.config.ts — projects with setup dependency
projects: [
  { name: 'setup', testMatch: /auth\.setup\.ts/ },
  {
    name: 'authenticated',
    use: { storageState: '.playwright/storageState.json' },
    dependencies: ['setup'],
  },
]
```

## tRPC RSC Interception

Server-side (RSC) tRPC calls require Next.js 15's `testProxy` + MSW:

```typescript
// next.config.ts
experimental: { testProxy: true }
```

Client-side calls can be intercepted with `page.route('**/api/trpc/**', ...)`.

## Failure Triage

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `storageState.json: file not found` | Auth setup didn't run | Check `dependencies: ['setup']` in config; re-run with `--project=setup` first |
| `ERR_CONNECTION_REFUSED` on port 3000 | webServer failed to start | Check `apps/web` for build errors; verify port not already in use |
| `Expected to be at /dashboard, got /login` | Test credentials wrong | Verify `TEST_USER_EMAIL`/`TEST_USER_PASSWORD` in `.env.test` match a seeded user |
| tRPC 401 on authenticated route | storageState expired | Delete `.playwright/storageState.json` and re-run setup project |
| `NEXTAUTH_URL mismatch` warning | Env var points to wrong port | Set `BETTER_AUTH_BASE_URL=http://localhost:3000` in `.env.test` |
| Flaky test: element not found | Race condition on navigation | Replace `waitForTimeout` with `waitForURL` or `waitForSelector` |
