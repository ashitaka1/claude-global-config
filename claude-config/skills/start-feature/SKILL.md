---
name: start-feature
description: Create and switch to a new feature branch, then begin guided feature development
argument-hint: feature-name
---

Create a new feature branch and immediately enter guided feature development.

## Usage

```
/start-feature [fix] <feature-name>
```

## What it does

1. Creates a git worktree on a branch following the project's naming conventions (default: `<user>/feature-<name>` or `<user>/fix-<name>`) and moves the session into it
2. Ensures the worktree directory is ignored
3. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `youruser/feature-user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Work out the branch name before creating anything.

   **Check project CLAUDE.md first** for branch naming conventions. With none, use:
   - `<user>/fix-<label>` when the `fix` argument is present, or when `$ARGUMENTS` already begins with `fix-`
   - `<user>/feature-<label>` otherwise

   `<user>` is the user's github username. `<label>` is `$ARGUMENTS` with any leading `fix-` removed, so `/start-feature fix-broken-parser` gives `<user>/fix-broken-parser` rather than `<user>/feature-fix-broken-parser`.

2. Create the worktree and move this session into it.

   Call `EnterWorktree` with `name` set to that branch name. The session's working directory moves into the worktree, so every later command runs there with plain `git`.

   `EnterWorktree` derives its own branch name rather than using `name` verbatim: it replaces `/` with `+` and prefixes `worktree-`. Rename the branch to the one worked out in step 1:

   ```bash
   git branch -m <branch-name>
   git branch --show-current
   ```

   After the rename `ExitWorktree` still reports the name it created, which no longer exists. That stays cosmetic because `/end-feature` cleans up with plain git rather than `ExitWorktree remove`.

3. Make sure the worktree directory is ignored.

   Worktrees land under `.claude/worktrees/`. Not every project ignores `.claude/`, and an unignored worktree shows up as untracked in the primary checkout for as long as it exists:

   ```bash
   git check-ignore -q .claude/worktrees || echo '.claude/worktrees/' >> .gitignore
   ```

   Commit that line with the feature's other changes.

4. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

## When a step is refused

Stop and report which step failed and what the refusal said. Do not route around it.

## Notes

- Always check project CLAUDE.md for specific branch naming conventions first
- The `worktree.baseRef` setting decides what the branch forks from: `fresh` (the default) uses `origin/<default-branch>`, `head` uses local HEAD
- A worktree session is isolated: git commands that redirect to the primary checkout are refused. `/end-feature` leaves the worktree before it merges
- The feature-dev workflow will handle planning, architecture, implementation, and testing
