---
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
