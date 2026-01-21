# Claude Code Defaults

Global configuration and reusable components for Claude Code development workflow.

## What's Included

### Global Configuration

- **CLAUDE.md** - Global development standards, workflow, and testing philosophy
- **~/.claude/settings.json** - Pre-approved permissions for safe commands

### Agents (`.claude/agents/`)

Workflow automation agents:

- `pre-work-check` - Verify branch and tests before starting work
- `test-scrutinizer` - Two-phase test plan review
- `readme-updater` - Update user documentation
- `claude-md-updater` - Update workflow documentation
- `project-spec-updater` - Update technical documentation
- `changelog-updater` - Maintain changelog
- `completion-checker` - Pre-merge quality gate
- `retro-reviewer` - Workflow optimization

### Skills (`.claude/skills/`)

- `/start-feature <name>` - Create branch and launch guided development

### Templates

- `templates/project_spec.md` - Project specification template

### Plugins

- **viam-claude** - Viam robotics platform development tools
  - Install: `/plugin install /Users/apr/Developer/Claude-defaults/viam-claude`

## Installation

The global `CLAUDE.md` in this repo should be copied to `~/.claude/CLAUDE.md` to apply across all projects.

Agents and skills are already in `.claude/` directories and will be discovered by Claude Code.

## Usage

1. Copy `CLAUDE.md` to your home directory's `.claude/` folder if you want truly global defaults
2. Or keep project-specific by copying sections to individual project CLAUDE.md files
3. Install viam-claude plugin for Viam projects: `/plugin install <path-to-this-repo>/viam-claude`
4. Use agents during development: `pre-work-check`, `test-scrutinizer`, `completion-checker`, etc.

## Workflow

See `CLAUDE.md` for the complete development workflow, including:
- Starting work on feature branches
- Two-phase test scrutiny
- Parallel documentation updates on commit
- Pre-merge quality checks

## Philosophy

- **Self-documenting code over comments**
- **Test custom logic, not libraries**
- **Never discard uncommitted work**
- **Separate concerns**: CLAUDE.md (workflow) vs project_spec.md (technical) vs README.md (users)
