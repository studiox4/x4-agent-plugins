# E2E — Electron App

Runtime guidance for running Playwright against `apps/desktop` (Electron,
IPC, native dialogs, file system).

## Prerequisites

Before running, verify:

- [ ] `packages/playwright-desktop/playwright.config.ts` exists
- [ ] `electron-playwright-helpers` is in `packages/playwright-desktop/package.json`
- [ ] `apps/desktop` is buildable (check for `electron-builder` or `electron-forge` config)
- [ ] On Linux CI: `DISPLAY` env var is set (`:99` with Xvfb)

## Key Import Pattern

```typescript
// Always use the _electron prefixed import
import { _electron as electron } from 'playwright'
import {
  findLatestBuild,
  parseElectronApp,
  ipcMainInvokeHandler,
  ipcRendererInvoke,
  stubDialog,
  clickMenuItemById,
} from 'electron-playwright-helpers'
```

`_electron` is experimental in Playwright but stable for standard UI flows.
It may have breaking changes between Playwright minor versions — pin the version.

## App Launch Pattern

```typescript
// electron-helpers.ts — shared across all test files
import { _electron as electron } from 'playwright'
import { findLatestBuild, parseElectronApp } from 'electron-playwright-helpers'

export async function launchApp() {
  const latestBuild = findLatestBuild('apps/desktop/dist')
  const appInfo = parseElectronApp(latestBuild)
  
  const electronApp = await electron.launch({
    args: [appInfo.main],
    executablePath: appInfo.executable,
    env: {
      ...process.env,
      ELECTRON_IS_TEST: '1',     // disables auto-updater, enables test IPC
      NODE_ENV: 'test',
    },
    // Required for CI (Linux)
    ...(process.env.CI && {
      args: [appInfo.main, '--disable-gpu', '--no-sandbox'],
    }),
  })
  
  const window = await electronApp.firstWindow()
  await window.waitForLoadState('domcontentloaded')
  return { electronApp, window }
}
```

For fast dev-mode testing (unpackaged), use:
```typescript
const electronApp = await electron.launch({ args: ['.'], cwd: 'apps/desktop' })
```

## Environment Setup

No `webServer` needed — Playwright launches Electron directly.

**`ELECTRON_IS_TEST=1` flag in main process:**
```typescript
// apps/desktop/src/main.ts
if (process.env.ELECTRON_IS_TEST === '1') {
  autoUpdater.enabled = false
  // expose test-only IPC channels if needed
}
```

## Run Command

```bash
turbo run e2e --filter=playwright-desktop
```

On Linux CI, Xvfb must be running:
```yaml
# GitHub Actions
- name: Start Xvfb
  run: Xvfb :99 -screen 0 1280x720x24 &
- name: Run e2e
  env:
    DISPLAY: ':99'
  run: turbo run e2e --filter=playwright-desktop
```

## Core Test Scenarios

### 1. App launch and window state
```typescript
test('opens one window with correct title', async () => {
  const { electronApp, window } = await launchApp()
  const windows = electronApp.windows()
  expect(windows).toHaveLength(1)
  const title = await window.title()
  expect(title).toBe('My App')
  await electronApp.close()
})
```

### 2. IPC handler round-trip (main process)
```typescript
test('get-user-data IPC handler returns user object', async () => {
  const { electronApp } = await launchApp()
  const result = await ipcMainInvokeHandler(electronApp, 'get-user-data', { id: 1 })
  expect(result).toMatchObject({ id: 1, name: expect.any(String) })
  await electronApp.close()
})
```

### 3. IPC from renderer to main
```typescript
test('save-file IPC writes file and confirms', async () => {
  const { electronApp, window } = await launchApp()
  const result = await ipcRendererInvoke(window, 'save-file', { content: 'hello' })
  expect(result.success).toBe(true)
  await electronApp.close()
})
```

### 4. File dialog stubbing
```typescript
test('open file dialog populates file path in UI', async () => {
  const { electronApp, window } = await launchApp()
  // Must stub BEFORE triggering the UI action that opens the dialog
  await stubDialog(electronApp, 'showOpenDialog', {
    canceled: false,
    filePaths: ['/tmp/test-file.txt'],
  })
  await window.getByRole('button', { name: 'Open File' }).click()
  await expect(window.getByText('/tmp/test-file.txt')).toBeVisible()
  await electronApp.close()
})
```

### 5. Application menu action
```typescript
test('File > New creates a new document', async () => {
  const { electronApp, window } = await launchApp()
  await clickMenuItemById(electronApp, 'new-document')
  await expect(window.getByText('Untitled Document')).toBeVisible()
  await electronApp.close()
})
```

### 6. Multi-window management
```typescript
test('opens a second window on demand', async () => {
  const { electronApp, window } = await launchApp()
  await window.getByRole('button', { name: 'New Window' }).click()
  const secondWindow = await electronApp.waitForEvent('window')
  await secondWindow.waitForLoadState('domcontentloaded')
  expect(electronApp.windows()).toHaveLength(2)
  await electronApp.close()
})
```

### 7. App quit and lifecycle
```typescript
test('quits cleanly from menu', async () => {
  const { electronApp } = await launchApp()
  await clickMenuItemById(electronApp, 'quit')
  await electronApp.waitForEvent('close')
  // If we reach here, the app closed without hanging
})
```

## IPC Handler Cleanup (Critical)

**Known Playwright bug on Linux/Windows:** IPC handlers registered during tests
are not cleaned up between tests, causing subsequent tests to hang indefinitely.

**Fix — always clean up in `afterEach`:**
```typescript
afterEach(async () => {
  ipcMain.removeAllListeners()
  // Or be specific: ipcMain.removeHandler('channel-name')
  await electronApp?.close()
})
```

Never use `ipcMain.handle` for test-only channels — use `ipcMain.once` so it
auto-removes after first invocation.

## Failure Triage

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| Test hangs indefinitely on Linux | Leaky IPC handlers | Add `ipcMain.removeAllListeners()` in `afterEach` |
| `executable not found` | App not built | Run `electron-builder build` in `apps/desktop` first |
| `[Errno 2] No such file or display` | Missing Xvfb on Linux | Set `DISPLAY=:99` and start Xvfb before test run |
| Native dialog blocks test | Dialog not stubbed before trigger | Call `stubDialog()` BEFORE the button click that opens it |
| `contextIsolation` error accessing renderer internals | Security settings correct | Use IPC channels via `contextBridge` instead of direct DOM access |
| `electronApp.evaluate is not serializable` | Closure over test variable | Pass data as second arg: `electronApp.evaluate(({ app }, arg) => ..., myValue)` |
| Second window not found | Race condition | Use `electronApp.waitForEvent('window')` not a fixed delay |
