---
name: next
description: Propose what to work on next — a ready issue across an issue-tracked project's repos, or the next open milestone in project_spec.md. Use when deciding what to work on next.
---

Propose one ready issue to work on: an open issue with no open blocker.

## Usage

```
/next
```

## Steps

1. Read the `Tracking: GitHub issues (...)` line from the project CLAUDE.md. Without one, the project keeps its state in `project_spec.md`; follow **Projects without a Tracking line** below instead.

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

## Projects without a Tracking line

1. Read `project_spec.md` § Milestones. The open milestones are the ones marked ⏳; their order in the list is the intended order. A milestone marked 🔎 is built and waits only on the owner's check: list it as waiting, and do not propose it. Without a `project_spec.md`, say there is no recorded work to pick from and stop.
2. Read § Technical Debt and § Open Questions for items that block an open milestone.
3. Propose the first open milestone in one line: its number, name, and check. Name any debt or question that has to be settled first. Wait for the user to confirm or choose another.
