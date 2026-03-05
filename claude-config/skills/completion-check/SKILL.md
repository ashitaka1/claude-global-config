---
name: completion-check
description: Pre-merge/PR checklist for feature branches. Ensures all workflow steps completed before merge.
disable-model-invocation: false
---

Verify that the current feature branch is ready to merge or to have a PR submitted.

## Usage

```
/completion-check
```

## What it does

Runs through the completion checklist:

1. **Tests passing** — Run the project's specified test command and verify all tests pass.

2. **Documentation updated** — Delegate to documentation agents **in parallel** as appropriate:
   - `readme-updater` — if user-facing changes were made
   - `project-spec-updater` — if technical/architectural changes were made
   - `changelog-updater` — if changes affect users/contributors
   - `claude-md-updater` — if workflow or project status changes

3. **Update project CLAUDE.md** — Ensure "Current Status" section reflects the current state of the project.

4. **Commit** — Stage and commit any documentation/status changes made by the previous steps.

## Implementation

When invoked:

1. Determine the current branch and project root. Verify we are NOT on main.

2. Run the project's test command (check project CLAUDE.md for the test command). If tests fail, stop and report.

3. Identify what changed on this branch vs main:
   ```bash
   git diff main...HEAD --stat
   ```

4. Based on the changes, launch the appropriate documentation agents in parallel using the Agent tool:
   - Use `readme-updater` if there are user-facing changes
   - Use `project-spec-updater` if there are architectural or technical changes
   - Use `changelog-updater` if there are user/contributor-facing changes
   - Use `claude-md-updater` if project status or workflow changed

5. Review the CLAUDE.md "Current Status" section and update it if needed.

6. Stage and commit any changes from documentation updates with an appropriate commit message.

7. Report the final status: tests passing, docs updated, branch ready.
