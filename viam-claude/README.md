# viam-claude Plugin

Claude Code plugin for Viam robotics platform development.

## What's Included

### Skills (Slash Commands)

- `/reload` - Hot-reload module to connected machine
- `/cycle` - Execute a single test cycle on the arm
- `/trial-start` - Start continuous trial (background cycling)
- `/trial-stop` - Stop active trial, return cycle count
- `/trial-status` - Check trial status and cycle count
- `/logs` - View machine logs (optionally filtered)
- `/status` - Get machine/component health status
- `/gen-module` - Generate new Viam module scaffold

### Documentation

- `docs/VIAM_GUIDE.md` - Comprehensive best practices guide covering:
  - Viam CLI patterns and gRPC methods
  - Go module development with RDK
  - Data export and analysis techniques

The guide is also available as a non-invocable skill that Claude auto-loads for context.

## Installation

From your project directory:

```bash
/plugin install /Users/apr/Developer/Claude-defaults/viam-claude
```

Or add to your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "viam-claude@local": true
  }
}
```

## Usage

Once installed, slash commands are available:

```bash
# Hot-reload your module
/reload

# Check machine status
/status

# View logs
/logs error
```

Claude will also have access to Viam best practices when working on your Viam projects.

## Requirements

- Viam CLI installed and configured
- Project must have `machine.json` with part_id and machine_id (for commands that interact with machines)
- Makefile targets for project-specific commands (optional, for `/reload` etc.)

## Customization

The commands assume certain project conventions. You may need to adjust:

- `/reload` assumes `make reload-module` target exists
- Other commands may reference specific Makefile targets or project structure

Copy skills to your project's `.claude/skills/` directory and modify as needed for your specific setup.
