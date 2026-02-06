# Project Specification: claude-global-config

## Purpose

This project provides a global configuration system for Claude Code, enabling consistent development workflows, automated documentation, and workflow agents across all projects and machines.

## User Profile

**Primary users:** Developers using Claude Code for software development

**Goals:**
- Maintain consistent development practices across projects
- Automate repetitive documentation tasks
- Enforce quality standards through automated agents
- Sync configuration across multiple machines

## Goals

**Goal:** Provide a portable, version-controlled Claude Code configuration system that works across machines

**Goal:** Enable reproducible development workflows through agents and slash commands

**Goal:** Automate documentation updates through specialized agents

**Non-Goal:** Provide language-specific tooling or frameworks

**Non-Goal:** Replace project-specific configuration

## Features

### Required
- Bidirectional sync system for deploying configuration
- Global development standards (CLAUDE.md)
- Workflow automation agents (pre-work-check, completion-checker, etc.)
- Documentation updater agents (readme-updater, changelog-updater, etc.)
- Slash commands for common workflows
- Settings management
- Project templates

### Milestones

1. ✅ Core sync system functional
2. ✅ Global CLAUDE.md with development workflow
3. ✅ Script consolidation and statusline rewrite
4. ⏳ Worktree-based feature development workflow
5. ⏳ Cross-platform compatibility

## Tech Stack

### Language(s)
- Bash (primary - for sync system and scripts)
- Markdown (documentation and agent definitions)
- JSON (settings)
- YAML (sync configuration)

### Tools
- `yq` for YAML parsing
- `git` for version control and worktrees
- `claude` CLI for plugin management
- `stat` for file metadata

### Platform/Deployment
- Runs on macOS (primary target)
- Linux support planned (requires platform detection)
- Deployed to `~/.claude/` via `sync.sh`

## Technical Architecture

### Components

