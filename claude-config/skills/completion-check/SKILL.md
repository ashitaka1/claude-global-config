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

1. **Rebased** — Rebase the branch onto the latest main.

2. **Tests passing** — Run the project's specified test command and verify all tests pass.

3. **Documentation updated** — Invoke the documentation skills **in parallel** as appropriate:
   - `/update-readme` — if user-facing changes were made
   - `/update-project-spec` — if technical/architectural changes were made
   - `/update-changelog` — if changes affect users/contributors
   - `/update-claude-md` — if workflow, commands, or gotchas changed

4. **Milestone checks** — List any milestone whose check the owner hasn't confirmed.

5. **Commit** — Stage and commit any documentation changes made by the previous steps.

6. **Delete the test plan** — Remove the approved test plan saved for Phase 2.

## Implementation

When invoked:

1. Determine the current branch and project root. Verify we are NOT on main, unless the user supplied `!onmain` this session.

   Off main, rebase the branch onto the latest main so it merges by fast-forward:
   ```bash
   git fetch origin
   git rebase --autostash origin/main
   ```
   Without an `origin` remote, rebase onto local `main`. If the rebase stops on a conflict, run `git rebase --abort`, stop, and ask the user whether to resolve the conflicts in the rebase or merge with a merge commit. If the branch has an upstream, report that its next push needs `--force-with-lease`.

2. Run the project's test command (check project CLAUDE.md for the test command). If tests fail, stop and report.

3. Identify what changed on this branch vs main:
   ```bash
   git diff main...HEAD --stat
   ```
   On main, compare against `origin/main` instead.

4. Based on the changes, invoke the appropriate documentation skills with the Skill tool, all in one message so they run in parallel. Each forks into its own context and returns when done.
   - `update-readme` if there are user-facing changes
   - `update-project-spec` if there are architectural or technical changes
   - `update-changelog` if there are user/contributor-facing changes
   - `update-claude-md` if workflow, commands, or gotchas changed

5. List in the final report any open milestone whose check the owner hasn't confirmed. Read the milestones from `project_spec.md`, or, when the project CLAUDE.md contains a `Tracking: GitHub issues (...)` line, from GitHub, for each repo the line names:
   ```bash
   gh api "repos/<owner>/<repo>/milestones?state=open" --jq '.[] | "\(.title)\t\(.open_issues) open\t\(.description)"'
   ```
   List same-titled milestones from different repos together, with each repo's open-issue count.

   In an issue-tracked project, also list the issues this branch's commits close, in this repo or another (`git log main..HEAD -E --grep='Closes ([^ ]+/[^ ]+)?#'`), and the issues `update-project-spec` left for the owner to close.

6. Stage and commit any changes from documentation updates. Write the message per **Writing → Commit messages**.

7. Delete the approved test plan, if one exists:
   ```bash
   rm -f "$(git rev-parse --show-toplevel)/.claude/test-proposals/<branch-name>.md"
   ```
   with `/` in the branch name replaced by `-`.

8. Report the final status: tests passing, docs updated, branch ready.
