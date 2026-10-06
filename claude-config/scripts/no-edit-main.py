#!/usr/bin/env python3
"""
Claude Code hook: blocks Edit/Write on the main branch.

PreToolUse: resolves the git branch from the target file's directory, not CWD.
This correctly handles worktree edits where the file is under
.worktrees/<branch>/ but CWD is the main repo on main.

UserPromptSubmit: a prompt containing ESCAPE_TOKEN lifts the block for the
rest of its session.
"""

import json
import os
import re
import subprocess
import sys
import tempfile

ESCAPE_TOKEN = "!onmain"
ESCAPE_DIR = os.path.join(tempfile.gettempdir(), "claude-onmain")


def escape_marker(session_id: str) -> str | None:
    if not re.fullmatch(r"[A-Za-z0-9_-]+", session_id or ""):
        return None
    return os.path.join(ESCAPE_DIR, session_id)


def record_escape(payload: dict) -> None:
    if ESCAPE_TOKEN not in payload.get("prompt", ""):
        return
    marker = escape_marker(payload.get("session_id", ""))
    if marker is None:
        return
    os.makedirs(ESCAPE_DIR, exist_ok=True)
    open(marker, "a").close()
    print(f"The user supplied {ESCAPE_TOKEN}: for the rest of this session, "
          "editing and committing on main is allowed.")


def escaped(payload: dict) -> bool:
    marker = escape_marker(payload.get("session_id", ""))
    return marker is not None and os.path.exists(marker)


def check_edit(payload: dict) -> None:
    file_path = payload.get("tool_input", {}).get("file_path", "")
    if not file_path:
        return

    file_dir = os.path.dirname(file_path)
    if not os.path.isdir(file_dir):
        return

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
        return

    if branch != "main" or escaped(payload):
        return

    # A gitignored file cannot become a commit, so editing one on main does not
    # put work on main. Scratch notes and .claude/test-proposals/ land here.
    try:
        ignored = subprocess.run(
            ["git", "check-ignore", "-q", file_path],
            capture_output=True,
            timeout=5,
            cwd=file_dir,
        ).returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        ignored = False

    if ignored:
        return

    print(json.dumps({
        "decision": "block",
        "reason": "BLOCKED: You tried to work on main. Use proper development protocol.",
    }))


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    if payload.get("hook_event_name") == "UserPromptSubmit":
        record_escape(payload)
    else:
        check_edit(payload)
    sys.exit(0)


if __name__ == "__main__":
    main()
