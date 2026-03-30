#!/usr/bin/env python3
"""
Claude Code PreToolUse hook: blocks Edit/Write on the main branch.

Resolves the git branch from the target file's directory, not CWD.
This correctly handles worktree edits where the file is under
.worktrees/<branch>/ but CWD is the main repo on main.
"""

import json
import os
import subprocess
import sys


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    file_path = payload.get("tool_input", {}).get("file_path", "")
    if not file_path:
        sys.exit(0)

    file_dir = os.path.dirname(file_path)
    if not os.path.isdir(file_dir):
        sys.exit(0)

    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=file_dir,
        )
        branch = result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        sys.exit(0)

    if branch == "main":
        print(json.dumps({
            "decision": "block",
            "reason": "BLOCKED: You tried to work on main. Use proper development protocol.",
        }))
        sys.exit(0)

    sys.exit(0)


if __name__ == "__main__":
    main()
