#!/usr/bin/env bash
# sync-core.sh - Core helper functions for Claude Code configuration sync

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# Backup Functions
# ============================================================================

backup_file() {
    local file="$1"
    local backup_dir="${2:-$HOME/.claude/backups/sync}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local filename=$(basename "$file")
    local backup_file="$backup_dir/${filename}.${timestamp}.tar.gz"

    mkdir -p "$backup_dir"

    if [ -f "$file" ]; then
        tar czf "$backup_file" -C "$(dirname "$file")" "$(basename "$file")" 2>/dev/null
        echo -e "${GREEN}✓${NC} Backed up: $backup_file"

        # Keep only last 10 backups per file
        ls -t "$backup_dir/$filename."*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
}

backup_directory() {
    local dir="$1"
    local backup_dir="${2:-$HOME/.claude/backups/sync}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local dirname=$(basename "$dir")
    local backup_file="$backup_dir/${dirname}.${timestamp}.tar.gz"

    mkdir -p "$backup_dir"

    if [ -d "$dir" ]; then
        tar czf "$backup_file" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null
        echo -e "${GREEN}✓${NC} Backed up: $backup_file"

        # Keep only last 10 backups per directory
        ls -t "$backup_dir/$dirname."*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
    fi
}

# ============================================================================
# Checksum Functions
# ============================================================================

compute_checksum() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "MISSING"
        return
    fi

    shasum -a 256 "$file" | awk '{print $1}'
}

compute_directory_checksum() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        echo "MISSING"
        return
    fi

    # Compute checksum of all files in directory
    find "$dir" -type f -exec shasum -a 256 {} \; | sort | shasum -a 256 | awk '{print $1}'
}

files_differ() {
    local file1="$1"
    local file2="$2"

    if [ ! -f "$file1" ] && [ ! -f "$file2" ]; then
        return 1  # Both missing, not different
    fi

    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 0  # One missing, different
    fi

    local checksum1=$(compute_checksum "$file1")
    local checksum2=$(compute_checksum "$file2")

    [ "$checksum1" != "$checksum2" ]
}

directories_differ() {
    local dir1="$1"
    local dir2="$2"

    if [ ! -d "$dir1" ] && [ ! -d "$dir2" ]; then
        return 1  # Both missing, not different
    fi

    if [ ! -d "$dir1" ] || [ ! -d "$dir2" ]; then
        return 0  # One missing, different
    fi

    local checksum1=$(compute_directory_checksum "$dir1")
    local checksum2=$(compute_directory_checksum "$dir2")

    [ "$checksum1" != "$checksum2" ]
}

# ============================================================================
# Path Functions
# ============================================================================

expand_path() {
    local path="$1"
    # Expand ~ to home directory
    echo "${path/#\~/$HOME}"
}

validate_path() {
    local path="$1"
    local expanded=$(expand_path "$path")

    # Ensure path doesn't escape expected directories
    case "$expanded" in
        "$HOME/.claude"*|"$HOME/Developer/Claude-defaults"*)
            return 0
            ;;
        *)
            echo -e "${RED}✗${NC} Invalid path: $path"
            return 1
            ;;
    esac
}

# ============================================================================
# Sync Functions
# ============================================================================

sync_file() {
    local source="$1"
    local target="$2"
    local backup_dir="${3:-$HOME/.claude/backups/sync}"
    local dry_run="${4:-false}"

    local expanded_target=$(expand_path "$target")

    if ! validate_path "$expanded_target"; then
        return 1
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would copy: $source → $expanded_target"
        return 0
    fi

    # Backup target if it exists
    if [ -f "$expanded_target" ]; then
        backup_file "$expanded_target" "$backup_dir"
    fi

    # Create target directory if needed
    mkdir -p "$(dirname "$expanded_target")"

    # Copy file
    cp "$source" "$expanded_target"
    echo -e "${GREEN}✓${NC} Synced: $source → $expanded_target"
}

