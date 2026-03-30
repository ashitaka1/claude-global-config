---
name: parallel-fix
description: Coordinate parallel bug fixes across isolated worktrees with dedicated test environments. Spawns bug-fixer agents that independently implement, test, and commit fixes. Use when fixing multiple independent bugs, or when the user invokes /parallel-fix.
disable-model-invocation: false
argument-hint: <issue-identifiers or description>
---

Coordinate parallel bug fixes with isolated worktrees and test environments.

## Usage

```
/parallel-fix #6 #15 #16+#19 #13+#14
/parallel-fix           (interactive -- prompts for issues)
```

Issue identifiers are project-specific (GitHub issue numbers, Jira keys, file paths, etc.). Multiple issues joined with `+` are grouped into a single agent. Without arguments, prompts the user for issue descriptions.

## Prerequisites

The project CLAUDE.md must contain a `## Development Infrastructure` section. See `~/.claude/skills/shared/references/agent-ops.md` ("Project Configuration Requirements") for the required format. If missing, stop and tell the user what's needed.

## Infrastructure Reference

Read `~/.claude/skills/shared/references/agent-ops.md` for all agent infrastructure operations: worktree management, test environment management, agent self-navigation, baseline testing, QA, committing, code review, approval prompt avoidance, user QA gate, and reporting.

This skill follows agent-ops for all infrastructure. What follows describes only the parallel-fix-specific workflow.

## Workflow

### Phase 1: Read Config and Gather Issues

1. Read CLAUDE.md and parse the `## Development Infrastructure` section.
2. Parse `$ARGUMENTS` into issue identifiers and groupings (`+` means same agent).
3. Fetch each issue using the Issue Tracker config.
4. If no arguments, ask the user to describe the fixes needed.

### Phase 2: Setup (parallel)

Do both in parallel — environments warm up while the baseline runs.

1. **Prerequisite checks:** Verify QA tools (`which`), verify setup prerequisites (token files, etc.).
2. **Create test environments:** One per agent. Follow agent-ops "Test Environment Management."
3. **Baseline test run:** Follow agent-ops "Baseline Testing."

### Phase 3: Plan Each Fix

For each issue group, the coordinator does lightweight exploration and test mapping:

1. Read the issue for clues about affected files.
2. Use Grep/Glob to locate the relevant code.
3. Read the functional test plan.
4. Map the issue to specific test items from the plan.
5. Determine: fix summary, unit test criteria, QA test items, branch name.

Present the full plan to the user:

```
## Parallel Fix Plan

### Baseline
- Known test failures: [list or "none"]

### Agent 1: branch-name (Issues #N, #M)
- Fix: [summary]
- Unit tests: [criteria]
- QA items:
  - [3.3.1] ...
- Environment: {name-prefix}-1

### Agent 2: ...

Approve this plan? [y/n]
```

Wait for approval. Adjust if requested.

### Phase 4: Verify Environments Ready

If `ready-check` is defined, poll each environment (max ~60s). Report failures.

### Phase 5: Spawn Agents

Follow agent-ops for worktree creation and agent spawning. Do NOT use `isolation: "worktree"`.

Create all worktrees up front, then spawn each `bug-fixer` agent with `run_in_background: true`.

Each agent prompt must include (the agent is autonomous — no follow-up questions):
- Self-navigation block and file path block (from agent-ops)
- Issue details
- Fix plan
- Worktree path and branch name
- Environment name
- Test command (with `$RESOURCE` pre-substituted)
- Known test failures
- QA setup, test items, tool reference, and tactics (read the tactics file and include contents)
- Commit conventions (with `$ISSUE` pre-substituted)
- Relevant project conventions from CLAUDE.md

### Phase 6: Collect Results

Follow agent-ops "Reporting." Log successes and failures.

### Phase 7: Code Review

Follow agent-ops "Code Review." Spawn a reviewer per successful agent.

### Phase 8: Cleanup and User QA

1. Destroy all test environments.
2. Follow agent-ops "User QA Gate" and "Reporting."

## Error Handling

- Environment creation failure: skip that agent, report, continue.
- Agent failure: do NOT retry. Report and let user decide.
- Cleanup failure: warn about orphaned environments, provide manual command.
