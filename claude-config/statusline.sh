#!/bin/bash
# Claude Code statusline script
# Displays: directory, git branch, git status symbols, and language indicators

# Read input from stdin
input=$(cat)

# Extract current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Convert home directory to tilde
cwd_tilde="${cwd/#$HOME/~}"

# Shorten directory path if too long (keep last 3 components)
dir_display=$(echo "$cwd_tilde" | awk -F'/' '{
  n=NF
  if(n<=3) print $0
  else printf ".../%s/%s/%s",$(n-2),$(n-1),$n
}')

# Start output with cyan directory
output="$(printf '\033[36m%s\033[0m' "$dir_display")"

# Check if in a git repository
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  # Get current branch name
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  output="${output} $(printf '\033[32m🌱 %s\033[0m' "$branch")"

  # Get git status
  git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

  if [ -n "$git_status" ]; then
    # Count different types of changes
    has_modified=$(echo "$git_status" | grep -E '^ M|^M ' | wc -l | tr -d ' ')
    has_untracked=$(echo "$git_status" | grep '^??' | wc -l | tr -d ' ')
    has_staged=$(echo "$git_status" | grep -E '^[MADR]' | wc -l | tr -d ' ')

    # Build status symbols
    status_symbols=""
    [ "$has_modified" -gt 0 ] && status_symbols="${status_symbols}📝"
    [ "$has_staged" -gt 0 ] && status_symbols="${status_symbols}$(printf '\033[32m++(%s)\033[0m' "$has_staged")"
    [ "$has_untracked" -gt 0 ] && status_symbols="${status_symbols}🤷"

    [ -n "$status_symbols" ] && output="${output} ${status_symbols}"
  else
    # Clean working directory
    output="${output} $(printf '\033[32m✓\033[0m')"
  fi
fi

# Show Go project indicator
[ -f "$cwd/go.mod" ] && output="${output} $(printf '\033[36m🐹\033[0m')"

# Output the final statusline
echo "$output"
