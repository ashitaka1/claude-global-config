#!/usr/bin/env python3
"""
Claude Code PreToolUse hook: blocks git invocations that use
  - cd <dir> && git ...   (chained cd)
  - git -C <dir> ...      (git's built-in directory flag)

Both patterns trigger an unnecessary user-approval prompt.
Instead, the agent should set cwd in the Bash tool's run parameters.
"""

import json
import re
import sys


def check_command(command: str) -> str | None:
    """Return a rejection reason if the command matches a blocked pattern, else None."""

    # Pattern 1: cd <anything> && git ...
    # Catches variants like:
    #   cd /foo && git status
    #   cd /foo/bar && git commit -m "msg"
    #   cd "$DIR" && git push
    if re.search(r'\bcd\s+\S+.*&&\s*git\b', command):
        return (
            "Blocked: do not chain `cd <dir> && git ...`. "
            "For worktree git operations, use: bash ~/.claude/scripts/worktree-git.sh <worktree-path> <git-args>"
        )

    # Pattern 2: git -C <dir> ...
    # Catches:
    #   git -C /some/path status
    #   git -C "$REPO" pull
    if re.search(r'\bgit\s+-C\b', command):
        return (
            "Blocked: do not use `git -C <dir>`. "
            "For worktree git operations, use: bash ~/.claude/scripts/worktree-git.sh <worktree-path> <git-args>"
        )

    return None


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        # Not valid JSON — let it through; not our concern.
        sys.exit(0)

    # Only care about Bash tool calls.
    if payload.get("tool_name") != "Bash":
        sys.exit(0)

    command = payload.get("tool_input", {}).get("command", "")
    reason = check_command(command)

    if reason:
        print(json.dumps({"decision": "block", "reason": reason}))
        sys.exit(0)

    # No match — allow the tool call to proceed.
    sys.exit(0)


if __name__ == "__main__":
    main()
