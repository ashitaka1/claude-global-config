---
name: update-changelog
description: Updates changelog.md following Keep a Changelog format. Use after completing features, fixes, or changes.
disable-model-invocation: false
---

Update changelog.md with recent changes following the Keep a Changelog format (keepachangelog.com).

## Usage

```
/update-changelog
```

## What it does

1. Review recent git commits
   ```bash
   git log --oneline -10
   git diff HEAD~5..HEAD --name-only
   ```

2. Categorize changes under the appropriate heading
3. Add entries to the [Unreleased] section
4. When releasing, move Unreleased items to a new version section

## Changelog format

### Added — New features
### Changed — Changes to existing functionality
### Deprecated — Features to be removed in future
### Removed — Removed features
### Fixed — Bug fixes
### Security — Vulnerability fixes

## Guidelines

Write per **Writing**. Changelog-specific:

- Present tense: "Add feature", not "Added feature".
- One entry per logical change, not per commit. Group related changes.
- Link issues and PRs where they exist.
- Exclude `.claude/`, CLAUDE.md, and project_spec.md changes — internal tooling and planning.
- Exclude internal refactoring that leaves behavior unchanged, development tooling changes, and documentation updates that don't track a feature change.

## Output

After updating changelog.md, provide a brief summary of what was added to the changelog.
