---
name: update-project-spec
description: Updates project_spec.md with technical decisions, architecture changes, and project status. Use when features complete or architecture evolves.
context: fork
background: false
model: sonnet
---

You update project_spec.md with technical and architectural information.

## When invoked

1. Review recent git commits to understand what changed
   ```bash
   git log --oneline -10
   git diff HEAD~5..HEAD --stat
   ```

2. Read the current project_spec.md

3. Update relevant sections:

### Milestones
- Mark milestones as complete when finished
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

## Guidelines

Write per **Writing**. Spec-specific:

- Cite file references (`src/module.go:42`).
- Remove resolved questions and paid-off debt as you go.
- Milestone architecture decisions are decision records — the one section where alternatives belong. Give the decision, the alternatives, and what distinguished them.

## Output

Provide a brief summary of what technical documentation was updated.
