#!/bin/bash

# Color theme: gray, orange, blue, green, lavender, teal, rose, gold, slate, cyan
# Auto-select color based on TTY for visual session differentiation
COLORS=(orange blue green lavender teal rose gold slate cyan)

# Get TTY number from process tree (script runs as subprocess, so walk up to find terminal)
# Try: 1) $TTY env var (zsh), 2) parent process TTY, 3) walk up process tree
get_tty_num() {
    local tty_name=""

    # Method 1: Check $TTY env var (zsh sets this)
    if [[ -n "$TTY" ]]; then
        tty_name="$TTY"
    else
        # Method 2: Walk up process tree to find a TTY
        local pid=$$
        while [[ $pid -gt 1 ]]; do
            tty_name=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
            if [[ -n "$tty_name" && "$tty_name" != "??" ]]; then
                break
            fi
            pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
        done
    fi

    # Extract number from tty name (e.g., ttys003 -> 3)
    # Use sed to strip leading zeros to avoid octal interpretation
    echo "$tty_name" | grep -o '[0-9]*$' | sed 's/^0*//' || echo "0"
}

tty_num=$(get_tty_num)
tty_num=${tty_num:-0}  # Default to 0 if empty (after stripping zeros from "000")
color_idx=$((10#$tty_num % ${#COLORS[@]}))  # 10# forces decimal interpretation
COLOR="${COLORS[$color_idx]}"

echo $COLOR
