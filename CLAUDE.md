# CLAUDE.md — claude-global-config

This file provides project-specific guidance for working on this repository.

## Current Status

Project phase: Active Development

Configuration sync system is functional. Ongoing work on sync robustness and documentation.

## About This Repository

This is a Claude Code global configuration repository. It manages:
- Global development standards (`claude-config/CLAUDE.md` — deployed to `~/.claude/CLAUDE.md`)
- Workflow automation agents (`claude-config/agents/`)
- Skills / slash commands (`claude-config/skills/`)
- Settings (`claude-config/settings.sync.json`)
- A bidirectional sync system (`sync.sh`) for deploying config across machines
- Project templates (`templates/`)
- A Viam robotics plugin (`viam-claude/`)

See `project_spec.md` for technical architecture and decisions.

## Project-Specific Conventions

### Testing

This project is primarily shell scripts and markdown. There is no `make test` target. Validation is done by running `./sync.sh status` and verifying sync behavior manually.

### Sync Development

When modifying the sync system (`sync.sh`, `lib/sync-core.sh`, `.sync-config.yaml`):
- Always test with `--dry-run` before live runs
- The sync config at `.sync-config.yaml` is the source of truth for what gets synced
- `lib/sync-core.sh` contains shared functions; `sync.sh` is the CLI entry point

### File Layout

```
claude-config/          # Canonical source for global config
  CLAUDE.md             # Global CLAUDE.md (deployed to ~/.claude/)
  agents/               # Workflow agents (deployed to ~/.claude/agents/)
  skills/               # Slash commands (deployed to ~/.claude/skills/)
  settings.sync.json    # Settings (deployed to ~/.claude/settings.json)
  api_key_helper.sh     # API key helper script
  statusline.sh         # Shell status line script
  plugins.txt           # Plugin list (auto-installed on deploy)
templates/              # Project templates
  CLAUDE.md             # Template for new project CLAUDE.md files
  project_spec.md       # Template for project specifications
viam-claude/            # Viam robotics platform plugin
sync.sh                 # Main sync CLI
lib/sync-core.sh        # Core sync library
```
