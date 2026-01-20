#!/bin/bash

# Claude global defaults location
CLAUDE_DIR="$HOME/.claude"
GLOBAL_CLAUDE="$CLAUDE_DIR/CLAUDE.md"
LOCAL_CLAUDE="$(dirname "$0")/CLAUDE.md"

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Backup existing file if it exists
if [ -f "$GLOBAL_CLAUDE" ]; then
    BACKUP="$GLOBAL_CLAUDE.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$GLOBAL_CLAUDE" "$BACKUP"
    echo "Backed up existing CLAUDE.md to: $BACKUP"
fi

# Copy local CLAUDE.md to global location
cp "$LOCAL_CLAUDE" "$GLOBAL_CLAUDE"
echo "Installed CLAUDE.md to: $GLOBAL_CLAUDE"
