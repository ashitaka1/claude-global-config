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
2. If the `push` argument is present, push the branch to the remote
3. If the `merge` argument is present, switch to main and merge the branch
4. If the `main` argument is present, push main to the origin
5. If the `clean` argument is present, delete the branch

## Merging

```bash
git switch main
git merge <branch>
```

## Cleanup

`clean` runs after the merge:

```bash
git branch -d <branch>
```

`git branch -d` refuses an unmerged branch. A refusal means the merge did not happen; report that rather than reaching for `-D`.

## Sessions started with `claude -w`

The session runs in a worktree, and `git switch main` there fails because the primary checkout has main checked out. Whenever `merge` or `clean` is present, first call `ExitWorktree` with `action: "keep"`; the session returns to the primary checkout with the worktree and branch intact. Say that the session moved. After the merge, `clean` also removes the worktree:

```bash
git worktree remove .claude/worktrees/<name>
git branch -d <branch>
```

`git worktree remove` refuses a worktree holding modified or untracked files. Step 1 committed everything, so a refusal means something unexpected is there; stop and ask.

## When a step is refused

Stop and report which step failed and what the refusal said. Do not improvise a route around it — a workflow that silently takes a different path is worse than one that halts.
