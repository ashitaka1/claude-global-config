---
name: next
description: Propose the next ready issue across the repos in an issue-tracked project's Tracking line. Use when deciding what to work on next.
---

Propose one ready issue to work on: an open issue with no open blocker.

## Usage

```
/next
```

## Steps

1. Read the `Tracking: GitHub issues (...)` line from the project CLAUDE.md. Without one, say the project is not issue-tracked and stop.

2. Search the tracked repos for ready issues. Join the repos with `OR`; several `repo:` qualifiers without it match nothing. The advanced engine is required, since the plain search ignores `is:blocked` and returns every issue:
   ```bash
   gh api -X GET search/issues --paginate -f advanced_search=true -f per_page=100 \
     -f q='(repo:<owner>/<repo> OR repo:<owner>/<repo>) is:issue is:open -is:blocked' \
     --jq '.items[] | "\(.repository_url | split("/") | .[-2:] | join("/"))#\(.number)\t\(.milestone.title // "-")\t\(.assignee.login // "-")\t\(.title)"'
   ```

3. Find the issues in the current repo that wait on another repo:
   ```bash
   gh api -X GET search/issues --paginate -f advanced_search=true -f per_page=100 \
     -f q='repo:<owner>/<this-repo> is:issue is:open is:blocked' --jq '.items[].number'
   gh api repos/<owner>/<this-repo>/issues/<n>/dependencies/blocked_by \
     --jq '.[] | select(.state == "open") | "\(.repository_url | split("/") | .[-2:] | join("/"))#\(.number)"'
   ```
   A ready issue in another repo that appears among these blockers unblocks work here.

4. Pick, in order: a ready issue in the current repo; a ready issue in another repo that unblocks one here. Skip issues assigned to someone else.

5. Show the ready list grouped by milestone, then propose the pick in one line: repo, number, title, and its milestone's `Check:` line. For a pick in another repo, name the issue here it unblocks; the user may open a session in that repo instead. Wait for the user to confirm or choose another.

6. On confirmation, assign it:
   ```bash
   gh issue edit <n> -R <owner>/<repo> --add-assignee @me
   ```
   In a `claude -w` session, assign it through the GitHub MCP tool `issue_write` (`method: update`, `assignees`).
