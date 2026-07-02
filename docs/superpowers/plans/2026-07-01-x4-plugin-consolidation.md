# x4 Plugin Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate this repo (`x4-skills`) into the single source of truth for the existing `x4` Claude Code plugin, absorbing all content from the currently-installed `studiox4/x4-agent-plugins` marketplace clone, folding in `github-wiki-bootstrap` as a real skill, and bumping the version — without pushing to the shared GitHub remote (that step is a separate, explicitly-confirmed action).

**Architecture:** Marketplace-of-plugins repo shape. Root `.claude-plugin/marketplace.json` lists one plugin (`x4`) sourced from `plugins/x4/`. Everything currently shipped from the installed clone at `~/.claude/plugins/marketplaces/x4-agent-plugins` gets copied byte-for-byte into this repo, then `github-wiki-bootstrap` moves under `plugins/x4/skills/`, then the version bumps.

**Tech Stack:** Plain bash for file operations (`cp -R`, `mkdir -p`), no build tooling. Validation via the plugin's own `tests/validate.sh`. Git for version control.

## Global Constraints

- Source of truth for everything being ported: `SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins` (the currently-installed, up-to-date clone of `studiox4/x4-agent-plugins`, branch `master`).
- Do not copy `$SRC/.git` — this repo keeps its own git history.
- Do not copy `$SRC/.claude/projects/` — that's local session/runtime state, not repo content.
- Versioning convention is the repo's own `/release` skill (bespoke bash + manual CHANGELOG edits), **not** npm `changesets` — there is no `.changeset/` dir or `package.json` in the source repo. Correcting the earlier assumption in the design spec: "keep changesets" means "keep this repo's existing bespoke version-bump convention," which this plan follows.
- New version after this work: **3.16.0** (minor bump — new skill added, no breaking changes), computed from current `3.15.1`.
- No `git push` to `origin` (`https://github.com/studiox4/x4-agent-plugins.git`) in this plan. The last task documents the manual push/tag/marketplace-repoint steps and stops for explicit user confirmation before any of them run.
- Every `cp` step must be re-runnable without error (use `mkdir -p` before copies, and prefer `cp -R src/. dest/` over `cp -R src dest` to avoid nested-directory duplication on a second run).

---

### Task 1: Copy root-level plugin repo scaffolding

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `CLAUDE.md`
- Create: `README.md`
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `public/images/x4-workflow-diagram.png`
- Modify: `.gitignore` (create fresh, then Task 6 fixes the one line that would break spec/plan tracking)

**Interfaces:**
- Produces: root `.claude-plugin/marketplace.json` with `plugins[0].source == "./plugins/x4"` — Task 2 must land content at that exact path.

- [ ] **Step 1: Copy the root files**

```bash
SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins
mkdir -p .claude-plugin public/images
cp "$SRC/.claude-plugin/marketplace.json" .claude-plugin/marketplace.json
cp "$SRC/CLAUDE.md" CLAUDE.md
cp "$SRC/README.md" README.md
cp "$SRC/LICENSE" LICENSE
cp "$SRC/CHANGELOG.md" CHANGELOG.md
cp "$SRC/.gitignore" .gitignore
cp "$SRC/public/images/x4-workflow-diagram.png" public/images/x4-workflow-diagram.png
```

- [ ] **Step 2: Verify the copy**

