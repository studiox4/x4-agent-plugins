---
name: x4-add
description: Add a new mobile app or web app to an existing x4-mono project
version: 1.0.0
license: MIT
---

# /add — Add App to Existing x4-mono Project

Add a new mobile app or web app to an existing x4-mono monorepo. Uses
the `create-x4 add` subcommand.

## Prerequisites

1. Must be run from inside an x4-mono project root (has `turbo.json` and
   the x4 workspace structure).
2. Bun must be installed.

## Process

### Step 1: Verify project

Check that the current directory is an x4-mono project:
- `turbo.json` exists
- `apps/` directory exists
- Root `package.json` has workspaces configured

If not in an x4-mono project, report:
```
Not in an x4-mono project. Run /create to scaffold a new project first.
```

### Step 2: Detect existing apps

Scan `apps/` to see what's already set up:
- List existing app directories and their types (web, api, mobile, desktop, etc.)
- Read root `package.json` for the npm scope

### Step 3: Choose what to add

Use `AskUserQuestion`:

```
## Add App to <project-name>

Existing apps: <list>

What would you like to add?

1. Mobile app   (Expo 52 + React Native)
2. Web app      (Next.js 15 + React 19)

Which app? (1-2):
```

### Step 4: Configure the new app

**For mobile app:**
```
## New Mobile App

- App name [<project-name>-mobile]:
- Bundle ID [com.<project-name>]:
```

**For web app:**
```
## New Web App

- App name [<project-name>-web-2]:
- Port [3003]:
```

### Step 5: Run create-x4 add

```bash
bunx create-x4 add
```

The `add` subcommand runs its own interactive prompts. Since we've already
gathered the configuration, provide the values when prompted.

Alternatively, if the CLI supports non-interactive add mode:
```bash
bunx create-x4 add --type mobile --name <name> --bundle-id <bundle-id>
```

### Step 6: Post-add setup

After the app is added:

1. Install dependencies: `bun install`
2. If mobile app was added and database is configured:
   - Remind about native auth setup (Expo Secure Store)
3. If web app was added:
   - Suggest configuring the port in the new app's config

### Step 7: Report

```
## App Added!

- **Type:** <mobile|web>
- **Name:** <app-name>
- **Location:** apps/<app-name>/
- **Port:** <port> [if web]

Run `bun dev` to start all apps including the new one.
```

## Rules

- Always verify we're in an x4-mono project before running
- Don't add an app type that already exists without asking
- Read the existing scope from root package.json — don't ask again
- If `create-x4 add` fails, show the error and suggest running
  `bun install` or checking for conflicts
