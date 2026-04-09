#!/usr/bin/env bash
# sync.sh - Claude Code Configuration Sync System
# Bidirectional sync between repository and live config

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source core functions (with existence check)
SYNC_CORE="$SCRIPT_DIR/lib/sync-core.sh"
if [ ! -f "$SYNC_CORE" ]; then
    echo "Error: Core library not found: $SYNC_CORE" >&2
    echo "Please ensure the repository is complete." >&2
    exit 1
fi
# shellcheck source=lib/sync-core.sh
source "$SYNC_CORE"

# Check required dependencies
check_dependencies

# Configuration
readonly REPO_DIR="$SCRIPT_DIR"
readonly LIVE_DIR="$HOME/.claude"
readonly STATE_FILE="$REPO_DIR/.sync-state.json"
readonly BACKUP_DIR="$HOME/.claude/backups/sync"
readonly CONFIG_FILE="$SCRIPT_DIR/.sync-config.yaml"

# Add repo directory to allowed paths for validation
SYNC_ALLOWED_PATHS+=("$REPO_DIR")

# ============================================================================
# Usage and Help
# ============================================================================

usage() {
    cat << 'EOF'
═══════════════════════════════════════════════════════════════
 Claude Config Sync - Bidirectional Configuration Management
═══════════════════════════════════════════════════════════════

USAGE:
  ./sync.sh <command> [options]

COMMANDS:
  reconcile [options]          Bidirectional sync with conflict resolution
  deploy [--dry-run]           Deploy repo → live config (overwrite)
  pull [--dry-run] [--force]   Pull live → repo (overwrite)
  status                       Show sync status and differences
  diff [file]                  Show detailed diff for file(s)
  help                         Show this help message

RECONCILE OPTIONS:
  --dry-run            Preview what would change
  --repo-wins          Auto-resolve all conflicts using repo version
  --live-wins          Auto-resolve all conflicts using live version

OTHER OPTIONS:
  --dry-run            Preview changes without modifying files
  --force              Skip confirmation prompts (for scripted use)

WORKFLOW:
  1. Experiment in live config (~/.claude/)
  2. Check status:     ./sync.sh status
  3. Reconcile:        ./sync.sh reconcile
  4. Commit changes:   git add -A && git commit
  5. Push to remote:   git push

EXAMPLES:
  ./sync.sh reconcile              # Interactive bidirectional sync
  ./sync.sh reconcile --dry-run    # Preview reconcile actions
  ./sync.sh reconcile --repo-wins  # Take repo version for all conflicts
  ./sync.sh status                 # Check what's different
  ./sync.sh diff CLAUDE.md         # Show diff for specific file

═══════════════════════════════════════════════════════════════
EOF
}

# ============================================================================
# Status Command
# ============================================================================