Run: `test -f .claude-plugin/marketplace.json && test -f CLAUDE.md && test -f README.md && test -f LICENSE && test -f CHANGELOG.md && test -f .gitignore && test -f public/images/x4-workflow-diagram.png && echo ALL_PRESENT`
Expected: `ALL_PRESENT`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json CLAUDE.md README.md LICENSE CHANGELOG.md .gitignore public/
git commit -m "chore: port x4 plugin repo root scaffolding from studiox4/x4-agent-plugins"
```

---

### Task 2: Copy the shipped plugin content

**Files:**
- Create: `plugins/x4/.claude-plugin/plugin.json`
- Create: `plugins/x4/README.md`, `plugins/x4/LICENSE`
- Create: `plugins/x4/agents/*.md` (6 files: backend, frontend, performance, reviewer, security-reviewer, tester)
- Create: `plugins/x4/commands/*.md` (35 files)
- Create: `plugins/x4/hooks/*` (includes `hooks.json`, `session-start.sh`, `auto-format.sh`, `plan-bridge-nudge.sh`, `protected-files.sh`, `teammate-idle.sh`)
- Create: `plugins/x4/skills/*` (35 existing skill dirs — `github-wiki-bootstrap` is added separately in Task 5, don't create it here)
- Create: `plugins/x4/templates/workflows/*`

**Interfaces:**
- Consumes: `plugins/x4/` directory created by Task 1's `marketplace.json` reference (`./plugins/x4`).
- Produces: `plugins/x4/.claude-plugin/plugin.json` at version `3.15.1` — Task 7 bumps this to `3.16.0`.

- [ ] **Step 1: Copy plugin content**

```bash
SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins/plugins/x4
mkdir -p plugins/x4/.claude-plugin plugins/x4/agents plugins/x4/commands plugins/x4/hooks plugins/x4/skills plugins/x4/templates
cp "$SRC/.claude-plugin/plugin.json" plugins/x4/.claude-plugin/plugin.json
cp "$SRC/README.md" plugins/x4/README.md
cp "$SRC/LICENSE" plugins/x4/LICENSE
cp -R "$SRC/agents/." plugins/x4/agents/
cp -R "$SRC/commands/." plugins/x4/commands/
cp -R "$SRC/hooks/." plugins/x4/hooks/
cp -R "$SRC/skills/." plugins/x4/skills/
cp -R "$SRC/templates/." plugins/x4/templates/
```

- [ ] **Step 2: Verify counts match the source**

Run:
```bash
SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins/plugins/x4
echo "agents: $(ls plugins/x4/agents | wc -l) vs $(ls "$SRC/agents" | wc -l)"
echo "commands: $(ls plugins/x4/commands | wc -l) vs $(ls "$SRC/commands" | wc -l)"
echo "skills: $(ls plugins/x4/skills | wc -l) vs $(ls "$SRC/skills" | wc -l)"
```
Expected: each pair of numbers matches (35/35 commands, 35/35 skills, 6/6 agents).

- [ ] **Step 3: Commit**

```bash
git add plugins/
git commit -m "chore: port x4 plugin content (agents, commands, hooks, skills, templates)"
```

---

### Task 3: Copy repo dev tooling and docs/tests/CI

**Files:**
- Create: `.claude/agent-team.config.md`, `.claude/project-tracker.config.md`, `.claude/x4-version`, `.claude/settings.json`
- Create: `.claude/agents/plugin-validator.md`
- Create: `.claude/commands/update-briefs.md`
- Create: `.claude/skills/release/SKILL.md`, `.claude/skills/update-briefs/SKILL.md`, `.claude/skills/validate/SKILL.md`
- Create: `docs/**` (guides, planning, BACKLOG.md, STATUS.md — everything except `docs/superpowers/`, which is this repo's own brainstorming/plans output and doesn't exist in the source repo)
- Create: `tests/**` (`validate.sh` + fixtures)
- Create: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: none new.
- Produces: `tests/validate.sh`, used by Task 6's verification step.

- [ ] **Step 1: Copy dev tooling**

```bash
SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins
mkdir -p .claude/agents .claude/commands .claude/skills
cp "$SRC/.claude/agent-team.config.md" .claude/agent-team.config.md
cp "$SRC/.claude/project-tracker.config.md" .claude/project-tracker.config.md
cp "$SRC/.claude/x4-version" .claude/x4-version
cp "$SRC/.claude/settings.json" .claude/settings.json
cp "$SRC/.claude/agents/plugin-validator.md" .claude/agents/plugin-validator.md
cp "$SRC/.claude/commands/update-briefs.md" .claude/commands/update-briefs.md
cp -R "$SRC/.claude/skills/." .claude/skills/
```

- [ ] **Step 2: Copy docs, tests, CI**

```bash
SRC=/Users/corbanbaxter/.claude/plugins/marketplaces/x4-agent-plugins
mkdir -p docs tests .github/workflows
cp -R "$SRC/docs/." docs/
cp -R "$SRC/tests/." tests/
cp "$SRC/.github/workflows/validate.yml" .github/workflows/validate.yml
```

- [ ] **Step 3: Verify**

Run: `test -f .claude/skills/release/SKILL.md && test -f tests/validate.sh && test -f .github/workflows/validate.yml && test -d docs/guides/plugin-guide && echo ALL_PRESENT`
Expected: `ALL_PRESENT`

- [ ] **Step 4: Commit**

```bash
git add .claude/ docs/ tests/ .github/
git commit -m "chore: port x4 repo dev tooling, docs, tests, and CI workflow"
```

---

### Task 4: Move github-wiki-bootstrap into the plugin's skills tree

**Files:**
- Create: `plugins/x4/skills/github-wiki-bootstrap/SKILL.md`, `plugins/x4/skills/github-wiki-bootstrap/assets/**`, `plugins/x4/skills/github-wiki-bootstrap/references/**`, `plugins/x4/skills/github-wiki-bootstrap/scripts/**`
- Delete: `skills/github-wiki-bootstrap/` (entire tree)

**Interfaces:**
- Consumes: existing `skills/github-wiki-bootstrap/` content (unchanged from before this migration).
- Produces: `plugins/x4/skills/github-wiki-bootstrap/` — now resolves as `/x4:github-wiki-bootstrap`.

- [ ] **Step 1: Move the skill**

```bash
git mv skills/github-wiki-bootstrap plugins/x4/skills/github-wiki-bootstrap
```

- [ ] **Step 2: Remove the now-empty top-level skills directory**

```bash
rmdir skills 2>/dev/null || true
```

- [ ] **Step 3: Verify**

Run: `test -f plugins/x4/skills/github-wiki-bootstrap/SKILL.md && ! test -d skills && echo MOVED_OK`
Expected: `MOVED_OK`

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: move github-wiki-bootstrap into plugins/x4/skills"
```

---

### Task 5: Fix .gitignore and validate the consolidated repo

**Files:**
- Modify: `.gitignore`

**Interfaces:**
- Consumes: `tests/validate.sh` (from Task 3).
- Produces: a `.gitignore` that does not hide `docs/superpowers/` (this repo's brainstorming specs/plans, including the file you're reading now, live there and must stay trackable).

- [ ] **Step 1: Remove the line that ignores docs/superpowers/**

The copied `.gitignore` ends with:

```
# Superpowers design specs (session artifacts)
docs/superpowers/
```

Edit `.gitignore` to delete those two lines (the comment and the `docs/superpowers/` pattern). Leave the other four ignore rules (`​.briefs/`, `skill-creator-workspace/`, `plugins/x4/skills/*/evals/`, `.claude/settings.local.json`) untouched.

- [ ] **Step 2: Confirm the spec/plan docs are trackable**

Run: `git check-ignore -v docs/superpowers/specs/2026-07-01-x4-plugin-consolidation-design.md docs/superpowers/plans/2026-07-01-x4-plugin-consolidation.md; echo "exit=$?"`
Expected: `exit=1` (no match — nothing is ignoring these paths). If it prints a match, the edit in Step 1 wasn't applied correctly; fix and re-run.

- [ ] **Step 3: Run the plugin's own structural validator**

Run: `bash tests/validate.sh`
Expected: exits 0, no `FAIL:` lines in the output (only `OK:` lines).

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: keep docs/superpowers/ trackable in the consolidated repo"
```

