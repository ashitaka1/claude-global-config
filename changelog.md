# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Changed
- `install.sh` now installs dependencies then runs `sync.sh deploy` instead of printing manual next steps
- Documented `.sync` suffix naming convention in README-SYNC.md

### Added
- `templates/` directory to sync config (deploys to `~/.claude/templates/`)

### Fixed
- viam-claude/README.md: removed phantom skills, added missing ones, fixed install path

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
