# ============================================================================
# .bash_aliases - Shell aliases and environment paths
# ============================================================================

# Ensure local and npm global binaries are in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
if [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
    export PATH="$HOME/.npm-global/bin:$PATH"
fi

# Tool shortcuts
alias tw='timew'
alias tb='tb'

# Common navigation & listing
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts
alias gs='git status -sb'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 15'

# Quick helper functions
# Quick open Vimwiki
wiki() {
    mkdir -p "$HOME/vimwiki"
    vim "$HOME/vimwiki/index.md"
}

# Quick daily overview: Timewarrior summary + Taskbook active tasks
today() {
    echo -e "\033[1;34m=== Taskbook Overview ===\033[0m"
    if command -v tb &>/dev/null; then
        tb
    else
        echo "taskbook (tb) not found in PATH"
    fi
    echo ""
    echo -e "\033[1;34m=== Timewarrior Summary ===\033[0m"
    if command -v timew &>/dev/null; then
        timew summary :today
    else
        echo "timewarrior (timew) not found in PATH"
    fi
}
