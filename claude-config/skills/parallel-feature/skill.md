---
name: parallel-feature
description: Design features interactively in series, then implement them in parallel. Combines feature-dev style discovery and architecture (with user input on each feature) with parallel autonomous implementation. Use when implementing multiple independent features, enhancements, or substantial changes that each need design decisions before coding. Also use when the user wants to batch several issues that are too complex for a simple bug fix.
disable-model-invocation: false
argument-hint: <issue-identifiers, feature descriptions, or nothing for interactive>
---

Design features interactively, then implement them in parallel.

## Usage

```
/parallel-feature #40 #41 #42
/parallel-feature "add dark mode" "refactor auth flow"
/parallel-feature           (interactive -- prompts for features)
```

Issue identifiers, descriptions, or a mix. Items joined with `+` are grouped into a single agent. Without arguments, prompts for feature descriptions.

## Prerequisites

The project CLAUDE.md must contain a `## Development Infrastructure` section. See `~/.claude/skills/shared/references/agent-ops.md` ("Project Configuration Requirements") for the required format. If missing, stop and tell the user what's needed.

## Infrastructure Reference

Read `~/.claude/skills/shared/references/agent-ops.md` for all agent infrastructure operations. This skill follows agent-ops for worktree management, test environments, agent spawning, QA, committing, code review, and reporting.

## How It Works

The bottleneck in feature work is design decisions, not implementation. This skill separates exploration, design, and implementation into a pipeline:

1. **Exploration phase (parallel, autonomous):** Launch explorer agents for all features simultaneously. This front-loads the slow, non-interactive codebase analysis.

2. **Design phase (serial, interactive):** As each feature's exploration completes, clarify requirements and propose architecture. One feature at a time so the user can give each full attention. Process features in completion order — whichever exploration finishes first gets designed first.

3. **Implementation phase (parallel, autonomous):** Once all designs are approved, spawn agents to execute them in parallel across isolated worktrees.

The design phase produces implementation blueprints specific enough for an autonomous agent to execute without asking follow-up questions.

## Workflow

### Phase 1: Read Config and Gather Features

1. Read CLAUDE.md and parse `## Development Infrastructure`.
2. Parse `$ARGUMENTS` into feature identifiers and groupings.
3. Fetch issues or use descriptions directly.
4. If no arguments, ask the user to describe the features.

### Phase 2: Explore All Features (Parallel)

Launch exploration for **all features simultaneously**. For each feature, spawn 1-2 `code-explorer` agents in the background (`run_in_background: true`):
- One tracing the existing implementation of related functionality
- One mapping the architecture, patterns, and integration points

Each agent should return a list of key files. This front-loads the slow, non-interactive work so that design can begin as soon as any feature's exploration completes.

### Phase 3: Design Each Feature (Serial, Interactive)

Design features one at a time. Do NOT proceed to the next until the current one is approved. **Pick up whichever feature's exploration finishes first** — you do not need to follow the original input order.

#### Step 1: Review Exploration

When a feature's explorer agents complete, read the key files they identified to build deep context. Present a brief summary of findings.

#### Step 2: Clarify

Identify ambiguities, edge cases, scope boundaries, and design choices. Present specific questions:

```
## Feature: [name]

Based on exploring the code, I have some questions:

1. [Specific question about behavior/scope/edge case]
2. [Specific question about design preference]
3. ...
```

Wait for answers. If the user says "your call," state your recommendation and confirm.

#### Step 3: Architect

Launch 2-3 `code-architect` agents in parallel with different focuses:
- **Minimal change:** smallest diff, maximum reuse of existing code
- **Clean architecture:** best abstractions, most maintainable
- **Pragmatic balance:** speed + quality tradeoff

Each agent proposes a concrete implementation plan given the explorer findings and the user's clarifying answers.

Review all approaches and present to the user:

