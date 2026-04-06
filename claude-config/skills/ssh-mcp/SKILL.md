---
name: ssh-mcp
description: >
  Add an SSH MCP server for a remote host. Defaults to project scope with
  standard credentials. Use when you need to connect to a remote machine
  via SSH MCP.
argument-hint: <host> [--user USER] [--scope user] [--name NAME] [--no-sudo]
---

# SSH MCP Setup

Add an SSH MCP server using tufantunc/ssh-mcp.

## Arguments

Parse `$ARGUMENTS` for:
- **host** (required, positional): hostname or IP address
- **--user USER**: SSH username (default: `viam`)
- **--scope user**: use user-level scope instead of project scope
- **--name NAME**: MCP server name (default: `ssh-<host>`)
- **--no-sudo**: disable sudo support

## Steps

1. Parse the arguments. If no host is provided, ask the user for one.

2. Build and run the `claude mcp add` command:

```
claude mcp add \
  --scope <project|user> \
  --transport stdio \
  <name> \
  -- npx -y ssh-mcp -- \
  --host=<host> \
  --user=<user> \
  --key=~/.ssh/id_tcos_hosts \
  --sudoPassword=checkmate \
  --maxChars=none
```

Omit `--sudoPassword=checkmate` if `--no-sudo` was passed.

3. Confirm to the user that the MCP server was added, showing the name and scope used.
