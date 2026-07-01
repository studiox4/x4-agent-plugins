# Updating the wiki from a PR

This is the workflow for the second command: deciding which wiki pages a PR affects, drafting the edits, and pushing them only after the user has seen and approved a diff. Read this file in full before running any of the three steps below — don't skip straight to the scripts.

**Why there's a human-review step:** generating documentation edits from a diff is a judgment call, not a deterministic transform. A script that silently rewrites wiki pages based on an LLM's read of a diff is exactly the kind of thing that can quietly ship wrong information to everyone who reads the wiki afterward. So this workflow always stops for confirmation before anything gets pushed, even when it's you (Claude) running the whole thing unattended in a longer task — surface the proposed diff in the conversation and wait for an explicit go-ahead before calling `apply_wiki_updates.sh`.

## Step 1 — Gather context (read-only)

```bash
scripts/gather_pr_context.sh OWNER/REPO PR_NUMBER
```

This clones the current wiki and fetches the PR's diff and metadata into a temp directory. It makes no changes to GitHub — safe to run any time, including just to see what's in there. It prints two lines you need to capture:

```
CONTEXT_DIR=/tmp/xxxxxx
WIKI_DIR=/tmp/xxxxxx/wiki
```

Read `$CONTEXT_DIR/pr_meta.json` (title, body, changed files with add/delete counts) and `$CONTEXT_DIR/pr_diff.patch` (the actual diff). Then read every `.md` file currently in `$WIKI_DIR` — all of them, not just the ones with obviously-matching names. Pages are often about a concept, not a file path, so a change to `src/auth/oauth.py` might matter to a page called `Authentication.md` OR a section inside `Architecture.md` with no "auth" in its filename at all.

If the wiki has never been initialized (the script will warn you), stop here and tell the user to run `bootstrap_wiki.sh` first — there's nothing to update yet.

## Step 2 — Decide what's impacted, and draft it

For each wiki page, ask: does anything in this diff change a fact this page currently states, or make a page's silence on a topic newly wrong? Concretely:

- A changed function signature, config option, CLI flag, endpoint, or environment variable that a page documents → that page needs an edit.
- A changed file that a page's code sample references or imports → check the sample still works.
- A new feature with no corresponding page → this is worth flagging to the user as a *possible new page*, but don't create one unprompted; ask first.
- Pure refactors, formatting, dependency bumps, test-only changes → usually no wiki impact. Say so plainly rather than forcing an edit to look useful.

If nothing is impacted, tell the user that directly — "PR #482 doesn't look like it touches anything the wiki documents" is a completely valid, useful outcome. Don't manufacture busywork edits.

For pages that do need changes:
- Edit the files directly inside `$WIKI_DIR` using your normal file-editing tools (str_replace or equivalent) — there's no script for this part, because the content is the part that needs your judgment, not automation.
- Make the smallest edit that keeps the page accurate. Don't rewrite a whole page because one paragraph is stale.
- If you're inferring behavior from the diff rather than reading it explicitly stated somewhere (PR description, code comments), say so to the user rather than stating it as fact in the wiki page. Wiki readers will trust what's written; don't launder a guess into something that reads as verified.
- Never invent explanatory content to fill `FAQ.md` — only add an FAQ entry if the PR's diff or description actually surfaces a question worth pre-answering.

## Step 3 — Show the diff, get confirmation, then push

Before running anything else, summarize in the conversation which pages you propose to touch and why, in plain language — not a raw diff dump first. Something like:

> PR #482 changed the OAuth token refresh logic. I'd update:
> - `Architecture.md` — the "Auth" section describes the old refresh interval
> - `FAQ.md` — add an entry about the new token expiry behavior since the PR description calls out it's a common support question
>
> Want me to go ahead?

Once the user says yes, run:

```bash
scripts/apply_wiki_updates.sh OWNER/REPO "$WIKI_DIR" "Update wiki for PR #482: OAuth token refresh" --yes
```

Always pass `--yes` when you (Claude) are the one running this — the script's own interactive `[y/N]` prompt is there for a human running it directly at a terminal, not for you, and without `--yes` a non-interactive run will just read no input and safely decline to push. Your confirmation step already happened in the conversation; that's the real gate.

The script shows the staged diff one more time before pushing (useful as your own last sanity check) and reports the live URL of every page it touched. Relay those links back to the user.

## Wiring this to run automatically (optional, more advanced)

Everything above assumes a person asks for this in conversation — "PR #482 merged, check the wiki." If the user wants it to run on every merge without prompting, that means running this same three-step flow from a GitHub Actions workflow on `pull_request: closed` (merged), with an agent harness invoked non-interactively. That's a real option, but it removes the human-in-the-loop confirmation described above — if you're asked to help set that up, make sure the user has thought about whether they want an unattended agent to have push access to their wiki, and consider having the workflow open a PR-style review (e.g., post the proposed diff as a PR comment, or to Slack) rather than pushing straight to `master` unattended.
