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
    command -v yq &>/dev/null || missing+=(yq)
    command -v op &>/dev/null || missing+=("op (1Password CLI)")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}✗${NC} Missing required dependencies: ${missing[*]}"
        echo "  Please run: ./install.sh"
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

    # Compute checksum of all files in directory using relative paths
    # This ensures identical content produces identical checksums regardless of location
    (cd "$dir" && find . -type f -exec shasum -a 256 {} \; | sort | shasum -a 256 | awk '{print $1}')
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
# Config Parsing Functions
# ============================================================================

# Expand path helper for config parsing
expand_config_path() {
    local path="$1"
    local repo_dir="$2"

    if [[ "$path" == ~/* ]]; then
        echo "$HOME/${path#~/}"
    elif [[ "$path" == /* ]]; then
        echo "$path"
    else
        echo "$repo_dir/$path"
    fi
}

# Parse sync config and return JSON
parse_sync_config() {
    local config_file="$1"
    local repo_dir="$2"

    # Convert YAML to JSON using yq
    local yaml_json=$(yq eval -o=json "$config_file")

    # Process files - expand paths and add names
    local files_json=$(echo "$yaml_json" | jq -r '.sync.files // []' | jq -c --arg repo_dir "$repo_dir" '
        map({
            source: .source,
            target: .target,
            name: (.name // (.target | split("/") | last))
        } | {
            source: (if .source | startswith("~/") then
                        ("'"$HOME"'/" + (.source | ltrimstr("~/")))
                     elif .source | startswith("/") then
                        .source
                     else
                        ($repo_dir + "/" + .source)
                     end),
            target: (if .target | startswith("~/") then
                        ("'"$HOME"'/" + (.target | ltrimstr("~/")))
                     elif .target | startswith("/") then
                        .target
                     else
                        ($repo_dir + "/" + .target)
                     end),
            name: .name
        })
    ')

    # Process directories - expand paths and add names
    local dirs_json=$(echo "$yaml_json" | jq -r '.sync.directories // []' | jq -c --arg repo_dir "$repo_dir" '
        map({
            source: .source,
            target: .target,
            name: (.name // ((.target | split("/") | last) + "/")),
            recursive: (.recursive // true)
        } | {
            source: (if .source | startswith("~/") then
                        ("'"$HOME"'/" + (.source | ltrimstr("~/")))
                     elif .source | startswith("/") then
                        .source
                     else
                        ($repo_dir + "/" + .source)
                     end),
            target: (if .target | startswith("~/") then
                        ("'"$HOME"'/" + (.target | ltrimstr("~/")))
                     elif .target | startswith("/") then
                        .target
                     else
                        ($repo_dir + "/" + .target)
                     end),
            name: .name,
            recursive: .recursive
        })
    ')

    # Process backup config - expand location path
    local backup_json=$(echo "$yaml_json" | jq -c --arg repo_dir "$repo_dir" '
        .sync.backup // {} | {
            enabled: (.enabled // true),
            location: (if .location then
                        (if .location | startswith("~/") then
                            ("'"$HOME"'/" + (.location | ltrimstr("~/")))
                         elif .location | startswith("/") then
                            .location
                         else
                            ($repo_dir + "/" + .location)
                         end)
                       else
                        "'"$HOME"'/.claude/backups/sync"
                       end),
            keep_count: (.keep_count // 10)
        }
    ')

    # Build final JSON
    jq -n \
        --argjson files "$files_json" \
        --argjson dirs "$dirs_json" \
        --argjson backup "$backup_json" \
        '{files: $files, directories: $dirs, backup_config: $backup}'
}

# Get sync files as JSON array (one per line)
get_sync_files() {
    local config_json="$1"
    echo "$config_json" | jq -r '.files[] | @json'
}

# Get sync directories as JSON array (one per line)
get_sync_directories() {
    local config_json="$1"
    echo "$config_json" | jq -r '.directories[] | @json'
}

# Extract field from JSON entry
extract_field() {
    local entry="$1"
    local field="$2"
    echo "$entry" | jq -r ".$field"
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

get_file_mtime() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi
    if [ "$IS_MACOS" = "true" ]; then
        stat -f "%m" "$file" 2>/dev/null || echo "0"
    else
        stat -c "%Y" "$file" 2>/dev/null || echo "0"
    fi
}

format_diverged_files() {
    local label1="$1"
    local file1="$2"
    local label2="$3"
    local file2="$4"

    local mtime1=$(get_file_mtime "$file1")
    local mtime2=$(get_file_mtime "$file2")
    local details1=$(format_file_details "$file1")
    local details2=$(format_file_details "$file2")

    if [ "$mtime1" -gt "$mtime2" ]; then
        echo -e "  ${label1}  ${GREEN}${details1}${NC}"
        echo -e "  ${label2}  ${YELLOW}${details2}${NC}"
    elif [ "$mtime2" -gt "$mtime1" ]; then
        echo -e "  ${label1}  ${YELLOW}${details1}${NC}"
        echo -e "  ${label2}  ${GREEN}${details2}${NC}"
    else
        echo "  ${label1}  ${details1}"
        echo "  ${label2}  ${details2}"
    fi
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

    # Build checksums object from config
    local checksums="{}"
    local config_json=$(parse_sync_config "$SCRIPT_DIR/.sync-config.yaml" "$SCRIPT_DIR")

    # Add checksums for each tracked file
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local name=$(extract_field "$entry" "name")
        if [ -f "$source" ]; then
            checksums=$(echo "$checksums" | jq --arg k "$name" --arg v "$(compute_checksum "$source")" '. + {($k): $v}')
        fi
    done < <(get_sync_files "$config_json")

    # Add checksums for each tracked directory
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local name=$(extract_field "$entry" "name")
        if [ -d "$source" ]; then
            checksums=$(echo "$checksums" | jq --arg k "$name" --arg v "$(compute_directory_checksum "$source")" '. + {($k): $v}')
        fi
    done < <(get_sync_directories "$config_json")

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

# Get list of plugins from plugins.txt
get_repo_plugins() {
    local plugins_file="$1"
    if [ ! -f "$plugins_file" ]; then
        return
    fi
    grep -v '^#' "$plugins_file" | grep -v '^[[:space:]]*$' | xargs -n1 | sort -u
}

plugins_differ() {
    local plugins_file="$1"

    local repo_plugins=$(get_repo_plugins "$plugins_file")
    local live_plugins=$(get_installed_plugins)

    [ "$repo_plugins" != "$live_plugins" ]
}

ensure_marketplace() {
    local marketplace="$1"
    local source="$2"

    # Check if marketplace is already configured
    if claude plugin marketplace list 2>/dev/null | grep -q "$marketplace"; then
        return 0
    fi

    echo "  Adding marketplace: $marketplace"
    if claude plugin marketplace add "$source" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Marketplace added"
        return 0
    else
        echo -e "  ${RED}✗${NC} Failed to add marketplace"
        return 1
    fi
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

    # Ensure required marketplaces are configured
    # Extract unique marketplaces from plugins file
    local marketplaces
    marketplaces=$(grep -v '^#' "$plugins_file" | grep -v '^[[:space:]]*$' | \
        grep '@' | sed 's/.*@//' | sort -u)

    for marketplace in $marketplaces; do
        case "$marketplace" in
            claude-plugins-official)
                ensure_marketplace "$marketplace" "anthropics/claude-plugins-official"
                ;;
            *)
                # Unknown marketplace - try to add by name as GitHub repo
                ensure_marketplace "$marketplace" "$marketplace" || true
                ;;
        esac
    done

    echo "Installing plugins..."

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
