---
description: Scaffold project tracking files (STATUS.md, BACKLOG.md, planning directory)
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

Initialize the project tracker for this repository.

## Process

1. **Read config** — load `.claude/project-tracker.config.md`. If it does not exist, use all defaults.

2. **Check for existing files** — if the status file, backlog file, or planning directory already exist,
   list them and ask the user before overwriting. Never silently overwrite.

3. **Create the config file** if `.claude/project-tracker.config.md` does not exist:
   - Write the default config template (from the Config Schema section of this plugin's spec)
   - Tell the user they can customize it

4. **Create the status file** at the configured `status_file` path with this template:

   ```
   # <Project Name> — Project Status

   > Last updated: <YYYY-MM-DD>

   ---

   ## Current Focus

   *Set your current focus here.*

   ---

   ## Planning Documents

   | # | Document | Status | Dependencies | Notes |
   |---|----------|--------|--------------|-------|

   ## Feature Build Progress

   | Feature | Planning | <status_columns[0]> | <status_columns[1]> | ... |
   |---------|----------|---------------------|---------------------|-----|

   ---

   ## Key Decisions

   | Decision | Choice | Status | See |
   |----------|--------|--------|-----|
   ```

   Use the project name from `package.json` name field, the repo directory name, or ask the user.
   The `<col>` headers come from the configured `status_columns`.

5. **Create the backlog file** at the configured `backlog_file` path:

   ```
   # <Project Name> — Backlog & Ideas

   Captured during development. Review during planning sessions.

   ---
   ```

6. **Create the planning directory** with subdirectories at the configured `planning_dir` path:
   ```
   mkdir -p <planning_dir>/todo <planning_dir>/in-progress <planning_dir>/complete
   ```

7. **Commit all created files:**

   ```
   git add <all created files>
   git commit -m "<commits.init from config>"
   ```

8. **Respond:**

   > Project tracker initialized.
   > - Status: `<status_file>`
   > - Backlog: `<backlog_file>`
   > - Planning: `<planning_dir>`
   > - Config: `.claude/project-tracker.config.md`
   >
   > Customize your config, then use `/idea` to capture ideas and `/plan-backlog` to turn them into PRDs.
