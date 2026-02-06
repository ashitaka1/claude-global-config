#!/usr/bin/env bash
# install.sh - Install dependencies for Claude Config Sync

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo " Claude Config Sync - Dependency Installation"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check for Homebrew on macOS
if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        echo -e "${RED}✗${NC} Homebrew not found"
        echo "  Install it from https://brew.sh"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Homebrew found"
else
    echo -e "${YELLOW}⚠${NC}  Not on macOS - install dependencies manually:"
    echo "  - rsync"
    echo "  - jq"
    echo "  - op (1Password CLI): https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

echo ""
echo "Installing dependencies..."
echo ""

# Install each dependency
for pkg in rsync jq yq; do
    if command -v "$pkg" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $pkg (already installed)"
    else
        echo -e "  Installing $pkg..."
        brew install "$pkg"
        echo -e "${GREEN}✓${NC} $pkg"
    fi
done

# 1Password CLI is a cask
if command -v op &>/dev/null; then
    echo -e "${GREEN}✓${NC} op (already installed)"
else
    echo -e "  Installing 1Password CLI..."
    brew install --cask 1password-cli
    echo -e "${GREEN}✓${NC} op"
fi

echo ""
echo -e "${GREEN}✓${NC} All dependencies installed. Running deploy..."
echo ""
exec ./sync.sh deploy
