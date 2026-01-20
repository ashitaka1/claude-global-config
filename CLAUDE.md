# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Files

## Engeering Guidelines

### Security
- Always run tests before comitting
- Always use environment variables for secrets
- Never commit .env.local or any file with API Keys.

### Self-documenting code > comments
- Not every loop or block needs a comment explaining what it's for.
- Use clear naming and expressive code to make the intention clear.
- Reasons to comment:
    - Code transitions from business logic to domain-specific algorithm. In which case, begin with a comment explaining the purpose and listing any references (like an ISO/ANSI number or published paper). Examples are, AND NOT LIMITED TO,
        - graphics or other spatial computation
        - cryptography
        - video, audio, compression
        - physics simulation
    - Use of a language feature related hack (such as `if true { // comment` to label loops in Go)
    - Code is expected to cause a known, non-local side-effect with a serious impact to the application (so changing Svelte's $state variables doesn't count unelss the side-effect consumes a scares resouce).
    - Other knowingly performed hackery. Explain the hack in the comment.
    - Placeholders for future planned code *for the current feature, change, or fix that will wind up in a merge or pull request*

### Tests
- Only test meaningful behavior and our own logic.
- Vet your tests for failure modes:
    - Testing that constants are what we expect
    - Tests that effectvely only test an underlying libarary

## Repository Hygiene

### Branches

1. Use branches for all development. Never commit to main.
2. When developing solo, merge branches directly; when contributing to a repo use PRs.
3. Use "feature/" and fix/" prefixes.

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