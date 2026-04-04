---
description: Scaffold Playwright e2e test suites for x4-mono apps — creates packages/playwright-web, packages/playwright-marketing, and/or packages/playwright-desktop with tailored configs, starter test files, and turbo.json integration. Run once per project or per app type.
argument-hint: "[web|marketing|desktop|all]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# /e2e-setup

Run the `/e2e-setup` skill to scaffold Playwright e2e suites.

Detects which apps are present (`apps/web`, `apps/marketing`, `apps/desktop`),
asks which to configure, and writes tailored Playwright packages with starter
tests, correct configs, and Turborepo integration.