sync_directory() {
    local source="$1"
    local target="$2"
    local backup_dir="${3:-$HOME/.claude/backups/sync}"
    local dry_run="${4:-false}"

    local expanded_target=$(expand_path "$target")

    if ! validate_path "$expanded_target"; then
        return 1
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would sync directory: $source → $expanded_target"
        return 0
    fi

    # Backup target if it exists
    if [ -d "$expanded_target" ]; then
        backup_directory "$expanded_target" "$backup_dir"
    fi

    # Create target directory
    mkdir -p "$expanded_target"

    # Sync directory contents
    rsync -a --delete "$source/" "$expanded_target/"
    echo -e "${GREEN}✓${NC} Synced directory: $source → $expanded_target"
}

# ============================================================================
# API Key Sanitization
# ============================================================================

sanitize_api_key_helper() {
    local live_helper="$HOME/.claude/api_key_helper.sh"
    local repo_helper="claude-config/api_key_helper.sh"

    if [ ! -f "$live_helper" ]; then
        echo -e "${YELLOW}⚠${NC}  No API key helper found in live config"
        return 0
    fi

    # Replace any hardcoded key values with env var reference
    sed -E 's/ANTHROPIC_API_KEY="[^"]+"/ANTHROPIC_API_KEY="\$ANTHROPIC_API_KEY"/' \
        "$live_helper" > "$repo_helper"

    chmod +x "$repo_helper"
    echo -e "${GREEN}✓${NC} Sanitized API key helper for repo"
}

deploy_api_key_helper() {
    local repo_helper="claude-config/api_key_helper.sh"
    local live_helper="$HOME/.claude/api_key_helper.sh"
    local dry_run="${1:-false}"

    if [ ! -f "$repo_helper" ]; then
        echo -e "${YELLOW}⚠${NC}  No API key helper template in repo"
        return 0
    fi

    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        echo -e "${YELLOW}⚠${NC}  Warning: ANTHROPIC_API_KEY not set in environment"
        echo "   Add to ~/.zshrc: export ANTHROPIC_API_KEY='your-key'"
        echo "   Skipping api_key_helper.sh deployment"
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would deploy API key helper with interpolated key"
        return 0
    fi

    # Backup existing helper
    if [ -f "$live_helper" ]; then
        backup_file "$live_helper"
    fi

    # Read template, interpolate env var value
    sed "s/\\\$ANTHROPIC_API_KEY/$ANTHROPIC_API_KEY/" \
        "$repo_helper" > "$live_helper"

    chmod +x "$live_helper"
    echo -e "${GREEN}✓${NC} Deployed API key helper with key from \$ANTHROPIC_API_KEY"
}

# ============================================================================
# Diff Functions
# ============================================================================

show_diff() {
    local file1="$1"
    local file2="$2"

    if [ ! -f "$file1" ] && [ ! -f "$file2" ]; then
        echo -e "${YELLOW}Neither file exists${NC}"
        return
    fi

    if [ ! -f "$file1" ]; then
        echo -e "${YELLOW}$file1 does not exist${NC}"
        echo -e "${GREEN}$file2 exists:${NC}"
        wc -l "$file2"
        return
    fi

    if [ ! -f "$file2" ]; then
        echo -e "${GREEN}$file1 exists:${NC}"
        wc -l "$file1"
        echo -e "${YELLOW}$file2 does not exist${NC}"
        return
    fi

    # Show unified diff
    diff -u "$file1" "$file2" || true
}

# ============================================================================
# Status Display Functions
# ============================================================================

format_status_line() {
    local status="$1"
    local name="$2"
    local details="${3:-}"

    case "$status" in
        "in-sync")
            echo -e "${GREEN}✓${NC} $name $details"
            ;;
        "diverged")
            echo -e "${YELLOW}⚠${NC} $name ${YELLOW}DIVERGED${NC}"
            [ -n "$details" ] && echo "  $details"
            ;;
        "repo-only")
            echo -e "${BLUE}→${NC} $name ${BLUE}REPO ONLY${NC}"
            [ -n "$details" ] && echo "  $details"
            ;;
        "live-only")
            echo -e "${YELLOW}←${NC} $name ${YELLOW}LIVE ONLY${NC}"
            [ -n "$details" ] && echo "  $details"
            ;;
        *)
            echo -e "${RED}✗${NC} $name ${RED}ERROR${NC}"
            [ -n "$details" ] && echo "  $details"
            ;;
    esac
}

