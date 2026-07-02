# Changelog

## x4

### 1.0.0 (2026-07-02)

- Consolidated the `x4` plugin repo onto this working copy (`x4-skills`) as the single source of truth, superseding the separately-cloned `studiox4/x4-agent-plugins` checkout
- Version reset to 1.0.0 — no external users depended on the prior 3.x numbering, so history starts clean here
- Full feature set carried forward: project scaffolding, backlog management, agent team coordination, llms.txt reference docs, and hook-based guardrails
- `skills/github-wiki-bootstrap`: new user-invoked skill — bootstraps and maintains a GitHub repo's wiki from the command line (enable + seed starter pages, or sync pages against a merged/open PR)
