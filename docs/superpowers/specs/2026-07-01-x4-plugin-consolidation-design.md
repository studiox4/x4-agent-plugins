# x4 Plugin Consolidation & Skill Architecture

## Problem

This repo (`x4-skills`) started as a fresh, flat `skills/` directory with one skill
(`github-wiki-bootstrap`). Separately, the user already owns a mature Claude Code
plugin named `x4` (v3.15.1, "Complete AI-powered development workflow"), published
from `studiox4/x4-agent-plugins` and currently registered locally as the
`x4-agent-plugins` marketplace. That repo has its own `agents/`, `commands/`,
`hooks/`, `templates/`, `docs/`, `tests/`, and changesets-based versioning.

Both used the plugin name `x4`. Two plugins sharing one namespace prefix
(`/x4:...`) collide — Claude Code can't merge them. The user wants every personal
skill going forward reachable as `/x4:{skill-name}`, with no collision risk, and
wants the repo structured for easy, repeatable growth (studied `mattpocock/skills`
for prior art: bucket folders, promoted-vs-not distinction, a plugin.json that
drives namespacing, a router skill, changesets for versioning).

## Decision

Consolidate onto **one** `x4` plugin. This repo (`x4-skills`, local working copy)
becomes the new source of truth for that plugin, absorbing the existing
`x4-agent-plugins` repo's content wholesale. When done, it gets pushed to
`studiox4/x4-agent-plugins` on GitHub, overwriting what's there today. The local
marketplace registration follows the repo, so `/x4:*` continues resolving to one
place.

## Structure

Marketplace-of-plugins shape (matches the existing repo, allows adding sibling
plugins later without renaming anything):

```
x4-skills/                              (repo root — pushes to studiox4/x4-agent-plugins)
├── .claude-plugin/
│   └── marketplace.json                # marketplace metadata, lists plugins[]
├── .claude/                            # dev tooling FOR this repo, not shipped
│   ├── agent-team.config.md
│   ├── project-tracker.config.md
│   ├── agents/plugin-validator.md
│   ├── commands/update-briefs.md
│   └── skills/{release,update-briefs,validate}/SKILL.md
├── .changeset/                         # changesets config + pending changesets
├── .github/workflows/validate.yml      # CI: runs plugin-validator / tests/validate.sh
├── CHANGELOG.md
├── plugins/
│   └── x4/                             # the one shipped plugin — namespace /x4:*
│       ├── .claude-plugin/plugin.json  # name: "x4", version, author, recommendations
│       ├── agents/                     # backend, frontend, reviewer, tester, ...
│       ├── commands/                   # add, create, work, pr-create, ...
│       ├── hooks/                      # auto-format, protected-files, ...
│       ├── skills/                     # <-- every new personal skill lands here, flat
│       │   ├── github-wiki-bootstrap/
│       │   ├── add/  create/  work/  ... (existing command-backed skills)
│       ├── templates/workflows/
│       └── README.md
├── docs/                                # guides, planning, backlog (ported as-is)
└── tests/                               # validate.sh + fixtures (ported as-is)
```

Key rule: **skills stay flat** under `plugins/x4/skills/<skill-name>/` until the
count genuinely demands categorization (mattpocock's bucket folders are a future
option, not adopted now — avoids premature structure for a repo currently at
~1 net-new skill).

## Namespace guarantee

Because there is exactly one `x4` plugin and its `plugin.json` name is `x4`,
every skill under `plugins/x4/skills/` resolves as `/x4:{skill-name}` with no
possibility of collision from other marketplaces. This is the mechanism the user
asked for — no new tooling needed, just the one-plugin consolidation above.

## Versioning

Keep changesets (existing convention from the ported repo). Adding
`github-wiki-bootstrap` is itself a changeset → minor version bump (3.15.1 →
3.16.0) on next release.

## Migration steps (high level — detailed in the implementation plan)

1. Copy `agents/`, `commands/`, `hooks/`, `templates/`, `docs/`, `tests/`,
   `.github/`, `CHANGELOG.md`, `.changeset/`, and both `.claude-plugin/*.json`
   files from the currently-installed `x4-agent-plugins` marketplace clone
   (`~/.claude/plugins/marketplaces/x4-agent-plugins`) into this repo, preserving
   their existing relative structure.
2. Move `skills/github-wiki-bootstrap/` → `plugins/x4/skills/github-wiki-bootstrap/`.
3. Add a changeset describing the new skill; bump `plugin.json` /
   `marketplace.json` versions together.
4. Run `tests/validate.sh` / the plugin-validator agent against the consolidated
   repo before anything is pushed.
5. Re-point (or re-add) the local `x4-agent-plugins` marketplace registration at
   this repo so `/x4:*` resolves from the consolidated copy.
6. **Explicit confirmation gate, not assumed by this design:** pushing to
   `studiox4/x4-agent-plugins` on GitHub overwrites remote history. This happens
   only when the user explicitly confirms at execution time.

## Future-growth hook

Add a short "adding a new skill" checklist to root `CLAUDE.md`: where it lives
(`plugins/x4/skills/<name>/SKILL.md`), that it's automatically `/x4:<name>`, and
when to graduate to bucket folders. This is what lets agent teams stamp out new
skills consistently without re-deriving this structure each time.

## Out of scope

- Bucket folders (engineering/productivity/etc.) — revisit once skill count grows.
- A router/"ask-matt"-style meta-skill — revisit once there are enough
  user-facing skills that discovery becomes a real problem.
- Docs-site publishing pipeline — the ported `docs/` content stays as internal
  guides, not published externally.
