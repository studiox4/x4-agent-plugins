# x4-agent-plugins

Reusable workflow plugins for Claude Code: project tracking, agent team ops, and llms.txt management.

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

```bash
# Install individual plugins
claude plugin install corbanbaxter/x4-agent-plugins/project-tracker
claude plugin install corbanbaxter/x4-agent-plugins/agent-team-ops
claude plugin install corbanbaxter/x4-agent-plugins/llmstxt-manager
```

## Local Development

```bash
# Link plugins for local testing
claude plugin link ./plugins/project-tracker
claude plugin link ./plugins/agent-team-ops
claude plugin link ./plugins/llmstxt-manager

# Validate all plugins
bash tests/validate.sh
```

## License

Apache 2.0
