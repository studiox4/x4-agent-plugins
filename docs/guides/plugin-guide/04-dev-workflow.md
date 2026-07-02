# 04 -- Dev Workflow

How to set up, develop, test, version, publish, and iterate on the three Claude Code plugins in the `studiox4/x4-agent-plugins/` monorepo.

---

## 1. Repository Structure

```
x4-agent-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Central registry of all plugins in this repo
├── plugins/
│   ├── project-tracker/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest: name, version, skills, commands, hooks
│   │   ├── commands/
│   │   │   ├── idea.md
│   │   │   └── init-tracker.md
│   │   ├── skills/
│   │   │   ├── idea/SKILL.md
│   │   │   └── plan-backlog/SKILL.md
│   │   ├── hooks/
│   │   │   └── session-start.md
│   │   ├── LICENSE                # Apache 2.0
│   │   └── README.md
│   ├── agent-team-ops/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── commands/
│   │   │   ├── work.md
│   │   │   ├── init-agents.md
│   │   │   ├── init-setup.md
│   │   │   ├── verify-local.md
│   │   │   ├── pr-create.md
│   │   │   ├── pr-status.md
│   │   │   └── pr-cleanup.md
│   │   ├── skills/
│   │   │   ├── work/SKILL.md
│   │   │   └── run-tests/SKILL.md
│   │   ├── agents/
│   │   │   ├── backend.md
│   │   │   ├── frontend.md
│   │   │   ├── reviewer.md
│   │   │   ├── tester.md
│   │   │   └── performance.md
│   │   ├── hooks/
│   │   │   ├── protected-files.sh
│   │   │   ├── auto-format.sh
│   │   │   └── teammate-idle.sh
│   │   ├── LICENSE                # Apache 2.0
│   │   └── README.md
│   ├── llmstxt-manager/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── commands/
│   │   │   ├── llmstxt-init.md
│   │   │   ├── llmstxt-update.md
│   │   │   └── llmstxt-status.md
│   │   ├── skills/
│   │   │   └── llmstxt-update/SKILL.md
│   │   ├── templates/
│   │   │   └── download-ai-docs.py
│   │   ├── LICENSE                 # Apache 2.0
│   │   └── README.md
│   └── x4-scaffold/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── commands/
│       │   └── scaffold.md
│       ├── skills/
│       │   └── scaffold/SKILL.md
│       ├── LICENSE                 # Apache 2.0
│       └── README.md
├── tests/
│   ├── fixtures/
│   │   ├── daykeep/               # Minimal mirror of Daykeep structure
│   │   │   ├── CLAUDE.md
│   │   │   ├── docs/STATUS.md
│   │   │   ├── docs/BACKLOG.md
│   │   │   ├── docs/llms-txt/
│   │   │   ├── package.json       # Has real dependencies for llmstxt scanning
│   │   │   └── .claude/
│   │   ├── simple-app/            # Single-app project (no monorepo)
│   │   │   ├── CLAUDE.md
│   │   │   ├── docs/STATUS.md
│   │   │   ├── docs/BACKLOG.md
│   │   │   ├── package.json
│   │   │   └── .claude/
│   │   └── python-project/        # Non-JS project
│   │       ├── CLAUDE.md
│   │       ├── docs/STATUS.md
│   │       ├── docs/BACKLOG.md
│   │       ├── pyproject.toml
│   │       ├── requirements.txt
│   │       └── .claude/
│   └── validate.sh                # Runs validation suite against all fixtures
├── .claude/
│   ├── CLAUDE.md                  # Instructions for developing the plugins themselves
│   └── settings.json
├── LICENSE                        # Apache 2.0 (repo-level)
├── README.md
└── CHANGELOG.md
```

### Key points

- Each plugin is fully self-contained under `plugins/<name>/`, with its own `.claude-plugin/plugin.json`, `LICENSE`, and `README.md`.
- The root `.claude-plugin/marketplace.json` is the central registry that lists all plugins in the repo. This follows the official `anthropics/claude-plugins-official` convention.
- Agent templates for `x4-agent-team-ops` live in `agents/` (not `templates/`), matching the standard plugin directory names.
- The `tests/fixtures/` directory contains minimal project skeletons for validation. These are not full apps -- just enough file structure for skills and hooks to read and write against.
- The repo's own `.claude/CLAUDE.md` provides context when using Claude Code to develop the plugins.
- Every plugin includes an Apache 2.0 `LICENSE` file, matching the repo-level license.

