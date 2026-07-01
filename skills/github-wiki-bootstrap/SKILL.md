---
name: github-wiki-bootstrap
description: >
  Sets up and maintains a GitHub repository's wiki entirely from the command
  line, no browser required. Covers two situations - enabling a wiki and
  seeding it with a full starter page set (Home, Sidebar, Footer,
  Getting-Started, Architecture, FAQ) on a repo that doesn't have one yet,
  and checking an existing wiki against a merged or open PR and updating
  whichever pages the PR's changes actually affect. Always use this skill
  whenever the user wants to set up a wiki, enable the wiki, bootstrap wiki
  pages, initialize the wiki, check if the wiki needs updating, update the
  wiki for a PR, sync the wiki with recent changes, or hits the classic
  "repository not found" / "repository not exported" error cloning a
  .wiki.git URL. Also trigger this when the user mentions a PR just merged
  and asks whether docs or the wiki need touching.
---

# GitHub Wiki Bootstrap & Maintenance

Three commands, one shared trick: GitHub wiki repos (`OWNER/REPO.wiki.git`) don't exist until something is pushed to them, and there's no official API to create that first page. Every command here works around that the same way — try a clone, fall back to a local `git init -b master` + direct push when the wiki has never been touched.

## Commands

| Command | Purpose | Writes to GitHub? |
|---|---|---|
| `scripts/bootstrap_wiki.sh OWNER/REPO` | Enable the wiki feature and seed it with a full starter page set | Yes — pushes starter pages |
| `scripts/gather_pr_context.sh OWNER/REPO PR_NUMBER` | Pull a PR's diff/metadata alongside the wiki's current pages, into one place to reason over | No — read-only |
| `scripts/apply_wiki_updates.sh OWNER/REPO WIKI_DIR "message" [--yes]` | Review a diff of pending edits and push them | Yes — only after a diff is shown |

## Setting up a new wiki

```bash
scripts/bootstrap_wiki.sh OWNER/REPO
```

See below for prerequisites. This is safe to re-run on a repo that already has a wiki — it only adds pages that don't already exist and never overwrites existing content.

What it does: enables `has_wiki` via the API, clones-or-inits the wiki repo, fills in `Home.md`, `_Sidebar.md`, `_Footer.md`, `Getting-Started.md`, `Architecture.md`, and `FAQ.md` from `assets/*.md.template` with the repo's real name/description/URL, commits, and pushes to `master` (never `main` — GitHub wiki repos hard-code `master` as their default branch regardless of what the parent repo uses).

The starter pages are honest placeholders, not invented content — encourage the user to fill in `Getting-Started.md`, `Architecture.md`, and `FAQ.md` with real project detail shortly after running this.

## Updating the wiki from a PR

This is a judgment call, not a deterministic script, so it's a three-step flow rather than a single command. **Read `references/updating-from-prs.md` in full before doing this** — it covers how to decide which pages a PR actually impacts, how to draft the edits, and the confirm-before-push step that keeps this from silently shipping wrong information to the wiki. The short version:

1. `scripts/gather_pr_context.sh OWNER/REPO PR_NUMBER` — pulls the PR diff + current wiki pages, read-only.
2. You (Claude) read the diff and the existing pages, decide what's actually impacted, and edit those files directly in the working directory the previous step gave you.
3. Show the user what you propose to change and why, then only after they confirm, `scripts/apply_wiki_updates.sh OWNER/REPO WIKI_DIR "message" --yes`.

Don't skip step 3's confirmation, and don't force an edit if nothing in the PR actually touches what the wiki documents — "nothing to update" is a valid, useful answer.

## Prerequisites (all commands)

All three commands shell out to the GitHub CLI (`gh`). Before running any of them:

```bash
gh auth status
```

If that fails, **stop and tell the user** to run:

```bash
gh auth login
gh auth setup-git
```

`gh auth setup-git` matters specifically — it wires git's credential helper to the `gh` token, which is what lets the plain `git push` inside these scripts succeed without a separate SSH key or PAT. A push failing partway through, after everything else worked, is almost always this step being skipped.

The user also needs **write access** (not just read) to the target repo — wiki pushes follow the same permission as pushing code to the main repo.

## Troubleshooting

- **`gh: command not found`** — install from https://cli.github.com. Don't try to hand-roll the GitHub API calls with raw `curl`; it's not worth reimplementing `gh`'s auth handling.
- **Push fails with an auth error even though `gh auth status` looks fine** — `gh auth setup-git` was never run. Have the user run it, then retry; no need to redo the clone/init step.
- **Script reports "not found" even after retrying `bootstrap_wiki.sh`** — the wiki feature may be disabled by org policy. Check `gh api repos/OWNER/REPO --jq '.has_wiki'`.
- **Changes pushed but nothing shows up on github.com** — confirm the push went to `master`, not `main`. `git branch` inside the wiki working directory should show `master` current.
- **`gather_pr_context.sh` warns the wiki was never initialized** — run `bootstrap_wiki.sh` first, then retry the PR-update flow.
