---
name: validate
description: Use when verifying the x4-agent-plugins marketplace structure — checks JSON manifests, command/skill pairing, hook scripts, and cross-references. Trigger for "validate the plugin", "check the marketplace", "is the structure correct?", before any release, or after adding new commands or skills.
disable-model-invocation: true
---

# Validate Plugin Marketplace

Run full structural validation of the x4-agent-plugins marketplace.

## Steps

### 1. Run baseline validation script

```bash
bash tests/validate.sh
```

Report the output to the user. If it fails, note the errors but continue.

### 2. Dispatch the plugin-validator agent

Use the Agent tool to dispatch the `plugin-validator` agent defined in `.claude/agents/plugin-validator.md` for deeper cross-reference and structural checks.

### 3. Report combined results

Present a unified summary of both the baseline script and agent findings:

- Total checks passed
- Issues found (with file paths and descriptions)
- Warnings

If everything passes, confirm with: "Marketplace validation passed — all checks clean."