### marketplace.json

The root `.claude-plugin/marketplace.json` registers all plugins so they can be discovered and installed individually:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "x4-agent-plugins",
  "description": "Reusable workflow plugins for Claude Code: project tracking, agent team ops, llms.txt management, and scaffolding",
  "owner": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  },
  "plugins": [
    {
      "name": "x4-project-tracker",
      "description": "Backlog capture, triage, PRD generation, and status tracking",
      "category": "productivity",
      "author": { "name": "Corban Baxter", "email": "corban@example.com" },
      "source": "plugins/project-tracker",
      "homepage": "https://github.com/studiox4/x4-agent-plugins",
      "version": "2.0.0",
      "tags": ["backlog", "planning", "prd", "status-tracking"]
    },
    {
      "name": "x4-agent-team-ops",
      "description": "Agent team coordination, feature dispatching, and review cycles",
      "category": "development",
      "author": { "name": "Corban Baxter", "email": "corban@example.com" },
      "source": "plugins/agent-team-ops",
      "homepage": "https://github.com/studiox4/x4-agent-plugins",
      "version": "2.0.0",
      "tags": ["agents", "teams", "workflow", "ci-cd"]
    },
    {
      "name": "x4-llmstxt-manager",
      "description": "Scan dependencies and manage llms.txt reference documentation",
      "category": "development",
      "author": { "name": "Corban Baxter", "email": "corban@example.com" },
      "source": "plugins/llmstxt-manager",
      "homepage": "https://github.com/studiox4/x4-agent-plugins",
      "version": "2.0.0",
      "tags": ["llms-txt", "documentation", "dependencies"]
    },
    {
      "name": "x4-scaffold",
      "description": "Project scaffolding and boilerplate generation",
      "category": "development",
      "author": { "name": "Corban Baxter", "email": "corban@example.com" },
      "source": "plugins/x4-scaffold",
      "homepage": "https://github.com/studiox4/x4-agent-plugins",
      "version": "2.0.0",
      "tags": ["scaffold", "boilerplate", "project-setup"]
    }
  ]
}
```

When you add a new plugin, add an entry here to make it discoverable.

---

## 2. Local Development

### Linking a plugin for local testing

During development, you do not publish to test changes. Instead, link the plugin directory so Claude Code loads it from your local filesystem.

```bash
# From a consumer project (e.g., Daykeep):
claude plugin link /path/to/x4-agent-plugins/plugins/project-tracker
claude plugin link /path/to/x4-agent-plugins/plugins/agent-team-ops
claude plugin link /path/to/x4-agent-plugins/plugins/llmstxt-manager
```

Linked plugins override any installed version of the same plugin. To unlink:

```bash
claude plugin unlink x4-project-tracker
```

### Using --plugin-dir flag

For one-off testing without linking:

```bash
claude --plugin-dir /path/to/x4-agent-plugins/plugins/project-tracker
```

This loads the plugin for the current session only, without persisting any link.

### Testing changes against a real project

The iteration loop looks like this:

```
1. Open two terminals:
   - Terminal A: x4-agent-plugins/ repo (editing plugin source)
   - Terminal B: consumer project (e.g., Daykeep)

2. In Terminal B, link the plugin(s) you are working on.

3. Edit plugin files in Terminal A.

4. In Terminal B, start a Claude Code session and invoke the skill/command.
   Changes to skill .md files take effect on the next invocation --
   no restart needed.

5. Observe behavior, adjust, repeat.

