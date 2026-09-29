---
name: completion-check
description: Pre-merge/PR checklist for feature branches. Ensures all workflow steps completed before merge.
---

Verify that the current feature branch is ready to merge or to have a PR submitted.

## Usage

```
/completion-check
```

## What it does

Runs through the completion checklist:

1. **Tests passing** — Run the project's specified test command and verify all tests pass.

2. **Documentation updated** — Invoke the documentation skills **in parallel** as appropriate:
   - `/update-readme` — if user-facing changes were made
   - `/update-project-spec` — if technical/architectural changes were made
   - `/update-changelog` — if changes affect users/contributors
   - `/update-claude-md` — if workflow or project status changes

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

4. Based on the changes, invoke the appropriate documentation skills with the Skill tool, all in one message so they run in parallel. Each forks into its own context and returns when done.
   - `update-readme` if there are user-facing changes
   - `update-project-spec` if there are architectural or technical changes
   - `update-changelog` if there are user/contributor-facing changes
   - `update-claude-md` if project status or workflow changed

5. Review the CLAUDE.md "Current Status" section and update it if needed.

6. Stage and commit any changes from documentation updates. Write the message per **Writing → Commit messages**.

7. Report the final status: tests passing, docs updated, branch ready.
