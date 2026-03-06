---
name: parallel-fix
description: Coordinate parallel bug fixes across isolated worktrees with dedicated test resources. Spawns bug-fixer agents that independently implement, test, and commit fixes.
disable-model-invocation: false
argument-hint: <issue-identifiers or description>
---

Coordinate parallel bug fixes with isolated worktrees and test resources.

## Usage

```
/parallel-fix #6 #15 #16+#19 #13+#14
/parallel-fix           (interactive -- prompts for issues)
```

Issue identifiers are project-specific (GitHub issue numbers, Jira keys, file paths, etc.). Multiple issues joined with `+` are grouped into a single fixer agent. Without arguments, prompts the user for issue descriptions.

## Prerequisites

The project CLAUDE.md must contain a `## Parallel Fix Config` section with the required subsections. If this section is missing, stop and tell the user what's needed and show them the expected format.

## Implementation

When invoked with `$ARGUMENTS`:

### Phase 1: Read Project Config

1. Read the project CLAUDE.md and locate the `## Parallel Fix Config` section.
2. Parse the following subsections:
   - **Issue Tracker** -- `fetch` command with `$ISSUE` placeholder for retrieving issue details
   - **Resource Pool** -- `base`, `create`, `destroy`, `name-prefix`, and optional `boot`, `ready-check` commands with `$BASE` and `$NAME` placeholders
   - **Commit Conventions** -- `issue-reference` template with `$ISSUE` placeholder, and `guidelines` for the descriptive part
   - **Test Command** -- command to run the project's test suite, with `$RESOURCE` placeholder
   - **QA** -- `functional-test-plan` (path to the test plan file), optional `qa-tactics` (path to reusable testing tactics), `setup` (ordered resource-setup steps with `$RESOURCE` placeholder), and **QA Tool Reference** (project-specific tool documentation for agents)
3. If the config section is missing or incomplete, stop and tell the user what's needed.

### Phase 2: Gather Issues

1. Parse `$ARGUMENTS` into issue identifiers and groupings (`+` means same agent).
2. For each issue, run the `fetch` command from Issue Tracker config (substituting `$ISSUE`).
3. Read and understand each issue's content from the fetch output.
4. If no arguments, ask the user to describe the fixes needed.

### Phase 3: Verify Prerequisites, Create Resource Pool, and Run Baseline Tests

**Prerequisite checks (before anything else):**

1. Verify QA tools are available by running `which` for each CLI tool referenced in the QA Tool Reference config (e.g., `which xcodebuildmcp`). If any are missing, stop and tell the user which tools need to be installed.
2. Verify QA setup prerequisites exist (e.g., token files, credential files referenced in the QA setup steps). If missing, ask the user to provide them before proceeding.

Then do both of these in parallel -- resources warm up while the baseline test runs.

**Resource pool creation:**

1. Read the pool config: `base`, `create`, `destroy`, `name-prefix`, and optional `boot`, `ready-check`.
2. Determine the number of resources needed (one per agent).
3. For each resource, generate a name: `{name-prefix}-{N}` (e.g., `BunProbile-fixer-1`).
4. Run the `create` command for each resource (substituting `$BASE` and `$NAME`), in parallel if possible.
5. If `boot` is defined, run boot commands in parallel (in background).

**Baseline test run:**

1. Run the project's test suite against main (using one of the pool resources or the project's default test target).
2. Collect the list of any failing test names/patterns.
3. This becomes `known_test_failures` -- passed to every agent so they can distinguish pre-existing failures from regressions they introduce.
4. If all tests pass, `known_test_failures` is empty.

### Phase 4: Plan Each Fix

For each issue group, the **coordinator** does lightweight exploration and test mapping:

