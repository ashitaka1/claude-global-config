#!/bin/bash
# worktree-git: run git commands from a worktree directory.
# Usage: worktree-git.sh <worktree-path> <git-args...>
#
# Spawned agents cannot persist `cd` between Bash tool calls, and
# `cd <dir> && git` / `git -C` trigger security prompts. This script
# encapsulates the cd+git pattern so agents can commit from worktrees.
set -euo pipefail

worktree="$1"
shift

if [[ ! -d "$worktree" ]]; then
    echo "error: worktree directory does not exist: $worktree" >&2
    exit 1
fi

cd "$worktree"
exec git "$@"
