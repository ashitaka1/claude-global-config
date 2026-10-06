# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Changed
- Test plans are an index plus one block per test (name, category, checks, why) with closing sections for untested items, changed existing tests, and manual validation. Plans follow rules for test names, harm-based justifications, injected clocks, deterministic concurrency tests, and state-then-events-then-return assertion order
- `test-scrutinizer` checks the new plan format and rejects tests that only defend a product decision; the calling session saves the approved proposal to `.claude/test-proposals/<branch-name>.md` (`/` replaced by `-`), updates it on each user edit, and passes its path to Phase 2
- `sync.sh` reads the installed plugin list from `claude plugin list --json` rather than scraping the table output, falling back to the scrape on CLIs without `--json`
- `install.sh` now installs dependencies then runs `sync.sh deploy` instead of printing manual next steps
- Documented `.sync` suffix naming convention in README-SYNC.md
- Consolidated shell scripts into `claude-config/scripts/` directory (was individual files at `claude-config/` root)
- Rewrote statusline with model name, context window bar, remote sync status, per-session color theming, and last user message
- Consolidated code-comment, commit-message, PR-description, and documentation prose rules into one `Writing` section in `claude-config/CLAUDE.md`; downstream files reference it instead of restating it
- Collapsed the doc-updater agent/skill pairs (`changelog-updater`, `claude-md-updater`, `project-spec-updater`, `readme-updater`, `retro-reviewer`) into forked skills (`update-changelog`, `update-claude-md`, `update-project-spec`, `update-readme`, `retro`) that combine the slash command and the isolated context in one file
- Replaced the worktree-isolation workaround (`worktree-git.sh` wrapper, `no-git-cd-chain.py` hook blocking `cd`/`git -C`) with native `isolation: "worktree"`; `bug-fixer` now renames its own worktree's branch instead of expecting a pre-created one, and `git -C *` is pre-approved
- Feature completion now stops after `/revise-claude-md` and tells the user to run `/end-feature` themselves, rather than assuming a script would finalize the branch
- `end-feature`, `parallel-feature`, and `parallel-fix` skills set to manual-only invocation, so Claude no longer auto-triggers merges, pushes, or background-agent fan-out from inferred intent
- Finished migrating `Bash` permission patterns off the `cmd:*` glob form (`python*`, `pip*`, `swift*`, `make*` now match without the trailing `:*`)

### Added
- `templates/` directory to sync config (deploys to `~/.claude/templates/`)
- `claude-config/scripts/terminal-color.sh` for TTY-based per-session accent colors
- Synced directory entries can declare `exclude` patterns (rsync excludes); used to keep the claude.ai-managed `skills/synced/` tree out of the repo

### Fixed
- `sync.sh reconcile` honors `exclude` patterns — it enumerates files directly instead of through rsync, so it proposed importing all 219 files of the claude.ai-managed `skills/synced/` tree into the repo
- A directory dry-run lists the files it would write and delete, instead of printing only `Would sync directory`; deletions were previously impossible to preview
- `sync.sh` compared every directory as identical under bash 3.2, the version macOS ships: `"${arr[@]}"` on an empty array is an unbound variable under `set -u`, which killed the checksum subshell, and `local x=$(...)` discarded the failure. `status` reported everything synchronized and `pull`/`deploy` skipped all directories
- `directories_differ` reports a difference when a checksum comes back empty, rather than treating two failed computations as a match
- `/end-feature` leaves the worktree before merging — a worktree-isolated session cannot redirect git into the primary checkout, and main is already checked out there, so the merge step could never run for a branch started by `/start-feature`
- `/end-feature clean` removes the worktree and branch with plain git rather than `ExitWorktree remove`, which refuses before the merge and tracks the pre-rename branch name
- `/start-feature` derives the branch name once, so `fix-` arguments no longer produce `<user>/feature-fix-<label>`
- `/start-feature` checks `git check-ignore` for `.claude/worktrees/` and adds it when missing, instead of assuming every repo ignores `.claude/`
- `no-edit-main.py` allows edits to gitignored files on main, which cannot become commits; it was blocking scratch notes and `.claude/test-proposals/`
- viam-claude/README.md: removed phantom skills, added missing ones, fixed install path
- `claude-config/settings.sync.json` recovered 93 lines of live configuration it had never recorded, including nine status-line hook events, exposed once `pull` stopped aborting early
- `sync.sh status`/`deploy`/`pull` no longer abort after the first changed item — `((count++))` returns the pre-increment value, which is falsy on a counter's first call, killing the run under `set -e`
- `sync.sh status` no longer reports the skills directory or plugins as diverged when only excluded content differs — checksums and file/plugin counts now honor the same exclude patterns as sync itself
- Pulling or comparing plugins now excludes claude.ai-provisioned `@synced` plugins, which `install-plugins.sh` can't resolve on another machine
- `parallel-feature` and `script-writer` skill files renamed from `skill.md` to `SKILL.md` — the lowercase name loaded only on case-insensitive filesystems
- README.md and root CLAUDE.md file listings corrected to match what's currently shipped — dropped four removed agents and a removed script, added missing skills

