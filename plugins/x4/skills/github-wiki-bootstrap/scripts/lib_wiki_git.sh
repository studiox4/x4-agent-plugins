#!/usr/bin/env bash
# lib_wiki_git.sh — shared helpers for github-wiki-bootstrap's commands.
# Sourced, not executed directly: `source "$(dirname "$0")/lib_wiki_git.sh"`

log()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# Verify gh is installed and authenticated. Exits with a clear message if not.
wiki_preflight() {
  command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) not found. Install it from https://cli.github.com, then run 'gh auth login'."
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login   then: gh auth setup-git   and try again."
}

# Sets REPO_NAME, REPO_URL, REPO_DESC for $1=OWNER $2=REPO
wiki_get_metadata() {
  local owner="$1" repo="$2"
  local json
  json="$(gh api "repos/$owner/$repo")" || die "Could not read repo metadata for $owner/$repo — check the name and your access."
  REPO_NAME="$(echo "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')"
  REPO_URL="$(echo "$json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["html_url"])')"
  REPO_DESC="$(echo "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin).get("description"); print(d if d else "No description set on the repo yet.")')"
}

# Clones the wiki for $1=OWNER $2=REPO into $3=WORKDIR/wiki, or falls back to a
# fresh `git init -b master` if the wiki has never been initialized.
# Sets WIKI_DIR and FRESH_INIT, and leaves the caller's cwd inside WIKI_DIR.
wiki_clone_or_init() {
  local owner="$1" repo="$2" workdir="$3"
  local wiki_url="https://github.com/$owner/$repo.wiki.git"
  WIKI_DIR="$workdir/wiki"
  local clone_log="$workdir/clone.log"

  log "Attempting to clone $wiki_url ..."
  if git clone "$wiki_url" "$WIKI_DIR" >"$clone_log" 2>&1; then
    log "Wiki exists — cloned it."
    cd "$WIKI_DIR"
    git checkout master >/dev/null 2>&1 || git checkout -b master
    FRESH_INIT=false
  elif grep -qiE 'not found|not exported|access denied' "$clone_log"; then
    log "Wiki has never been initialized. Falling back to local init + first push."
    mkdir -p "$WIKI_DIR"
    cd "$WIKI_DIR"
    git init -b master >/dev/null
    git remote add origin "$wiki_url"
    FRESH_INIT=true
  else
    cat "$clone_log" >&2
    die "Clone failed for a reason other than 'wiki never initialized' — see output above."
  fi
}

# Commits everything staged/modified under $1=WIKI_DIR with message $2, and
# pushes to origin master. No-op (returns 1) if there's nothing to commit.
wiki_commit_and_push() {
  local wiki_dir="$1" message="$2"
  ( cd "$wiki_dir" && git add -A )
  if ( cd "$wiki_dir" && git diff --cached --quiet ); then
    log "Nothing to commit."
    return 1
  fi
  ( cd "$wiki_dir" \
      && git -c user.name="${GIT_AUTHOR_NAME:-github-wiki-bootstrap}" \
             -c user.email="${GIT_AUTHOR_EMAIL:-noreply@example.com}" \
             commit -m "$message" >/dev/null )
  log "Pushing to origin master ..."
  ( cd "$wiki_dir" && git push origin master ) \
    || die "Push failed. If this is an auth error, run 'gh auth setup-git' and retry."
  return 0
}
