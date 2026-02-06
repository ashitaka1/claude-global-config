# CLAUDE.md

This file provides global guidance to Claude Code (claude.ai/code) across all projects.

## Engineering Guidelines

NEVER make changes directly on main. Follow the development workflow.

### Security
- Always run tests before committing
- Always use environment variables for secrets
- Never commit .env.local or any file with API Keys

### Self-documenting code > comments
- Not every loop or block needs a comment explaining what it's for
- Use clear naming and expressive code to make the intention clear
- Reasons to comment:
    - Code transitions from business logic to domain-specific algorithm. In which case, begin with a comment explaining the purpose and listing any references (like an ISO/ANSI number or published paper). Examples include (but are not limited to):
        - Graphics or other spatial computation
        - Cryptography
        - Video, audio, compression
        - Physics simulation
    - Use of a language feature related hack (such as `if true { // comment` to label loops in Go)
    - Code is expected to cause a known, non-local side-effect with a serious impact to the application
    - Other knowingly performed hackery. Explain the hack in the comment.
    - Placeholders for future planned code *for the current feature, change, or fix that will wind up in a merge or pull request*

### Tests
- Only test meaningful behavior and our own logic
- Vet your tests for failure modes:
    - Testing that constants are what we expect
    - Tests that effectively only test an underlying library

## Repository Hygiene

### Branches

1. ALWAYS use branches for all development. Never commit to main.
2. When developing solo, merge branches directly; when contributing to a repo use PRs.
3. **Branch naming:** Unless project specifies otherwise, use:
   - `<user>/feature-<feature-label>` for features
   - `<user>/fix-<fix-label>` for bug fixes

   Where `<user>` is the user's github username. Projects may specify different formats in their CLAUDE.md.

### Commits

1. Limit commits to a single feature, change, or fix whenever possible.
2. Only commit passing tests.
3. When tests exist, commit them with the features they test.

#### Commit messages

1. Limit commit message content to the content/code changes.
2. Do not reference concepts from outside the changes themselves, such as chat contents.
3. Especially do not reference unused alternative implementation possibilities where you received feedback to do something else.
4. The audience of the commit log messages are the contributors to the repo.
5. Do not include a co-author message.

## Documentation Standards

- As with commits, do not annotate documentation with history of our conversation that do not add clarity. For example, if we discuss an alerting feature that includes an image, and later we decide to cut images from scope, do not annotate the feature with "(no images)".

---

## Development Workflow

### Starting Work

1. **Run `pre-work-check` agent** — verifies feature branch and passing tests
2. If on main, use `/start-feature <name>` to create a worktree and begin guided development
3. Never commit directly to main

**Important:** After context compaction, branch state may be lost. Always verify with `pre-work-check` before continuing work.

### Feature Development

Use `/start-feature <name>` to create a worktree with a feature branch and enter guided feature development. This launches the feature-dev workflow which provides:
- Discovery and clarifying questions
- Agent-driven codebase exploration
- Architecture design with trade-off analysis
- Implementation with quality review

**After Architecture Design (before implementation):**
Create a test plan using the required template:

| Test Name | Category | Custom Logic Tested |
|-----------|----------|---------------------|
| ... | ... | ... |

**Categories:** Config validation, Constructor validation, State machine, Thread safety, Error handling, Integration, Documentation

**Test Scrutiny Phase 1:** Delegate to `test-scrutinizer` agent for plan review. The agent will:
- Verify each test names specific custom logic (not SDK/library code)
- Validate categories are accurate (not just accepted at face value)
- Save the approved proposal to `.claude/test-proposals/<branch-name>.md` for Phase 2 comparison

Tests must name specific custom logic being tested — if you can't, it's likely plumbing.

### Implementation Phase (TDD)

1. Write tests according to approved plan
2. Run tests (should fail)
3. Implement feature
4. Run tests (should pass)
5. **Test Scrutiny Phase 2:** Delegate to `test-scrutinizer` agent for implementation review
   - Agent reads saved proposal from `.claude/test-proposals/<branch-name>.md`
   - Compares written tests against proposal
   - Verifies tests actually test what they claimed to test
   - Checks for proper techniques