## [2026-02-06]

### Changed
- Split CLAUDE.md into global config (`claude-config/CLAUDE.md`) and project-level file (repo root)
- Simplified claude-md-updater and project-spec-updater agents to focus on their own scope
- Streamlined README-SYNC.md — consolidated workflow examples, removed redundant sections
- Aligned branch naming convention (`<user>/feature-*`, `<user>/fix-*`) across all agents and skills

### Added
- `templates/CLAUDE.md` — lightweight template for new project CLAUDE.md files
- TODO.md reference link in project CLAUDE.md

### Removed
- Stale API key setup instructions from README.md and README-SYNC.md
- "Available Agents/Skills" inventory sections from global CLAUDE.md

## [2026-02-05]

### Changed
- Refactored sync system to be config-driven — all commands now parse `.sync-config.yaml` instead of hardcoded file lists

### Added
- TODO.md with remaining improvement opportunities

## [2026-02-04]

### Changed
- Replaced hardcoded paths with `~/.claude/` for portability
- Extracted statusline logic to `claude-config/statusline.sh`
- Removed API key sanitization/interpolation (assumes 1Password CLI)
- Made `jq` and `op` required dependencies
- Fixed directory checksum to use relative paths for consistent comparison
- Improved dry-run and confirmation prompts to only show actually-diverged files
- Refined settings permissions (removed chmod/chown/kill)

### Added
- `claude-config/api_key_helper.sh` and `claude-config/statusline.sh` to repo
- Auto-configure plugin marketplaces during deploy
- Recency coloring for diverged files in status output
- `--force` flag for scripted deploys
- `gen-module` skill: language, visibility, and resource-type parameters

### Fixed
- Backup cleanup race condition with spaces in filenames
- Plugin install error handling and output parsing

## [2026-01-26]

### Changed
- Converted viam-claude skills from project-specific (Makefile targets) to portable CLI commands
- Updated pre-work-check agent to discover test commands via LLM
- Updated start-feature skill to reference branch naming conventions with fallback

### Added
- `dataset-create` and `dataset-delete` skills for viam-claude
- Branch naming guidelines to CLAUDE.md
- VIAM.md reference documentation to viam plugin

### Removed
- Project-specific viam skills: `/cycle`, `/trial-start`, `/trial-stop`, `/trial-status`

## [2026-01-25]

### Added
- Bidirectional sync system (`sync.sh`, `lib/sync-core.sh`)
- `.sync-config.yaml` for declarative sync configuration
- `claude-config/settings.sync.json` with curated permission baseline
- `claude-config/plugins.txt` for plugin auto-installation
- `README-SYNC.md` documentation
- Reorganized agents and skills into `claude-config/` directory

## [2026-01-20]

### Added
- Development workflow in CLAUDE.md (feature branches, test scrutiny, parallel doc updates)
- Testing philosophy with anti-patterns table and language-agnostic examples
- Git safety rules for preserving uncommitted work
- 8 workflow agents: pre-work-check, test-scrutinizer, readme-updater, claude-md-updater, project-spec-updater, changelog-updater, completion-checker, retro-reviewer
- `/start-feature` skill
- `templates/project_spec.md`
- viam-claude plugin with reload, logs, status, gen-module, and guide skills
- Project README

## [2026-01-19]

### Added
- Initial CLAUDE.md with engineering guidelines
- `install.sh` setup script
