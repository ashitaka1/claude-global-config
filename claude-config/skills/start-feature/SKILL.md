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

1. Creates a new git worktree with branch following the project's branch naming conventions (default: `<user>/feature-<name>` or `<user>/fix-<name>`) in .worktrees
2. Switches to that branch/tree
3. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `youruser/feature-user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Create a worktree with a new branch following the project's branch naming conventions:

   **Check project CLAUDE.md first** for branch naming conventions. If there are none, use this default format:
   - `<user>/feature-<label>` for features
   - `<user>/fix-<label>` for bug fixes if the `fix` argument is present

   Where `<user>` is the user's github username.

   Example commands (using default format):
   ```bash
   git worktree add .worktrees/<user>-feature-$ARGUMENTS -b <user>/feature-$ARGUMENTS
   cd .worktrees/<user>-feature-$ARGUMENTS
   ```

   The worktree directory name replaces `/` with `-` in the branch name.

2. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

This ensures a seamless workflow: worktree creation → guided development without manual steps between.

## Notes

- Always check project CLAUDE.md for specific branch naming conventions first
- Worktrees are placed in `.worktrees/` (already in `.gitignore`)
- The feature-dev workflow will handle planning, architecture, implementation, and testing
