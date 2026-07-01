#!/usr/bin/env bash
#
# bootstrap_wiki.sh — enable a GitHub repo's wiki and seed it with starter pages.
# Usage: bootstrap_wiki.sh OWNER/REPO
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"
# shellcheck source=lib_wiki_git.sh
source "$SCRIPT_DIR/lib_wiki_git.sh"

if [[ $# -ne 1 || "$1" != */* ]]; then
  die "Usage: $0 OWNER/REPO   (example: $0 corban-gmr/orchestrate)"
fi
OWNER="${1%%/*}"
REPO="${1##*/}"

wiki_preflight
log "Authenticated as $(gh api user --jq '.login' 2>/dev/null || echo '(unknown user)')"

log "Enabling wiki on $OWNER/$REPO ..."
gh api "repos/$OWNER/$REPO" -X PATCH -f has_wiki=true >/dev/null \
  || die "Could not enable the wiki. Check admin access and org wiki policy."

wiki_get_metadata "$OWNER" "$REPO"
TODAY="$(date +%Y-%m-%d)"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
wiki_clone_or_init "$OWNER" "$REPO" "$WORKDIR"

fill_template() {
  sed \
    -e "s|{{REPO_NAME}}|$REPO_NAME|g" \
    -e "s|{{REPO_URL}}|$REPO_URL|g" \
    -e "s|{{REPO_DESC}}|$REPO_DESC|g" \
    -e "s|{{DATE}}|$TODAY|g" \
    "$1" > "$2"
}

ADDED_ANY=false
for template in "$ASSETS_DIR"/*.md.template; do
  filename="$(basename "$template" .template)"
  if [[ -f "$WIKI_DIR/$filename" ]]; then
    log "Skipping $filename (already exists)"
    continue
  fi
  fill_template "$template" "$WIKI_DIR/$filename"
  log "Added $filename"
  ADDED_ANY=true
done

wiki_commit_and_push "$WIKI_DIR" "Bootstrap wiki starter pages" || true

echo
log "Done. Wiki is live at: https://github.com/$OWNER/$REPO/wiki"
if $ADDED_ANY; then
  log "Fill in Getting-Started.md, Architecture.md, and FAQ.md with real project content next."
fi
