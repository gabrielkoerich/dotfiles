#!/usr/bin/env bash
# WorktreeRemove: Claude Code has already confirmed discarding changes, so the removal is forced.
# Its worktree-* branch goes only when merged, -d refuses otherwise
set -euo pipefail
wt=$(jq -r .worktree_path)
common=$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)
branch=$(git -C "$wt" branch --show-current)
git --git-dir="$common" worktree remove --force "$wt" >&2
case "$branch" in
  worktree-*) git --git-dir="$common" branch -d "$branch" >&2 || true ;;
esac
