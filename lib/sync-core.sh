#!/usr/bin/env bash
# sync-core.sh - Core helper functions for Claude Code configuration sync

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Detect OS for platform-specific commands
readonly IS_MACOS=$([[ "$(uname -s)" == "Darwin" ]] && echo true || echo false)

# ============================================================================
# Dependency Checks
# ============================================================================

check_dependencies() {
    local missing=()
    command -v rsync &>/dev/null || missing+=(rsync)
    command -v shasum &>/dev/null || missing+=(shasum)
    command -v jq &>/dev/null || missing+=(jq)
    command -v op &>/dev/null || missing+=("op (1Password CLI)")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}✗${NC} Missing required dependencies: ${missing[*]}"
        echo "  Please install them and try again."
        echo "  On macOS: brew install rsync jq"
        echo "  1Password CLI: https://developer.1password.com/docs/cli/get-started/"
        exit 1
    fi
}

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

        # Keep only last 10 backups per file (handles spaces in filenames safely)
        find "$backup_dir" -maxdepth 1 -name "$filename.*.tar.gz" -print0 2>/dev/null | \
            xargs -0 ls -t 2>/dev/null | tail -n +11 | while IFS= read -r old_backup; do
                rm -f "$old_backup"
            done
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

        # Keep only last 10 backups per directory (handles spaces in filenames safely)
        find "$backup_dir" -maxdepth 1 -name "$dirname.*.tar.gz" -print0 2>/dev/null | \
            xargs -0 ls -t 2>/dev/null | tail -n +11 | while IFS= read -r old_backup; do
                rm -f "$old_backup"
            done
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

# Allowed base paths for sync operations (can be extended by caller)
# shellcheck disable=SC2034
SYNC_ALLOWED_PATHS=("$HOME/.claude")

expand_path() {
    local path="$1"
    # Expand ~ to home directory
    echo "${path/#\~/$HOME}"
}

validate_path() {
    local path="$1"
    local expanded=$(expand_path "$path")

    # Ensure path doesn't escape expected directories
    for allowed in "${SYNC_ALLOWED_PATHS[@]}"; do
        case "$expanded" in
            "$allowed"*)
                return 0
                ;;
        esac
    done

    echo -e "${RED}✗${NC} Invalid path: $path (not in allowed paths)"
    return 1
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
    local modified

    # Platform-specific stat command
    if [ "$IS_MACOS" = "true" ]; then
        modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
    else
        # Linux stat format
        modified=$(stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1)
    fi

    # Fallback if stat fails
    if [ -z "$modified" ]; then
        modified="unknown"
    fi

    echo "$lines lines | Modified: $modified"
}

# ============================================================================
# State Management
# ============================================================================

save_sync_state() {
    local state_file=".sync-state.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local operation="$1"  # "deploy" or "pull"

    # Load existing state to preserve both timestamps
    local existing_deploy="null"
    local existing_pull="null"

    if [ -f "$state_file" ]; then
        existing_deploy=$(jq -r '.last_deploy // "null"' "$state_file" 2>/dev/null || echo "null")
        existing_pull=$(jq -r '.last_pull // "null"' "$state_file" 2>/dev/null || echo "null")
    fi

    # Update the appropriate timestamp
    if [ "$operation" = "deploy" ]; then
        existing_deploy="$timestamp"
    else
        existing_pull="$timestamp"
    fi

    # Build checksums object
    local checksums="{}"

    # Add checksums for each tracked file/directory
    if [ -f "CLAUDE.md" ]; then
        checksums=$(echo "$checksums" | jq --arg v "$(compute_checksum "CLAUDE.md")" '. + {"CLAUDE.md": $v}')
    fi

    if [ -f "claude-config/settings.sync.json" ]; then
        checksums=$(echo "$checksums" | jq --arg v "$(compute_checksum "claude-config/settings.sync.json")" '. + {"settings.json": $v}')
    fi

    if [ -f "claude-config/api_key_helper.sh" ]; then
        checksums=$(echo "$checksums" | jq --arg v "$(compute_checksum "claude-config/api_key_helper.sh")" '. + {"api_key_helper.sh": $v}')
    fi

    if [ -d "claude-config/agents" ]; then
        checksums=$(echo "$checksums" | jq --arg v "$(compute_directory_checksum "claude-config/agents")" '. + {"agents": $v}')
    fi

    if [ -d "claude-config/skills" ]; then
        checksums=$(echo "$checksums" | jq --arg v "$(compute_directory_checksum "claude-config/skills")" '. + {"skills": $v}')
    fi

    # Build final JSON with jq
    jq -n \
        --arg deploy "$existing_deploy" \
        --arg pull "$existing_pull" \
        --argjson checksums "$checksums" \
        '{last_deploy: $deploy, last_pull: $pull, checksums: $checksums}' > "$state_file"
}

load_sync_state() {
    local state_file=".sync-state.json"
    local key="$1"

    if [ ! -f "$state_file" ]; then
        echo "Never"
        return
    fi

    local value
    value=$(jq -r ".$key // empty" "$state_file" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "Never"
    else
        echo "$value"
    fi
}

# ============================================================================
# Plugin Management
# ============================================================================

# Get list of installed plugins (handles different output formats)
get_installed_plugins() {
    local output
    output=$(claude plugin list 2>/dev/null) || return 1

    # Try different patterns to extract plugin names
    # Pattern 1: lines with ❯ marker
    # Pattern 2: lines starting with whitespace followed by plugin name
    # Pattern 3: JSON output if --json is supported
    echo "$output" | grep -E '^\s*(❯|•|-|\*)?\s*\S+@' | \
        sed -E 's/^[[:space:]]*(❯|•|-|\*)?[[:space:]]*//' | \
        awk '{print $1}' | sort -u
}

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

    local failed=0

    # Read plugins file and install each one
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        local plugin
        plugin=$(echo "$line" | xargs)

        echo "  → $plugin"
        local output
        if output=$(claude plugin install "$plugin" 2>&1); then
            if echo "$output" | grep -qi "already installed"; then
                echo "    (already installed)"
            else
                echo "    (installed)"
            fi
        else
            echo -e "    ${RED}(failed: $output)${NC}"
            ((failed++))
        fi
    done < "$plugins_file"

    if [ $failed -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC}  $failed plugin(s) failed to install"
    else
        echo -e "${GREEN}✓${NC} Plugins ready"
    fi
}

pull_plugins() {
    local plugins_file="$1"
    local dry_run="${2:-false}"

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would update $plugins_file from installed plugins"
        return 0
    fi

    # Get list of installed plugins
    local installed
    installed=$(get_installed_plugins)

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
