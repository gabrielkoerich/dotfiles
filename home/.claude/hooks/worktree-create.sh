#!/usr/bin/env bash
# WorktreeCreate: Claude Code's own location, made by git cow so build output is cloned, not rebuilt.
# Claude Code reads all of stdout as the worktree path, so git's own output goes to stderr
set -euo pipefail
in=$(cat)
name=$(jq -r .worktree_name <<<"$in")
base=$(jq -r .base_worktree_path <<<"$in")
ref=$(jq -r '.target_ref // empty' <<<"$in")
path="$base/.claude/worktrees/$name"
cd "$base"
if command -v git-cow >/dev/null; then
  git cow add -b "worktree-$name" "$path" ${ref:+"$ref"} >&2
else
  git worktree add -b "worktree-$name" "$path" ${ref:+"$ref"} >&2
fi
echo "$path"
