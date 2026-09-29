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
3. If the `merge` argument is present, merge the branch into main
4. If the `main` argument is present, push main to the origin
5. If the `clean` argument is present, delete the branch, and the worktree when there is one

## Cleanup

A feature branch may or may not have a worktree behind it, so `clean` covers two cases.

**In a worktree** — `/start-feature` put the session there with `EnterWorktree`. Call `ExitWorktree`. `action: "remove"` deletes the worktree and its branch together; use `action: "keep"` when `merge` was not requested, so the work survives.

`remove` refuses a worktree holding uncommitted files, or commits that reached no other branch. Report what it names and ask before passing `discard_changes`.

**On a plain branch** — the branch came from `git switch -c`, and `ExitWorktree` reports a no-op. Switch to main and run `git branch -d <branch>`, which refuses anything unmerged.
