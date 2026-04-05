# x4-agent-plugins — Backlog & Ideas

Captured during development. Review during planning sessions.

---

## x4 Cloud — One-Click Deploy Wizard

**Captured:** 2026-04-04

Enhanced `/x4:deploy-setup` — interactive wizard using Railway MCP + Neon MCP to create project, services, domains, and DB in one command. Secure local credential storage. Auto-populates `.env.local` after provisioning. Extends `/x4:status` with live service health. Extends `/x4:pr-cleanup` to tear down Railway preview environments.

Open questions: purely CLI or also a web UI? Multi-environment (staging + production) in v1?

---

## Plugin Marketplace — `/x4:add <plugin>`

**Captured:** 2026-04-04

New `/x4:add <plugin>` command that installs third-party plugins (Stripe, Resend, PostHog, feature flags) into a scaffolded monorepo. Each plugin has an `x4-plugin.json` manifest describing what it adds (schema tables, tRPC routes, UI components, env vars). Companion `/x4:remove <plugin>` for undo. First-party plugins: `stripe`, `resend`, `posthog`, `flags`.

Open questions: registry hosted where? Conflict resolution when plugins touch the same files?

---
