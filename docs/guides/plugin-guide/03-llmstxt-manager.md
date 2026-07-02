# 03 — x4-llmstxt-manager Plugin

A Claude Code plugin that scans your project dependencies, discovers llms.txt documentation endpoints, downloads them locally, and keeps your CLAUDE.md reference table in sync. Works with any ecosystem: JavaScript/Bun, Python, Rust, Go, and Ruby.

---

## 1. Overview

Modern libraries increasingly publish machine-readable documentation at `llms.txt` or `llms-full.txt` endpoints. This plugin automates the entire lifecycle:

1. **Scan** — Reads dependency manifests (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`) and builds a deduplicated dependency list.
2. **Discover** — For each dependency, probes the library's website and known directories for llms.txt files.
3. **Download** — Fetches discovered docs into a local directory (default: `docs/llms-txt/`).
4. **Sync** — Updates the reference docs table in `CLAUDE.md` and any agent files that reference the docs.
5. **Report** — Prints a summary of new, updated, unchanged, failed, and removed docs.

Three commands are provided:

| Command           | Purpose                                                |
| ----------------- | ------------------------------------------------------ |
| `/llmstxt-init`   | Scaffold Python download script, known-sources cache, docs dir, and config |
| `/llmstxt-update` | Full scan, discover, download, and sync (script mode or standalone mode) |
| `/llmstxt-status` | Read-only report of what is current, stale, or missing |

---

## 2. Plugin Manifest

<!-- prettier-ignore -->
> **File:** `llmstxt-manager/.claude-plugin/plugin.json`

```json
{
  "name": "x4-llmstxt-manager",
  "description": "Scan project dependencies, discover llms.txt documentation files, download and manage AI-readable reference docs",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

The official plugin manifest is minimal. Commands and skills are discovered automatically from the `commands/` and `skills/` directories — they do not need to be listed in `plugin.json`.

---

## 3. Directory Structure

```
llmstxt-manager/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── llmstxt-init.md
│   ├── llmstxt-update.md
│   └── llmstxt-status.md
├── skills/
│   └── llmstxt-update/
│       └── SKILL.md
├── templates/
│   └── download-ai-docs.py
├── LICENSE
└── README.md
```

---

## 4. Skill: `llmstxt-update`

> **File:** `llmstxt-manager/skills/llmstxt-update/SKILL.md`

The complete SKILL.md content is provided in [Section 8](#8-complete-file-contents). Below is a summary of the workflow it defines.

### Configuration Discovery

Before starting, check for a `.llmstxt.json` config file in the project root. If it does not exist, use these defaults:

- **docs_dir**: `docs/llms-txt/`
- **skip**: `[]` (empty — skip nothing extra)
- **claude_md**: `CLAUDE.md` (path to CLAUDE.md, relative to project root)
- **agent_dir**: `.claude/agents/` (path to agent files)

### Step 1 — Scan Dependencies

Detect the project ecosystem(s) by searching for manifest files. A project may use multiple ecosystems (e.g., a JS frontend with a Python backend).

**JavaScript / Bun / Node:**

- Find all `package.json` files (excluding `node_modules/`)
- Extract `dependencies` and `devDependencies` from each
- Deduplicate across all workspaces

**Python:**

- Find `requirements.txt`, `requirements/*.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`
- Extract package names from pip requirements or pyproject `[project.dependencies]`

**Rust:**

- Find all `Cargo.toml` files
- Extract `[dependencies]`, `[dev-dependencies]`, and `[build-dependencies]`

**Go:**

- Find `go.mod` files
- Extract `require` block entries

**Ruby:**

- Find `Gemfile` files
- Extract `gem` declarations

Produce a deduplicated list. Categorize each dependency:

- **Framework** — e.g., next, django, rails, actix-web, gin
- **Library** — e.g., zod, pydantic, serde, gorilla/mux
- **Tool** — e.g., eslint, pytest, clippy
- **Skip** — type stubs (`@types/*`), tiny polyfills, internal packages, anything in the `skip` config list

Report the total count and breakdown to the user.

### Step 2 — Discover llms.txt Files

For each non-skipped dependency:

1. **Registry lookup** — Get the package homepage/repository URL:
   - npm: `https://registry.npmjs.org/{package}` — read `homepage` or `repository.url`
   - PyPI: `https://pypi.org/pypi/{package}/json` — read `info.home_page` or `info.project_urls.Homepage`
   - crates.io: `https://crates.io/api/v1/crates/{package}` — read `crate.homepage` or `crate.repository`
   - Go: use the module path directly (e.g., `https://pkg.go.dev/{module}`)
   - RubyGems: `https://rubygems.org/api/v1/gems/{gem}.json` — read `homepage_uri`

2. **Probe URL patterns** — Given a base URL (e.g., `https://example.com`), try:
   - `{base}/llms-full.txt`
   - `{base}/llms.txt`
   - `{base}/docs/llms-full.txt`
   - `{base}/docs/llms.txt`
   - For GitHub repos: raw content URL patterns for `llms.txt` in the repo root

3. **Directory cross-reference** — Check known aggregator sites:
   - `https://llmstxt.site/{package}`
   - `https://llmstxthub.com/{package}`

4. **Validate** — A valid response must:
   - Return HTTP 200
   - Have a text content-type (not HTML, not a 404 page)
   - Be longer than 100 characters (reject placeholder files)
   - Not contain `<html` or `<!DOCTYPE` (catch HTML served as text)

5. **Check existing** — If the doc already exists locally, compare content. Mark as `unchanged` if identical.

Prefer `llms-full.txt` over `llms.txt` when both exist (more complete).

### Step 3 — Download to Docs Directory

For each discovered doc:

1. Create the docs directory if it does not exist
2. Save as `{docs_dir}/{package-name}.txt` (normalize names: `@scope/pkg` becomes `scope-pkg`)
3. Track status: `new`, `updated`, `unchanged`, `failed`
4. For any existing local docs whose package is no longer in dependencies, mark as `removed` (do NOT auto-delete — report to user)

### Step 4 — Update CLAUDE.md Reference Table

If the project has a `CLAUDE.md` file (at the configured path):

1. Find the reference docs table (look for a markdown table under a heading containing "Reference Docs" or "llms.txt")
2. Rebuild the table with current docs using columns: File, Library, Use when...
3. For new entries, generate a short "Use when..." hint based on the library category:
   - Framework: "Building routes, pages, middleware"
   - ORM/DB: "Schema, queries, migrations"
   - Validation: "Schema validation, parsing"
   - Testing: "Writing and running tests"
   - Generic: "Using {library} APIs and configuration"
4. Preserve existing "Use when..." descriptions for unchanged entries
5. If no reference docs table exists, append one at the end of CLAUDE.md

### Step 5 — Update Agent Files

If the project has agent files (at the configured `agent_dir`):

1. Scan each `.md` file in the agent directory
2. Look for sections referencing docs (headings like "Reference Docs", "Available Docs", or file paths matching the docs directory)
3. Update file path references to match current docs
4. Do not rewrite agent files that have no reference doc section

### Step 6 — Report Summary

Print a structured summary showing: ecosystems detected, dependency counts, a status table (new/updated/unchanged/failed/removed), files written and modified, and orphaned docs still on disk.

---

## 5. Commands

### `/llmstxt-init`

> **File:** `llmstxt-manager/commands/llmstxt-init.md`

One-time scaffolding command that sets up the llms.txt management infrastructure for a project:

1. Creates the docs directory (default: `docs/llms-txt/`)
2. Creates `.llmstxt.json` config file with project-appropriate defaults
3. Copies `templates/download-ai-docs.py` to the configured script path (e.g., `scripts/download-ai-docs.py`)
4. Creates a known-sources cache file (`docs/llms-txt/.known-sources.json`) for tracking discovered URLs
5. Commits all scaffolded files

After running `/llmstxt-init`, use `/llmstxt-update` to perform the first scan and download.

### `/llmstxt-update`

> **File:** `llmstxt-manager/commands/llmstxt-update.md`

Full scan, discover, download, and sync. Executes all six steps from the skill workflow. See [Section 8](#8-complete-file-contents) for the complete file content.

### `/llmstxt-status`

> **File:** `llmstxt-manager/commands/llmstxt-status.md`

Read-only check. Does NOT download or modify any files. Classifies each dependency as Current, Missing, Orphaned, or Stale (>30 days since last download). Also checks whether the CLAUDE.md reference table is in sync. See [Section 8](#8-complete-file-contents) for the complete file content.

---

## 6. Configuration

### `.llmstxt.json` (optional, custom)

This is a custom configuration file, not part of the Claude Code plugin spec. The plugin auto-discovers dependencies from `package.json` and other manifest files with zero config. The `.llmstxt.json` file in the project root is only needed to override defaults.

| Field       | Type       | Default             | Description                                                                                       |
| ----------- | ---------- | ------------------- | ------------------------------------------------------------------------------------------------- |
| `docs_dir`       | `string`   | `"docs/llms-txt/"`  | Directory to store downloaded docs, relative to project root                                      |
| `skip`           | `string[]` | `[]`                | Glob patterns or exact package names to skip. `@types/*` and common polyfills are always skipped. |
| `claude_md`      | `string`   | `"CLAUDE.md"`       | Path to CLAUDE.md file, relative to project root                                                  |
| `agent_dir`      | `string`   | `".claude/agents/"` | Directory containing agent `.md` files                                                            |
| `extra_packages` | `string[]` | `[]`                | Additional package names to scan for llms.txt docs, beyond what is found in manifests             |
| `script`         | `string`   | `""`                | Path to a Python download script (e.g., `scripts/download-ai-docs.py`). When set, `/llmstxt-update` runs in script mode, delegating downloads to this script instead of probing URLs directly. |

### Auto-skipped Packages

These are always skipped regardless of config:

**JavaScript/Bun:**

- `@types/*` (TypeScript type stubs)
- `typescript`, `eslint-*` configs (tooling meta-packages)
- Single-function polyfills under 1KB on npm

**Python:**

- `pip`, `setuptools`, `wheel` (packaging tools)
- Type stub packages (`*-stubs`, `types-*`)

**Rust:**

- `proc-macro2`, `syn`, `quote` (macro infrastructure)

**Go:**

- `golang.org/x/*` is NOT skipped (these often have docs)

**Ruby:**

- `bundler`, `rake` (core tooling)

### Filename Normalization

Downloaded files are named by normalizing the package name:

- `@scope/package` becomes `scope-package.txt`
- `package-name` stays `package-name.txt`
- Python: `django-rest-framework` stays as-is
- Rust: `tokio` stays `tokio.txt`
- Go: `github.com/gin-gonic/gin` becomes `gin.txt` (last path segment)

---

## 7. Ecosystem Adapters

The plugin detects project ecosystems by the presence of manifest files. Multiple ecosystems can coexist (e.g., a Next.js frontend with a Python ML service).

### JavaScript / Bun / Node

**Manifests:** `**/package.json` (excluding `node_modules/`)

**Registry:** npm (`https://registry.npmjs.org/{package}`)

**Discovery strategy:**

1. Read `homepage` field from npm registry response
2. Fall back to `repository.url` (convert GitHub URLs to raw homepage)
3. Probe standard llms.txt paths on the resolved homepage
4. Many JS frameworks publish at their docs site (e.g., `https://nextjs.org/llms-full.txt`)

### Python

**Manifests:** `requirements.txt`, `requirements/*.txt`, `pyproject.toml` (`[project.dependencies]` and `[project.optional-dependencies]`), `setup.py`, `setup.cfg`

**Registry:** PyPI (`https://pypi.org/pypi/{package}/json`)

**Discovery strategy:**

1. Read `info.home_page` or `info.project_urls.Homepage` or `info.project_urls.Documentation`
2. Documentation URL is often more useful than homepage for Python packages
3. Read the Docs sites: try `https://{package}.readthedocs.io/llms.txt`

### Rust

**Manifests:** `**/Cargo.toml`

**Registry:** crates.io (`https://crates.io/api/v1/crates/{crate}`)

**Discovery strategy:**

1. Read `crate.homepage` or `crate.repository` or `crate.documentation`
2. docs.rs: try `https://docs.rs/{crate}/latest/llms.txt` (not commonly available yet)
3. If homepage is a GitHub repo, check repo root for `llms.txt`

### Go

**Manifests:** `**/go.mod`

**Registry:** pkg.go.dev (scrape or use module path directly)

**Discovery strategy:**

1. Module paths are URLs by convention (e.g., `github.com/gin-gonic/gin`)
2. Resolve to the actual homepage (GitHub, project site)
3. Probe standard llms.txt paths

### Ruby

**Manifests:** `**/Gemfile`

**Registry:** RubyGems (`https://rubygems.org/api/v1/gems/{gem}.json`)

**Discovery strategy:**

1. Read `homepage_uri` or `source_code_uri` or `documentation_uri`
2. Probe standard llms.txt paths on resolved URLs

---

## 8. Complete File Contents

Every file needed for the plugin, ready to copy into the `llmstxt-manager/` directory.

---

### `.claude-plugin/plugin.json`

```json
{
  "name": "x4-llmstxt-manager",
  "description": "Scan project dependencies, discover llms.txt documentation files, download and manage AI-readable reference docs",
  "author": {
    "name": "Corban Baxter",
    "email": "corban@example.com"
  }
}
```

---

### `skills/llmstxt-update/SKILL.md`

<pre><code>---
name: llmstxt-update
description: >
  Scan project dependencies across all supported ecosystems, discover llms.txt
  documentation endpoints, download to a local directory, and update CLAUDE.md
  and agent file references. Use when dependencies change, new libraries are
  added, or reference docs need refreshing.
disable-model-invocation: true
---

# /llmstxt-update — Refresh LLMs.txt Reference Docs

Scan project dependencies, discover llms.txt files, download them, and update
all references. Works with any project ecosystem.

## Configuration Discovery

Before starting, check for a `.llmstxt.json` config file in the project root.
If it does not exist, use these defaults:

| Setting     | Default           |
| ----------- | ----------------- |
| `docs_dir`  | `docs/llms-txt/`  |
| `skip`      | `[]`              |
| `claude_md` | `CLAUDE.md`       |
| `agent_dir` | `.claude/agents/` |

If `.llmstxt.json` exists, read it and merge with defaults.

## Workflow

### Mode Selection

Before scanning, check if a `script` path is configured in `.llmstxt.json`:

- **Script mode** (when `script` is set): Delegate the download phase to the configured Python script (e.g., `templates/download-ai-docs.py`). The script handles URL probing, downloading, and known-sources caching. The skill still handles Steps 4-6 (CLAUDE.md sync, agent file updates, reporting).
- **Standalone mode** (when `script` is not set): The skill handles the entire workflow end-to-end, including URL probing and downloading.

### Step 1 — Scan Dependencies

Detect the project ecosystem(s) by searching for manifest files. A project may
use multiple ecosystems simultaneously.

**Search for these manifests (excluding vendor/dependency directories):**

| Ecosystem  | Manifests                                                  |
| ---------- | ---------------------------------------------------------- |
| JavaScript | `**/package.json` (skip `node_modules/`)                   |
| Python     | `requirements.txt`, `requirements/*.txt`, `pyproject.toml` |
| Rust       | `**/Cargo.toml`                                            |
| Go         | `**/go.mod`                                                |
| Ruby       | `**/Gemfile`                                               |

For each manifest found, extract dependency names. Deduplicate across all files.

**Always skip these regardless of config:**

- JavaScript: `@types/*`, single-function polyfills
- Python: `pip`, `setuptools`, `wheel`, `*-stubs`, `types-*`
- Rust: `proc-macro2`, `syn`, `quote`
- Ruby: `bundler`, `rake`

Also skip anything matching patterns in the config `skip` array.

Categorize remaining deps as Framework, Library, or Tool. Report counts.

### Step 2 — Discover llms.txt Files

For each non-skipped dependency:

1. **Registry lookup** — Get the package homepage/repository URL from the
   appropriate registry:
   - npm registry for JS packages
   - PyPI JSON API for Python packages
   - crates.io API for Rust crates
   - Module path resolution for Go modules
   - RubyGems API for Ruby gems

2. **Probe URL patterns** — Given a base URL, try in order:
   - `{base}/llms-full.txt` (preferred — more complete)
   - `{base}/llms.txt`
   - `{base}/docs/llms-full.txt`
   - `{base}/docs/llms.txt`
   - For GitHub repos: check raw content in repo root

3. **Directory cross-reference** — Check known aggregators:
   - `https://llmstxt.site/{package}`
   - `https://llmstxthub.com/{package}`

4. **Validate responses** — A valid response must:
   - Return HTTP 200
   - Have text content-type (not HTML, not a redirect to a 404 page)
   - Be longer than 100 characters (reject stubs/placeholders)
   - Not contain `&lt;html` or `&lt;!DOCTYPE` (catch HTML served as text)

5. **Compare with existing** — If the file already exists locally and content
   is identical, mark as `unchanged`.

Prefer `llms-full.txt` over `llms.txt` when both are found.

### Step 3 — Download to Docs Directory

For each discovered doc:

1. Create the docs directory if it does not exist
2. Normalize the filename:
   - `@scope/pkg` becomes `scope-pkg.txt`
   - `github.com/org/repo` becomes `repo.txt` (last path segment)
   - All others: `{name}.txt`
3. Save the file
4. Track status: `new`, `updated`, `unchanged`, `failed`
5. For existing local docs whose package is no longer in dependencies, mark as
   `removed` but do NOT delete — report to user for manual cleanup

### Step 4 — Update CLAUDE.md Reference Table

If the configured CLAUDE.md file exists:

1. Find the reference docs table — search for a markdown table under a heading
   that contains "Reference Docs" or "llms.txt" (case-insensitive)
2. Rebuild the table rows from current docs:
   | File | Library | Use when... |
   |------|---------|-------------|
3. Preserve existing "Use when..." descriptions for entries that have not changed
4. Generate hints for new entries based on category:
   - Framework: "Building routes, pages, middleware, configuration"
   - ORM/Database: "Schema, queries, migrations, relations"
   - Validation: "Schema validation, parsing, transforms"
   - HTTP/API: "API routes, requests, middleware"
   - Testing: "Writing and running tests"
   - Generic fallback: "Using {library} APIs and configuration"
5. If no reference docs section exists, append one before the end of the file

### Step 5 — Update Agent Files

If the configured agent directory exists:

1. Scan each `.md` file in the directory
2. Look for sections that reference the docs directory path (e.g., lines
   containing `docs/llms-txt/` or a "Reference Docs" heading)
3. Update file paths to match current docs
4. Do not modify agent files that have no reference doc section
5. Do not modify files outside the agent directory

### Step 6 — Report Summary

Print a structured summary:

    ## llmstxt-update Summary

    Ecosystems detected: JavaScript (3 package.json), Python (1 requirements.txt)
    Scanned: 52 dependencies (14 skipped)

    | Status    | Count | Packages                      |
    |-----------|-------|-------------------------------|
    | New       | 3     | hono, drizzle, tanstack-query |
    | Updated   | 1     | next                          |
    | Unchanged | 8     | zod, react, tailwindcss, ...  |
    | Failed    | 26    | express (no endpoint), ...    |
    | Removed   | 1     | old-lib (still on disk)       |

    Files written:
    - docs/llms-txt/hono.txt (new, 48KB)
    - docs/llms-txt/next.txt (updated, 125KB)

    Files modified:
    - CLAUDE.md (reference table: 3 rows added, 1 removed)
    - .claude/agents/backend.md (doc paths updated)

    Orphaned docs (delete manually if unneeded):
    - docs/llms-txt/old-lib.txt
</code></pre>

---

### `commands/llmstxt-update.md`

<pre><code>---
description: Scan dependencies and refresh llms.txt reference docs
allowed-tools: [Read, Write, Glob, Grep, WebFetch, Bash]
---

# /llmstxt-update

Run the full llms.txt refresh workflow:

1. Read `.llmstxt.json` config from the project root if it exists. If not, use
   defaults: docs in `docs/llms-txt/`, CLAUDE.md at project root, agents in
   `.claude/agents/`, no extra skip patterns.

2. Scan all dependency manifests in the project. Supported ecosystems detected
   automatically by manifest presence:
   - **JavaScript/Bun/Node:** `**/package.json` (skip `node_modules/`)
   - **Python:** `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`
   - **Rust:** `**/Cargo.toml`
   - **Go:** `**/go.mod`
   - **Ruby:** `**/Gemfile`

3. Deduplicate and categorize all dependencies. Always skip type stubs
   (`@types/*`, `types-*`, `*-stubs`), packaging tools (`pip`, `setuptools`,
   `bundler`, `rake`), and macro infrastructure (`proc-macro2`, `syn`,
   `quote`). Also skip anything matching patterns in the config `skip` array.

4. For each significant dependency, discover llms.txt endpoints:
   - Query the appropriate package registry for homepage/repository URL
   - Probe `{url}/llms-full.txt`, `{url}/llms.txt`, `{url}/docs/llms-full.txt`,
     `{url}/docs/llms.txt`
   - For GitHub repos, check raw content in the repo root
   - Cross-reference `llmstxt.site` and `llmstxthub.com`
   - Validate: HTTP 200, text content-type, >100 chars, no HTML
   - Prefer `llms-full.txt` over `llms.txt` when both exist

5. Download discovered docs to the configured docs directory. Normalize
   filenames (`@scope/pkg` becomes `scope-pkg.txt`). Track new, updated,
   unchanged, and failed.

6. Flag existing local docs whose packages are no longer in dependencies as
   orphaned. Do not auto-delete them.

7. If CLAUDE.md exists: find or create a reference docs table and rebuild it
   with current docs. Preserve existing "Use when..." descriptions.

8. If agent files exist in the agent directory: update any doc path references
   to match current files.

9. Print a summary table with counts, file-level changes, and orphan warnings.

## Configuration

Optional `.llmstxt.json` in project root:

    {
      "docs_dir": "docs/llms-txt/",
      "skip": ["@myorg/internal-*", "some-private-lib"],
      "claude_md": "CLAUDE.md",
      "agent_dir": ".claude/agents/"
    }

All fields are optional. Defaults apply for any omitted field.
</code></pre>

---

### `commands/llmstxt-status.md`

<pre><code>---
description: Show the current state of llms.txt docs — what is current, stale, or missing
allowed-tools: [Read, Glob, Grep, Bash]
---

# /llmstxt-status

Read-only check of llms.txt documentation status. This command does NOT
download, modify, or delete any files.

1. Read `.llmstxt.json` config from the project root if it exists. If not, use
   defaults.

2. Scan all dependency manifests using the same ecosystem detection as
   `/llmstxt-update`:
   - JavaScript/Bun/Node, Python, Rust, Go, Ruby

3. Deduplicate and categorize. Apply the same skip rules (type stubs, packaging
   tools, config skip list).

4. List all `.txt` files currently in the configured docs directory.

5. For each dependency, classify:
   - **Current** — a matching doc file exists locally and the package is in
     dependencies
   - **Missing** — the package is in dependencies but no local doc exists (the
     library may or may not publish an llms.txt endpoint)
   - **Orphaned** — a local doc file exists but the package is no longer in any
     dependency manifest
   - **Stale** — a doc exists but was last modified more than 30 days ago and
     may benefit from a refresh

6. Check CLAUDE.md reference table sync:
   - Are all local docs listed in the table?
   - Are there table entries pointing to docs that no longer exist?

7. Print a status report:

    ## llmstxt-status Report

    Ecosystems detected: JavaScript (3 package.json files), Python (1 pyproject.toml)
    Total dependencies: 52 (14 skipped)
    Docs directory: docs/llms-txt/ (11 files)

    | Status   | Count | Details                              |
    |----------|-------|--------------------------------------|
    | Current  | 8     | zod, react, next, hono, drizzle, ... |
    | Missing  | 30    | express, lodash, chalk, ...          |
    | Orphaned | 1     | old-lib.txt                          |
    | Stale    | 2     | drizzle (45d ago), trpc (32d ago)    |

    CLAUDE.md sync: 1 doc not in table (hono), 0 stale table entries

    Run /llmstxt-update to discover and download missing docs.

This command is useful for:
- Quick health check after adding or removing dependencies
- Identifying which docs might need refreshing after upgrades
- Finding orphaned docs from removed dependencies
- Verifying CLAUDE.md table is in sync with actual docs
</code></pre>