6. When satisfied, commit in Terminal A.
```

### Verifying a link is active

```bash
claude plugin list
```

Linked plugins show their local path instead of a version number.

---

## 3. Multi-Project Testing Strategy

Every change should be validated against at least two project types before publishing. The three test fixtures in the repo cover the main categories.

### Test matrix

| Plugin          | Daykeep (complex monorepo) | simple-app (single app) | python-project (non-JS) |
| --------------- | -------------------------- | ----------------------- | ----------------------- |
| x4-project-tracker | Required                   | Required                | Required                |
| x4-agent-team-ops  | Required                   | Required                | Optional                |
| x4-llmstxt-manager | Required                   | Required                | Required                |

### What to verify per plugin

**x4-project-tracker:**

- `/idea` appends items to `docs/BACKLOG.md` with correct formatting
- `/plan-backlog` reads BACKLOG.md, presents triage menu, updates STATUS.md
- `/prd-generate` creates a new file in the planning directory
- SessionStart hook prints current phase from STATUS.md
- Config file (`.claude/project-tracker.config.md`) is read when present, defaults used when absent

**x4-agent-team-ops:**

- `/work` reads STATUS.md, identifies next task, proposes agent team
- `/run-tests` executes the configured test command
- `/init-agents` generates agent .md files from templates
- PreToolUse hook blocks writes to protected files
- PostToolUse hook runs formatter after file edits
- TeammateIdle hook enforces test pass before idle
- Works with and without the other two plugins installed

**x4-llmstxt-manager:**

- `/llmstxt-update` scans dependencies (package.json, pyproject.toml, go.mod)
- Discovers llms.txt URLs for detected dependencies
- Downloads and saves to configured docs directory
- Updates CLAUDE.md reference table
- `/llmstxt-status` shows current vs available docs

### Validation checklist

Run through this before every publish:

```
[ ] x4-project-tracker against daykeep fixture -- all skills produce correct output
[ ] x4-project-tracker against simple-app fixture -- defaults work without config file
[ ] x4-project-tracker against python-project fixture -- STATUS.md and BACKLOG.md work
[ ] x4-agent-team-ops against daykeep fixture -- all hooks fire correctly
[ ] x4-agent-team-ops against simple-app fixture -- works without other plugins
[ ] x4-llmstxt-manager against daykeep fixture -- finds all monorepo dependencies
[ ] x4-llmstxt-manager against simple-app fixture -- single package.json scan works
[ ] x4-llmstxt-manager against python-project fixture -- pyproject.toml scan works
[ ] Each plugin has .claude-plugin/plugin.json, LICENSE, and README.md
[ ] Root .claude-plugin/marketplace.json lists all plugins with correct versions
[ ] Each plugin installs cleanly from a fresh state (no leftover links)
[ ] Each plugin's config defaults are sane when no config file exists
```

---

## 4. Versioning Strategy

Each plugin is versioned independently via the `version` field in its `.claude-plugin/plugin.json`. Keep the version in sync with the corresponding entry in the root `marketplace.json`.

### Semver rules

| Bump  | When                                                                                      | Example                                            |
| ----- | ----------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Patch | Bug fixes, wording changes in skills, no behavior change                                  | Fix typo in `/idea` output format                   |
| Minor | New skill/command added, new config option (backward-compatible), improved behavior       | Add `/prd-generate` skill to x4-project-tracker       |
| Major | Breaking config changes, renamed skills/commands, removed features, changed hook behavior | Rename `backlog_file` config key to `backlog_path` |

### .claude-plugin/plugin.json version field

```json
// plugins/project-tracker/.claude-plugin/plugin.json
{
  "name": "x4-project-tracker",
  "version": "2.0.0",
  "description": "Backlog capture, triage, PRD generation, status tracking"
}
```

### Changelog format

Maintain a single `CHANGELOG.md` at the repo root, organized by plugin and version:

```markdown
# Changelog

## x4-project-tracker

### 1.2.0 (2026-03-20)

- Added `/prd-generate` skill for standalone PRD creation
- SessionStart hook now shows build progress percentage

### 1.1.0 (2026-03-18)

- Added scope labels configuration to config file
- `/plan-backlog` now supports custom triage categories

### 1.0.0 (2026-03-15)

- Initial release: `/idea`, `/plan-backlog`, SessionStart hook

## x4-agent-team-ops

### 1.0.0 (2026-03-15)

- Initial release: `/work`, `/run-tests`, `/init-agents`, all hooks

## x4-llmstxt-manager

### 1.0.0 (2026-03-15)

- Initial release: `/llmstxt-update`, `/llmstxt-status`
```

### Independent versioning

Plugins version independently. A change to `x4-project-tracker` does not require bumping `x4-agent-team-ops`. The CHANGELOG groups entries by plugin so consumers can track what changed in the plugins they use.

---

## 5. Publishing and Distribution

### Publishing a plugin

From the plugin repo root:

```bash
# Publish a single plugin
claude plugin publish ./plugins/project-tracker

