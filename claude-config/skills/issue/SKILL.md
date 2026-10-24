---
name: issue
description: Create an issue in one of an issue-tracked project's repos, with its milestone, blocked-by links, and parent, and add it to the project's GitHub Project.
argument-hint: <repo> "<title>" ["<body>"] [--milestone <title>] [--blocked-by <refs>] [--parent <ref>]
---

Create an issue that `/next` in any of the project's repos will see.

## Usage

```
/issue ascension-gamestate "Publish pylon positions" "Add pylon positions to the state snapshot." --milestone Fielded --blocked-by ascension-ios-app#31
```

## Steps

1. Read the `Tracking: GitHub issues (...)` line from the project CLAUDE.md. The repo must be one it names. The optional `project <owner>/<number>` part names the Project, and the optional `auto-add` part lists the repos whose issues the Project adds by itself.

2. Choose the repo whose code the work concerns. Work that a change in one repo causes in another is an issue in the repo that has to do the work, blocked by or blocking the issue that caused it.

3. Check the inputs:
   - The milestone exists in that repo: `gh api "repos/<owner>/<repo>/milestones?state=open" --jq '.[].title'`. If it exists only in another tracked repo, offer to create it here with the same title and `Check:` line.
   - Each blocker and the parent exist. Refs are `#<n>` for this repo or `<repo>#<n>` for another tracked repo.
   - For a question or debt issue, use the type (`Question`, `Tech debt`) in an organization's repo and the label (`question`, `tech-debt`) in a personal account's, and create a missing one, as `update-project-spec` describes.

4. Create the issue, with the parent if given:
   ```bash
   gh issue create -R <owner>/<repo> --title "<title>" --body "<body>" --milestone "<milestone>" [--type "<type>" | --label <label>] [--parent <parent URL>]
   ```

5. Link each blocker, giving the issue URL for a blocker in another repo:
   ```bash
   gh issue edit <n> -R <owner>/<repo> --add-blocked-by <blocker number or URL>
   ```

6. Add the issue to the Project, unless the Tracking line lists its repo after `auto-add`. Without a `project` part, skip this step.
   ```bash
   gh project item-add <number> --owner <owner> --url <issue URL>
   ```

7. Report the issue URL, its links, and whether `/next` would list it as ready.

## Sessions started with `claude -w`

Claude Code refuses `gh` writes there. Create the issue through the GitHub MCP tool `issue_write` (`method: create`, with `milestone` as the milestone's number, and `parent_issue_number` with `parent_owner`/`parent_repo` for a parent in another repo). Write the link and Project-add commands from steps 5 and 6 to a file in the scratchpad and give them to the user to run outside Claude Code.
