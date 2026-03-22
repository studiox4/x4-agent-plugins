---
description: Set up the llms.txt reference docs system — scaffold download script, known-sources cache, and docs directory.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /llmstxt-init

Run the `/llmstxt-init` skill to set up the llms.txt reference docs system.

Scaffolds `scripts/download-ai-docs.ts`, `docs/llms-txt/`, `known-sources.json`,
and `.llmstxt.json` config. Detects project ecosystem and extra packages
automatically. Optionally runs the initial download.