# Publish all three
claude plugin publish ./plugins/project-tracker
claude plugin publish ./plugins/agent-team-ops
claude plugin publish ./plugins/llmstxt-manager
```

The `publish` command reads the `plugin.json` manifest, validates the plugin structure, and uploads it to the Claude Code plugin registry under your account.

### How users install

Users install by specifying the repo and plugin path:

```bash
# Install individual plugins
claude plugin install studiox4/x4-agent-plugins/x4-project-tracker
claude plugin install studiox4/x4-agent-plugins/x4-agent-team-ops
claude plugin install studiox4/x4-agent-plugins/x4-llmstxt-manager

# Or install all three at once if supported
claude plugin install studiox4/x4-agent-plugins/x4-project-tracker \
                      studiox4/x4-agent-plugins/x4-agent-team-ops \
                      studiox4/x4-agent-plugins/x4-llmstxt-manager
```

After installation, the plugin's skills, commands, and hooks are available in any Claude Code session within the project.

### Verifying installation

```bash
claude plugin list
```

Shows installed plugins with their versions and source.

---

## 6. Update Flow

### How consumer projects get updates

```bash
# Update a specific plugin
claude plugin update x4-project-tracker

# Update all installed plugins
claude plugin update
```

This pulls the latest published version. Linked plugins (for local dev) are not affected by `update`.

### Breaking change handling

When a major version bump introduces breaking changes:

1. Document the breaking change in the CHANGELOG with a **BREAKING** label.
2. Include migration instructions in the CHANGELOG entry.
3. If the config format changed, the plugin's first-run logic should detect the old format and print a clear message explaining what to change.

Example CHANGELOG entry for a breaking change:

```markdown
### 2.0.0 (2026-04-01)

- **BREAKING**: Renamed config key `backlog_file` to `backlog_path` in
  project-tracker.config.md. Update your config file frontmatter accordingly.
- **BREAKING**: `/plan-backlog` now requires `status_file` to be set
  (previously defaulted to `docs/STATUS.md` silently).
```

### Config migration between versions

Plugins should handle old configs gracefully:

- If a deprecated config key is present, use it but print a warning suggesting the new key.
- If a required new config key is missing, fall back to the previous default and print a notice.
- Never silently break. Always tell the user what changed and what to do.

The skill or hook markdown can include a migration note section that the agent reads and follows:

```markdown
## Config Migration (v1 to v2)

If the user's config file uses `backlog_file` instead of `backlog_path`:

1. Read the value from `backlog_file`
2. Use it as `backlog_path`
3. Tell the user: "Your config uses the deprecated key `backlog_file`.
   Rename it to `backlog_path` to avoid this warning."
```

---

## 7. Iteration Pattern

This is the core feedback loop for improving the plugins over time.

```
1. USE the plugin in a consumer project (e.g., Daykeep)
   - Run /idea, /work, /llmstxt-update in normal development

2. NOTICE something that could be improved
   - A skill misses an edge case
   - A hook fires when it should not
   - A config option is missing
   - Output formatting is unclear

3. DETERMINE: is this project-specific or generic?
   - Project-specific: fix it in the consumer project's config or CLAUDE.md
   - Generic: this applies to any project using the plugin

4. PORT the improvement to the plugin repo
   - Switch to the x4-agent-plugins/ repo
   - Edit the relevant skill/hook/command file
   - Update the config defaults if adding a new option
   - Add a test fixture case if the edge case is tricky

5. TEST locally
   - Link the updated plugin in the consumer project
   - Verify the improvement works
   - Run through the validation checklist for that plugin

6. BUMP version and update CHANGELOG
   - Patch for bug fixes, minor for new features
   - Write a clear changelog entry

7. PUBLISH
   - claude plugin publish ./plugins/<name>

8. UPDATE in consumer project
   - claude plugin unlink <name>    (remove the dev link)
   - claude plugin update <name>    (pull the published version)
   - Verify it still works
```

### Real example

```
Problem noticed in Daykeep:
  /idea adds items to BACKLOG.md but does not deduplicate --
  the same idea gets captured twice if you run /idea in two sessions.

Analysis:
  This is generic. Any project would benefit from dedup.

Fix in plugin repo:
  Edit plugins/project-tracker/skills/idea/SKILL.md
  Add a step: "Before appending, scan existing BACKLOG.md entries.
  If a substantially similar item exists, ask the user whether to
  merge or add as separate."

Test:
  Link plugin in Daykeep, run /idea with a duplicate idea, confirm
  it detects the duplicate and prompts.

