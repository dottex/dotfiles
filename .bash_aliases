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

# fzf Shell Configuration & Keybindings
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'
    # Source debian/ubuntu/arch fzf shell bindings if present
    if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash 2>/dev/null || true
    elif [ -f ~/.fzf.bash ]; then
        source ~/.fzf.bash 2>/dev/null || true
    fi
fi

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

# Environment Configuration Status Report
env-status() {
    local status_script=""
    for p in "$HOME/dotfiles/status.sh" "$HOME/Projects/dotfiles/status.sh" "./status.sh"; do
        if [ -x "$p" ]; then
            status_script="$p"
            break
        fi
    done

    if [ -n "$status_script" ]; then
        "$status_script" "$@"
    else
        echo "status.sh not found. Clone dotfiles to ~/dotfiles or run from repo directory."
    fi
}

# Run automated tests
test-env() {
    local test_script=""
    for p in "$HOME/dotfiles/tests/run_tests.sh" "$HOME/Projects/dotfiles/tests/run_tests.sh" "./tests/run_tests.sh"; do
        if [ -x "$p" ]; then
            test_script="$p"
            break
        fi
    done

    if [ -n "$test_script" ]; then
        "$test_script" "$@"
    else
        echo "tests/run_tests.sh not found."
    fi
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
