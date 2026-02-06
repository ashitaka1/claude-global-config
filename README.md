# Claude Code Defaults

Global configuration and reusable components for Claude Code development workflow.

## What's Included

### Global Configuration (`claude-config/`)

- **CLAUDE.md** - Global development standards, workflow, and testing philosophy (deployed to `~/.claude/CLAUDE.md`)
- **settings.sync.json** - Pre-approved permissions for safe commands, includes hook to prevent accidental edits on main
- **scripts/** - Shell utilities (deployed to `~/.claude/scripts/`)
  - `api_key_helper.sh` - API key management helper
  - `statusline.sh` - Status line with model, git status, sync state, context bar
  - `terminal-color.sh` - Per-session TTY-based color theming

### Agents (`claude-config/agents/`)

Workflow automation agents:

- `pre-work-check` - Verify branch and tests before starting work
- `test-scrutinizer` - Two-phase test plan review
- `readme-updater` - Update user documentation
- `claude-md-updater` - Update project-level workflow documentation
- `project-spec-updater` - Update technical documentation
- `changelog-updater` - Maintain changelog
- `completion-checker` - Pre-merge quality gate
- `retro-reviewer` - Workflow optimization

### Skills (`claude-config/skills/`)

- `/start-feature <name>` - Create worktree with feature branch and launch guided development

### Templates (`templates/`)

- `CLAUDE.md` - Project-level CLAUDE.md template
- `project_spec.md` - Project specification template

### Plugins

- **viam-claude** - Viam robotics platform development tools

## Installation

### Automated Sync (Recommended)

Use the built-in sync system to manage configuration:

```bash
# Clone this repository
git clone <repo-url>
cd claude-global-config

# Deploy to live config (installs plugins automatically)
./sync.sh deploy
```

### Manual Installation

Alternatively, manually copy files:
- `claude-config/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `claude-config/agents/*` → `~/.claude/agents/*`
- `claude-config/skills/*` → `~/.claude/skills/*`
- `claude-config/settings.sync.json` → `~/.claude/settings.json`

## Configuration Sync

### Making Configuration Changes

1. **Experiment in Live Config**
   ```bash
   # Edit files in ~/.claude/ directly
   vim ~/.claude/CLAUDE.md
   # OR add a new agent
   vim ~/.claude/agents/my-new-agent.md
   ```

2. **Check Status**
   ```bash
   ./sync.sh status
   ```

3. **Preview Changes**
   ```bash
   ./sync.sh pull --dry-run
   ./sync.sh diff CLAUDE.md
   ```

4. **Pull Changes into Repo**
   ```bash
   ./sync.sh pull
   ```

5. **Review and Commit**
   ```bash
   git diff
   git add -A
   git commit -m "Update configuration from live experiments"
   git push
   ```

6. **Deploy on Other Machines**
   ```bash
   # On another machine
   git pull
   ./sync.sh deploy
   ```

See [README-SYNC.md](README-SYNC.md) for detailed sync documentation.

## Usage

1. Run `./sync.sh deploy` to install global config to `~/.claude/`
2. Copy `templates/CLAUDE.md` and `templates/project_spec.md` into new projects for project-level config
3. Use agents during development: `pre-work-check`, `test-scrutinizer`, `completion-checker`, etc.

## Workflow

See `claude-config/CLAUDE.md` for the complete development workflow, including:
- Starting work on feature branches
- Two-phase test scrutiny
- Parallel documentation updates on commit
- Pre-merge quality checks

## Philosophy

- **Self-documenting code over comments**
- **Test custom logic, not libraries**
- **Never discard uncommitted work**
- **Separate concerns**: Global CLAUDE.md (standards) vs project CLAUDE.md (project context) vs project_spec.md (technical) vs README.md (users)
