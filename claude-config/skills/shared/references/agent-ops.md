# Agent Operations Manual

How agents work autonomously in worktrees — navigation, file operations, test environments, testing, QA, and committing. Skills that spawn agents include the relevant sections of this document in agent prompts.

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

How to format commit messages. Includes `issue-reference` template (with `$ISSUE` placeholder) and `guidelines` for the message body.

```
issue-reference: "Fixes $ISSUE"
guidelines: |
  - First line: imperative summary, under 72 characters
  - ...
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

## Worktree Navigation

Background agents cannot reliably use `cd` to change directories (it does not persist between Bash tool calls). All git commands must use the `worktree-git.sh` wrapper script. File operations (Read, Edit, Write) must use full absolute worktree paths.

### Self-Navigation Block

Include this verbatim in every agent prompt, substituting `{absolute_worktree_path}` and `{branch_name}`:

```
## CRITICAL: Working Directory and Git

You are working in a git worktree. `cd` does NOT persist between Bash tool calls. You MUST follow these rules:

**For git commands**, use the worktree-git wrapper (NEVER bare `git`, `cd && git`, or `git -C`):
    bash ~/.claude/scripts/worktree-git.sh {absolute_worktree_path} <git-args>

**For file operations** (Read, Edit, Write), use full worktree paths:
    {absolute_worktree_path}/Path/To/File.swift

**For non-git Bash commands** that need to run in the worktree, use full paths in the command arguments (e.g., `ls {absolute_worktree_path}/some/dir`).

Your FIRST action must be to verify your branch:
    bash ~/.claude/scripts/worktree-git.sh {absolute_worktree_path} branch --show-current
It must print `{branch_name}`. If not, stop and report the error.
```

### File Path Block

The self-navigation block above covers file paths. No separate block needed.

---

## Worktree Management (Coordinator)

### Creating Worktrees

```bash
git worktree add .worktrees/$WORKTREE_DIR -b $BRANCH_NAME
```

Where `$WORKTREE_DIR` is the branch name with `/` replaced by `-` (e.g., `user/fix-foo` becomes `user-fix-foo`).

### Cleaning Up Worktrees

```bash
git worktree remove .worktrees/$WORKTREE_DIR
```

If dirty or locked:

```bash
rm -rf .worktrees/$WORKTREE_DIR
git worktree prune
git branch -D $BRANCH_NAME
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

Spawned agents cannot use standalone `cd` (it does not persist between Bash tool calls) and `cd <dir> && git` / `git -C` are blocked. Use the **worktree-git wrapper** for all git operations:

```bash
bash ~/.claude/scripts/worktree-git.sh {absolute_worktree_path} <git-args...>
```

Examples:
```bash
bash ~/.claude/scripts/worktree-git.sh /path/to/.worktrees/my-branch status
bash ~/.claude/scripts/worktree-git.sh /path/to/.worktrees/my-branch add file1.swift file2.swift
bash ~/.claude/scripts/worktree-git.sh /path/to/.worktrees/my-branch commit -F - <<'EOF'
Commit message here

Fixes #123
EOF
bash ~/.claude/scripts/worktree-git.sh /path/to/.worktrees/my-branch branch --show-current
```

Steps:
1. Verify branch: `bash ~/.claude/scripts/worktree-git.sh {worktree} branch --show-current`
2. Stage specific files: `bash ~/.claude/scripts/worktree-git.sh {worktree} add <files>`
3. Commit with conventions from config
4. Verify commit: `bash ~/.claude/scripts/worktree-git.sh {worktree} log --oneline -1`

---

## Avoiding Approval Prompts

These Bash patterns trigger security prompts and must be avoided by both agents and coordinators:

- **One command per Bash call.** No newline-separated commands.
- **No `$()` substitution.** Use two separate Bash calls instead.
- **No `cd && git` or `cd; git` chains.** Blocked by hook. Use `worktree-git.sh` wrapper instead.
- **No `git -C`.** Blocked by hook. Use `worktree-git.sh` wrapper instead.
- **Parallel operations:** Multiple Bash calls in one message, not `&` and `wait`.

---

## Code Review

After agents commit, the coordinator spawns code review agents. Pass the worktree path and instruct the reviewer to run `env -C <worktree_path> git diff main...HEAD`. Review findings become separate follow-up commits.

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
