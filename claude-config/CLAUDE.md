# CLAUDE.md

This file provides global guidance to Claude Code (claude.ai/code) across all projects.

## Engineering Guidelines

NEVER make changes directly on main. Follow the development workflow.

The one exception: when the user's prompt contains `!onmain`, editing and committing on main is allowed for the rest of that session. Only the user supplies it; never suggest it.

### Security
- Always run tests before committing
- Always use environment variables for secrets
- Never commit .env.local or any file with API Keys

### Tests
- Only test meaningful behavior and our own logic
- Vet your tests for failure modes:
    - Testing that constants are what we expect
    - Tests that effectively only test an underlying library

## Repository Hygiene

### Branches

1. NEVER COMMIT TO MAIN, unless the user has supplied `!onmain` this session.
2. When developing solo, merge branches directly; when contributing to a repo use PRs.
   - Fast-forward whenever possible. Create a merge commit only when history has diverged; never pass `--no-ff`, whatever the existing log looks like.
3. **Branch naming:** Unless project specifies otherwise, use:
   - `<user>/feature-<feature-label>` for features
   - `<user>/fix-<fix-label>` for bug fixes

   Where `<user>` is the user's github username. Projects may specify different formats in their CLAUDE.md.

### Git Commands

- **Use `git commit -F - <<'EOF'` for multi-line messages.** The `$(cat <<'EOF'...)` form triggers unnecessary approval prompts; command substitution defeats static permission matching.

### Commits

1. Limit commits to a single feature, change, or fix whenever possible.
2. Only commit passing tests.
3. When tests exist, commit them with the features they test.

## Writing

These rules govern written artifacts — code comments, commit messages, pull request descriptions, and documentation. They do not govern conversation.

### How to write

**Register.** Write to a colleague across a desk. The reader already wants the information and will decide what it's worth.

**Assume the reader is attentive and already convinced.** Write the claim and let the sentence end. A reader holding the claim needs no complement, no benchmark, no emphasis; supplying them says you expect them to miss the point or doubt it.

**No sentence says its claim twice.** A second half that completes, contrasts, or benchmarks the first is the claim restated. State it once and move on. A negative claim is fine where the absence is the content — *the file is never written to disk* — and is not fine where it's the shadow of something already said.

That gives you:

- Say what a thing is. *The endpoint returns JSON* is finished; the reader supplies *rather than XML*.
- Say the property or the figure. *The job takes four minutes.* *The list is alphabetical.* With no figure, name the property and leave it unranked.
- Say the word. *It works.* *The cost.* *The deadline.*
- Say the finding. No sentence whose job is to set up the next one, none whose job is to characterize the one before, no paragraph announcing what a section contains.
- Start at the content. There's no approach to write.

**Record the decision alone.** An option you considered and dropped feels like content because ruling it out cost you something. The reader needs the choice; the field you cleared to reach it is your working and it stays out. Decision records are the exception — there the alternatives are the genre's content.

**When you can't say what a thing is without saying what it isn't, you don't have the claim yet.** Work it out before writing the sentence rather than writing around the gap.

**Nothing the reader can already see.** A line that re-narrates the diff, the code above it, or the section it heads carries no signal the reader doesn't already hold.

**Nothing from outside the artifact.** Our conversation, the approaches you abandoned, project events ("hackathon-ready"), decorative ticket references. The artifact describes its subject, not its circumstances.

**No pitch.** "Now possible", "no longer requires", "lets you", "use this when". Nobody is being sold. Say what the thing does.

### Code comments

Clear naming and expressive code carry the intention; not every loop or block needs a comment. A comment earns its place when:

- Code transitions from business logic to a domain-specific algorithm. Open with the purpose and cite the reference — an ISO/ANSI number, a published paper. Graphics and other spatial computation, cryptography, video, audio, compression, physics simulation.
- A language-feature hack needs a label, such as `if true { // comment` to label loops in Go.
- The code causes a known non-local side effect with serious impact on the application.
- Other knowing hackery. Explain the hack.
- A placeholder marks planned code for the current feature, change, or fix.

### Commit messages

Audience: a contributor reading `git log` — running `git blame` on a confusing line, hunting a regression, scanning recent history. Not the end user, not release notes.

**Default to subject-only.** A body earns its place only when it answers a *why* the diff cannot: a hidden constraint, a non-obvious technical cause, an architectural decision a contemporary reviewer would puzzle over. Test each candidate line — would a developer running `git blame` on this code months from now be confused without it? If no, cut.

