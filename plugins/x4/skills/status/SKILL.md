---
name: status
description: Quick diagnostic dashboard showing app status, ports, database, git state, and companion plugins
version: 1.0.0
---

# /status -- Project Health Dashboard

Quick read-only dashboard for an x4-mono project. Shows what exists,
what's running, and what's configured.

## Prerequisites

Must be run from inside an x4-mono project root (has `turbo.json` and
`apps/` directory). If not in a project, suggest `/create`.

## Process

### Step 1: Detect project

1. Check for `turbo.json` in the current directory.
2. If missing, output:
   ```
   Not in an x4-mono project. Run /create to scaffold one.
   ```
   Then stop.
3. Read the root `package.json` to get the project name.

### Step 2: Detect apps and ports

Scan the `apps/` directory for subdirectories. Map each to its expected port:

| App directory  | Port | Protocol |
|----------------|------|----------|
| `apps/web/`    | 3000 | HTTP     |
| `apps/api/`    | 3002 | HTTP     |
| `apps/marketing/` | 3001 | HTTP  |
| `apps/docs/`   | 3003 | HTTP     |
| `apps/mobile*` | --   | Expo     |
| `apps/desktop/`| --   | Electron |

For each app with a port, check if it is running:
```bash
lsof -i :<port> -t 2>/dev/null
```
If the command returns a PID, the app is "Running". Otherwise "Stopped".

For mobile and desktop, just report "Detected" (no port to check).

### Step 3: Database status

1. Check if `.env.local` exists.
2. If yes, read it and look for `DATABASE_URL`.
3. If `DATABASE_URL` is set, report "Configured" with the host masked
   (show only `neon.tech/...` or similar, not the full connection string).
4. If not set or `.env.local` is missing, report "Not configured -- run /env".

### Step 4: Git status

1. Run `git remote -v` to check for a configured remote.
2. Run `git branch --show-current` to get the current branch name.
3. Run `git status --porcelain` to check for uncommitted changes.

Report:
- Remote: name + URL, or "No remote configured"
- Branch: current branch name
- Working tree: "Clean" or "<N> uncommitted changes"

### Step 5: Companion plugins

Check installation status of companion plugins. List which are installed
and which are missing.

**Required by x4:**
- `superpowers@claude-plugins-official`
- `code-simplifier@claude-plugins-official`

**Recommended:**
- `frontend-design@claude-plugins-official`
- `code-review@claude-plugins-official`
- `playwright@claude-plugins-official`
- `typescript-lsp@claude-plugins-official`
- `commit-commands@claude-plugins-official`
- `github@claude-plugins-official`
- `railway@railway-skills`

### Step 6: Display dashboard

Present all information in a single formatted output using `AskUserQuestion`:

```
## x4 Project Status

**Project:** <name>
**Location:** <cwd>

### Apps & Services

| App        | Port | Status  | URL                    |
|------------|------|---------|------------------------|
| web        | 3000 | Running | http://localhost:3000   |
| api        | 3002 | Stopped | http://localhost:3002   |
| marketing  | 3001 | --      | (not installed)        |
| mobile     | --   | Detected| Expo Dev Client        |

(Only show rows for apps that exist. Show "not installed" only for
web and api if missing, since those are expected in most presets.)

### Infrastructure

| Service       | Status                              |
|---------------|-------------------------------------|
| Database      | Configured (neon.tech/...)          |
| Git remote    | origin -> github.com/user/repo      |
| Branch        | main                                |
| Working tree  | Clean                               |

### Companion Plugins

| Plugin          | Status    | Used by               |
|-----------------|-----------|------------------------|
| superpowers     | Installed | /plan-backlog          |
| code-simplifier | Missing   | /work Phase 4          |
| frontend-design | Missing   | Frontend agent         |
| code-review     | Installed | Reviewer agent         |
| playwright      | Missing   | Tester agent           |
| typescript-lsp  | Installed | All TypeScript work    |
| commit-commands | Missing   | Git workflow           |
| github          | Installed | PR management          |
| railway         | Missing   | Railway deploys        |

### Tips
- Run /tour for a guided walkthrough of your project
- Run /onboard to install missing companion plugins
- Run /env to reconfigure environment variables

Anything else? (type a question or "done")
```

## Rules

- This is a read-only diagnostic skill. Do NOT modify any files.
- Mask sensitive values (DATABASE_URL connection strings, API keys).
- If `lsof` is not available, skip port checks and show "Unknown" status.
- Only show apps that actually exist in the `apps/` directory.
- Keep output concise -- this should be a quick glance, not a deep dive.
