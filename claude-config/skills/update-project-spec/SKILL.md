---
name: update-project-spec
description: Updates project_spec.md with technical decisions, architecture changes, and project status, or files that status as GitHub issues in issue-tracked projects. Use when features complete or architecture evolves.
context: fork
background: false
model: sonnet
---

You update project_spec.md with technical and architectural information. In an issue-tracked project, you also record milestones, open questions, and technical debt in GitHub.

## When invoked

1. Review recent git commits to understand what changed
   ```bash
   git log --oneline -10
   git diff HEAD~5..HEAD --stat
   ```

2. Read the project CLAUDE.md. If it contains a `Tracking: GitHub issues (...)` line, the project is issue-tracked: handle Milestones, Open Questions, and Technical Debt under **Issue-tracked projects** below, and skip those sections of the spec.

3. Read the current project_spec.md

4. Update relevant sections:

### Milestones
- Set a milestone to 🔎 when its work has landed and only the owner's check remains, and to ✅ only when the owner has confirmed the check. Otherwise leave it ⏳.
- Give each new milestone a check.
- Update descriptions if scope changed
- Add new milestones if project expanded

### Open Questions
- Remove questions that were answered during implementation
- Add new architectural or technical questions discovered

### Technical Debt
- Add new debt discovered during implementation (with file references)
- Remove debt that was paid off

### Implementation Notes
- Add patterns, techniques, or design decisions discovered while building
- Document integration details that weren't obvious
- Capture workarounds and their rationale

### Milestone Architecture Decisions
- When a milestone completes, record the architectural decisions it settled
- Give the decision, the alternatives, and what distinguished them

### Technical Architecture
- Update if components changed
- Revise data schema if it evolved
- Add new infrastructure or dependencies

## Issue-tracked projects

The Tracking line names one repo or several. Run every step below for each `<owner>/<repo>` it names.

Questions and debt are issue types in an organization's repo and labels in a personal account's. Find which with `gh api repos/<owner>/<repo> --jq .owner.type`:

| Owner type | Question | Debt | Search with |
|------------|----------|------|-------------|
| `Organization` | type `Question` | type `Tech debt` | `type:Question`, `type:"Tech debt"` |
| `User` | label `question` | label `tech-debt` | `label:question`, `label:tech-debt` |

Quote a multi-word type; `type:Tech debt` silently matches nothing. Read the current state first:

```bash
gh api "repos/<owner>/<repo>/milestones?state=open" --jq '.[] | "\(.number)\t\(.title)\t\(.open_issues) open\t\(.description)"'
gh issue list -R <owner>/<repo> --state open --search '<question qualifier>'
gh issue list -R <owner>/<repo> --state open --search '<debt qualifier>'
```

Put a new milestone, question, or piece of debt in the repo whose code it concerns. A milestone with work in several repos gets a milestone in each, with the same title and the same `Check:` line.

A missing type or label is expected. Create it before first use:

```bash
gh label create tech-debt -R <owner>/<repo> --force
gh api orgs/<owner>/issue-types -f name="Tech debt" -F is_enabled=true
```

and likewise `question` / `Question`. Set a type with `gh issue create --type "Tech debt"`.

In a session started with `claude -w`, Claude Code refuses `gh` writes. There, create and comment on issues through the GitHub MCP tools (`issue_write`, `add_issue_comment`). For milestones, labels, issue types, and blocked-by links, which those tools lack, put each body in a file in the scratchpad and list the full `gh` commands in your output for the user to run outside Claude Code.

### Milestones
- Add a new milestone with a plain-name title and a `Check:` line in its description:
  ```bash
  gh api "repos/<owner>/<repo>/milestones" -f title="<title>" -f description="Check: <what the owner verifies>"
  ```
- If a milestone's scope changed, edit its `Check:` line and keep the rest of the description.
- Never close a milestone. List any milestone with no open issues in your output; the owner closes it once the check passes.

### Open Questions
- Open a question issue for each new architectural or technical question.
- When implementation answered an open question, comment the answer on its issue and list the issue in your output for the owner to close.

### Technical Debt
- Open a debt issue for each new piece of debt, with file references in the body.
- For debt paid off on this branch, check that the resolving commit carries `Closes #N`, or `Closes <owner>/<repo>#N` for an issue in another repo. If it doesn't, comment the commit on the issue and list the issue in your output.

Search open issues before opening one, and comment on a match instead of duplicating it. Where a new issue cannot start until another closes, link them: `gh issue edit <n> -R <owner>/<repo> --add-blocked-by <m>`, with the blocker's issue URL in place of `<m>` when it lives in another repo.

## Guidelines

Write per **Writing**. Spec-specific:

- Cite file references (`src/module.go:42`).
- Remove resolved questions and paid-off debt as you go.
- Milestone architecture decisions are decision records — the one section where alternatives belong. Give the decision, the alternatives, and what distinguished them.
- Issue titles and bodies follow **Writing** too: the title states the question or the debt; the body gives file references and what a reader needs to act on it.

## Output

Provide a brief summary of what technical documentation was updated. In an issue-tracked project, list, by repo, the issues and milestones you opened, the issues you commented on, and the issues and milestones waiting on the owner to close.
