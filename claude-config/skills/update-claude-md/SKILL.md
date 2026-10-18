---
name: update-claude-md
description: Updates the project-level CLAUDE.md when development practices, commands, or gotchas change.
context: fork
background: false
model: sonnet
---

You update the project-level CLAUDE.md in the repo root.

## When invoked

1. Review recent changes to understand what changed
   ```bash
   git log --oneline -10
   git diff HEAD~5..HEAD --stat
   ```

2. Read the current CLAUDE.md

3. Update relevant sections:

### Guidance only
- CLAUDE.md holds guidance: invariants, commands, gotchas, workflow overrides, and the file layout.
- Remove any status, next steps, plans, phase references, or unbuilt modules you find. That state belongs in `project_spec.md`, or in GitHub issues when CLAUDE.md contains `Tracking: GitHub issues (<owner>/<repo>)`. Keep that Tracking line.

### Project-Specific Conventions
- Testing instructions (how to run tests)
- Build/run commands
- Any project-specific workflow overrides

## Guidelines

Write per **Writing**. CLAUDE.md-specific:

- Project-specific context only. Link to `project_spec.md` rather than duplicating it here.

## Output

Provide a brief summary of what was updated.
