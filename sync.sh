#!/usr/bin/env bash
# sync.sh - Claude Code Configuration Sync System
# Bidirectional sync between repository and live config

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source core functions
# shellcheck source=lib/sync-core.sh
source "$SCRIPT_DIR/lib/sync-core.sh"

# Configuration
readonly REPO_DIR="$SCRIPT_DIR"
readonly LIVE_DIR="$HOME/.claude"
readonly STATE_FILE="$REPO_DIR/.sync-state.json"
readonly BACKUP_DIR="$HOME/.claude/backups/sync"

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
  deploy [--dry-run]   Deploy repo → live config (overwrite)
  pull [--dry-run]     Pull live → repo (overwrite)
  status               Show sync status and differences
  diff [file]          Show detailed diff for file(s)
  help                 Show this help message

OPTIONS:
  --dry-run            Preview changes without modifying files

WORKFLOW:
  1. Experiment in live config (~/.claude/)
  2. Check status:     ./sync.sh status
  3. Review changes:   ./sync.sh diff
  4. Pull to repo:     ./sync.sh pull
  5. Commit changes:   git add -A && git commit
  6. Deploy elsewhere: git pull && ./sync.sh deploy

EXAMPLES:
  ./sync.sh status                 # Check what's different
  ./sync.sh diff CLAUDE.md         # Show diff for specific file
  ./sync.sh pull --dry-run         # Preview pull operation
  ./sync.sh deploy                 # Deploy repo to live config

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

    # Check CLAUDE.md
    local repo_claude="$REPO_DIR/CLAUDE.md"
    local live_claude="$LIVE_DIR/CLAUDE.md"

    if files_differ "$repo_claude" "$live_claude"; then
        format_status_line "diverged" "CLAUDE.md" "DIVERGED"
        echo "  Repo:  $(format_file_details "$repo_claude")"
        echo "  Live:  $(format_file_details "$live_claude")"
        ((issues++))
    else
        local lines=$(wc -l < "$repo_claude" 2>/dev/null | tr -d ' ' || echo "?")
        format_status_line "in-sync" "CLAUDE.md" "(${lines} lines)"
    fi

    # Check settings.json
    local repo_settings="$REPO_DIR/claude-config/settings.sync.json"
    local live_settings="$LIVE_DIR/settings.json"

    if files_differ "$repo_settings" "$live_settings"; then
        format_status_line "diverged" "settings.json" "DIVERGED"
        echo "  Repo:  $(format_file_details "$repo_settings")"
        echo "  Live:  $(format_file_details "$live_settings")"
        ((issues++))
    else
        local lines=$(wc -l < "$repo_settings" 2>/dev/null | tr -d ' ' || echo "?")
        format_status_line "in-sync" "settings.json" "(${lines} lines)"
    fi

    # Check api_key_helper.sh
    local repo_helper="$REPO_DIR/claude-config/api_key_helper.sh"
    local live_helper="$LIVE_DIR/api_key_helper.sh"

    if [ -f "$repo_helper" ] || [ -f "$live_helper" ]; then
        if files_differ "$repo_helper" "$live_helper"; then
            format_status_line "diverged" "api_key_helper.sh" "DIVERGED"
            echo "  Repo:  $(format_file_details "$repo_helper")"
            echo "  Live:  $(format_file_details "$live_helper")"
            ((issues++))
        else
            format_status_line "in-sync" "api_key_helper.sh"
        fi
    fi

    # Check agents directory
    local repo_agents="$REPO_DIR/claude-config/agents"
    local live_agents="$LIVE_DIR/agents"

    if directories_differ "$repo_agents" "$live_agents"; then
        format_status_line "diverged" "agents/" "DIVERGED"

        # Count files in each
        local repo_count=$(find "$repo_agents" -type f 2>/dev/null | wc -l | tr -d ' ')
        local live_count=$(find "$live_agents" -type f 2>/dev/null | wc -l | tr -d ' ')

        echo "  Repo:  $repo_count files"
        echo "  Live:  $live_count files"
        ((issues++))
    else
        local count=$(find "$repo_agents" -type f 2>/dev/null | wc -l | tr -d ' ')
        format_status_line "in-sync" "agents/" "($count files)"
    fi

    # Check skills directory
    local repo_skills="$REPO_DIR/claude-config/skills"
    local live_skills="$LIVE_DIR/skills"

    if directories_differ "$repo_skills" "$live_skills"; then
        format_status_line "diverged" "skills/" "DIVERGED"

        # Count directories in each
        local repo_count=$(find "$repo_skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        local live_count=$(find "$live_skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

        echo "  Repo:  $repo_count skill(s)"
        echo "  Live:  $live_count skill(s)"
        ((issues++))
    else
        local count=$(find "$repo_skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        format_status_line "in-sync" "skills/" "($count skill(s))"
    fi

    # Check plugins
    local plugins_file="$REPO_DIR/claude-config/plugins.txt"
    if [ -f "$plugins_file" ]; then
        local repo_plugins=$(grep -v '^#' "$plugins_file" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
        local live_plugins=$(claude plugin list 2>/dev/null | grep -E '^\s+❯' | wc -l | tr -d ' ')

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
        echo ""
        echo "Next Steps:"
        echo "  1. Review changes: ./sync.sh diff"
        echo "  2. Preview pull:   ./sync.sh pull --dry-run"
        echo "  3. Pull to repo:   ./sync.sh pull"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# Diff Command
# ============================================================================

cmd_diff() {
    local target="${1:-}"

    if [ -z "$target" ]; then
        # Show all diffs
        echo "═══════════════════════════════════════════════════════════════"
        echo " Differences Between Repo and Live Config"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""

        # CLAUDE.md
        if files_differ "$REPO_DIR/CLAUDE.md" "$LIVE_DIR/CLAUDE.md"; then
            echo "─── CLAUDE.md ─────────────────────────────────────────────"
            show_diff "$REPO_DIR/CLAUDE.md" "$LIVE_DIR/CLAUDE.md"
            echo ""
        fi

        # settings.json
        if files_differ "$REPO_DIR/claude-config/settings.sync.json" "$LIVE_DIR/settings.json"; then
            echo "─── settings.json ─────────────────────────────────────────"
            show_diff "$REPO_DIR/claude-config/settings.sync.json" "$LIVE_DIR/settings.json"
            echo ""
        fi

        # agents
        if directories_differ "$REPO_DIR/claude-config/agents" "$LIVE_DIR/agents"; then
            echo "─── agents/ ───────────────────────────────────────────────"
            echo "Directories differ. Use 'diff agents' for details."
            echo ""
        fi

        # skills
        if directories_differ "$REPO_DIR/claude-config/skills" "$LIVE_DIR/skills"; then
            echo "─── skills/ ───────────────────────────────────────────────"
            echo "Directories differ. Use 'diff skills' for details."
            echo ""
        fi

        return
    fi

    # Show specific file diff
    case "$target" in
        CLAUDE.md)
            show_diff "$REPO_DIR/CLAUDE.md" "$LIVE_DIR/CLAUDE.md"
            ;;
        settings.json|settings)
            show_diff "$REPO_DIR/claude-config/settings.sync.json" "$LIVE_DIR/settings.json"
            ;;
        api_key_helper.sh|api_key_helper)
            show_diff "$REPO_DIR/claude-config/api_key_helper.sh" "$LIVE_DIR/api_key_helper.sh"
            ;;
        agents)
            diff -ur "$REPO_DIR/claude-config/agents" "$LIVE_DIR/agents" || true
            ;;
        skills)
            diff -ur "$REPO_DIR/claude-config/skills" "$LIVE_DIR/skills" || true
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown target: $target"
            echo "Valid targets: CLAUDE.md, settings, api_key_helper, agents, skills"
            exit 1
            ;;
    esac
}