6. **If Phase 2 fails:** Return to step 1 — rewrite tests to match proposal, or revise proposal and re-run Phase 1

### Feature Validation

Before documenting or committing, verify the feature works in the target environment:
1. Build the project
2. Test in the actual runtime environment (not just unit tests)
3. Verify integration points work as expected
4. If issues found, fix and re-run tests before proceeding

**Why this matters:** Unit tests verify logic, but validation catches integration issues (configuration problems, dependency resolution, timing issues). Documentation should describe working behavior, not theoretical behavior.

### Committing Changes

When asked to commit:

1. Run tests: `make test`
2. If tests fail, abort and report
3. Run documentation agents **in parallel**:
   - `readme-updater` (if user-facing changes)
   - `claude-md-updater` (if workflow changes)
   - `project-spec-updater` (if technical/architectural changes)
   - `changelog-updater` (if changes affect users/contributors)
4. Stage doc changes
5. Execute `git commit`

### Completing Work

1. **Delegate to `completion-checker` agent** — verify branch is ready to merge
2. Address any blocking issues
3. Merge branch to main (solo) or open PR (collaborative)
4. Clean up the worktree: `git worktree remove .worktrees/<dir>` or use `/clean_gone`
5. Use `retro-reviewer` agent periodically to review Claude Code usage and suggest improvements

---

## Testing Philosophy

### Test the Right Things at the Right Layers

**Unit tests** — custom logic only:
- State machines (transitions, edge cases)
- Config/constructor validation
- Thread safety of concurrent operations
- Error handling (our handling logic, not that errors propagate)

**Integration tests** — system state at lifecycle boundaries:
- State after start/stop operations
- Correct initialization of compound state
- Multi-component coordination results

**Documentation tests** — prove contracts:
- Wrapper components return exactly what they wrap

### What NOT to Test

| Anti-pattern | Example | Why it's bad |
|--------------|---------|--------------|
| Plumbing | "DoCommand routes to handleStart" | Tests dispatch, not logic |
| Delegation | "sensor.Readings calls controller.GetState" | Tests wiring, not behavior |
| Library code | "framework.Method moves data" | Trust the framework/library |
| Orchestration | "process calls function A then function B" | Tests sequence, not outcomes |
| Dead code | "unused function returns value" | If unused, delete it |
| Constants | "defaultTimeout == 10s" | Tautology |

### Testing Techniques

> **Note:** Code examples below are illustrative (language-agnostic principles shown in pseudocode/Go style). Adapt to your project's language.

**Test logic directly, not through dispatch layers:**
```
// Bad: tests dispatch mechanism + handler
system.dispatchCommand("start")

// Good: tests handler logic only
system.handleStart()
```

**State verification over call verification:**
```
// Bad: verify function was called
assert(mockDependency.methodWasCalled)

// Good: verify system state after operation
state = system.getState()
assert(state.count == 1)
```

**Direct state setup for isolation:**
```
// Bad: calls setup that spawns background work, creating race with test
system.start()
system.processItem()
state = system.getState() // racing with background work!

// Good: manually set up state to test specific logic in isolation
system.state = {active: true, count: 0}
system.processItem()
state = system.getState() // no race, testing exactly what we want
```

This isolates the logic under test. If `start()` breaks, a test for `start()` will catch it — not every test that happens to use it.

---

## Git Safety: Never Discard Uncommitted Work

Before running ANY command that discards changes (`git checkout -- <file>`, `git restore`, `git reset --hard`, `git stash drop`):

1. **Identify where the changes belong** — which branch should own them?
2. **Preserve them first:**
   - If they belong on current branch: commit them
   - If they belong on a different branch: stash, switch, apply, commit, switch back
   - If unsure: `git stash` and tell the user
3. **Ask the user** if there's any ambiguity about whether changes should be kept

**Never assume uncommitted changes can be safely discarded.** Even if they seem unrelated to the current task, they represent work that may not exist anywhere else.
