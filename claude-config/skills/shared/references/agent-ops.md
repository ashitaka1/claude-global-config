# Agent Operations Manual

How agents work autonomously in worktrees — isolation, test environments, testing, QA, and committing. Skills that spawn agents include the relevant sections of this document in agent prompts.

---

## Project Configuration Requirements

Skills that use this manual expect a `## Development Infrastructure` section in the project's CLAUDE.md. This section describes the project-specific tools and conventions that agents need. Without it, skills cannot create test environments, run tests, or format commits correctly.

### Required Subsections

#### Issue Tracker

How to fetch issue details. Must include a `fetch` command with a `$ISSUE` placeholder.

```
fetch: gh issue view $ISSUE --json number,title,body,labels
```

#### Test Environments

How to create, boot, and destroy isolated environments for testing and QA. Each agent gets its own environment. Commands use `$BASE` (template name) and `$NAME` (instance name) placeholders.

```
base: <base environment name>
create: <command to clone/create from base — $BASE and $NAME placeholders>
destroy: <command to tear down — $NAME placeholder>
boot: <optional command to start — $NAME placeholder>
ready-check: <optional command to verify ready — $NAME placeholder>
name-prefix: <prefix for generated names, e.g., "myproject-env">
```

The `create` command should be idempotent or tolerate re-runs. The `boot` command runs after `create` and is where post-boot setup belongs (e.g., enabling accessibility on iOS simulators). The `name-prefix` is used to generate unique names (`{prefix}-1`, `{prefix}-2`, etc.) and to detect stale environments from interrupted runs.

#### Test Command

How to run the project's test suite. Uses `$RESOURCE` placeholder for the environment name.

```
xcodebuild test ... --simulator-name "$RESOURCE"
```

#### Commit Conventions

Project-specific commit deltas. The message itself follows **Writing → Commit messages**; this block supplies the `issue-reference` template (with `$ISSUE` placeholder) and, in `guidelines`, only what this project does differently.

```
issue-reference: "Fixes $ISSUE"
guidelines: |
  - <project override, e.g. required ticket-key prefix>
```

#### QA

Where to find the functional test plan and testing tactics, plus setup steps for QA on a test environment.

```
functional-test-plan: <path to test plan file>
qa-tactics: <optional path to testing tactics file>
setup: |
  1. <step with $RESOURCE placeholder>
  2. ...
```

#### QA Tool Reference

Project-specific commands for UI inspection, interaction, and verification. Included verbatim in agent prompts.

---

## Worktree Isolation

Spawn agents with `isolation: "worktree"`. The harness creates the worktree under `<project-root>/.claude/worktrees/agent-<id>`, starts the agent inside it, and auto-cleans it if nothing changed. `.claude/` is already gitignored.

Inside its worktree an agent uses plain `git` and ordinary relative paths. No wrapper script, no directory flag, no absolute-path discipline.

### Branch Naming

The harness names the branch `worktree-agent-<id>`. An agent that owes the coordinator a specific branch renames it as its first action:

```bash
git branch -m $BRANCH_NAME
```

The rename is visible from the main checkout immediately. The coordinator finds the branch with `git branch --list` and the worktree with `git worktree list`.

### Cleanup (Coordinator)

An unchanged worktree is removed automatically. One holding commits persists, and is locked while its agent lives:

```bash
git worktree remove --force .claude/worktrees/agent-<id>
git worktree prune
```

---

## Test Environment Management (Coordinator)

### Creating Environments

1. Read the Test Environments config from CLAUDE.md.
2. Check for stale environments matching `name-prefix`. Destroy any found.
3. Generate names: `{name-prefix}-{N}`.
4. Run `create` for each (substituting `$BASE` and `$NAME`). Can parallelize with separate Bash calls.
5. If `boot` is defined, run it for each. Can parallelize.

### Destroying Environments

Run `destroy` for each environment. Parallelize with separate Bash calls. If destruction fails, warn the user and provide the manual command.

---

## Baseline Testing

Before agents begin work, run the test suite on main to establish known failures:

1. Run the test command from config.
2. Collect failing test names/patterns.
3. Pass this as `known_test_failures` to every agent so they distinguish pre-existing failures from regressions.

---

## Agent QA

The coordinator maps each work item to specific test items from the functional test plan. Agents execute the QA setup steps, verify each item, and report results with screenshot evidence.

### QA Integrity Rule

An agent's QA must verify the **core behavior** of its feature — not just "no regressions." If an agent cannot exercise the primary feature (e.g., test fixtures lack the required data, the environment can't produce the scenario), the agent MUST:
1. Report status as **FAILED**, not SUCCESS
2. Explain exactly what it could not verify and why
3. Not commit the code

The coordinator MUST NOT present a branch as ready for user QA if the agent could not verify the core feature. "Tests pass and it doesn't crash" is not QA for a new feature.

### QA Data Prerequisites

Before spawning agents, the coordinator must verify that the test environment contains data to exercise each feature's QA criteria. If test fixtures or mock data lack the required inputs:
- Add them to the fixture before spawning
- Or include fixture modification as an explicit step in the agent's prompt
- Or flag to the user that QA will require live data

---

## Committing

### Agent Commit Checklist

Run plain `git` from inside your worktree:

1. Verify branch: `git branch --show-current`
2. Stage specific files: `git add <files>`
3. Commit with conventions from config
4. Verify commit: `git log --oneline -1`

```bash
git commit -F - <<'EOF'
Commit message here

Fixes #123
EOF
```

---

## Avoiding Approval Prompts

These Bash patterns trigger security prompts and must be avoided by both agents and coordinators:

- **One command per Bash call.** No newline-separated commands.
- **No `$()` substitution.** Use two separate Bash calls instead.
- **Parallel operations:** Multiple Bash calls in one message, not `&` and `wait`.

---

## Code Review

After agents commit, the coordinator spawns code review agents. Spawn the reviewer with `isolation: "worktree"` on the agent's branch and have it run `git diff main...HEAD`. Review findings become separate follow-up commits.

---

## User QA Gate

**Do NOT merge to main until the user explicitly approves.** Merging may auto-close linked issues.

### QA Environment Setup

Before presenting results, set up a QA simulator for each successful branch so the user can test immediately. If the project has a `scripts/qa-setup.sh`, run it for each branch. Otherwise, create simulators using the Test Environments config.

### Presenting Results

```
## Ready for Your QA

Branches ready for review (not yet merged):
- `branch-name` (#N) — `just qa branch-name` or already running on simulator BunProbile-qa-...

Merging will auto-close the linked GitHub issues, so please review before merging.
When ready, say "merge" and I'll merge them to main.
```

---

## Reporting

After all agents complete, compile:

### Results Summary

```
| Branch | Work Item | Status | Commit |
|--------|-----------|--------|--------|
| ... | #6 | OK | abc1234 |
| ... | #15 | FAILED | -- |
```

### Agent Observations

Surface anything agents reported:
- **Technical:** refactoring opportunities, tech debt
- **QA process:** inefficiencies, missing tactics
- **Platform/framework:** undocumented behaviors, workarounds
