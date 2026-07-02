#!/usr/bin/env bash
#
# apply_wiki_updates.sh — shows a summary of edits made in a wiki working
# directory (produced by gather_pr_context.sh, then hand-edited), and pushes
# them after confirmation. Only ever touches files that actually changed.
#
# Usage: apply_wiki_updates.sh OWNER/REPO WIKI_DIR "commit message" [--yes]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_wiki_git.sh
source "$SCRIPT_DIR/lib_wiki_git.sh"

if [[ $# -lt 3 || "$1" != */* ]]; then
  die "Usage: $0 OWNER/REPO WIKI_DIR \"commit message\" [--yes]"
fi
OWNER="${1%%/*}"
REPO="${1##*/}"
WIKI_DIR="$2"
COMMIT_MSG="$3"
AUTO_YES=false
[[ "${4:-}" == "--yes" ]] && AUTO_YES=true

[[ -d "$WIKI_DIR/.git" ]] || die "$WIKI_DIR doesn't look like a wiki git working directory (no .git found). Run gather_pr_context.sh first."

wiki_preflight

echo
log "Pending changes in $WIKI_DIR:"
( cd "$WIKI_DIR" && git add -A && git status --porcelain=v1 )

if ( cd "$WIKI_DIR" && git diff --cached --quiet ); then
  log "Nothing staged — no wiki pages were actually edited. Nothing to push."
  exit 0
fi

echo
log "Diff of changes:"
( cd "$WIKI_DIR" && git diff --cached )

if ! $AUTO_YES; then
  echo
  read -r -p "Push these changes to https://github.com/$OWNER/$REPO/wiki ? [y/N] " REPLY
  [[ "$REPLY" =~ ^[Yy]$ ]] || { log "Not pushing. Changes remain staged in $WIKI_DIR if you change your mind."; exit 0; }
fi

if wiki_commit_and_push "$WIKI_DIR" "$COMMIT_MSG"; then
  echo
  log "Pushed. Updated pages:"
  ( cd "$WIKI_DIR" && git show --name-only --pretty=format: HEAD ) | grep -v '^$' | while read -r f; do
    page="${f%.md}"
    echo "  https://github.com/$OWNER/$REPO/wiki/$page"
  done
fi
