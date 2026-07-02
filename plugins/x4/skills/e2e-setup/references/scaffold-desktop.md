# Scaffold: packages/playwright-desktop

Files to create for the Electron app e2e suite.

Ask the user before writing:
- "What is the built Electron main entry path?" → default: `apps/desktop/dist/main.js`

## Files to Create

### `packages/playwright-desktop/package.json`

```json
{
  "name": "@repo/playwright-desktop",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "e2e": "playwright test",
    "e2e:headed": "playwright test --headed",
    "e2e:ui": "playwright test --ui"
  },
  "dependencies": {
    "@repo/playwright-config": "workspace:*"
  },
  "devDependencies": {
    "@playwright/test": "latest",
    "electron-playwright-helpers": "latest"
  }
}
```

### `packages/playwright-desktop/playwright.config.ts`

```typescript
import { defineConfig } from '@playwright/test'
import { baseConfig } from '@repo/playwright-config'

export default defineConfig({
  ...baseConfig,
  testDir: './e2e/tests',
  // No webServer — Playwright launches Electron directly
  // Each test is responsible for launching and closing the app
})
```

### `packages/playwright-desktop/electron-helpers.ts`

```typescript
import { _electron as electron, ElectronApplication, Page } from 'playwright'
import { findLatestBuild, parseElectronApp } from 'electron-playwright-helpers'
import path from 'path'

const MAIN_ENTRY = process.env.ELECTRON_MAIN ?? '{{ELECTRON_MAIN}}'

export interface AppFixture {
  electronApp: ElectronApplication
  window: Page
}

export async function launchApp(): Promise<AppFixture> {
  let executablePath: string | undefined
  let args: string[]

  if (process.env.CI || process.env.USE_BUILD) {
    // Packaged build (CI or explicit flag)
    const latestBuild = findLatestBuild(path.dirname(MAIN_ENTRY))
    const appInfo = parseElectronApp(latestBuild)
    executablePath = appInfo.executable
    args = [appInfo.main]
  } else {
    // Dev mode — faster iteration, no build needed
    args = [path.resolve(MAIN_ENTRY)]
  }

  const electronApp = await electron.launch({
    executablePath,
    args: [
      ...args,
      // Required for CI (Linux headless)
      ...(process.env.CI ? ['--disable-gpu', '--no-sandbox'] : []),
    ],
    env: {
      ...process.env,
      ELECTRON_IS_TEST: '1',
      NODE_ENV: 'test',
    },
  })

  const window = await electronApp.firstWindow()
  await window.waitForLoadState('domcontentloaded')
  return { electronApp, window }
}
```

Replace `{{ELECTRON_MAIN}}` with the user's answer.

### `packages/playwright-desktop/e2e/tests/launch.spec.ts`

```typescript
import { test, expect } from '@playwright/test'
import { launchApp } from '../../electron-helpers'
import { ElectronApplication } from 'playwright'

let electronApp: ElectronApplication

test.afterEach(async () => {
  await electronApp?.close()
})

test.describe('app launch', () => {
  test('opens exactly one window', async () => {
    const app = await launchApp()
    electronApp = app.electronApp
    expect(electronApp.windows()).toHaveLength(1)
  })

  test('window title is correct', async () => {
    const { window } = await launchApp().then(a => { electronApp = a.electronApp; return a })
    const title = await window.title()
    expect(title).toBeTruthy()
    expect(title).not.toBe('')
  })

  test('main content area is visible', async () => {
    const { window } = await launchApp().then(a => { electronApp = a.electronApp; return a })
    await expect(window.locator('body')).toBeVisible()
  })
})
```

### `packages/playwright-desktop/e2e/tests/ipc.spec.ts`

```typescript
import { test, expect } from '@playwright/test'
import { launchApp } from '../../electron-helpers'
import { ipcMainInvokeHandler } from 'electron-playwright-helpers'
import { ElectronApplication, ipcMain } from 'electron'

let electronApp: ElectronApplication

test.afterEach(async () => {
  // CRITICAL: Remove IPC handlers to prevent test leaks on Linux/Windows
  // See: https://github.com/microsoft/playwright/issues/39248
  try {
    // @ts-expect-error — access main process ipcMain
    await electronApp?.evaluate(({ ipcMain }) => ipcMain.removeAllListeners())
  } catch { /* ignore if app already closed */ }
  await electronApp?.close()
})

test.describe('IPC handlers', () => {
  test('app-version handler returns a version string', async () => {
    const { electronApp: app } = await launchApp()
    electronApp = app
    const version = await ipcMainInvokeHandler(electronApp, 'app-version')
    expect(typeof version).toBe('string')
    expect(version).toMatch(/\d+\.\d+\.\d+/)
  })

  // Add your actual IPC channel tests here
})
```

### `packages/playwright-desktop/e2e/tests/dialogs.spec.ts`

```typescript
import { test, expect } from '@playwright/test'
import { launchApp } from '../../electron-helpers'
import { stubDialog } from 'electron-playwright-helpers'
import { ElectronApplication } from 'playwright'

let electronApp: ElectronApplication

test.afterEach(async () => {
  await electronApp?.close()
})

test.describe('native dialogs', () => {
  test('open file dialog result appears in UI', async () => {
    const { electronApp: app, window } = await launchApp()
    electronApp = app

    // Stub BEFORE triggering the action that opens the dialog
    await stubDialog(electronApp, 'showOpenDialog', {
      canceled: false,
      filePaths: ['/tmp/test-document.txt'],
    })

    // Replace with the actual UI element that opens a file dialog
    await window.getByRole('button', { name: /open/i }).click()
    await expect(window.getByText('/tmp/test-document.txt')).toBeVisible()
  })

  test('canceled dialog does not change state', async () => {
    const { electronApp: app, window } = await launchApp()
    electronApp = app

    await stubDialog(electronApp, 'showOpenDialog', { canceled: true, filePaths: [] })
    await window.getByRole('button', { name: /open/i }).click()
    // State should be unchanged — assert whatever the default state is
    await expect(window.getByText('/tmp/test-document.txt')).not.toBeVisible()
  })
})
```

## `.gitignore` Additions

```
playwright-report/
test-results/
```

## After Scaffolding

Tell the user:
1. Run `bun install` from repo root
2. Run `npx playwright install chromium` from `packages/playwright-desktop/`
3. Add `ELECTRON_IS_TEST=1` handling in `apps/desktop/src/main.ts` to disable the auto-updater during tests
4. Replace placeholder IPC channel names in `ipc.spec.ts` with actual channel names from the app
5. Replace the "open" button selector in `dialogs.spec.ts` with the actual element that triggers a file dialog
6. For CI: add Xvfb setup step to the GitHub Actions workflow (see `e2e-desktop.md`)