cmd_status() {
    echo "═══════════════════════════════════════════════════════════════"
    echo " Claude Config Sync Status"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Repository:  $REPO_DIR"
    echo "Live Config: $LIVE_DIR"
    echo "Last Deploy: $(load_sync_state "last_deploy")"
    echo "Last Pull:   $(load_sync_state "last_pull")"
    echo ""
    echo "───────────────────────────────────────────────────────────────"
    echo "SYNC STATUS"
    echo "───────────────────────────────────────────────────────────────"
    echo ""

    local issues=0
    local config_json=$(parse_sync_config "$CONFIG_FILE" "$REPO_DIR")

    # Check each file from config
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")

        if files_differ "$source" "$target"; then
            format_status_line "diverged" "$name" "DIVERGED"
            format_diverged_files "Repo:" "$source" "Live:" "$target"
            ((issues++))
        else
            if [ -f "$source" ]; then
                local lines=$(wc -l < "$source" 2>/dev/null | tr -d ' ' || echo "?")
                format_status_line "in-sync" "$name" "(${lines} lines)"
            else
                format_status_line "in-sync" "$name"
            fi
        fi
    done < <(get_sync_files "$config_json")

    # Check each directory from config
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")

        if directories_differ "$source" "$target"; then
            format_status_line "diverged" "$name" "DIVERGED"

            # Count files in each
            local repo_count=$(find "$source" -type f 2>/dev/null | wc -l | tr -d ' ')
            local live_count=$(find "$target" -type f 2>/dev/null | wc -l | tr -d ' ')

            echo "  Repo:  $repo_count files"
            echo "  Live:  $live_count files"
            ((issues++))
        else
            local count=$(find "$source" -type f 2>/dev/null | wc -l | tr -d ' ')
            format_status_line "in-sync" "$name" "($count files)"
        fi
    done < <(get_sync_directories "$config_json")

    # Check plugins (separate mechanism)
    local plugins_file="$REPO_DIR/claude-config/plugins.txt"
    if [ -f "$plugins_file" ]; then
        local repo_plugins=$(grep -v '^#' "$plugins_file" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
        local live_plugins
        live_plugins=$(get_installed_plugins | wc -l | tr -d ' ')

        if [ "$repo_plugins" -ne "$live_plugins" ]; then
            format_status_line "diverged" "plugins" "DIVERGED"
            echo "  Repo:  $repo_plugins plugin(s) in plugins.txt"
            echo "  Live:  $live_plugins plugin(s) installed"
            ((issues++))
        else
            format_status_line "in-sync" "plugins" "($repo_plugins plugin(s))"
        fi
    fi

    echo ""
    echo "───────────────────────────────────────────────────────────────"
    echo "SUMMARY"
    echo "───────────────────────────────────────────────────────────────"
    echo ""

    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}All files synchronized. No action needed.${NC}"
    else
        echo -e "${YELLOW}⚠ $issues item(s) need attention${NC}"
        echo "  Review changes: ./sync.sh diff"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# Diff Command
# ============================================================================

cmd_diff() {
    local target="${1:-}"
    local config_json=$(parse_sync_config "$CONFIG_FILE" "$REPO_DIR")

    if [ -z "$target" ]; then
        # Show all diffs
        echo "═══════════════════════════════════════════════════════════════"
        echo " Differences Between Repo and Live Config"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""

        # Check each file from config
        while IFS= read -r entry; do
            local source=$(extract_field "$entry" "source")
            local target_path=$(extract_field "$entry" "target")
            local name=$(extract_field "$entry" "name")

            if files_differ "$source" "$target_path"; then
                echo "─── $name ─────────────────────────────────────────────"
                show_diff "$source" "$target_path"
                echo ""
            fi
        done < <(get_sync_files "$config_json")

        # Check each directory from config
        while IFS= read -r entry; do
            local source=$(extract_field "$entry" "source")
            local target_path=$(extract_field "$entry" "target")
            local name=$(extract_field "$entry" "name")

            if directories_differ "$source" "$target_path"; then
                echo "─── $name ─────────────────────────────────────────────"
                echo "Directories differ. Use 'diff $name' for details."
                echo ""
            fi
        done < <(get_sync_directories "$config_json")

        return
    fi

    # Show specific target diff - search config for match
    local found=false

    # Search files
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target_path=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")

        # Match on name (with or without extension variants)
        local base_name="${name%.*}"
        local target_base="${target%.*}"
        if [[ "$name" == "$target" ]] || [[ "$base_name" == "$target_base" ]] || [[ "$base_name" == "$target" ]]; then
            show_diff "$source" "$target_path"
            found=true
            break
        fi
    done < <(get_sync_files "$config_json")

    if [ "$found" = "true" ]; then
        return
    fi

    # Search directories
    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target_path=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")

        # Match on name (remove trailing slash for comparison)
        local clean_name="${name%/}"
        local clean_target="${target%/}"
        if [[ "$name" == "$target" ]] || [[ "$clean_name" == "$clean_target" ]] || [[ "$clean_name" == "$target" ]]; then
            diff -ur "$source" "$target_path" || true
            found=true
            break
        fi
    done < <(get_sync_directories "$config_json")

    if [ "$found" = "false" ]; then
        echo -e "${RED}✗${NC} Unknown target: $target"
        echo "Available targets:"
        get_sync_files "$config_json" | while IFS= read -r entry; do
            echo "  - $(extract_field "$entry" "name")"
        done
        get_sync_directories "$config_json" | while IFS= read -r entry; do
            echo "  - $(extract_field "$entry" "name")"
        done
        exit 1
    fi
}

# ============================================================================
# Deploy Command (Repo → Live)
# ============================================================================

cmd_deploy() {
    local dry_run="${1:-false}"
    local config_json=$(parse_sync_config "$CONFIG_FILE" "$REPO_DIR")

    echo "═══════════════════════════════════════════════════════════════"
    echo " Deploy: Repo → Live Config"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    # Build list of what differs from config
    local affected=()

    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")
        if files_differ "$source" "$target"; then
            affected+=("file:$source:$target:$name")
        fi
    done < <(get_sync_files "$config_json")

    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")
        if directories_differ "$source" "$target"; then
            affected+=("dir:$source:$target:$name")
        fi
    done < <(get_sync_directories "$config_json")

    # Check plugins separately
    if plugins_differ "$REPO_DIR/claude-config/plugins.txt"; then
        affected+=("plugins")
    fi

    if [ ${#affected[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ Everything already in sync${NC}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}DRY-RUN MODE: No files will be modified${NC}"
        echo ""
    fi

    local changes=0

    # Process each affected item
    for item in "${affected[@]}"; do
        if [[ "$item" == "plugins" ]]; then
            deploy_plugins "$REPO_DIR/claude-config/plugins.txt" "$dry_run"
            ((changes++))
        elif [[ "$item" == file:* ]]; then
            IFS=':' read -r _ source target name <<< "$item"
            sync_file "$source" "$target" "$BACKUP_DIR" "$dry_run"
            ((changes++))
        elif [[ "$item" == dir:* ]]; then
            IFS=':' read -r _ source target name <<< "$item"
            sync_directory "$source" "$target" "$BACKUP_DIR" "$dry_run"
            ((changes++))
        fi
    done

    if [ "$dry_run" = "false" ]; then
        save_sync_state "deploy"
        echo ""
        echo -e "${GREEN}✓ Deploy complete${NC}"
    else
        echo ""
        echo -e "${BLUE}Run without --dry-run to apply changes${NC}"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# Pull Command (Live → Repo)
# ============================================================================

cmd_pull() {
    local dry_run="${1:-false}"
    local force="${2:-false}"
    local config_json=$(parse_sync_config "$CONFIG_FILE" "$REPO_DIR")

    echo "═══════════════════════════════════════════════════════════════"
    echo " Pull: Live Config → Repo"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    # Build list of what differs from config (note: reversed order for pull)
    local affected=()
    local affected_names=()

    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")
        if files_differ "$target" "$source"; then
            affected+=("file:$target:$source:$name")
            affected_names+=("$name")
        fi
    done < <(get_sync_files "$config_json")

    while IFS= read -r entry; do
        local source=$(extract_field "$entry" "source")
        local target=$(extract_field "$entry" "target")
        local name=$(extract_field "$entry" "name")
        if directories_differ "$target" "$source"; then
            affected+=("dir:$target:$source:$name")
            affected_names+=("$name")
        fi
    done < <(get_sync_directories "$config_json")

    # Check plugins separately
    if plugins_differ "$REPO_DIR/claude-config/plugins.txt"; then
        affected+=("plugins")
        affected_names+=("plugins")
    fi

    if [ ${#affected[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ Everything already in sync${NC}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        return 0
    fi

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}DRY-RUN MODE: No files will be modified${NC}"
        echo ""
    elif [ "$force" = "false" ]; then
        echo -e "${YELLOW}⚠  This will overwrite repo files with live config${NC}"
        echo "Affected: ${affected_names[*]}"
        echo ""
        local confirm=""
        read -p "Continue? (yes/no): " -r confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted"
            exit 0
        fi
        echo ""
    fi

    local changes=0

    # Process each affected item
    for item in "${affected[@]}"; do
        if [[ "$item" == "plugins" ]]; then
            pull_plugins "$REPO_DIR/claude-config/plugins.txt" "$dry_run"
            ((changes++))
        elif [[ "$item" == file:* ]]; then
            IFS=':' read -r _ source target name <<< "$item"
            sync_file "$source" "$target" "$BACKUP_DIR" "$dry_run"
            ((changes++))
        elif [[ "$item" == dir:* ]]; then
            IFS=':' read -r _ source target name <<< "$item"
            sync_directory "$source" "$target" "$BACKUP_DIR" "$dry_run"
            ((changes++))
        fi
    done

    if [ "$dry_run" = "false" ]; then
        save_sync_state "pull"
        echo ""
        echo -e "${GREEN}✓ Pull complete${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Review changes: git diff"
        echo "  2. Commit changes: git add -A && git commit"
        echo "  3. Push to remote: git push"
    else
        echo ""
        echo -e "${BLUE}Run without --dry-run to apply changes${NC}"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# Reconcile Command (Bidirectional)
# ============================================================================

cmd_reconcile() {
    local dry_run="${1:-false}"
    local conflict_strategy="${2:-ask}"  # ask, repo-wins, live-wins

    local config_json=$(parse_sync_config "$CONFIG_FILE" "$REPO_DIR")

    echo "═══════════════════════════════════════════════════════════════"
    echo " Reconcile: Bidirectional Sync"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Last reconcile: $(load_sync_state "last_reconcile")"
    echo ""

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}DRY-RUN MODE: No files will be modified${NC}"
        echo ""
    fi

    local auto_repo=0
    local auto_live=0
    local conflicts=0
    local skipped=0
    local resolved=0
    local deletions=0

    # Process every tracked file individually
    while IFS='|' read -r repo_path live_path checksum_key; do
        [ -z "$repo_path" ] && continue

        local base=$(get_base_checksum "$STATE_FILE" "$checksum_key")
        local status=$(classify_file "$repo_path" "$live_path" "$base")

        case "$status" in
            in-sync)
                continue
                ;;

            repo-changed|new-repo)
                echo -e "  ${GREEN}→${NC} $checksum_key  (repo → live)"
                sync_single_file "$repo_path" "$live_path" "$BACKUP_DIR" "$dry_run"
                ((auto_repo++))
                ;;

            live-changed|new-live)
                echo -e "  ${GREEN}←${NC} $checksum_key  (live → repo)"
                sync_single_file "$live_path" "$repo_path" "$BACKUP_DIR" "$dry_run"
                ((auto_live++))
                ;;

            deleted-repo)
                echo -e "  ${RED}×${NC} $checksum_key  (deleted in repo → delete live)"
                delete_synced_file "$live_path" "$dry_run"
                ((deletions++))
                ;;

            deleted-live)
                echo -e "  ${RED}×${NC} $checksum_key  (deleted in live → delete repo)"
                delete_synced_file "$repo_path" "$dry_run"
                ((deletions++))
                ;;

            both-changed)
                ((conflicts++))
                if [ "$dry_run" = "true" ]; then
                    echo -e "  ${YELLOW}!${NC} $checksum_key  (CONFLICT — both changed)"
                    continue
                fi

                local resolution
                case "$conflict_strategy" in
                    repo-wins)
                        echo -e "  ${YELLOW}!${NC} $checksum_key  (conflict → repo wins)"
                        resolution="repo"
                        ;;
                    live-wins)
                        echo -e "  ${YELLOW}!${NC} $checksum_key  (conflict → live wins)"
                        resolution="live"
                        ;;
                    ask)
                        resolution=$(resolve_conflict "$checksum_key" "$repo_path" "$live_path")
                        ;;
                esac

                case "$resolution" in
                    repo)
                        if [ -f "$repo_path" ]; then
                            sync_single_file "$repo_path" "$live_path" "$BACKUP_DIR" "false"
                        else
                            delete_synced_file "$live_path" "false"
                        fi
                        ((resolved++))
                        ;;
                    live)
                        if [ -f "$live_path" ]; then
                            sync_single_file "$live_path" "$repo_path" "$BACKUP_DIR" "false"
                        else
                            delete_synced_file "$repo_path" "false"
                        fi
                        ((resolved++))
                        ;;
                    skip)
                        ((skipped++))
                        ;;
                esac
                ;;
        esac
    done < <(enumerate_tracked_files "$config_json")

    # Reconcile plugins
    local plugins_file="$REPO_DIR/claude-config/plugins.txt"
    if [ -f "$plugins_file" ] && plugins_differ "$plugins_file"; then
        echo ""
        echo -e "  ${YELLOW}⚠${NC} Plugins differ"
        if [ "$dry_run" = "true" ]; then
            echo -e "  ${BLUE}[DRY-RUN]${NC} Would reconcile plugins"
        else
            echo "  Repo plugins:"
            get_repo_plugins "$plugins_file" | sed 's/^/    /'
            echo "  Live plugins:"
            get_installed_plugins | sed 's/^/    /'
            echo ""
            local plugin_choice=""
            if [ "$conflict_strategy" = "repo-wins" ]; then
                plugin_choice="r"
            elif [ "$conflict_strategy" = "live-wins" ]; then
                plugin_choice="l"
            else
                read -p "  Plugins: (r)epo → live / (l)ive → repo / (s)kip? " -r plugin_choice
            fi
            case "$plugin_choice" in
                r|repo)
                    deploy_plugins "$plugins_file" "false"
                    ;;
                l|live)
                    pull_plugins "$plugins_file" "false"
                    ;;
                *)
                    echo "  Skipped plugins"
                    ((skipped++))
                    ;;
            esac
        fi
    fi

    # Summary
    echo ""
    echo "───────────────────────────────────────────────────────────────"
    echo "SUMMARY"
    echo "───────────────────────────────────────────────────────────────"
    echo ""

    local total=$((auto_repo + auto_live + resolved + deletions))
    if [ $total -eq 0 ] && [ $conflicts -eq 0 ]; then
        echo -e "${GREEN}Already in sync. Nothing to do.${NC}"
    else
        [ $auto_repo -gt 0 ] && echo -e "  ${GREEN}→${NC} $auto_repo file(s) repo → live"
        [ $auto_live -gt 0 ] && echo -e "  ${GREEN}←${NC} $auto_live file(s) live → repo"
        [ $deletions -gt 0 ] && echo -e "  ${RED}×${NC} $deletions file(s) deleted"
        [ $resolved -gt 0 ] && echo -e "  ${YELLOW}!${NC} $resolved conflict(s) resolved"
        [ $skipped -gt 0 ] && echo -e "  ${BLUE}○${NC} $skipped item(s) skipped"
    fi

    if [ "$dry_run" = "false" ] && [ $total -gt 0 ]; then
        save_sync_state "reconcile"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# Main Command Dispatcher