---

### Task 6: Bump the plugin version to 3.16.0

**Files:**
- Modify: `plugins/x4/.claude-plugin/plugin.json:4` (`"version": "3.15.1"` → `"3.16.0"`)
- Modify: `.claude-plugin/marketplace.json:8` (`"version": "3.15.1"` under `metadata`) and `:20` (`"version": "3.15.1"` under `plugins[0]`) → both `"3.16.0"`
- Modify: `plugins/x4/hooks/session-start.sh:24` (`X4_VERSION="3.15.1"` → `X4_VERSION="3.16.0"`)
- Modify: `plugins/x4/skills/upgrade/SKILL.md:13,20,85` (three occurrences of `3.15.1` → `3.16.0`: the `CURRENT_VERSION` comment, the prose line reading it, and the `echo "3.15.1" > .claude/x4-version` literal)
- Modify: `CHANGELOG.md` (new entry at the top of the `## x4` section)

**Interfaces:**
- Consumes: version bump rules from `.claude/skills/release/SKILL.md` Steps 3–6 (ported in Task 3) — this task applies those steps manually for a `minor` bump, without the push/tag/briefs steps (8–11), which belong to the explicit-confirmation step at the end of this plan.

- [ ] **Step 1: Bump plugin.json**

Edit `plugins/x4/.claude-plugin/plugin.json`, change:
```json
  "version": "3.15.1",
```
to:
```json
  "version": "3.16.0",
```

