# Claude Code Configuration Sync System

A bidirectional sync system for managing Claude Code configuration across multiple machines. Treats this repository as the canonical source while allowing experimentation in live config.

## Overview

The sync system enables a simple workflow:
1. **Experiment** in live config (`~/.claude/`)
2. **Pull** changes back to repo when satisfied
3. **Commit** and push changes to git
4. **Deploy** on other machines via git pull + sync

## Quick Start

### Check Status

See what's different between repo and live config:

```bash
./sync.sh status
```

### Deploy Repo to Live Config

Copy configuration from repository to `~/.claude/`:

```bash
# Preview changes
./sync.sh deploy --dry-run

# Apply changes
./sync.sh deploy
```

### Pull Live Config to Repo

Copy experimental changes from `~/.claude/` back to repository:

```bash
# Preview changes
./sync.sh pull --dry-run

# Apply changes
./sync.sh pull

# Review and commit
git diff
git add -A
git commit -m "Update configuration from live experiments"
git push
```

### View Differences

Show detailed diffs between repo and live config:

```bash
# Show all differences
./sync.sh diff

# Show specific file
./sync.sh diff CLAUDE.md
./sync.sh diff settings
./sync.sh diff agents
./sync.sh diff skills
```

## What Gets Synced

### Files (bidirectional)
- `CLAUDE.md` ↔ `~/.claude/CLAUDE.md`
- `claude-config/settings.sync.json` ↔ `~/.claude/settings.json`
- `claude-config/api_key_helper.sh` ↔ `~/.claude/api_key_helper.sh` (with sanitization)
- `claude-config/plugins.txt` ↔ installed plugins (auto-install on deploy, auto-update on pull)

### Directories (bidirectional)
- `claude-config/agents/*` ↔ `~/.claude/agents/*`
- `claude-config/skills/*` ↔ `~/.claude/skills/*`

### Never Synced (runtime/local only)
- `~/.claude/cache/`
- `~/.claude/history.jsonl`
- `~/.claude/plans/`
- `~/.claude/session-env/`
- `~/.claude/plugins/`
- `~/.claude/backups/`
- All other runtime directories

## Workflow Examples

### Scenario 1: Add a New Agent

```bash
# Create agent in live config
vim ~/.claude/agents/my-new-agent.md

# Test it with Claude Code
# ... verify it works ...

# Check what changed
./sync.sh status
./sync.sh diff agents

# Pull to repo
./sync.sh pull

# Commit
git add claude-config/agents/my-new-agent.md
git commit -m "Add my-new-agent"
git push

# Deploy on other machines
# (on another machine)
git pull
./sync.sh deploy
```

### Scenario 2: Install a New Plugin

```bash
# Install plugin in Claude Code
/plugin install new-plugin@claude-plugins-official

# Or use claude CLI
claude plugin install new-plugin@claude-plugins-official

# Pull to update plugins.txt
./sync.sh pull

# Commit
git add claude-config/plugins.txt
git commit -m "Add new-plugin"
git push

# Deploy on other machines (auto-installs the plugin)
git pull
./sync.sh deploy
```

### Scenario 3: Update CLAUDE.md Workflow

```bash
# Edit live config
vim ~/.claude/CLAUDE.md

# Test changes with Claude Code
# ... verify workflow works ...

# Pull to repo
./sync.sh pull --dry-run  # Preview
./sync.sh diff CLAUDE.md  # See exact changes
./sync.sh pull            # Apply

# Commit
git add CLAUDE.md
git commit -m "Update workflow documentation"
git push
```

### Scenario 4: Sync Settings Across Machines

```bash
# On machine A: update settings
vim ~/.claude/settings.json

# Pull and push
./sync.sh pull
git add .claude/settings.sync.json
git commit -m "Update settings"
git push

# On machine B: receive settings
git pull
./sync.sh deploy
```

## Safety Features

### Automatic Backups

Before any overwrite operation, the sync system creates compressed backups:

```bash
~/.claude/backups/sync/
├── CLAUDE.md.20260125-180000.tar.gz
├── settings.json.20260125-180100.tar.gz
└── agents.20260125-180200.tar.gz
```

Backups are kept for the last 10 operations per file/directory.

### Dry-Run Mode

Preview changes before applying:

```bash
./sync.sh deploy --dry-run  # See what would change
./sync.sh pull --dry-run    # See what would be pulled
```

### Confirmation Prompts

Pull operations (which overwrite repo files) require explicit confirmation:

```bash
$ ./sync.sh pull
⚠  This will overwrite repo files with live config
Affected: CLAUDE.md, settings.sync.json, agents/, skills/

Continue? (yes/no):
```

## API Key Management

The sync system handles API keys securely:

### On Pull (live → repo):
- Hardcoded API key values are replaced with `$ANTHROPIC_API_KEY` placeholder
- Sanitized version stored in repo (safe to commit)