```
## Feature: [name]

### Approach A: [name] (recommended)
- [What changes and where]
- [Trade-offs]

### Approach B: [name]
- [What changes and where]
- [Trade-offs]

### My recommendation: [which and why]

Approve an approach? [A/B/C or adjustments]
```

After the user chooses, produce the final implementation blueprint:

```
### Implementation Blueprint: [name]

**Files to modify:**
- [file]: [specific changes]
- [file]: [specific changes]

**New files:**
- [file]: [purpose]

**Tests:**
- [what to test]

**QA criteria:**
- [specific verifiable items]

**Branch:** [branch-name]
```

#### Step 4: Repeat

Pick up the next feature whose exploration has completed. Repeat Steps 1-3. If no explorations have finished yet, wait for the next one to complete.

### Phase 4: Setup

After all designs are approved:

1. Prerequisite checks (QA tools, setup files).
2. **Verify QA prerequisites for each feature.** For every QA criterion in every blueprint, confirm the test environment can actually produce that scenario. Check that test fixtures, mock data, or configuration contain the inputs needed to exercise the feature. If not, add them now — before spawning agents. An agent that cannot verify its core feature is a failed agent, regardless of whether tests pass.
3. Create test environments — one per agent. Follow agent-ops.
4. Run baseline tests. Follow agent-ops.

### Phase 5: Present Full Plan

Before spawning agents, present the consolidated plan:

```
## Implementation Plan

### Baseline
- Known test failures: [list or "none"]

### Agent 1: branch-name (Feature: [name])
- Design: [brief summary of approved blueprint]
- Key files: [files to modify/create]
- Tests: [what to write/verify]
- QA: [verification criteria]
- Environment: {name-prefix}-1

### Agent 2: ...

[Flag any file overlaps between agents that may need merge reconciliation]

Approve and begin implementation? [y/n]
```

Wait for approval. The user may want to sequence agents (Wave 1/Wave 2) if there are dependencies.

### Phase 6: Spawn Agents

Follow agent-ops for worktree creation and spawning. Create all worktrees first, then spawn `bug-fixer` agents with `run_in_background: true`.

Each agent prompt must include:
- Self-navigation block and file path block (from agent-ops)
- **The full approved implementation blueprint** — this is the primary guidance
- Issue details (if from tracker)
- Worktree path and branch name
- Environment name
- Test command, known test failures
- QA setup, test items, tool reference, and tactics
- Commit conventions
- Project conventions from CLAUDE.md

The blueprint is the most important part. It must be specific enough that the agent can implement without ambiguity — specific files, specific changes, specific patterns to follow.

### Phase 7: Collect, Review, and Present

1. Collect results. Follow agent-ops "Reporting."
2. **Validate QA results.** For each agent, check that QA actually verified the core feature — not just "no regressions." If an agent reports it could not test the core behavior (e.g., "no test data for this scenario"), treat it as **FAILED** regardless of test results. Do not present it as ready for user QA.
3. Code review each successful branch. Follow agent-ops "Code Review."
4. Destroy test environments.
5. Follow agent-ops "User QA Gate" — present branches, offer to build on named environments for testing.

## Design Phase Tips

- **Be specific.** "Refactor the auth flow" is not a plan. "Add `bypassAuth()` to `AppState` that sets `authenticationState = .authenticated` when mock mode is on" is a plan.
- **Name the files.** Don't say "update the relevant view." Say "update `InputZoneView.swift` line 95."
- **Show the pattern.** If the codebase has conventions, describe them so the agent follows them.
- **Define done.** QA criteria should be verifiable. "It should look right" is not. "The button uses `.buttonStyle(.bordered)` with `.buttonBorderShape(.capsule)`" is.
- **Flag overlaps.** If two features touch the same files, note it so the user can sequence them.

## Error Handling

- Environment creation failure: skip that agent, report, continue.
- Agent failure: do NOT retry. Report and let user decide.
- Cleanup failure: warn about orphaned environments, provide manual command.
