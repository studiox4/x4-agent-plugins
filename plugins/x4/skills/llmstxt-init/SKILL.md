---
name: llmstxt-init
description: Scaffold the llms.txt download script, known-sources cache, and docs directory into a project
version: 2.0.0
license: MIT
---

# /llmstxt-init — Set Up LLMs.txt Reference Docs System

One-time setup that scaffolds a download script, known-sources cache, docs
directory, and config file into the project. After setup, `/llmstxt-update`
uses the script for fast, cached dependency scanning.

## Process

### Step 1: Detect project setup

1. Check for existing setup:
   - Does `docs/llms-txt/` (or configured `docs_dir`) already exist?
   - Does `scripts/download-ai-docs.ts` already exist?
   - Does `.llmstxt.json` config exist?
   - Does `known-sources.json` exist in the docs dir?

2. Detect the project ecosystem:
   - Check for `package.json` → JavaScript/Node ecosystem
   - Check for `pyproject.toml`, `requirements.txt` → Python ecosystem
   - Check for `Cargo.toml` → Rust ecosystem
   - Check for `go.mod` → Go ecosystem
   - Check for `Gemfile` → Ruby ecosystem

3. Verify Python 3.8+ is available (`python3 --version`). The download script
   uses only stdlib — no pip install needed.

4. If any files already exist, ask the user before overwriting.

### Step 2: Detect extra packages

Scan the project for tools that aren't npm dependencies but have useful
llms.txt docs. Auto-detect based on:

- Config files: `vercel.json` → Vercel, `railway.toml` → Railway
- Database config: Neon, Supabase, PlanetScale references in env files or config
- Framework detection: Next.js, Expo, etc. from package.json
- Runtime: Bun (from lockfile), Deno (from `deno.json`)

Ask the user to confirm detected extras and add any others:

```
## Extra Packages

These tools aren't npm dependencies but have llms.txt docs:

Detected:
  1. bun (bun.lockb found)
  2. vercel (vercel.json found)
  3. @neondatabase/serverless (Neon references found)

Add more? (comma-separated names, or press Enter to continue)
```

### Step 3: Configure skip patterns

Present default skip patterns and let the user customize:

```
## Skip Patterns

These packages will be skipped (no useful llms.txt):

  - @types/* (type definitions)
  - eslint* (linting tools)
  - @tailwindcss/* (CSS engine internals)
  - @storybook/* (build tooling)
  - prettier (formatter)

Add custom skip patterns? (comma-separated, or press Enter to continue)
```

### Step 4: Write the download script

Copy the download script template from the plugin's `templates/download-ai-docs.py`
to `scripts/download-ai-docs.py` in the project.

Customize the template with:
- `EXTRA_PACKAGES` array from Step 2 detections
- `SKIP_PATTERNS` array from Step 3 (append user patterns to defaults)
- `DOCS_DIR` path from config

The script is pure Python 3 stdlib (urllib, json, pathlib) — no pip install needed.
It works on any machine with Python 3.8+.

The script:
1. Scans all dependency manifests across the project (package.json, requirements.txt,
   Cargo.toml, go.mod, Gemfile)
2. Deduplicates and filters dependencies against skip patterns
3. Discovers llms.txt URLs using a 5-step pipeline:
   - Check local cache (`known-sources.json`) for previously working URLs
   - Look up package homepage on npm/PyPI/crates.io registry
   - Probe URL patterns: `{homepage}/llms-full.txt`, `{homepage}/llms.txt`,
     `{homepage}/docs/llms-full.txt`, `{homepage}/docs/llms.txt`
   - Try GitHub raw content URLs for repo-hosted docs
   - Cross-reference aggregator sites (`llmstxt.site`, `llmstxthub.com`)
4. Downloads new/updated docs to the docs directory
5. Detects orphaned files (docs for packages no longer in the project)
6. Caches working URLs in `known-sources.json`
7. Supports `--json` flag for machine-readable output

Make the script executable: `chmod +x scripts/download-ai-docs.py`

### Step 5: Create the docs directory

```
mkdir -p docs/llms-txt
```

Initialize `known-sources.json` with an empty object:
```json
{}
```

### Step 6: Write config file

Write `.llmstxt.json` if it doesn't exist:

```json
{
  "docs_dir": "docs/llms-txt/",
  "skip": [],
  "extra_packages": ["bun", "vercel"],
  "claude_md": "CLAUDE.md",
  "agent_dir": ".claude/agents/",
  "script": "scripts/download-ai-docs.py"
}
```

### Step 7: Run initial download

Ask the user: "Run the download script now to populate docs? (yes/no)"

If yes, run: `python3 scripts/download-ai-docs.py`

Show progress and results.

### Step 8: Update CLAUDE.md

If `CLAUDE.md` exists and has no reference docs table, append one:

```markdown
## Reference Docs

When you need API details for a dependency, read the relevant file from `docs/llms-txt/`:

| File | Library | Use when... |
|------|---------|-------------|
```

Populate with any docs that were downloaded.

### Step 9: Commit

```
git add scripts/download-ai-docs.py docs/llms-txt/ .llmstxt.json
git commit -m "feat: add llms.txt reference docs system"
```

### Step 10: Report

```
## llmstxt-init Complete

- Script: scripts/download-ai-docs.py
- Docs: docs/llms-txt/ (N files)
- Cache: docs/llms-txt/known-sources.json
- Config: .llmstxt.json

Next steps:
- Run /llmstxt-update anytime to refresh docs
- Run /llmstxt-status to check coverage
- Add reference docs sections to agent files with /init-agents
```

## Rules

- Never overwrite existing files without asking
- The download script uses only Python stdlib (urllib, json, pathlib) — no pip install
- `known-sources.json` is checked into git (cache persists across machines)
- Always prefer `llms-full.txt` over `llms.txt` when both exist
- The script works with Python 3.8+ on any platform
