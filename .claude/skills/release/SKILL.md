---
name: release
description: Bump plugin version (patch/minor/major), update CHANGELOG.md, commit, push, and create a GitHub release tag
disable-model-invocation: true
---

# Release Plugin Version

Intentional version bump for the x4 plugin. Replaces automatic pre-commit hook versioning with a deliberate release action.

**Usage:** `/release [patch|minor|major]` — defaults to `patch` if no argument given.

## Steps

### 1. Run validation

Run `bash tests/validate.sh` to verify the marketplace is structurally valid. If validation fails, stop and report the errors — do not bump the version.

### 2. Determine bump type

Check the skill argument for the bump type:
- `patch` (default) — bug fixes, doc changes, minor tweaks
- `minor` — new commands, skills, or agents added
- `major` — breaking changes (renamed commands, restructured plugin)

If no argument was provided, default to `patch`.

### 3. Read current version

Read the current version from `plugins/x4/.claude-plugin/plugin.json` — it's in the `version` field (semver format, e.g., `3.1.1`).

### 4. Calculate new version

Apply the bump:
- `patch`: `3.1.1` → `3.1.2`
- `minor`: `3.1.1` → `3.2.0`
- `major`: `3.1.1` → `4.0.0`

### 5. Update plugin.json and marketplace.json

Edit `plugins/x4/.claude-plugin/plugin.json` to set the new version.
Edit `.claude-plugin/marketplace.json` to set the new version in both `metadata.version` and `plugins[].version`.

### 6. Update CHANGELOG.md

Add a new entry at the top of the `## x4` section in `CHANGELOG.md`:

```markdown
### <new-version> (<YYYY-MM-DD>)

- <summary of changes since last release>
```

To determine the summary, check `git log` since the last version tag or changelog entry. Write concise bullet points describing the changes.

### 7. Commit

Stage all changed files (`plugin.json`, `marketplace.json`, `CHANGELOG.md`) and commit:

```
release: x4 v<new-version>
```

### 8. Push

Push to origin:

```bash
git push
```

### 9. Create GitHub release tag

Create a tagged release on GitHub using `gh`:

```bash
gh release create v<new-version> --title "x4 v<new-version>" --notes "<changelog entry for this version>"
```

The `--notes` content should be the changelog bullet points from step 6.

### 10. Update briefs

Regenerate all brief documents in `.briefs/` to reflect the new version and current plugin state:

1. Read the current plugin state: `plugins/x4/.claude-plugin/plugin.json` (version), all skills, commands, agents, hooks, `CHANGELOG.md`
2. Update `.briefs/x4-architecture-and-user-flow.md` — version, skill/command counts, command reference table, pipeline description, any new features
3. Update `.briefs/marketing-site-brief.md` — version, command counts, command reference, changelog highlights, key stats

Briefs are gitignored so this does not require a commit.

### 11. Report

Report the new version to the user:

> Released x4 v<new-version>
> - Commit: pushed to origin
> - Tag: v<new-version>
> - GitHub release: <release-url>
> - Briefs: updated
