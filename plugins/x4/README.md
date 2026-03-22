# x4

Complete AI-powered development workflow plugin for Claude Code.

Combines project scaffolding, feature planning, UI design, backlog management, agent team coordination, llms.txt reference docs, and hook-based guardrails into a single plugin.

## Install

```bash
/plugin marketplace add studiox4/x4-agent-plugins
/plugin install x4@x4-agent-plugins
```

## Commands

| Command | Description |
|---------|-------------|
| `/x4:onboard` | Check tools, accounts, CLIs — set up your dev environment |
| `/x4:create [name]` | Scaffold a new x4-mono project |
| `/x4:tour` | Guided walkthrough — explore apps, test login, try AI chat |
| `/x4:kickstart` | Brainstorm features, design UI, prioritize, batch-generate PRDs |
| `/x4:add` | Add a mobile or web app to an existing project |
| `/x4:env` | Set up environment variables |
| `/x4:status` | Quick project health dashboard |
| `/x4:idea <idea>` | Capture a feature idea to the backlog |
| `/x4:plan-backlog` | Triage backlog, brainstorm, plan, write PRD |
| `/x4:init-tracker` | Scaffold STATUS.md, BACKLOG.md, planning folders |
| `/x4:work` | 7-phase build pipeline: Orient → Setup → Build → Review → Ship → Memory → Cleanup |
| `/x4:run-tests` | Run configured test commands |
| `/x4:init-setup` | Interactive wizard to configure database, hosting, CI, tests |
| `/x4:init-agents` | Generate project-specific agent files from templates |
| `/x4:verify-local` | Run all checks with auto-fix — mandatory ship gate |
| `/x4:pr-create` | Create branch + DB branch + draft PR + preview setup |
| `/x4:pr-status` | Check CI, preview URLs, and review state |
| `/x4:pr-cleanup` | Post-merge cleanup |
| `/x4:llmstxt-init` | Scaffold llms.txt download script and config |
| `/x4:llmstxt-update` | Scan, discover, download, and sync llms.txt docs |
| `/x4:llmstxt-status` | Read-only status report of current docs |

## Agent Templates

| Agent | Role |
|-------|------|
| backend | Server-side code, database schema, API routes |
| frontend | UI code, components, pages, styling |
| reviewer | Read-only code review |
| tester | Unit tests and e2e tests |
| performance | Read-only performance audit |

## License

Apache 2.0
