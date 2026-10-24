---
name: end-feature
description: Commit code and clean up
disable-model-invocation: true
argument-hint: [push] [merge] [main] [clean]
---

Commit code and clean up after a feature or fix branch, optionally merging to main and/or pushing.

## Usage

```
/end-feature [push] [merge] [main] [clean]
```

## What it does

1. Commit the current working directory
2. If the `push` or `merge` argument is present, rebase the branch onto the latest main
3. If the `push` argument is present, push the branch to the remote
4. If the `merge` argument is present, switch to main, update it, and fast-forward it to the branch
5. If the `main` argument is present, push main to the origin
6. If the `clean` argument is present, delete the branch

## Rebasing

```bash
git fetch origin
git rebase origin/main
```

Without an `origin` remote, rebase onto local `main`. If the rebase stops on a conflict, run `git rebase --abort`, stop, and ask the user whether to resolve the conflicts in the rebase or merge with a merge commit.

If the rebase moved the branch, run the project's test command again and stop on a failure.

## Pushing

```bash
git push --force-with-lease -u origin <branch>
```

## Merging

```bash
git switch main
git pull --ff-only
git merge --ff-only <branch>
```

Skip `git pull` when main has no upstream. If `git merge --ff-only` refuses, run `git fetch origin`. When `origin/main` moved since the rebase, switch back to the branch and return to the rebase step. When it did not, local main holds commits `origin` lacks: stop and report them. Run a plain `git merge <branch>` only when the user has chosen a merge commit over resolving rebase conflicts.

## Cleanup

`clean` runs after the merge:

```bash
git branch -d <branch>
```

`git branch -d` refuses an unmerged branch. A refusal means the merge did not happen; report that rather than reaching for `-D`.

## Sessions started with `claude -w`

The session runs in a worktree, and `git switch main` there fails because the primary checkout has main checked out. Rebase and push from the worktree. Then, whenever `merge` or `clean` is present, call `ExitWorktree` with `action: "keep"`; the session returns to the primary checkout with the worktree and branch intact. Say that the session moved. A return to the rebase step from there runs in the worktree: `git -C .claude/worktrees/<name> rebase origin/main`. After the merge, `clean` also removes the worktree:

```bash
git worktree remove .claude/worktrees/<name>
git branch -d <branch>
```

`git worktree remove` refuses a worktree holding modified or untracked files. Step 1 committed everything, so a refusal means something unexpected is there; stop and ask.

## When a step is refused

Stop and report which step failed and what the refusal said. Do not improvise a route around it — a workflow that silently takes a different path is worse than one that halts.
