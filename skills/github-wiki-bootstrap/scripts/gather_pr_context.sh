#!/usr/bin/env bash
#
# gather_pr_context.sh — read-only. Pulls a PR's diff + metadata and the
# current wiki pages into one temp directory so an agent can decide which
# pages a PR should update. Makes no writes to GitHub.
#
# Usage: gather_pr_context.sh OWNER/REPO PR_NUMBER
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_wiki_git.sh
source "$SCRIPT_DIR/lib_wiki_git.sh"

if [[ $# -ne 2 || "$1" != */* ]]; then
  die "Usage: $0 OWNER/REPO PR_NUMBER   (example: $0 corban-gmr/orchestrate 482)"
fi
OWNER="${1%%/*}"
REPO="${1##*/}"
PR_NUMBER="$2"

wiki_preflight

WORKDIR="$(mktemp -d)"
log "Working directory: $WORKDIR"

log "Fetching PR #$PR_NUMBER metadata ..."
gh pr view "$PR_NUMBER" --repo "$OWNER/$REPO" \
  --json number,title,body,url,mergedAt,files,additions,deletions \
  > "$WORKDIR/pr_meta.json" \
  || die "Could not fetch PR #$PR_NUMBER on $OWNER/$REPO. Check the number and your access."

log "Fetching PR diff ..."
gh pr diff "$PR_NUMBER" --repo "$OWNER/$REPO" > "$WORKDIR/pr_diff.patch" 2>/dev/null || true

log "Cloning current wiki (read-only — no changes will be pushed by this script) ..."
wiki_clone_or_init "$OWNER" "$REPO" "$WORKDIR"
if [[ "${FRESH_INIT:-false}" == "true" ]]; then
  warn "This repo's wiki has never been initialized — there's nothing to update yet."
  warn "Run bootstrap_wiki.sh $OWNER/$REPO first, then re-run this."
fi

echo
log "Changed files in PR #$PR_NUMBER:"
python3 -c '
import json
with open("'"$WORKDIR"'/pr_meta.json") as f:
    meta = json.load(f)
for fobj in meta.get("files", []):
    print(f"  {fobj[\"path\"]}  (+{fobj[\"additions\"]}/-{fobj[\"deletions\"]})")
'

echo
log "Existing wiki pages:"
find "$WIKI_DIR" -maxdepth 1 -name '*.md' -printf '  %f\n' 2>/dev/null \
  || find "$WIKI_DIR" -maxdepth 1 -name '*.md' -exec basename {} \; | sed 's/^/  /'

echo
echo "CONTEXT_DIR=$WORKDIR"
echo "WIKI_DIR=$WIKI_DIR"
echo
log "Next: read $WORKDIR/pr_meta.json and $WORKDIR/pr_diff.patch, compare against the"
log "pages in $WIKI_DIR, edit whichever pages the PR actually affects directly in"
log "$WIKI_DIR, then run apply_wiki_updates.sh to review and push."