Version:
  Bump x4-project-tracker from 1.0.0 to 1.1.0 (new behavior, backward-compatible).

Publish and update.
```

---

## 8. CI/Testing for the Plugin Repo Itself

### Validation script

`tests/validate.sh` runs structural and content checks:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
ERRORS=0

# 0. Validate root marketplace.json exists
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MARKETPLACE" ]; then
  echo "FAIL: Root .claude-plugin/marketplace.json missing"
  ERRORS=$((ERRORS + 1))
else
  echo "OK: .claude-plugin/marketplace.json exists"
fi

# 1. Validate .claude-plugin/plugin.json manifests, LICENSE, and README.md
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir/.claude-plugin/plugin.json"

  # Check manifest exists at .claude-plugin/plugin.json (not root plugin.json)
  if [ ! -f "$manifest" ]; then
    echo "FAIL: $plugin_name missing .claude-plugin/plugin.json"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check required fields
  for field in name version description; do
    if ! grep -q "\"$field\"" "$manifest"; then
      echo "FAIL: $plugin_name/.claude-plugin/plugin.json missing '$field' field"
      ERRORS=$((ERRORS + 1))
    fi
  done

  echo "OK: $plugin_name/.claude-plugin/plugin.json is valid"

  # Check LICENSE file exists
  if [ ! -f "$plugin_dir/LICENSE" ]; then
    echo "FAIL: $plugin_name missing LICENSE file"
    ERRORS=$((ERRORS + 1))
  else
    echo "OK: $plugin_name/LICENSE exists"
  fi

  # Check README.md exists
  if [ ! -f "$plugin_dir/README.md" ]; then
    echo "FAIL: $plugin_name missing README.md"
    ERRORS=$((ERRORS + 1))
  else
    echo "OK: $plugin_name/README.md exists"
  fi
done

# 2. Validate all referenced skill files exist
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")

  if [ -d "$plugin_dir/skills" ]; then
    for skill_dir in "$plugin_dir/skills"/*/; do
      skill_file="$skill_dir/SKILL.md"
      if [ ! -f "$skill_file" ]; then
        echo "FAIL: $plugin_name skill $(basename "$skill_dir") missing SKILL.md"
        ERRORS=$((ERRORS + 1))
      else
        echo "OK: $plugin_name/skills/$(basename "$skill_dir")/SKILL.md exists"
      fi
    done
  fi

  if [ -d "$plugin_dir/commands" ]; then
    for cmd_file in "$plugin_dir/commands"/*.md; do
      if [ ! -f "$cmd_file" ]; then
        echo "FAIL: $plugin_name command file missing: $cmd_file"
        ERRORS=$((ERRORS + 1))
      else
        echo "OK: $plugin_name/commands/$(basename "$cmd_file") exists"
      fi
    done
  fi

  if [ -d "$plugin_dir/hooks" ]; then
    for hook_file in "$plugin_dir/hooks"/*.md; do
      if [ ! -f "$hook_file" ]; then
        echo "FAIL: $plugin_name hook file missing: $hook_file"
        ERRORS=$((ERRORS + 1))
      else
        echo "OK: $plugin_name/hooks/$(basename "$hook_file") exists"
      fi
    done
  fi
done

# 3. Validate no plugin references files outside its own directory
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")
  if grep -r '\.\./\.\.' "$plugin_dir" --include="*.md" 2>/dev/null; then
    echo "WARN: $plugin_name contains parent directory traversals -- review manually"
  fi
done

# 4. Report
echo ""
if [ $ERRORS -gt 0 ]; then
  echo "FAILED: $ERRORS error(s) found"
  exit 1
else
  echo "PASSED: All plugins valid"
  exit 0
fi
```

### GitHub Actions CI

```yaml
# .github/workflows/validate.yml
name: Validate Plugins
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate plugin structure
        run: bash tests/validate.sh

      - name: Check plugin.json and marketplace.json are valid JSON
        run: |
          python3 -m json.tool .claude-plugin/marketplace.json > /dev/null || {
            echo "Invalid JSON: .claude-plugin/marketplace.json"
            exit 1
          }
          for f in plugins/*/.claude-plugin/plugin.json; do
            python3 -m json.tool "$f" > /dev/null || {
              echo "Invalid JSON: $f"
              exit 1
            }
          done

      - name: Check CHANGELOG updated (on PR only)
        if: github.event_name == 'pull_request'
        run: |
          if git diff --name-only origin/main...HEAD | grep -q '^plugins/'; then
            if ! git diff --name-only origin/main...HEAD | grep -q 'CHANGELOG.md'; then
              echo "WARNING: Plugin files changed but CHANGELOG.md not updated"
            fi
          fi
```

