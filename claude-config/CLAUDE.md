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

1. NEVER COMMIT TO MAIN.
2. When developing solo, merge branches directly; when contributing to a repo use PRs.
3. **Branch naming:** Unless project specifies otherwise, use:
   - `<user>/feature-<feature-label>` for features
   - `<user>/fix-<fix-label>` for bug fixes

   Where `<user>` is the user's github username. Projects may specify different formats in their CLAUDE.md.

### Git Commands

- **Avoid targeting git at a different directory.** Both `cd <path> && git ...` and `git -C <path> ...` trigger approval prompts. When working in worktrees or subdirectories, prefer running git commands from within that directory (e.g., agents launched with worktree isolation should use plain `git` since they're already in the worktree).

### Commits

1. Limit commits to a single feature, change, or fix whenever possible.
2. Only commit passing tests.
3. When tests exist, commit them with the features they test.

#### Commit messages

The audience is contributors reading `git log` — typically running `git blame` on a confusing line, hunting a regression, or scanning recent history. Write for them. Not for the end user, not as release notes, not as a record of our conversation.

  1. **Default to subject-only.** A body earns its place only when it answers a *why* the diff cannot — a hidden constraint, a non-obvious technical cause, or an architectural decision a contemporary reviewer would otherwise puzzle over. Test each candidate line: would a developer running `git blame` on this code months from now be confused without it? If no, cut.

     Never produce:
     - **Bug narrative.** Symptoms, reproduction, operator-perceived behavior — issue-tracker material, not commit material.
     - **Pitch tone.** "Now possible", "X is optional", "use this when", "no longer requires", "lets you".
     - **Listings of absences.** "No DHCP proxy, no TFTP — only X." Describe what the code does, not what it avoids.
     - **Restatements of the diff.** If a line re-narrates what the new code does, it carries no signal the diff doesn't already.
     - **Anything outside the diff.** Our conversation, alternatives you tried, project events ("hackathon-ready"), decorative ticket references. (Functional trailers like `Closes #45` that drive issue automation are fine — they're part of the change.) The commit describes the change, not its circumstances.

  2. Do not include a co-author message.

  3. Use `git commit -F - <<'EOF'` for multi-line messages. The `$(cat <<'EOF'...)` form triggers unnecessary approval prompts.

## Documentation Standards

- As with commits, do not annotate documentation with history of our conversation that do not add clarity. For example, if we discuss an alerting feature that includes an image, and later we decide to cut images from scope, do not annotate the feature with "(no images)".

---

## Development Workflow

### Starting Work

Use `/start-feature <name>` to create a worktree and begin guided development

### Feature Development

Use `/start-feature <name>` to create a worktree with a feature branch and enter guided feature development. This launches the feature-dev workflow which provides:
- Discovery and clarifying questions
- Agent-driven codebase exploration
- Architecture design with trade-off analysis
- Implementation with quality review

#### Test plan
**After Architecture Design (before implementation):**
Create a test plan using the required template:

| Test Name | Category | Justification |
|-----------|----------|---------------|
| ... | ... | ... |

**Categories:** Config validation, Constructor validation, State machine, Thread safety, Error handling, Integration, Documentation

**Justification:** You must think carefully and explain *exactly* how your tests actually test meaningful custom logic, user input, or something else non-trivial.

**Test Scrutiny Phase 1:** Delegate to `test-scrutinizer` agent for plan review.
- Pass it your test plan.
- Work with the test-scrutinizer until it approves your plan.
- When your plan is approved, save the approved proposal to `.claude/test-proposals/<branch-name>.md` for Phase 2 comparison
- Ask the user to review your plan, and make any requested modifications.

#### Implementation (TDD)

1. Write tests according to approved plan
2. Run tests (should fail)
3. Implement feature
4. Run tests (should pass)
5. **Test Scrutiny Phase 2:** Delegate to `test-scrutinizer` agent for implementation review
6. **If Phase 2 fails:** Return to step 1 — rewrite tests to match proposal, or revise proposal and re-run Phase 1

### Feature Validation

Before merging to main, verify the feature works in the target environment:
1. Build the project
2. Test in the actual runtime environment (not just unit tests)
3. Verify integration points work as expected
4. If issues found, fix and re-run tests before proceeding

**Why this matters:** Unit tests verify logic, but validation catches integration issues (configuration problems, dependency resolution, timing issues). Documentation should describe working behavior, not theoretical behavior.

### Completing Work

1. **Run `/completion-check`** — runs tests, handles documentation updates, commits.
2. Attempt to validate the application in a test environment. Follow any project directives for doing so.
3. Use /end-feature to finalize the feature branch.
4. Use /revise-claude-md

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

Most matches against this table are unconditional rejections. Rare exceptions exist — for example, an exact-value assertion that looks like algorithm-pinning may be acceptable if the function has only one reasonable closed form. Such exceptions are governed by the positive criteria below.

### When a Test Is Worth Writing

The anti-pattern table is a fast filter — if a test matches a pattern there, drop it without further review. But clearing the filter doesn't mean the test pulls its weight. For tests on real custom logic, score against three properties:

> **A test is worth writing if it pins a contract you'd document, at a boundary input, against multiple classes of plausible mistake.**

Hit at least two of three and the test pays for itself.

**Doc-worthy contract.** If you'd write a doc-string about the property the function holds, a test pinning that property enforces the documentation. If you wouldn't bother to document it because it's implementation detail, don't bother to test it. *Doc-worthy* means a property a careful reader would want surfaced when reading the source for the first time — not "interesting enough to test" (which would be circular).

**Boundary input.** A test at typical inputs largely restates what the code visibly does. A test at a *boundary* (zero, max, wrap, nil, empty, single-element, just-above/below a threshold) is where bugs hide. Per line of test, boundary cases carry more weight. This is a weight criterion, not a skip criterion — a typical-input case is sometimes the cleanest expression of the contract.

**Multi-class mistakes.** A good test fails for a *family* of plausible bugs (forgot the branch, wrong formula, wrong types, removed a parameter). Before writing a test, name two or three distinct realistic mistakes it would catch. If you can name only one, it's a weak test.

#### Pin contracts, not algorithms

Phrase assertions in terms of input → output behavior, error conditions, and invariants — not internal arithmetic. The test for whether you've crossed the line: would a different correct implementation pass this? If yes, contract. If no, algorithm.

Exact-value assertions are acceptable when the function has only one reasonable closed form (the formula *is* the contract). When multiple correct implementations exist, prefer behavioral assertions (positive, within plausible bounds, etc.). This is a judgment call, not a rule — name the trade-off.

Project-level CLAUDE.md may make this criterion mandatory (e.g., projects shipping multiple alternative backends) or relax it.

#### Failure messages should be diagnostic

This is a separate criterion that governs *how a test is written*, not *whether to write it*. When a test fails, the expected-vs-actual output should point at the bug, not at test mechanics.

- **Diagnostic:** `expected 150, got -42` — wrap math underflowed.
- **Non-diagnostic:** `mock called 2 times, expected 1` — tells you about calls, not behavior.

Reviewed at implementation time, not in the test plan.

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
