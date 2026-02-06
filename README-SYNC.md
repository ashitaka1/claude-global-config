# Claude Code Configuration Sync System

A bidirectional sync system for managing Claude Code configuration across multiple machines. Treats this repository as the canonical source while allowing experimentation in live config.

## Overview

The sync system enables a simple workflow:
1. **Experiment** in live config (`~/.claude/`)
2. **Pull** changes back to repo when satisfied
3. **Commit** and push changes to git
4. **Deploy** on other machines via git pull + sync

## Quick Start

```bash
# See what's different between repo and live config
./sync.sh status

# Deploy repo to live config
./sync.sh deploy --dry-run   # preview
./sync.sh deploy             # apply

# Pull live config changes back to repo
./sync.sh pull --dry-run     # preview
./sync.sh pull               # apply (requires confirmation)

# View detailed diffs
./sync.sh diff               # all differences
./sync.sh diff CLAUDE.md     # specific file
```

## What Gets Synced

Configuration is defined in `.sync-config.yaml`.

### Files (bidirectional)
- `claude-config/CLAUDE.md` ↔ `~/.claude/CLAUDE.md`
- `claude-config/settings.sync.json` ↔ `~/.claude/settings.json`
- `claude-config/api_key_helper.sh` ↔ `~/.claude/api_key_helper.sh`
- `claude-config/statusline.sh` ↔ `~/.claude/statusline.sh`

### Directories (bidirectional)
- `claude-config/agents/*` ↔ `~/.claude/agents/*`
- `claude-config/skills/*` ↔ `~/.claude/skills/*`

### Plugins
- `claude-config/plugins.txt` tracks installed plugins
- Deploy auto-installs plugins listed in the file
- Pull auto-updates the file from installed plugins

### Never Synced (runtime/local only)
- `~/.claude/cache/`, `~/.claude/plans/`, `~/.claude/plugins/`, `~/.claude/backups/`, and other runtime directories

## Typical Workflow

The workflow is the same regardless of what you're changing (agents, settings, CLAUDE.md, etc.):

```bash
# 1. Edit in live config
vim ~/.claude/agents/my-new-agent.md

# 2. Test with Claude Code, iterate until satisfied

# 3. Pull to repo
./sync.sh pull

# 4. Review and commit
git diff
git add claude-config/agents/my-new-agent.md
git commit -m "Add my-new-agent"
git push

# 5. Deploy on other machines
git pull && ./sync.sh deploy
```

## Safety Features

### Automatic Backups

Before any overwrite, the sync system creates compressed backups in `~/.claude/backups/sync/`. The last 10 backups per file/directory are retained.

### Dry-Run Mode

Preview changes before applying:

```bash
./sync.sh deploy --dry-run
./sync.sh pull --dry-run
```

### Confirmation Prompts

Pull operations (which overwrite repo files) require explicit "yes" confirmation.

## Command Reference

| Command | Description |
|---------|-------------|
| `./sync.sh status` | Show sync status (✓ in sync, ⚠ diverged, → repo only, ← live only) |
| `./sync.sh deploy [--dry-run]` | Deploy repo → live config (backs up, copies, installs plugins) |
| `./sync.sh pull [--dry-run]` | Pull live config → repo (requires confirmation) |
| `./sync.sh diff [target]` | Show differences (target matches on filename, e.g. `CLAUDE.md`, `agents`) |
| `./sync.sh help` | Show usage information |

## Setup on a New Machine

```bash
git clone <repo-url>
cd claude-global-config
./sync.sh deploy
```

## Troubleshooting

**Status shows "diverged" but I didn't change anything:**
The sync state is tracked in `.sync-state.json` (gitignored). Run `./sync.sh deploy` to re-sync.

**Accidentally pulled wrong changes:**
Backups are in `~/.claude/backups/sync/`. Extract with `tar xzf <backup-file>`. Or use `git checkout` to restore repo files from git history.

## Design Philosophy

- **Simple overwrites, not merges.** Deploy overwrites live config. Pull overwrites repo. Review with `diff` before pulling.
- **Git is the canonical source.** Live config is ephemeral and can be regenerated via deploy.
- **Config-driven.** All sync paths are defined in `.sync-config.yaml`, not hardcoded.

## See Also

- [claude-config/CLAUDE.md](claude-config/CLAUDE.md) - Global development standards and workflow
- [.sync-config.yaml](.sync-config.yaml) - Sync configuration
- [lib/sync-core.sh](lib/sync-core.sh) - Core sync functions