### Running locally

```bash
# From the plugin repo root
bash tests/validate.sh
```

### Testing against fixtures

To test a plugin against the test fixtures without linking into a real project:

```bash
# Start Claude Code in the fixture directory with the plugin loaded
cd tests/fixtures/daykeep
claude --plugin-dir ../../../plugins/project-tracker
# Then invoke /idea, /plan-backlog, etc. and verify output
```

This is useful for quick smoke tests. Full validation still requires testing against a real project like Daykeep.

---

## 9. Creating New Plugins

### When to extract a new plugin vs. adding to existing

**Add to an existing plugin when:**

- The new skill/command/hook is closely related to the plugin's purpose
- It shares config with existing features
- Users would expect it to be part of the same plugin

**Create a new plugin when:**

- The functionality serves a different concern entirely
- It has no dependency on existing plugins
- It would be useful to projects that have no need for the existing plugins
- The existing plugin is already large and a new addition would dilute its focus

### Plugin creation checklist

```
[ ] Define the plugin's single responsibility (one sentence)
[ ] List all skills, commands, and hooks it will include
[ ] Decide on config keys and defaults
[ ] Create the directory structure under plugins/<name>/
[ ] Write .claude-plugin/plugin.json with name, version (start at 0.1.0), description
[ ] Add LICENSE file (Apache 2.0 -- copy from another plugin)
[ ] Add README.md describing the plugin, its skills, and configuration
[ ] Write each skill's SKILL.md
[ ] Write each command's .md file
[ ] Write each hook's .md file
[ ] Add the plugin entry to root .claude-plugin/marketplace.json
[ ] Add a test fixture entry (or confirm existing fixtures cover it)
[ ] Add the plugin to tests/validate.sh (it auto-discovers, so usually no change)
[ ] Add a section to CHANGELOG.md
[ ] Update the repo README.md with the new plugin
[ ] Test locally via plugin link in at least one real project
[ ] Run full validation checklist
[ ] Publish at 0.1.0 (pre-release) or 1.0.0 (stable)
```

### Directory scaffold

When creating a new plugin, start with this minimal structure:

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── <first-skill>/SKILL.md
├── commands/
│   └── <first-command>.md    (optional)
├── hooks/
│   └── <first-hook>.md       (optional)
├── LICENSE                    # Apache 2.0
└── README.md
```

### Minimal .claude-plugin/plugin.json

```json
{
  "name": "<name>",
  "version": "0.1.0",
  "description": "<One-line description of what this plugin does>",
  "skills": [
    {
      "name": "<first-skill>",
      "path": "skills/<first-skill>/SKILL.md",
      "description": "<What the skill does>"
    }
  ],
  "commands": [],
  "hooks": []
}
```

Also add the plugin entry to the root `.claude-plugin/marketplace.json` so it is discoverable.

### Using /create-plugin from plugin-dev

If you are developing inside the plugin repo with Claude Code and have the plugin-dev tooling set up in `.claude/CLAUDE.md`, you can run:

```
/create-plugin <name> "<description>"
```

This scaffolds the directory structure, writes a starter `plugin.json`, and creates placeholder files for one skill and one command. You then fill in the actual content.

---

## Quick Reference

| Task                          | Command                                                             |
| ----------------------------- | ------------------------------------------------------------------- |
| Link plugin for local dev     | `claude plugin link ./plugins/<name>`                               |
| Unlink plugin                 | `claude plugin unlink <name>`                                       |
| Test without linking          | `claude --plugin-dir ./plugins/<name>`                              |
| List installed/linked plugins | `claude plugin list`                                                |
| Publish a plugin              | `claude plugin publish ./plugins/<name>`                            |
| Install from registry         | `claude plugin install studiox4/x4-agent-plugins/<name>` |
| Update a plugin               | `claude plugin update <name>`                                       |
| Update all plugins            | `claude plugin update`                                              |
| Validate all plugins locally  | `bash tests/validate.sh`                                            |
