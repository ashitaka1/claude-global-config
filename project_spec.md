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
- Workflow automation agents (pre-work-check, test-scrutinizer, etc.)
- Documentation updater skills (update-readme, update-changelog, etc.)
- Slash commands for common workflows
- Settings management
- Project templates

### Milestones

1. ✅ Core sync system functional
2. ✅ Global CLAUDE.md with development workflow
3. ✅ Script consolidation and statusline rewrite
4. ✅ Worktree-based feature development workflow
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

### Milestone 4: Worktree-Based Feature Development

**Approach:** Use Claude Code's native worktree isolation rather than managing worktrees by hand

**Key Decisions:**
- Agents run with `isolation: "worktree"`; the harness creates the worktree under `.claude/worktrees/agent-<id>` and removes it if nothing changed
- `/start-feature` calls `EnterWorktree`, which moves the session's working directory
- `/end-feature` calls `ExitWorktree` with `keep` *before* merging, because a worktree-isolated session cannot reach the primary checkout; cleanup afterwards is plain `git worktree remove` and `git branch -d`
- An agent owing the coordinator a specific branch renames its own with `git branch -m`
- `worktree.baseRef` set to `head`, so worktrees fork from local work rather than `origin/<default-branch>`

**Rationale:**
- Subagents cannot reach paths outside the project root, and native isolation places worktrees inside it
- Inside its worktree an agent runs plain `git`, so no wrapper script or directory flag is needed
- Subagent worktrees inherit `baseRef`; under `fresh` a bug-fixer spawned from a feature branch would silently start from the remote default branch

**Trade-offs considered:**
- Hand-rolled worktrees in `.worktrees/` with a `worktree-git.sh` wrapper: what this replaced. Written when agents could not persist `cd` between Bash calls, and it required a hook to block `cd && git` and the directory flag
- `claude -w` at session start: works, but fixes the branch decision before the session begins
- `EnterWorktree` mid-session: chosen, because branch and tree creation stay in the REPL where the decision is actually made

**Files affected:**
- `claude-config/CLAUDE.md` (dropped the directory-flag guidance)
- `claude-config/skills/start-feature/SKILL.md`, `end-feature/SKILL.md`
- `claude-config/skills/shared/references/agent-ops.md`, `parallel-fix`, `parallel-feature`
- `claude-config/agents/bug-fixer.md`
- `claude-config/settings.sync.json` (hook removed, `worktree.baseRef`)

**Open questions:**
- `/parallel-fix` still has the coordinator assign branch names; worth testing whether the rename step holds up across a full parallel run

## Implementation Notes

### Worktree Placement
Worktrees live under `.claude/worktrees/`. This repo covers that with its `.claude/` entry in `.gitignore`, but most repos do not, so `/start-feature` checks with `git check-ignore` and appends the entry when it is missing. The harness names agent worktrees after the agent id.

`EnterWorktree` does not use its `name` argument as the branch name: it replaces `/` with `+` and prefixes `worktree-`. `/start-feature` renames the branch afterwards, which leaves `ExitWorktree` reporting a branch that no longer exists — the reason cleanup uses plain git rather than `ExitWorktree remove`.

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
