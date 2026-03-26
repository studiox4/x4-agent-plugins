---
name: release
description: Bump plugin version (patch/minor/major), update CHANGELOG.md, and commit — runs validation first
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

### 5. Update plugin.json

Edit `plugins/x4/.claude-plugin/plugin.json` to set the new version.

### 6. Update CHANGELOG.md

Add a new entry at the top of the `## x4` section in `CHANGELOG.md`:

```markdown
### <new-version> (<YYYY-MM-DD>)

- <summary of changes since last release>
```

To determine the summary, check `git log` since the last version tag or changelog entry. Write concise bullet points describing the changes.

### 7. Commit

Stage both files and commit:

```
release: x4 v<new-version>
```

Report the new version to the user.
