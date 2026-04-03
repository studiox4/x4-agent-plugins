---
name: upgrade
description: Use when the user wants to apply x4 project migrations after updating the plugin, when the session-start hook reports a version mismatch, or when /doctor flags missing features. Detects gaps between the current x4 version and what exists in the project, then scaffolds only what's missing. Safe to run multiple times. Trigger for "upgrade x4", "apply migrations", "update my project after upgrading", "x4 says I need to upgrade", or after the session-start hook shows a version mismatch.
version: 1.0.0
license: MIT
---

# /upgrade — Apply x4 Project Migrations

Detects gaps between the current plugin version and what's been applied to
this project. Applies only what's missing — idempotent, always safe to re-run.

<!-- CURRENT_VERSION: 3.10.0 -->
<!-- Updated automatically by /release — do not edit this line manually -->

## Process

### Step 1: Detect project state

1. Read the current plugin version from the `CURRENT_VERSION` comment above: `3.10.0`

2. Read the project's last-applied version from `.claude/x4-version`:
   - If the file exists, read its contents (trim whitespace)
   - If absent but `.claude/agent-team.config.md` exists: treat as `0.0.0`
     (project was set up before version tracking was introduced)
   - If neither exists: treat as a fresh project — skip migrations, just write
     the version file. Nothing to migrate.

3. If project version == current version: "This project is already on v{version}." Stop.

4. Tell the user:
   ```
   ## x4 Upgrade — v{project_version} → v{current_version}

   Scanning for migrations to apply...
   ```

### Step 2: Run the migration checklist

Work through every migration in the registry below, in version order.
Only evaluate migrations for versions newer than the project version.

For each migration: check silently, collect findings. Don't ask per-migration —
gather all actions first, then present them together in Step 3.

Each migration has three possible outcomes:
- **Apply** — the change is needed and will be made
- **Skip** — the change is already present, nothing to do
- **Offer** — the change requires user interaction (e.g., running a sub-skill)

### Step 3: Present findings and confirm

Show a summary table:

```
## Migrations to Apply

  v3.7.0  railway.toml          {Apply / Skip / Offer — /deploy-setup}
  v3.9.0  brand/BRAND.md        {Apply (migrate from config) / Apply (fresh) / Skip}
  v3.9.0  brand/assets/         {Apply / Skip}

Auto-apply all? (yes / review each / skip all)
```

If user picks "review each": walk through each Apply/Offer item one at a time.
If user picks "yes": apply all without further prompts.
If user picks "skip all": update the version file only — user can re-run later.

### Step 4: Apply migrations

Apply each confirmed migration. Report each as it completes:

```
  ✓ Created brand/BRAND.md (migrated from agent-team.config.md)
  ✓ Created brand/assets/ with README
  ○ railway.toml — already present, skipped
  → /deploy-setup — offered, user will run separately
```

### Step 5: Update version file

Write the current plugin version to `.claude/x4-version`:

```bash
echo "3.10.0" > .claude/x4-version
```

Create `.claude/` if it doesn't exist.

### Step 6: Report

```
## Upgrade Complete — x4 v{current_version}

{N} migrations applied, {M} already present, {K} offered for manual setup.

Project is now on v{current_version}.
Run /x4:doctor anytime to check project health.
```

---

## Migration Registry

Each migration is a version-tagged check. New entries are added here as
new x4 versions ship. The `/release` skill appends new migration blocks.

---

### v3.7.0 — Railway deployment (`railway.toml`)

**Check:** `.claude/agent-team.config.md` contains a `ci:` section with
`preview_url_command` referencing `railway`, AND `railway.toml` does NOT
exist in the project root.

**Action (Offer):** This requires guided setup — cannot auto-apply.

```
Railway is configured in your project but railway.toml is missing.
Run /x4:deploy-setup to generate railway.toml and configure PR previews.

Run now? (yes / later)
```

If "yes": delegate to `/x4:deploy-setup`.
If "later": note it in the report.

---

### v3.9.0 — Brand guide (`brand/BRAND.md` + `brand/assets/`)

**Check A:** `brand/BRAND.md` does NOT exist.

  **Case 1 — Legacy config present:**
  A `brand:` YAML block exists in `.claude/agent-team.config.md`.

  Action (Apply): Extract all brand values from the YAML block and write
  `brand/BRAND.md` using the template format (same structure as
  `init-setup/references/brand-template.md`). Map fields:
  - `brand.name` → `**Name:**`
  - `brand.tagline` → `**Tagline:**`
  - `brand.voice` → `**Voice:**`
  - `brand.audience` → `**Audience:**`
  - `brand.email.provider` → `**Provider:**`
  - `brand.email.api_key_env` → `**API key env var:**`
  - `brand.email.from` → `**Email from:**` in Social section
  - `brand.email.audience_id` → `**Audience ID:**`
  - `brand.social.twitter_handle` → `**Twitter/X:**`
  - `brand.social.linkedin_url` → `**LinkedIn:**`
  - `brand.social.hashtags` → `**Hashtags:**` (join with spaces)
  - `brand.social.x_api_key_env` → `**API key env var:**` in X section

  After creating `brand/BRAND.md`, note in the report:
  "Migrated brand config from agent-team.config.md → brand/BRAND.md.
  The `brand:` block in agent-team.config.md is now superseded — you can
  remove it, but it's harmless to leave."

  **Case 2 — No legacy config:**
  Action (Offer): No existing data to migrate. Ask if they want to set up
  brand config now:

  ```
  No brand configuration found. Set up brand/BRAND.md now?
  1. Yes — walk through brand setup (name, voice, email, social)
  2. Skip — I'll run /x4:init-setup or create it manually later
  ```

  If yes: run the brand setup questions from init-setup Step 6c, then
  write `brand/BRAND.md` from the template.

**Check B:** `brand/assets/` does NOT exist.

  Action (Apply — no confirmation needed): Create `brand/assets/README.md`:

  ```markdown
  # Brand Assets

  Add your logo and image files here. Update the paths in `../BRAND.md`.

  | File | Dimensions | Format | Purpose |
  |------|-----------|--------|---------|
  | logo.svg | any | SVG | Primary logo — light backgrounds |
  | logo-dark.svg | any | SVG | Dark backgrounds, Twitter/LinkedIn banner bg |
  | logo-icon.svg | any | SVG | Favicon, social media avatar |
  | og-image.png | 1200×630 | PNG | Open Graph — link previews everywhere |
  | banner.png | 1500×500 | PNG | Twitter/LinkedIn profile header |
  ```

---

## Adding New Migrations (for x4 maintainers)

When a new version introduces a change that requires project updates:

1. Add a migration block above following the `### vX.Y.Z — Name` format
2. Specify: what to check, which case applies, what action to take
3. Mark action as **Apply** (automatic), **Offer** (interactive), or **Skip** (informational)
4. Run `/release` — it updates `CURRENT_VERSION` in this file, `X4_VERSION` in
   `session-start.sh`, and the version constants everywhere they appear

The migration registry is append-only. Never remove old migrations — they're
skipped automatically when the project version is already past them.