- [ ] **Step 2: Bump marketplace.json (both occurrences)**

Edit `.claude-plugin/marketplace.json`, change the `metadata.version` field:
```json
    "version": "3.15.1"
```
to:
```json
    "version": "3.16.0"
```
and the `plugins[0].version` field:
```json
      "version": "3.15.1",
```
to:
```json
      "version": "3.16.0",
```

- [ ] **Step 3: Bump the session-start.sh constant**

Edit `plugins/x4/hooks/session-start.sh`, change:
```bash
X4_VERSION="3.15.1"
```
to:
```bash
X4_VERSION="3.16.0"
```

- [ ] **Step 4: Bump the upgrade skill's version markers**

Edit `plugins/x4/skills/upgrade/SKILL.md`, three changes:
1. Line 13: `<!-- CURRENT_VERSION: 3.15.1 -->` → `<!-- CURRENT_VERSION: 3.16.0 -->`
2. Line 20: `` `3.15.1` `` → `` `3.16.0` `` (in "Read the current plugin version from the `CURRENT_VERSION` comment above: `3.15.1`")
3. Line 85: `echo "3.15.1" > .claude/x4-version` → `echo "3.16.0" > .claude/x4-version`

- [ ] **Step 5: Add the CHANGELOG entry**

Edit `CHANGELOG.md`, insert immediately after the `## x4` line (before the existing `### 3.15.1 (2026-04-07)` entry):

```markdown
### 3.16.0 (2026-07-02)

- Consolidated the `x4` plugin repo onto this working copy (`x4-skills`), superseding the separately-cloned `studiox4/x4-agent-plugins` checkout as source of truth
- `skills/github-wiki-bootstrap`: new user-invoked skill — bootstraps and maintains a GitHub repo's wiki from the command line (enable + seed starter pages, or sync pages against a merged/open PR)
```

- [ ] **Step 6: Verify the version is consistent everywhere**