# ============================================================================
# Deploy Command (Repo → Live)
# ============================================================================

cmd_deploy() {
    local dry_run="${1:-false}"

    echo "═══════════════════════════════════════════════════════════════"
    echo " Deploy: Repo → Live Config"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    if [ "$dry_run" = "true" ]; then
        echo -e "${BLUE}DRY-RUN MODE: No files will be modified${NC}"
        echo ""
    fi

    # Deploy CLAUDE.md
    if [ -f "$REPO_DIR/CLAUDE.md" ]; then
        sync_file "$REPO_DIR/CLAUDE.md" "$LIVE_DIR/CLAUDE.md" "$BACKUP_DIR" "$dry_run"
    fi

    # Deploy settings.json
    if [ -f "$REPO_DIR/claude-config/settings.sync.json" ]; then
        sync_file "$REPO_DIR/claude-config/settings.sync.json" "$LIVE_DIR/settings.json" "$BACKUP_DIR" "$dry_run"
    fi

    # Deploy api_key_helper.sh (with interpolation)
    if [ -f "$REPO_DIR/claude-config/api_key_helper.sh" ]; then
        deploy_api_key_helper "$dry_run"
    fi

    # Deploy agents directory
    if [ -d "$REPO_DIR/claude-config/agents" ]; then
        sync_directory "$REPO_DIR/claude-config/agents" "$LIVE_DIR/agents" "$BACKUP_DIR" "$dry_run"
    fi

    # Deploy skills directory
    if [ -d "$REPO_DIR/claude-config/skills" ]; then
        sync_directory "$REPO_DIR/claude-config/skills" "$LIVE_DIR/skills" "$BACKUP_DIR" "$dry_run"
    fi

    # Deploy plugins (install from plugins.txt)
    if [ -f "$REPO_DIR/claude-config/plugins.txt" ]; then
        deploy_plugins "$REPO_DIR/claude-config/plugins.txt" "$dry_run"
    fi

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

    echo "═══════════════════════════════════════════════════════════════"
    echo " Pull: Live Config → Repo"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    if [ "$dry_run" = "false" ]; then
        echo -e "${YELLOW}⚠  This will overwrite repo files with live config${NC}"
        echo "Affected: CLAUDE.md, settings.sync.json, agents/, skills/"
        echo ""
        read -p "Continue? (yes/no): " -r confirm
        if [ "$confirm" != "yes" ]; then
            echo "Aborted"
            exit 0
        fi
        echo ""
    else
        echo -e "${BLUE}DRY-RUN MODE: No files will be modified${NC}"
        echo ""
    fi

    # Pull CLAUDE.md
    if [ -f "$LIVE_DIR/CLAUDE.md" ]; then
        sync_file "$LIVE_DIR/CLAUDE.md" "$REPO_DIR/CLAUDE.md" "$BACKUP_DIR" "$dry_run"
    fi

    # Pull settings.json
    if [ -f "$LIVE_DIR/settings.json" ]; then
        sync_file "$LIVE_DIR/settings.json" "$REPO_DIR/claude-config/settings.sync.json" "$BACKUP_DIR" "$dry_run"
    fi

    # Pull api_key_helper.sh (with sanitization)
    if [ -f "$LIVE_DIR/api_key_helper.sh" ]; then
        if [ "$dry_run" = "true" ]; then
            echo -e "${BLUE}[DRY-RUN]${NC} Would sanitize and pull api_key_helper.sh"
        else
            sanitize_api_key_helper
        fi
    fi

    # Pull agents directory
    if [ -d "$LIVE_DIR/agents" ]; then
        sync_directory "$LIVE_DIR/agents" "$REPO_DIR/claude-config/agents" "$BACKUP_DIR" "$dry_run"
    fi

    # Pull skills directory
    if [ -d "$LIVE_DIR/skills" ]; then
        sync_directory "$LIVE_DIR/skills" "$REPO_DIR/claude-config/skills" "$BACKUP_DIR" "$dry_run"
    fi

    # Pull plugins (update plugins.txt from installed plugins)
    pull_plugins "$REPO_DIR/claude-config/plugins.txt" "$dry_run"

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
        deploy)
            local dry_run=false
            if [ "${1:-}" = "--dry-run" ]; then
                dry_run=true
            fi
            cmd_deploy "$dry_run"
            ;;
        pull)
            local dry_run=false
            if [ "${1:-}" = "--dry-run" ]; then
                dry_run=true
            fi
            cmd_pull "$dry_run"
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
