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
3. Leave the worktree, when the session is in one
4. If the `merge` argument is present, merge the branch into main
5. If the `main` argument is present, push main to the origin
6. If the `clean` argument is present, delete the branch, and the worktree when there was one

Step 1 leaves `.claude/test-proposals/<branch>.md` alone. The test workflow writes it into the worktree and it is never committed.

## Leaving the worktree comes before merging

A worktree-isolated session cannot merge. Redirecting git at the primary checkout with `-C` is refused by the harness, and `git switch main` inside the worktree fails because the primary checkout already has main checked out. A session that came from `/start-feature` has to return to the primary checkout first.

Call `ExitWorktree` with `action: "keep"`, whenever `merge` or `clean` is present. The session returns to the primary checkout with the worktree and its branch intact, and the merge then runs as ordinary git. Say that the session moved; it changes where every later command runs.

Never `action: "remove"` here. It refuses while the commits have reached no other branch, which is always true before the merge, and it tracks the branch name `EnterWorktree` created rather than the one `/start-feature` renamed to.

## Cleanup

`clean` runs from the primary checkout, after the merge, with plain git:

```bash
git worktree remove --force .claude/worktrees/<dir>
git worktree prune
git branch -d <branch>
```

`--force` covers the `.claude/test-proposals/` file left behind by design. Look at what the worktree holds before using it — anything beyond that file is unexpected, so stop and ask.

`git branch -d` refuses an unmerged branch. A refusal means the merge did not happen; report that rather than reaching for `-D`.

## When a step is refused

Stop and report which step failed and what the refusal said. Do not improvise a route around it — a workflow that silently takes a different path is worse than one that halts.
