# x4-llmstxt-manager

A Claude Code plugin that scans your project dependencies, discovers llms.txt documentation endpoints, downloads them locally, and keeps your CLAUDE.md reference table in sync.

## Commands

### `/llmstxt-update`

Full scan, discover, download, and sync. Scans all dependency manifests, probes for llms.txt endpoints, downloads docs, and updates CLAUDE.md and agent file references.

### `/llmstxt-status`

Read-only status report. Shows what docs are current, missing, orphaned, or stale without modifying any files.

## Supported Ecosystems

- **JavaScript/Bun/Node** — `package.json`
- **Python** — `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg`
- **Rust** — `Cargo.toml`
- **Go** — `go.mod`
- **Ruby** — `Gemfile`

## Configuration

Optional `.llmstxt.json` in project root:

```json
{
  "docs_dir": "docs/llms-txt/",
  "skip": ["@myorg/internal-*"],
  "claude_md": "CLAUDE.md",
  "agent_dir": ".claude/agents/"
}
```

All fields are optional. Defaults apply for any omitted field.

## Installation

```bash
claude plugin install studiox4/x4-agent-plugins/x4-llmstxt-manager
```

## License

Apache 2.0