- **sync.sh**: Main CLI entry point for sync operations (status, deploy, pull, push)
- **lib/sync-core.sh**: Shared sync functions and core logic
- **.sync-config.yaml**: Configuration defining what files/directories to sync and where
- **claude-config/**: Canonical source directory for all configuration files
  - **CLAUDE.md**: Global development standards and workflow
  - **agents/**: Workflow automation agents (markdown files)
  - **scripts/**: Shell scripts (api_key_helper.sh, statusline.sh, terminal-color.sh)
  - **skills/**: Slash commands (start-feature, feature-dev, etc.)
  - **settings.sync.json**: Claude Code settings
  - **plugins.txt**: List of plugins to install
- **templates/**: Project templates (CLAUDE.md, project_spec.md)
- **viam-claude/**: Viam robotics platform plugin

### Data Schema

**Sync Configuration (.sync-config.yaml):**
```yaml
files:
  - source: path/in/repo
    target: path/in/home
    name: display-name
```

**Settings (settings.sync.json):**
- Standard Claude Code settings format
- Uses `.sync` suffix in repo to distinguish from live `settings.json`

### Configuration Variables

- `~/.claude/`: Target deployment directory
- `.sync-backups/`: Backup directory for replaced files

## Milestone Architecture Decisions

### Milestone 3: Script Consolidation and Statusline Rewrite

**Approach:** Consolidated all scripts into `claude-config/scripts/` directory and rewrote statusline with enhanced features

**Key Decisions:**
- Created `claude-config/scripts/` directory for better organization (instead of loose files in `claude-config/`)
- Rewrote statusline.sh to include: model name, context window bar, remote sync status, per-session color theming, last user message
- Added `terminal-color.sh` for TTY-based accent colors that vary per terminal session
- Updated `.sync-config.yaml` to use directory sync for scripts
- Updated `settings.sync.json` to reference new script paths in `~/.claude/scripts/`

**Trade-offs considered:**
- Flat structure in claude-config: Simpler but harder to manage as scripts grow
- Per-file sync config: More verbose YAML but more explicit control
- Directory sync: Chosen for simplicity and automatic inclusion of new scripts

**Files affected:**
- `claude-config/scripts/api_key_helper.sh` (moved from `claude-config/`)
- `claude-config/scripts/statusline.sh` (rewritten)
- `claude-config/scripts/terminal-color.sh` (new)
- `claude-config/settings.sync.json` (updated paths)
- `.sync-config.yaml` (added scripts directory)

### Milestone 4: Worktree-Based Feature Development (In Progress)

**Approach:** Use git worktrees for feature branches instead of branch switching

**Key Decisions:**
- Place worktrees in `.worktrees/` directory (added to .gitignore)
- Modified `/start-feature` skill to create worktrees automatically
- Updated global CLAUDE.md to document worktree workflow
- Updated pre-work-check agent description to emphasize running before changes
- Added worktree cleanup step to "Completing Work" workflow

**Rationale:**
- Subagents launched via Task tool cannot access files outside project root
- Worktrees keep all development within the project directory tree
- Avoids permission scoping issues with external paths
- Allows parallel work on multiple features without stashing

**Trade-offs considered:**
- Branch switching: Simpler mental model but requires stashing, conflicts with subagent permissions
- External worktrees (e.g., `~/worktrees/`): Cleaner project dir but breaks subagent access
- In-project worktrees: Chosen for subagent compatibility despite adding .worktrees/ directory

**Files affected:**
- `claude-config/CLAUDE.md` (updated workflow documentation)
- `claude-config/skills/start-feature/SKILL.md` (modified to create worktrees)
- `claude-config/agents/pre-work-check.md` (clarified when to use)
- `.gitignore` (added `.worktrees/`)

**Open questions:**
- Should we provide a `/clean-worktrees` skill for batch cleanup?
- How to handle worktree references in project-specific MEMORY.md?

## Implementation Notes

### Worktree Directory Naming
Branch names use `/` (e.g., `ashitaka1/feature-foo`) but worktree directories use `-` (e.g., `.worktrees/ashitaka1-feature-foo`) because `/` in directory names complicates path handling.

### Sync Config Discipline
When adding new files to deploy, always update `.sync-config.yaml` rather than hardcoding paths in shell scripts. This keeps the sync system maintainable and self-documenting.

### Settings File Naming Convention
Settings file uses `.sync.json` suffix in repo (`settings.sync.json`) to distinguish it from live `settings.json` in `~/.claude/`. The sync system strips the suffix during deployment.

### Script Path References
After consolidating scripts to `claude-config/scripts/`, all references in `settings.sync.json` and documentation must use `~/.claude/scripts/` prefix. This caught multiple references that needed updating.

### Statusline Design
The rewritten statusline includes multiple information sources in a single line:
- Model name (from Claude API or cache)
- Context window usage as visual bar
- Git branch and sync status
- Per-session color theming based on TTY
- Last user message preview

This required careful shell scripting to handle errors gracefully and avoid blocking the prompt.

## Technical Debt

### Platform-specific `stat` command
**Location:** `lib/sync-core.sh` in `format_file_details()`

Uses macOS syntax: `stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file"`

GNU stat (Linux) uses different flags. Need platform detection and conditional syntax.

### Plugin list parsing fragility
**Location:** `lib/sync-core.sh` in plugin sync functions

Parses `claude plugin list` output with: `grep -E '^\s+❯' | awk '{print $2}'`

This depends on exact CLI output format. Should use more robust parsing or handle format changes gracefully.

### No test suite
The project consists primarily of shell scripts but has no automated tests. Validation is manual via `./sync.sh status`. Consider adding basic integration tests.

### Viam plugin coupling
The `viam-claude/` directory is domain-specific (robotics) and creates coupling. Consider moving to separate repo or documenting as optional example.

## Development Process

### Testing approach
- Manual validation via `./sync.sh status`
- Dry-run testing with `./sync.sh deploy --dry-run`
- Live testing on local machine before committing

### Deployment
- User runs `./sync.sh deploy` to push changes to `~/.claude/`
- User runs `./sync.sh pull` to bring live changes back to repo
- User runs `./sync.sh status` to check sync state

### Code review
Solo development currently. Standard git workflow with feature branches and merge to main.