format_file_details() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Missing"
        return
    fi

    local lines=$(wc -l < "$file" | tr -d ' ')
    local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || date -r "$file" "+%Y-%m-%d %H:%M:%S")

    echo "$lines lines | Modified: $modified"
}

# ============================================================================
# State Management
# ============================================================================

save_sync_state() {
    local state_file=".sync-state.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local operation="$1"  # "deploy" or "pull"

    # Start JSON structure
    local json="{"
    json+="\"last_${operation}\": \"$timestamp\","
    json+="\"checksums\": {"

    # Add checksums for tracked files
    local first=true

    # CLAUDE.md
    if [ -f "CLAUDE.md" ]; then
        [ "$first" = false ] && json+=","
        json+="\"CLAUDE.md\": \"$(compute_checksum "CLAUDE.md")\""
        first=false
    fi

    # settings.sync.json
    if [ -f "claude-config/settings.sync.json" ]; then
        [ "$first" = false ] && json+=","
        json+="\"settings.json\": \"$(compute_checksum "claude-config/settings.sync.json")\""
        first=false
    fi

    # api_key_helper.sh
    if [ -f "claude-config/api_key_helper.sh" ]; then
        [ "$first" = false ] && json+=","
        json+="\"api_key_helper.sh\": \"$(compute_checksum "claude-config/api_key_helper.sh")\""
        first=false
    fi

    # agents directory
    if [ -d "claude-config/agents" ]; then
        [ "$first" = false ] && json+=","
        json+="\"agents\": \"$(compute_directory_checksum "claude-config/agents")\""
        first=false
    fi

    # skills directory
    if [ -d "claude-config/skills" ]; then
        [ "$first" = false ] && json+=","
        json+="\"skills\": \"$(compute_directory_checksum "claude-config/skills")\""
        first=false
    fi

    json+="}}"

    # Write to state file
    echo "$json" | python3 -m json.tool > "$state_file" 2>/dev/null || echo "$json" > "$state_file"
}

load_sync_state() {
    local state_file=".sync-state.json"
    local key="$1"

    if [ ! -f "$state_file" ]; then
        echo "Never"
        return
    fi

    # Extract value using grep and sed (portable)
    grep "\"$key\"" "$state_file" | sed -E 's/.*"([^"]+)".*/\1/' || echo "Never"
}

# ============================================================================
# Plugin Management
# ============================================================================

deploy_plugins() {
    local plugins_file="$1"
    local dry_run="${2:-false}"

    if [ ! -f "$plugins_file" ]; then
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would install plugins from $plugins_file"
        return 0
    fi

    echo -e "${GREEN}Installing plugins...${NC}"

    # Read plugins file and install each one
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        local plugin=$(echo "$line" | xargs)

        echo "  → $plugin"
        if claude plugin install "$plugin" 2>&1 | grep -q "already installed"; then
            echo "    (already installed)"
        fi
    done < "$plugins_file"

    echo -e "${GREEN}✓${NC} Plugins ready"
}

pull_plugins() {
    local plugins_file="$1"
    local dry_run="${2:-false}"

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would update $plugins_file from installed plugins"
        return 0
    fi

    # Get list of installed plugins
    local installed=$(claude plugin list 2>/dev/null | grep -E '^\s+❯' | awk '{print $2}' | sort)

    if [ -z "$installed" ]; then
        echo -e "${YELLOW}⚠${NC}  No plugins installed"
        return 0
    fi

    # Write to plugins.txt
    cat > "$plugins_file" << 'EOF'
# Claude Code Plugins
# One plugin per line, format: plugin-name@marketplace
# Lines starting with # are ignored

EOF

    echo "$installed" >> "$plugins_file"
    echo -e "${GREEN}✓${NC} Updated $plugins_file with installed plugins"
}
