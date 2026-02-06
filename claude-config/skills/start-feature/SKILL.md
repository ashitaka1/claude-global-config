---
name: start-feature
description: Create and switch to a new feature branch, then begin guided feature development
disable-model-invocation: true
---

Create a new feature branch and immediately enter guided feature development.

## Usage

```
/start-feature <feature-name>
```

## What it does

1. Creates a new branch following the project's branch naming conventions (default: `<user>/feature-<name>`)
2. Switches to that branch
3. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `youruser/feature-user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Create and switch to the branch following the project's branch naming conventions:

   **Check project CLAUDE.md first** for branch naming conventions. If there are none, use this default format:
   - `<user>/feature-<label>` for features
   - `<user>/fix-<label>` for bug fixes

   Where `<user>` is the user's github username.

   Example command (using default format):
   ```bash
   git checkout -b <user>/feature-$ARGUMENTS
   ```

2. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

This ensures a seamless workflow: branch creation → guided development without manual steps between.

## Notes

- Always check project CLAUDE.md for specific branch naming conventions first
- The feature-dev workflow will handle planning, architecture, implementation, and testing