### On Deploy (repo → live):
- Placeholder interpolated with actual key from `$ANTHROPIC_API_KEY` environment variable
- Working script deployed to `~/.claude/api_key_helper.sh`

### Setup:

Add to your `~/.zshrc`:

```bash
export ANTHROPIC_API_KEY='your-api-key-here'
```

Then:

```bash
source ~/.zshrc
./sync.sh deploy
```

## Command Reference

### `./sync.sh status`

Show sync status between repo and live config.

**Output:**
- ✓ In sync
- ⚠ Diverged
- → Repo only
- ← Live only

### `./sync.sh deploy [--dry-run]`

Deploy repository → live config (overwrite).

**Options:**
- `--dry-run`: Preview changes without modifying files

**What it does:**
1. Backs up existing live config files
2. Copies repo files to `~/.claude/`
3. Interpolates API key in `api_key_helper.sh`
4. Updates sync state

### `./sync.sh pull [--dry-run]`

Pull live config → repository (overwrite).

**Options:**
- `--dry-run`: Preview changes without modifying files

**What it does:**
1. Confirms operation (requires "yes")
2. Backs up existing repo files
3. Copies live config to repo
4. Sanitizes API key in `api_key_helper.sh`
5. Updates sync state

**Note:** After pull, review changes with `git diff` before committing.

### `./sync.sh diff [file]`

Show differences between repo and live config.

**Arguments:**
- No argument: Show all differences
- `CLAUDE.md`: Diff CLAUDE.md
- `settings`: Diff settings.json
- `api_key_helper`: Diff api_key_helper.sh
- `agents`: Diff agents directory
- `skills`: Diff skills directory

### `./sync.sh help`

Show usage information and examples.

## Multi-Machine Workflow

### Initial Setup on New Machine

```bash
# Clone repo
git clone <repo-url> ~/Developer/Claude-defaults
cd ~/Developer/Claude-defaults

# Set API key
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc

# Deploy configuration
./sync.sh deploy

# Verify
./sync.sh status
```

### Ongoing Sync Workflow

```bash
# Receive changes from other machines
git pull
./sync.sh status
./sync.sh deploy

# Make local changes
vim ~/.claude/CLAUDE.md

# Share changes
./sync.sh pull
git add -A && git commit -m "Update config"
git push
```

## Troubleshooting

### Status shows "diverged" but I didn't change anything

The sync state is tracked in `.sync-state.json` (gitignored). If you deploy on one machine and not others, status will show divergence.

**Solution:** Run `./sync.sh deploy` to sync with current repo state.

### API key helper deployment fails

Error: `ANTHROPIC_API_KEY not set in environment`

**Solution:**
```bash
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
./sync.sh deploy
```

### Accidentally pulled wrong changes

All overwrites create backups in `~/.claude/backups/sync/`.

**Solution:**
```bash
# Extract backup
cd ~
tar xzf ~/.claude/backups/sync/CLAUDE.md.20260125-180000.tar.gz

# Or for repo files
cd ~/Developer/Claude-defaults
tar xzf ~/.claude/backups/sync/CLAUDE.md.20260125-180000.tar.gz
```

### Want to restore an old version

Check git history:

```bash
git log --oneline CLAUDE.md
git show <commit>:CLAUDE.md
git checkout <commit> -- CLAUDE.md
```

## Advanced Usage

### Inspect Sync State

The sync state is stored in `.sync-state.json`:

```bash
cat .sync-state.json | python3 -m json.tool
```

Shows last deploy/pull timestamps and file checksums.

### Manual Backup Before Risky Operation

```bash
# Backup live config
tar czf ~/claude-backup-$(date +%Y%m%d).tar.gz ~/.claude/

# Backup repo
tar czf ~/repo-backup-$(date +%Y%m%d).tar.gz ~/Developer/Claude-defaults/
```

### Verify Checksums

```bash
# Compute checksum of a file
shasum -a 256 ~/.claude/CLAUDE.md

# Compare with repo
shasum -a 256 ~/Developer/Claude-defaults/CLAUDE.md
```

## Design Philosophy

### Simple Overwrite Strategy

The sync system uses simple overwrites (not intelligent merging):
- **Deploy:** Repo completely overwrites live config
- **Pull:** Live config completely overwrites repo

**Why:** Simple, predictable, and fits the "experiment then promote" workflow. Review changes with `diff` before pulling.

### Canonical Source in Git

The repository is the authoritative source:
- Live config is ephemeral (can be regenerated via deploy)
- All permanent changes flow through git
- Multi-machine sync via standard git workflow

### Global + Project-Specific

- **Global:** `~/.claude/agents/` and `~/.claude/skills/` available everywhere
- **Project:** Individual projects can add `claude-config/agents/` for project-specific agents

## See Also

- [CLAUDE.md](CLAUDE.md) - Main workflow and conventions
- [.sync-config.yaml](.sync-config.yaml) - Sync configuration
- [lib/sync-core.sh](lib/sync-core.sh) - Core sync functions
