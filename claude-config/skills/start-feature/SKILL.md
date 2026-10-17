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

1. Creates and switches to a branch following the project's naming conventions (default: `<user>/feature-<name>` or `<user>/fix-<name>`)
2. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `youruser/feature-user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Work out the branch name.

   **Check project CLAUDE.md first** for branch naming conventions. With none, use:
   - `<user>/fix-<label>` when the `fix` argument is present, or when `$ARGUMENTS` already begins with `fix-`
   - `<user>/feature-<label>` otherwise

   `<user>` is the user's github username. `<label>` is `$ARGUMENTS` with any leading `fix-` removed, so `/start-feature fix-broken-parser` gives `<user>/fix-broken-parser` rather than `<user>/feature-fix-broken-parser`.

2. Create the branch from the current HEAD and switch to it:

   ```bash
   git switch -c <branch-name>
   ```

   Uncommitted changes come along onto the new branch.

3. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

## When a step is refused

Stop and report which step failed and what the refusal said. Do not route around it.

## Notes

- Always check project CLAUDE.md for specific branch naming conventions first
- A second session working in the same repo at the same time starts with `claude -w <name>`, which gives it its own worktree
- The feature-dev workflow will handle planning, architecture, implementation, and testing
