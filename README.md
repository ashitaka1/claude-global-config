# Claude Code Defaults

Global configuration and reusable components for Claude Code development workflow.

## What's Included

### Global Configuration

- **CLAUDE.md** - Global development standards, workflow, and testing philosophy
- **~/.claude/settings.json** - Pre-approved permissions for safe commands

### Agents (`claude-config/agents/`)

Workflow automation agents:

- `pre-work-check` - Verify branch and tests before starting work
- `test-scrutinizer` - Two-phase test plan review
- `readme-updater` - Update user documentation
- `claude-md-updater` - Update workflow documentation
- `project-spec-updater` - Update technical documentation
- `changelog-updater` - Maintain changelog
- `completion-checker` - Pre-merge quality gate
- `retro-reviewer` - Workflow optimization

### Skills (`claude-config/skills/`)

- `/start-feature <name>` - Create branch and launch guided development

### Templates

- `templates/project_spec.md` - Project specification template

### Plugins

- **viam-claude** - Viam robotics platform development tools
  - Install: `/plugin install /Users/apr/Developer/Claude-defaults/viam-claude`

## Installation

### Automated Sync (Recommended)

Use the built-in sync system to manage configuration:

```bash
# Clone this repository
git clone <repo-url> ~/Developer/Claude-defaults
cd ~/Developer/Claude-defaults

# Set up API key (if using api_key_helper)
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc

# Deploy to live config (installs plugins automatically)
./sync.sh deploy
```

### Manual Installation

Alternatively, manually copy files:
- `CLAUDE.md` → `~/.claude/CLAUDE.md`
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
   cd ~/Developer/Claude-defaults
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
   cd ~/Developer/Claude-defaults
   git pull
   ./sync.sh deploy
   ```

See [README-SYNC.md](README-SYNC.md) for detailed sync documentation.

## Usage

1. Copy `CLAUDE.md` to your home directory's `claude-config/` folder if you want truly global defaults
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
