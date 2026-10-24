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
4. ✅ Branch-based feature development workflow
5. 🔎 Project state tracked in GitHub issues. Check: in a project whose CLAUDE.md declares `Tracking: GitHub issues (<owner>/<repo>)`, `update-project-spec` files a milestone, a question, and a debt item as issues, and `/completion-check` lists the open milestones and the issues the branch closes; in a project tracking two repos, `/issue` creates an issue blocked by one in the other repo and `/next` leaves it out of the ready list until the blocker closes
6. ⏳ Shared config moved to `viamrobotics/claude-code-configuration`, with this repo holding only personal config. Check: every non-personal item here has a merged upstream PR or a recorded reason to stay, and `./sync.sh deploy` leaves an upstream `make install` intact
7. ⏳ Cross-platform compatibility

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
  - **scripts/**: Hook and helper scripts (no-edit-main.py, statusline.sh, terminal-color.sh)
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
- No `model` key, so Claude Code uses its default
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

### Milestone 4: Branch-Based Feature Development

**Approach:** Feature work happens on a plain branch in the primary checkout; worktrees are reserved for concurrent work

**Key Decisions:**
- `/start-feature` runs `git switch -c <branch>`; `/end-feature` switches to main, merges, and deletes the branch
- A second session in the same repo starts with `claude -w <name>`; `/end-feature` calls `ExitWorktree` with `keep` before merging from such a session, then removes the worktree with plain git
- Agents run with `isolation: "worktree"`; the harness creates the worktree under `.claude/worktrees/agent-<id>` and removes it if nothing changed
- An agent owing the coordinator a specific branch renames its own with `git branch -m`
- `worktree.baseRef` set to `head`, so worktrees fork from local work rather than `origin/<default-branch>`

**Rationale:**
- A worktree's only benefit is a second working directory for concurrent sessions or agents, which interactive feature work rarely needs; for a single session it costs an exit before every merge, harness branch naming, and worktrees left behind in repos
- Parallel agents edit concurrently, so they keep worktrees
- Subagent worktrees inherit `baseRef`; under `fresh` a bug-fixer spawned from a feature branch would silently start from the remote default branch

**Trade-offs considered:**
- Hand-rolled worktrees in `.worktrees/` with a `worktree-git.sh` wrapper: written when agents could not persist `cd` between Bash calls, and it required a hook to block `cd && git` and the directory flag
- `EnterWorktree` in `/start-feature`: the previous approach. The harness names the branch `worktree-<name>`, so the skill renamed it, leaving `ExitWorktree` tracking a branch that no longer existed, and it appended `.claude/worktrees/` to each repo's `.gitignore`
- A `WorktreeCreate` hook to name the branch directly: works, but replacing harness creation also replaces its `baseRef` handling and agent auto-cleanup, which the hook then has to reimplement
- Plain branches: chosen, because concurrent sessions in one repo are rare and `claude -w` covers them

**Files affected:**
- `claude-config/CLAUDE.md`
- `claude-config/skills/start-feature/SKILL.md`, `end-feature/SKILL.md`

**Open questions:**
- `/parallel-fix` still has the coordinator assign branch names; worth testing whether the rename step holds up across a full parallel run

## Implementation Notes

### Main-Branch Edit Guard
`claude-config/scripts/no-edit-main.py` runs as a hook and blocks edits and commits while the checkout is on `main`. A `UserPromptSubmit` hook records `!onmain` from the user's prompt, and the guard allows edits for the rest of that session. Only the user's prompt counts; the agent cannot set it.

### GitHub Issue Tracking
A project opts in with a `Tracking: GitHub issues (...)` line in its CLAUDE.md naming one repo or several, optionally followed by `; project <owner>/<number>` and `; auto-add <owner>/<repo>`. Milestones are GitHub milestones with plain-name titles whose description contains a `Check:` line; a milestone with work in several repos is a same-titled milestone in each. Questions and debt are the issue types `Question` and `Tech debt` in an organization's repos and the labels `question` and `tech-debt` in a personal account's, created on first use. Planned work is an issue. Commits that resolve an issue end with `Closes #N` or `Closes <owner>/<repo>#N`. Without the line, these stay in `project_spec.md`.

Dependencies are native blocked-by links between the specific issues that depend. A milestone neither blocks nor is blocked: a milestone-level dependency is lossy, and in Ascension two milestones each waited on the other, a cycle that resolves into a chain at issue level. `/next` finds ready work with the advanced search (`advanced_search=true`; the plain search ignores `is:blocked`), joining several `repo:` qualifiers with `OR`, since the advanced engine ANDs them. The search index lags closes by a few minutes, so `/next` can propose a just-closed issue; the owner's confirmation catches it. An agent relies on auto-add only for a repo the Tracking line lists, and adds others with `gh project item-add`.

### Worktree Placement
The harness puts worktrees under `.claude/worktrees/`, names agent worktrees after the agent id, and names the branch `worktree-<name>`.

### Sync Config Discipline
When adding new files to deploy, always update `.sync-config.yaml` rather than hardcoding paths in shell scripts. This keeps the sync system maintainable and self-documenting.

### Settings File Naming Convention
Settings file uses `.sync.json` suffix in repo (`settings.sync.json`) to distinguish it from live `settings.json` in `~/.claude/`. The sync system strips the suffix during deployment.

### Portable Settings
Sync compares settings files by their JSON content, with hook and status-line `command` strings rewritten so the machine's home path reads `$HOME/`, and writes settings files in that form in both directions. iTerm2 installs its `cc-status` hooks with an absolute home path and rewrites `settings.json` in its own JSON formatting; the work and personal machines have different usernames.

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

### Conflicts with Viam's shared config
Viam's shared config, `viamrobotics/claude-code-configuration` (cloned at `~/eng/claude-code-config`), also installs into `~/.claude/`. Its `make install` merges item by item. `./sync.sh deploy` replaces `skills/`, `scripts/`, and `agents/` with `rsync --delete` and copies `settings.json` whole (`lib/sync-core.sh:480`), so a deploy erases what that install added: its skills, scripts, and agents, and the permissions, hooks, and `statusLine` it merged into settings.

The repos also overlap:
- `viam-claude/` here and `plugins/viam-claude/` upstream are diverged copies of one plugin. This copy has `skills/`; upstream has `commands/`.
- Both ship `terminal-color.sh` and a status line script (`statusline.sh` here, `status-line.sh` upstream), with different contents.
- Upstream's `worktree-enforcement` bundle (`rules/worktree-only.md`, `/new-work`) requires a worktree for every edit. This repo develops on plain branches in the primary checkout.
- Upstream's `rules/code-comments.md` and `rules/pull-request.md` overlap the global CLAUDE.md's **Writing** section.

### No test suite
The project consists primarily of shell scripts but has no automated tests. Validation is manual via `./sync.sh status`. Consider adding basic integration tests.

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