**Match the repo's log.** Check `git log --oneline` before committing and write the subject in the prevailing style: ticket key format if the work has an associated issue key (`APP-1234:` vs `[APP-1234]` vs bare), mood and capitalization, and — most of all — parsimony. If surrounding subjects are terse, yours must be too; don't out-write the log.

**No bug narrative.** Symptoms, reproduction steps, operator-perceived behavior are issue-tracker material.

Functional trailers that drive issue automation (`Closes #45`) are part of the change and belong in the message. Do not include a co-author line.

### Pull request descriptions

Audience: a reviewer deciding whether the change is correct. They have the diff and the commit log. Give them what neither holds — the constraint that forced this shape, what to exercise to see it work, and the risk they should weigh.

### Documentation

Each file has one audience. Content belonging to another audience goes to that file.

| File | Audience | Content |
|------|----------|---------|
| `README.md` | someone learning to use the project | what it does, how to install and run it, how to configure it |
| `project_spec.md` | someone working on the project | architecture, data schemas, implementation notes, technical debt, open questions, decision records |
| `CLAUDE.md` | Claude, working in this repo | project status, test and build commands, workflow overrides |
| `changelog.md` | users and contributors tracking releases | one entry per logical change, categorized |

A decision record is the one place alternatives belong: the decision, the alternatives, and what distinguished them. Everywhere else, record the decision alone.

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
Write a test plan in the format below. A person reads it, so it must be skimmable and understandable without reading the code.

**Format**

1. Open with an index: a numbered list of every test by name and category.
2. List the design assumptions the tests rely on (rules, limits, state fields) as a short bulleted list.
3. Group tests by the file they will live in. Give each test its own block, not a table row:

```
**7. Repeated progress reports keep an install alive** (State machine)
- Checks: one or two bullets saying what is set up and what is asserted.
- Why: the harm a wrong implementation would cause.
```

4. End with three short sections: "Deliberately not tested" (with the reason for each), "Changes to existing tests", and any manual or hardware validation that stands in for tests.

**Names.** A name states the behavior in plain language, so someone who has not read the code can tell what breaks when the test fails. Avoid internal function names, jargon, restating the claim ("X shows as X"), and names so general they hide the cases ("never breaks"). If a test checks two separate things, the name says both, or the test is split.

**Categories:** Config validation, Constructor validation, State machine, Thread safety, Error handling, Integration, Documentation.

**Why.** Name the harm in plain words: a good install marked failed, a machine booting an empty disk, a duplicated event, bad input reaching a log. Then, if useful, list the distinct mistakes the test would catch. "Pins the rule" and "restates the decision" are not justifications. You must think carefully and explain *exactly* how the test catches a real mistake in custom logic, user input, or something else non-trivial.

**Test the implementation, not the decision.** Decisions — product choices, architecture, a default, a tie-break — belong in the spec. A test checks that the code carries out the design correctly; it does not defend the design against change. "Pins decision A" is not a justification. "Catches an off-by-one that admits a value the design excludes" is.

**Mechanics the tests follow.**
- When behavior depends on time, time comes from an injected clock. No sleeps. Waiting uses a poll helper.
- Concurrency tests are deterministic: hold a lock in one thread and assert on the other. Do not rely on scheduling luck.
- In a test of stateful behavior, assert the resulting state first, then side effects such as events, and the returned value last. A wrong return value then cannot hide a wrong state.
- Name each subtest after the mistake it catches.

**Test Scrutiny Phase 1:** Delegate to `test-scrutinizer` agent for plan review.
- Pass it your test plan.
- Work with the test-scrutinizer until it approves your plan.
- When your plan is approved, save the approved proposal to `.claude/test-proposals/<branch-name>.md` for Phase 2 comparison. Replace any `/` in the branch name with `-`.
- Ask the user to review your plan, and make any requested modifications. Edits that only remove or loosen tests do not need another scrutiny pass. Update the saved proposal with every edit.

#### Implementation (TDD)

1. Write tests according to approved plan
2. Run tests (should fail)
3. Implement feature
4. Run tests (should pass)
5. **Test Scrutiny Phase 2:** Delegate to `test-scrutinizer` agent for implementation review. Pass it the saved proposal's path.
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
3. Run `/revise-claude-md`.
4. Stop and tell the user the branch is ready for `/end-feature`. That skill merges, pushes, and removes the worktree, and only the user invokes it.

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
