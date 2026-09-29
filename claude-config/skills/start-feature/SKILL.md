---
name: start-feature
description: Create and switch to a new feature branch, then begin guided feature development
disable-model-invocation: false
argument-hint: feature-name
---

Create a new feature branch and immediately enter guided feature development.

## Usage

```
/start-feature [fix] <feature-name>
```

## What it does

1. Creates a git worktree on a branch following the project's naming conventions (default: `<user>/feature-<name>` or `<user>/fix-<name>`) and moves the session into it
2. Switches to that branch/tree
3. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `youruser/feature-user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Create the worktree and move this session into it.

   **Check project CLAUDE.md first** for branch naming conventions. If there are none, use this default format:
   - `<user>/feature-<label>` for features
   - `<user>/fix-<label>` for bug fixes if the `fix` argument is present

   Where `<user>` is the user's github username.

   Call `EnterWorktree` with `name` set to that branch name. The session's working directory moves into the worktree, so every later command runs there with plain `git`.

   Confirm the branch matches the convention, and rename it if the tool derived something else:

   ```bash
   git branch --show-current
   git branch -m <user>/feature-$ARGUMENTS
   ```

2. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

This ensures a seamless workflow: worktree creation → guided development without manual steps between.

## Notes

- Always check project CLAUDE.md for specific branch naming conventions first
- `EnterWorktree` places worktrees in `.claude/worktrees/` (already in `.gitignore`)
- The `worktree.baseRef` setting decides what the branch forks from: `fresh` (the default) uses `origin/<default-branch>`, `head` uses local HEAD
- `/end-feature clean` leaves the worktree via `ExitWorktree`
- The feature-dev workflow will handle planning, architecture, implementation, and testing
