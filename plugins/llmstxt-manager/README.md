# x4-llmstxt-manager

A Claude Code plugin that scans your project dependencies, discovers llms.txt documentation endpoints, downloads them locally, and keeps your CLAUDE.md reference table in sync.

## How It Works

[llms.txt](https://llmstxt.org/) is a convention where library authors publish documentation in plain text optimized for LLM consumption. This plugin discovers and downloads those files for every dependency in your project, giving your AI agents current documentation without web searches.

### The Pipeline

```
/llmstxt-init → scaffolds download script + config
/llmstxt-update → runs script, downloads docs, updates references
/llmstxt-status → read-only health check
```

## Commands

### `/llmstxt-init`

One-time setup that scaffolds:
- `scripts/download-ai-docs.py` — Pure Python 3 download script (no pip install needed)
- `docs/llms-txt/` — Local docs directory
- `docs/llms-txt/known-sources.json` — URL cache (checked into git)
- `.llmstxt.json` — Configuration file

The script discovers llms.txt URLs using a 5-step pipeline:
1. Check known-sources cache for previously working URLs
2. Look up package homepage on npm/PyPI/crates.io registry
3. Probe URL patterns (`/llms-full.txt`, `/llms.txt`, `/docs/llms-full.txt`, etc.)
4. Try GitHub raw content URLs for repo-hosted docs
5. Cross-reference aggregator sites (`llmstxt.site`, `llmstxthub.com`)

### `/llmstxt-update`

Full scan, discover, download, and sync. Two modes:

- **Script mode** (preferred): If `scripts/download-ai-docs.py` exists, runs it with `--json` for fast cached discovery.
- **Standalone mode**: Performs all discovery inline if no script exists.

After downloading, updates CLAUDE.md reference table and agent file references.

### `/llmstxt-status`

Read-only status report. Shows what docs are current, missing, orphaned, or stale without modifying any files.

## Supported Ecosystems

- **JavaScript/Bun/Node** — `package.json`
- **Python** — `requirements.txt`, `pyproject.toml`
- **Rust** — `Cargo.toml`
- **Go** — `go.mod`
- **Ruby** — `Gemfile`

## Configuration

Optional `.llmstxt.json` in project root:

```json
{
  "docs_dir": "docs/llms-txt/",
  "skip": ["@myorg/internal-*"],
  "extra_packages": ["bun", "vercel"],
  "claude_md": "CLAUDE.md",
  "agent_dir": ".claude/agents/",
  "script": "scripts/download-ai-docs.py"
}
```

All fields are optional. Defaults apply for any omitted field.

## Running the Script Directly

```bash
# Human-readable output
python3 scripts/download-ai-docs.py

# JSON output (for automation / skill consumption)
python3 scripts/download-ai-docs.py --json
```

## How Agents Use the Docs

Each agent file (`.claude/agents/*.md`) can have a reference docs section:

```markdown
## Reference Docs

When you need API details, read the relevant file from docs/llms-txt/:

- `hono.txt` — Hono middleware, routing, context
- `drizzle-kit.txt` — Schema, queries, migrations
```

The team lead also gets a reference table in `CLAUDE.md` pointing to every doc file.

## Installation

```bash
claude plugin install studiox4/x4-agent-plugins/x4-llmstxt-manager
```

## License

Apache 2.0