1. Read the issue description for clues about affected files.
2. Use Grep/Glob to locate the relevant code.
3. Read the functional test plan file (from QA config).
4. **Map the issue to specific test items** from the functional test plan. Identify:
   - Which numbered test items directly verify the fix (e.g., issue #15 maps to items 3.3.*)
   - Which related test items should be checked for regressions (e.g., nearby items in the same section)
5. Determine:
   - **Fix summary** -- what needs to change and where
   - **Unit test criteria** -- which existing unit tests must pass, any new unit tests needed
   - **QA test items** -- the specific functional test plan items to execute (by number and description)
   - **Branch name** -- following project branch naming conventions

6. Compile the full plan and present it to the user for approval:

```
## Parallel Fix Plan

### Baseline
- Known test failures: [list or "none -- all tests pass"]

### Agent 1: branch-name (Issues #N, #M)
- Fix: [summary]
- Unit tests: [criteria]
- QA items from functional test plan:
  - [3.3.1] Done screen shows a score summary (e.g. "12/15 correct")
  - [3.3.2] A "Return to Dashboard" button dismisses the session
  - ...
- Resources: {name-prefix}-1

### Agent 2: ...
[etc.]

Approve this plan? [y/n]
```

7. Wait for user approval. Adjust if requested.

### Phase 5: Verify Resources Ready

Before spawning agents, verify all resources are ready:

1. If `ready-check` is defined, poll each resource (short sleep between checks, max ~60s).
2. If a resource fails to become ready, report the error and ask the user how to proceed.

### Phase 6: Spawn Fixer Agents

**Do NOT use `isolation: "worktree"`** -- it places worktrees under `.claude/` which triggers settings-protection prompts. Instead, the coordinator manages worktrees manually:

For each agent:

1. **Create the worktree and branch:**
   ```bash
   git worktree add .worktrees/$WORKTREE_DIR -b $BRANCH_NAME
   ```
   Where `$WORKTREE_DIR` is the branch name with `/` replaced by `-`.

2. **`cd` into the worktree** before spawning the agent. The agent inherits the coordinator's CWD, so plain `git` commands will operate on the worktree.

3. **Launch the `bug-fixer` agent** (without `isolation`). Pass it a prompt containing ALL of the following (the agent is autonomous and cannot ask follow-up questions):

- Issue details (full content from Phase 2)
- Fix plan (from Phase 4)
- Worktree path (absolute)
- Branch name (already created by the coordinator)
- Resource names (list of assigned resource identifiers)
- Test command (from config, with `$RESOURCE` pre-substituted)
- Known test failures (from Phase 3 baseline run)
- QA setup steps (from config, with `$RESOURCE` pre-substituted)
- QA test items (the specific functional test plan items mapped in Phase 4, with descriptions and pass criteria)
- QA tool reference (from config -- project-specific tool documentation)
- QA tactics (from the file referenced in QA config, if present -- read it and include its full contents)
- Commit conventions (issue-reference template with `$ISSUE` pre-substituted, plus guidelines)
- Relevant project conventions from CLAUDE.md (accessibility rules, coding conventions, etc.)

**Spawning agents -- CWD is critical:**

Agents inherit the coordinator's CWD at spawn time. This MUST be the worktree directory. Follow this exact sequence for EACH agent, one step per tool call:

1. Bash: `cd /path/to/worktree`
2. Bash: `git branch --show-current` -- confirm it matches the expected branch. If not, stop and debug.
3. Agent call with `run_in_background: true` -- spawn the agent.
4. Wait for this spawn to return before starting the next agent's sequence.

**NEVER spawn multiple agents in a single message.** Each agent must be spawned in its own message, immediately after its cd+verify step. Interruptions between cd and spawn (user messages, other tool calls) can cause the CWD to become stale.

**Do not duplicate the agents' work.** The coordinator waits for all agents to return.

### Phase 7: Collect Results

As each agent returns:

1. Check its reported status: success, test failure, or error.
2. For **successes**: log the commit SHA, branch name, and any technical observations the agent reported.
3. For **failures**: log the error and flag for user attention.

### Phase 8: Code Review

For each successful agent, spawn a code review agent to review the committed changes. Pass it the worktree path and diff against main. Any findings from code review become **separate commits** on the same branch -- they do not block the fix commit.

### Phase 9: Cleanup

1. Run the `destroy` command for each pool resource.
2. Report final summary:

```
## Parallel Fix Results

| Branch | Issues | Status | Commit |
|--------|--------|--------|--------|
| ... | #6 | OK | abc1234 |
| ... | #15 | OK | def5678 |
| ... | #13+#14 | FAILED | -- |

Resources cleaned up: N/N
```

3. If agents reported technical observations (refactoring opportunities, tech debt), compile them:

```
## Technical Observations (from agents)
- [agent/branch]: [observation]
```

4. If agents reported QA process observations (inefficiencies, missing tactics, friction), compile them:

```
## QA Process Observations (from agents)
- [agent/branch]: [observation]
```

5. If agents reported platform or framework discoveries (undocumented behaviors, workarounds, gotchas), compile them and suggest additions to the QA tactics doc:

```
## Platform/Framework Discoveries (from agents)
- [agent/branch]: [discovery and workaround]
  → Suggested qa-tactics addition: [brief tactic]
```

6. For successful branches, suggest next steps (push, PR, merge).

## Error Handling

- If a resource fails to create: skip that agent, report to user, continue with others.
- If an agent fails: do NOT retry automatically. Report the failure and let the user decide.
- If cleanup fails: warn the user about orphaned resources and provide the manual cleanup command.

## Notes

- The coordinator does the planning, test mapping, baseline testing, and decision-making. Agents execute autonomously.
- Agents commit independently -- each fix is a self-contained commit on its own branch.
- Code review happens post-commit. Review findings are separate follow-up commits.
- The resource pool is generic -- project CLAUDE.md defines what resources are and how to manage them.
- The issue tracker is generic -- project CLAUDE.md defines how to fetch issue details.
- The functional test plan is the source of truth for QA criteria. The coordinator maps issues to test items; agents execute them.
- Agents report technical observations (refactoring opportunities, tech debt) and QA process observations (inefficiencies, missing tactics) without acting on them. The coordinator surfaces both to the user.
