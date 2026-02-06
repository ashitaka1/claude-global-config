#!/bin/bash

# Claude Code statusline script
# Line 1: MODEL | dir | branch status (sync) | lang | context bar
# Line 2: last user message

# Per-session color theming via TTY-based color selection
COLOR=$(bash ~/.claude/scripts/terminal-color.sh)

C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'
C_BAR_EMPTY='\033[38;5;238m'
case "$COLOR" in
    orange)   C_ACCENT='\033[38;5;173m' ;;
    blue)     C_ACCENT='\033[38;5;74m' ;;
    teal)     C_ACCENT='\033[38;5;66m' ;;
    green)    C_ACCENT='\033[38;5;71m' ;;
    lavender) C_ACCENT='\033[38;5;139m' ;;
    rose)     C_ACCENT='\033[38;5;132m' ;;
    gold)     C_ACCENT='\033[38;5;136m' ;;
    slate)    C_ACCENT='\033[38;5;60m' ;;
    cyan)     C_ACCENT='\033[38;5;37m' ;;
    *)        C_ACCENT="$C_GRAY" ;;
esac

input=$(cat)

# --- JSON extraction ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
max_k=$((max_context / 1000))

# --- Directory display (last 3 components with ~/ prefix) ---
cwd_tilde="${cwd/#$HOME/~}"
dir_display=$(echo "$cwd_tilde" | awk -F'/' '{
  n=NF
  if(n<=3) print $0
  else printf ".../%s/%s/%s",$(n-2),$(n-1),$n
}')

# --- Git section ---
branch=""
git_symbols=""
sync_info=""

if [[ -n "$cwd" && -d "$cwd" ]] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Categorized git status (no -uall to avoid memory issues on large repos)
    git_porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

    if [[ -n "$git_porcelain" ]]; then
        has_modified=$(echo "$git_porcelain" | grep -cE '^ M|^M ')
        has_staged=$(echo "$git_porcelain" | grep -cE '^[MADR]')
        has_untracked=$(echo "$git_porcelain" | grep -c '^??')

        [[ "$has_modified" -gt 0 ]] && git_symbols+="📝"
        [[ "$has_staged" -gt 0 ]] && git_symbols+="${C_ACCENT}++(${has_staged})${C_RESET}"
        [[ "$has_untracked" -gt 0 ]] && git_symbols+="🤷"
    else
        git_symbols="${C_ACCENT}✓${C_RESET}"
    fi

    # Remote sync status
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        fetch_head="$cwd/.git/FETCH_HEAD"
        fetch_ago=""
        if [[ -f "$fetch_head" ]]; then
            fetch_time=$(stat -f %m "$fetch_head" 2>/dev/null || stat -c %Y "$fetch_head" 2>/dev/null)
            if [[ -n "$fetch_time" ]]; then
                now=$(date +%s)
                diff=$((now - fetch_time))
                if [[ $diff -lt 60 ]]; then fetch_ago="<1m ago"
                elif [[ $diff -lt 3600 ]]; then fetch_ago="$((diff / 60))m ago"
                elif [[ $diff -lt 86400 ]]; then fetch_ago="$((diff / 3600))h ago"
                else fetch_ago="$((diff / 86400))d ago"
                fi
            fi
        fi

        counts=$(git -C "$cwd" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
        ahead=$(echo "$counts" | cut -f1)
        behind=$(echo "$counts" | cut -f2)

        if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
            sync_info="synced${fetch_ago:+ ${fetch_ago}}"
        elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
            sync_info="${ahead} ahead${fetch_ago:+, ${fetch_ago}}"
        elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
            sync_info="${behind} behind${fetch_ago:+, ${fetch_ago}}"
        else
            sync_info="${ahead}↑ ${behind}↓"
        fi
    fi
fi

# --- Language indicators ---
lang=""
[[ -n "$cwd" && -f "$cwd/go.mod" ]] && lang="🐹"

# --- Context window bar ---
# 20k baseline: system prompt (~3k), tools (~15k), memory (~300), plus dynamic context
baseline=20000
bar_width=10

context_length=0
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    context_length=$(jq -s '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        last |
        if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end
    ' < "$transcript_path")
fi

if [[ "$context_length" -gt 0 ]]; then
    pct=$((context_length * 100 / max_context))
    pct_prefix=""
else
    pct=$((baseline * 100 / max_context))
    pct_prefix="~"
fi
[[ $pct -gt 100 ]] && pct=100

bar=""
for ((i=0; i<bar_width; i++)); do
    bar_start=$((i * 10))
    progress=$((pct - bar_start))
    if [[ $progress -ge 8 ]]; then
        bar+="${C_ACCENT}█${C_RESET}"
    elif [[ $progress -ge 3 ]]; then
        bar+="${C_ACCENT}▄${C_RESET}"
    else
        bar+="${C_BAR_EMPTY}░${C_RESET}"
    fi
done

ctx="${bar} ${C_GRAY}${pct_prefix}${pct}% of ${max_k}k tokens"

# --- Build line 1 ---
output="${C_ACCENT}${model}${C_GRAY} | ${C_ACCENT}${dir_display}"
if [[ -n "$branch" ]]; then
    output+="${C_GRAY} | 🌱 ${branch}"
    [[ -n "$git_symbols" ]] && output+=" ${git_symbols}"
    [[ -n "$sync_info" ]] && output+="${C_GRAY} (${sync_info})"
fi
[[ -n "$lang" ]] && output+="${C_GRAY} | ${lang}"
output+="${C_GRAY} | ${ctx}${C_RESET}"

printf '%b\n' "$output"

# --- Line 2: last user message ---
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    plain_output="${model} | ${dir_display}"
    [[ -n "$branch" ]] && plain_output+=" | ${branch} ${git_symbols} (${sync_info})"
    [[ -n "$lang" ]] && plain_output+=" | ${lang}"
    plain_output+=" | xxxxxxxxxx ${pct}% of ${max_k}k tokens"
    max_len=${#plain_output}

    last_user_msg=$(jq -rs '
        def is_unhelpful:
            startswith("[Request interrupted") or
            startswith("[Request cancelled") or
            . == "";

        [.[] | select(.type == "user") |
         select(.message.content | type == "string" or
                (type == "array" and any(.[]; .type == "text")))] |
        reverse |
        map(.message.content |
            if type == "string" then .
            else [.[] | select(.type == "text") | .text] | join(" ") end |
            gsub("\n"; " ") | gsub("  +"; " ")) |
        map(select(is_unhelpful | not)) |
        first // ""
    ' < "$transcript_path" 2>/dev/null)

    if [[ -n "$last_user_msg" ]]; then
        if [[ ${#last_user_msg} -gt $max_len ]]; then
            echo "💬 ${last_user_msg:0:$((max_len - 3))}..."
        else
            echo "💬 ${last_user_msg}"
        fi
    fi
fi