Run:
```bash
grep -rn "3.16.0" plugins/x4/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/x4/hooks/session-start.sh plugins/x4/skills/upgrade/SKILL.md CHANGELOG.md | wc -l
grep -rln "3.15.1" plugins/x4/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/x4/hooks/session-start.sh plugins/x4/skills/upgrade/SKILL.md
```
Expected: first command prints a count ≥ 6 (one per changed line, marketplace.json contributes two); second command prints nothing (no leftover `3.15.1` in those five files — earlier historical CHANGELOG entries below the new one still say `3.15.1` on purpose and aren't part of this grep set).

- [ ] **Step 7: Re-run the structural validator**

Run: `bash tests/validate.sh`
Expected: exits 0, no `FAIL:` lines.

- [ ] **Step 8: Commit**

```bash
git add plugins/x4/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/x4/hooks/session-start.sh plugins/x4/skills/upgrade/SKILL.md CHANGELOG.md
git commit -m "release: x4 v3.16.0"
```

---

### Task 7: Document the skill-authoring convention in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md` (append a new section)

**Interfaces:**
- Produces: a checklist future work (human or agent team) follows to add new skills without re-deriving the repo's structure.

- [ ] **Step 1: Append the checklist**

Add this section to the end of `CLAUDE.md`:

```markdown
## Adding a new skill

Every skill lives at `plugins/x4/skills/<skill-name>/SKILL.md` — flat, no
category subfolders. Because this repo ships exactly one plugin named `x4`,
every skill automatically resolves as `/x4:<skill-name>` with no collision
risk from other marketplaces.

1. Create `plugins/x4/skills/<skill-name>/SKILL.md` with YAML frontmatter
   (`name`, `description`; add `disable-model-invocation: true` if it should
   only ever be user-invoked via `/x4:<skill-name>`, never auto-triggered).
2. Put any supporting scripts/templates/references in
   `plugins/x4/skills/<skill-name>/{scripts,assets,references}/` as needed —
   see `plugins/x4/skills/github-wiki-bootstrap/` for the pattern.
3. Run `bash tests/validate.sh` before committing.
4. Bump the version with `/release [patch|minor|major]` (new skill = `minor`).
5. If skill count in `plugins/x4/skills/` grows large enough that flat listing
   becomes hard to navigate, revisit bucket folders (`engineering/`,
   `productivity/`, etc., mirroring `mattpocock/skills`) — not needed yet.
```

- [ ] **Step 2: Verify**

Run: `grep -q "## Adding a new skill" CLAUDE.md && echo APPENDED`
Expected: `APPENDED`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add skill-authoring checklist to CLAUDE.md"
```

---

### Task 8: Stop for explicit confirmation before touching the shared remote

**Files:** none — this task is a checkpoint, not code.

This repo now has full local history (Tasks 1–7) and has never pushed anywhere.
Do **not** run any of the following without the user explicitly confirming
each one at execution time — these affect shared state (`studiox4/x4-agent-plugins`
on GitHub) and the local marketplace registration used by every other Claude
Code session on this machine:

1. **Point this local checkout at the existing remote and push**, overwriting
   `studiox4/x4-agent-plugins`'s current history:
   ```bash
   git remote add origin https://github.com/studiox4/x4-agent-plugins.git
   git push origin main:master --force-with-lease
   ```
   (the source repo's default branch is `master`, not `main` — confirm with
   the user which branch name they want to standardize on before running this).

2. **Tag the release**, once the push above is confirmed successful:
   ```bash
   gh release create v3.16.0 --title "x4 v3.16.0" --notes "$(sed -n '/^### 3.16.0/,/^### 3.15.1/p' CHANGELOG.md | sed '$d')"
   ```

3. **Re-point the local marketplace registration** so `/x4:*` resolves from
   this consolidated repo instead of the stale clone at
   `~/.claude/plugins/marketplaces/x4-agent-plugins`. The simplest path: after
   the push in step 1 lands, ask Claude Code to update the `x4-agent-plugins`
   marketplace (refresh/reinstall), which re-clones from the now-updated
   `studiox4/x4-agent-plugins` remote — no manual JSON editing needed.

Report to the user: "Local consolidation complete (7 commits on `main`,
validated). Ready for the push/tag/marketplace-refresh steps above whenever
you confirm — nothing has touched GitHub or your other sessions yet."
