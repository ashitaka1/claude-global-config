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

1. Creates a new branch named `feature/<feature-name>`
2. Switches to that branch
3. Launches `/feature-dev:feature-dev` for guided development

## Example

```
/start-feature user-authentication
```

This creates `feature/user-authentication` and enters the feature-dev workflow.

## Implementation

When invoked with `$ARGUMENTS`:

1. Create and switch to the branch:
   ```bash
   git checkout -b feature/$ARGUMENTS
   ```

2. Immediately invoke the feature-dev skill:
   ```
   /feature-dev:feature-dev
   ```

This ensures a seamless workflow: branch creation → guided development without manual steps between.

## Notes

- Follows project branching conventions (feature/ prefix)
- For bug fixes, use `feature/fix-<description>` or manually create `fix/<description>` branches
- The feature-dev workflow will handle planning, architecture, implementation, and testing
