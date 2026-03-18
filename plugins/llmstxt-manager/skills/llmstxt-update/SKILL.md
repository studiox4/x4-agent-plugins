---
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

## Script Mode vs Standalone Mode

This skill operates in two modes:

**Script mode** (preferred): If the download script exists at the configured
`script` path (default: `scripts/download-ai-docs.py`), run it with `--json`
and use the structured output. This is faster and uses the known-sources cache.

**Standalone mode**: If no script exists, perform all discovery inline using
the steps below. Suggest running `/llmstxt-init` to set up the script for
faster future runs.

### Script Mode Workflow

1. Run `python3 {script_path} --json`
2. Parse the JSON output (contains: ecosystems, results with new/updated/unchanged/failed/orphaned)
3. Delete orphaned files from the docs directory (confirm with user first)
4. Jump to Step 4 (Update CLAUDE.md) using the script's results

### Standalone Mode Workflow

## Workflow

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
   - Not contain `<html` or `<!DOCTYPE` (catch HTML served as text)

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
