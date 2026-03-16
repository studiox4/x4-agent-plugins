# x4-agent-plugins

A Claude Code plugin marketplace with reusable workflow plugins: project tracking, agent team ops, and llms.txt management.

## Plugins

### project-tracker

Backlog capture, triage, PRD generation, and project status tracking.

**Commands:**
- `/btw <idea>` — Capture a feature idea to the backlog
- `/plan-backlog` — Triage backlog items into PRDs
- `/init-tracker` — Scaffold tracking files for a new project

### agent-team-ops

Agent team coordination, feature dispatching, test running, review cycles, and hook-based guardrails.

**Commands:**
- `/work` — Pick up the next feature, dispatch an agent team, and ship it
- `/run-tests` — Run configured test commands
- `/init-agents` — Generate project-specific agent files from templates

### llmstxt-manager

Scan project dependencies, discover llms.txt documentation endpoints, download and manage AI-readable reference docs.

**Commands:**
- `/llmstxt-update` — Full scan, discover, download, and sync
- `/llmstxt-status` — Read-only status report of current docs

## Installation

### Add the marketplace

```
/plugin marketplace add corbanbaxter/x4-agent-plugins
```

### Install plugins

```
/plugin install project-tracker@x4-agent-plugins
/plugin install agent-team-ops@x4-agent-plugins
/plugin install llmstxt-manager@x4-agent-plugins
```

### Auto-suggest plugins for your team

Add this to your project's `.claude/settings.json` so team members are prompted to install the marketplace and plugins when they trust the project:

```json
{
  "extraKnownMarketplaces": {
    "x4-agent-plugins": {
      "source": {
        "source": "github",
        "repo": "corbanbaxter/x4-agent-plugins"
      }
    }
  },
  "enabledPlugins": {
    "project-tracker@x4-agent-plugins": true,
    "agent-team-ops@x4-agent-plugins": true,
    "llmstxt-manager@x4-agent-plugins": true
  }
}
```

## Local Development

```bash
# Test the marketplace locally
/plugin marketplace add ./path/to/x4-agent-plugins
/plugin install project-tracker@x4-agent-plugins

# Validate marketplace structure
claude plugin validate .

# Run structural checks
bash tests/validate.sh

# Link individual plugins for iterative development
claude plugin link ./plugins/project-tracker
claude plugin link ./plugins/agent-team-ops
claude plugin link ./plugins/llmstxt-manager
```

## License

Apache 2.0
