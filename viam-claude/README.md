# viam-claude Plugin

Claude Code plugin for Viam robotics platform development.

## What's Included

### Skills (Slash Commands)

- `/reload` - Hot-reload module to connected machine
- `/logs` - View machine logs (optionally filtered)
- `/status` - Get machine/component health status
- `/gen-module` - Generate new Viam module scaffold
- `/dataset-create` - Create a dataset
- `/dataset-delete` - Delete a dataset

### Documentation

- `docs/VIAM_GUIDE.md` - Comprehensive best practices guide covering:
  - Viam CLI patterns and gRPC methods
  - Go module development with RDK
  - Data export and analysis techniques

The guide is also available as a non-invocable skill (`/viam-guide`) that Claude auto-loads for context.

## Installation

From the repo root:

```bash
claude plugin install ./viam-claude
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

# Create a dataset
/dataset-create
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