# ============================================================================

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        reconcile)
            local dry_run=false
            local strategy="ask"
            for arg in "$@"; do
                case "$arg" in
                    --dry-run) dry_run=true ;;
                    --repo-wins) strategy="repo-wins" ;;
                    --live-wins) strategy="live-wins" ;;
                    *)
                        echo -e "${RED}✗${NC} Unknown option: $arg"
                        echo "Usage: ./sync.sh reconcile [--dry-run] [--repo-wins|--live-wins]"
                        exit 1
                        ;;
                esac
            done
            cmd_reconcile "$dry_run" "$strategy"
            ;;
        deploy)
            local dry_run=false
            for arg in "$@"; do
                case "$arg" in
                    --dry-run) dry_run=true ;;
                    *)
                        echo -e "${RED}✗${NC} Unknown option: $arg"
                        echo "Usage: ./sync.sh deploy [--dry-run]"
                        exit 1
                        ;;
                esac
            done
            cmd_deploy "$dry_run"
            ;;
        pull)
            local dry_run=false
            local force=false
            for arg in "$@"; do
                case "$arg" in
                    --dry-run) dry_run=true ;;
                    --force) force=true ;;
                    *)
                        echo -e "${RED}✗${NC} Unknown option: $arg"
                        echo "Usage: ./sync.sh pull [--dry-run] [--force]"
                        exit 1
                        ;;
                esac
            done
            cmd_pull "$dry_run" "$force"
            ;;
        status)
            cmd_status
            ;;
        diff)
            cmd_diff "${1:-}"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"
