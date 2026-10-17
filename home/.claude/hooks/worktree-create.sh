#!/usr/bin/env bash
# WorktreeCreate: Claude Code's own location, made by git cow so build output is cloned, not rebuilt.
# Claude Code reads all of stdout as the worktree path, so git's own output goes to stderr
set -euo pipefail
in=$(cat)
name=$(jq -r '.name // .worktree_name' <<<"$in")
cwd=$(jq -r '.cwd' <<<"$in")
# the main checkout, also when the session already sits in a worktree
common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)
base=$(dirname "$common")
path="$base/.claude/worktrees/$name"
cd "$base"
ref=HEAD
git rev-parse -q --verify origin/HEAD >/dev/null && ref=origin/HEAD
if command -v git-cow >/dev/null; then
  git cow add -b "worktree-$name" "$path" "$ref" >&2
else
  git worktree add -b "worktree-$name" "$path" "$ref" >&2
fi
echo "$path"
