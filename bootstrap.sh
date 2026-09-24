#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

REPO_URL=${REPO_URL:-}
REPO_BRANCH=${REPO_BRANCH:-main}
SOURCE_DIR=${SOURCE_DIR:-/opt/infra-bootstrap-src}
TARGET_SCRIPT=${TARGET_SCRIPT:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

git_auth_args=()
if [[ -n $GITHUB_TOKEN ]]; then
  git_auth_args=(-c "http.extraHeader=Authorization: Bearer $GITHUB_TOKEN")
fi

clone_or_update_repo() {
  if [[ -d $SOURCE_DIR/.git ]]; then
    git "${git_auth_args[@]}" -C "$SOURCE_DIR" fetch origin "$REPO_BRANCH"
    git -C "$SOURCE_DIR" checkout --quiet "$REPO_BRANCH"
    git "${git_auth_args[@]}" -C "$SOURCE_DIR" pull --ff-only origin "$REPO_BRANCH"
  else
    if [[ -e $SOURCE_DIR ]]; then
      die "source path exists and is not a git repository: $SOURCE_DIR"
    fi
    git "${git_auth_args[@]}" clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$SOURCE_DIR"
  fi
}

run_target_script() {
  local script="$SOURCE_DIR/$TARGET_SCRIPT"
  [[ -x $script ]] || die "target script is not executable: $script"
  "$script" "$@"
}

main() {
  [[ $EUID -eq 0 ]] || die 'run as root'
  [[ -n $REPO_URL ]] || die 'REPO_URL is required'
  [[ -n $TARGET_SCRIPT ]] || die 'TARGET_SCRIPT is required'
  clone_or_update_repo
  run_target_script "$@"
}

main "$@"
