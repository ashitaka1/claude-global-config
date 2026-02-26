---
name: end-feature
description: Commit code and clean up
disable-model-invocation: false
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
5. If the `clean` argument is present, clean up the current worktree and branch
