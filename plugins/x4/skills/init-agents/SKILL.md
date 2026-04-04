---
name: init-agents
description: Use when setting up agent files for a project or when .claude/agents/ is empty or has unresolved template placeholders. Reads CLAUDE.md to fill in tech stack, conventions, and directory ownership. Trigger for "set up agents", "generate agent files", "my agents have {{placeholders}}", or when /work can't find agent files. Run once after /init-setup.
version: 2.0.0
license: MIT
---

# /init-agents — Generate Agent Files

Generate project-specific agent `.md` files in `.claude/agents/` from the
bundled agent templates. This command should be run once during project setup.

## Steps

1. **Read config.** Read `.claude/agent-team.config.md`. If it does not exist,
   create it with defaults and ask the user to review before continuing.

2. **Read CLAUDE.md.** Parse the project's `CLAUDE.md` to extract:
   - Tech stack (languages, frameworks, libraries)
   - Monorepo structure (if any)
   - Key conventions (naming, patterns, tooling)
   - Path aliases
   - Package manager (npm, yarn, pnpm, bun)
   - Existing commands (dev, build, test, lint)

3. **Check for existing agents.** If `.claude/agents/` already contains agent
   files, ask the user whether to overwrite or skip each one.

4. **Generate agent files.** For each agent role defined in `agents` config:
   a. Read the corresponding template from the plugin's `agents/` directory.
   b. Replace template placeholders with project-specific values:
   - `{{OWNED_DIRS}}` -- from config `agents.<role>.owns`
   - `{{MODEL}}` -- from config `agents.<role>.model`
   - `{{TECH_STACK}}` -- extracted from CLAUDE.md
   - `{{CONVENTIONS}}` -- extracted from CLAUDE.md
   - `{{PATH_ALIASES}}` -- extracted from CLAUDE.md
   - `{{PACKAGE_MANAGER}}` -- extracted from CLAUDE.md
   - `{{TEST_COMMAND}}` -- from config `test_commands.unit`
   - `{{E2E_COMMAND}}` -- from config `test_commands.e2e`
   - `{{SHARED_PACKAGE}}` -- from config `shared_packages[0].path` (if set)
   - `{{SHARED_OWNER}}` -- from config `shared_packages[0].owner` (if set)
   - `{{OFF_LIMITS_DIRS}}` -- directories owned by OTHER agents (agent must not touch these)
   - `{{REFERENCE_DOCS}}` -- if `opensrc/sources.json` exists, generate a table
     mapping relevant source paths in `opensrc/` to this agent's domain. Otherwise omit.
     c. Write the generated file to `.claude/agents/<role>.md`.

5. **Summary.** Print which agent files were created and remind the user they
   can customize them freely -- the generated files are owned by the project,
   not the plugin.

## Notes

- If the user has custom agent roles not in the templates (e.g., `cli`, `devops`),
  generate a minimal agent file with owned dirs and conventions, using the
  `backend.md` template as a base.
- The reviewer and performance agents always get `read_only: true` in their
  frontmatter and never receive Write/Edit tools.
- Re-running `/init-agents` after initial setup is safe -- it asks before overwriting.
