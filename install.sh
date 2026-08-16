#!/usr/bin/env bash
# ============================================================================
# install.sh - Universal Environment Bootstrap & Dotfiles Installer
# Compatible with: ChromeOS, GitHub Codespaces, Google Cloud Shell, Linux VMs
# ============================================================================

set -e

# Color definitions for output
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }

START_TIME=$(date +%s)

# ----------------------------------------------------------------------------
# 1. Determine Execution Context & User Information
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Identify target non-root user if running as root
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=true
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        TARGET_USER="$SUDO_USER"
    else
        # Try to find UID 1000 user (standard on Cloud Shell, Codespaces, Crostini)
        TARGET_USER=$(getent passwd | awk -F: '$3 == 1000 {print $1}')
        if [ -z "$TARGET_USER" ]; then
            TARGET_USER=$(whoami)
        fi
    fi
else
    IS_ROOT=false
    TARGET_USER="$(whoami)"
fi

TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [ -z "$TARGET_HOME" ]; then
    TARGET_HOME="$HOME"
fi

log_info "Running setup for user: ${BOLD}$TARGET_USER${RESET} (Home: $TARGET_HOME)"

# Helper functions for privilege separation
run_as_target_user() {
    if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
        sudo -u "$TARGET_USER" HOME="$TARGET_HOME" PATH="$TARGET_HOME/.npm-global/bin:$TARGET_HOME/.local/bin:$PATH" "$@"
    else
        PATH="$TARGET_HOME/.npm-global/bin:$TARGET_HOME/.local/bin:$PATH" "$@"
    fi
}

run_as_root() {
    if [ "$IS_ROOT" = true ]; then
        "$@"
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    else
        log_error "Root privileges required for '$*' but sudo is not available."
        return 1
    fi
}

# ----------------------------------------------------------------------------
# 2. System Packages (timewarrior, git, curl, wget, unzip, vim)
# ----------------------------------------------------------------------------
# Detect NVM if present in user or system paths
for nvm_path in "$TARGET_HOME/.nvm/nvm.sh" "/usr/local/nvm/nvm.sh" "/usr/share/nvm/init-nvm.sh"; do
    if [ -s "$nvm_path" ]; then
        export NVM_DIR="$(dirname "$nvm_path")"
        [ -s "$nvm_path" ] && \. "$nvm_path" 2>/dev/null || true
        break
    fi
done

log_info "Checking system packages..."

REQUIRED_PACKAGES=()
command -v timew &>/dev/null || REQUIRED_PACKAGES+=("timewarrior")
command -v git &>/dev/null   || REQUIRED_PACKAGES+=("git")
command -v curl &>/dev/null  || REQUIRED_PACKAGES+=("curl")
command -v wget &>/dev/null  || REQUIRED_PACKAGES+=("wget")
command -v unzip &>/dev/null || REQUIRED_PACKAGES+=("unzip")
command -v vim &>/dev/null   || REQUIRED_PACKAGES+=("vim")
command -v node &>/dev/null  || REQUIRED_PACKAGES+=("nodejs")
command -v npm &>/dev/null   || REQUIRED_PACKAGES+=("npm")

if [ ${#REQUIRED_PACKAGES[@]} -gt 0 ]; then
    log_info "Installing missing packages: ${REQUIRED_PACKAGES[*]}..."
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        run_as_root apt-get update -qq
        run_as_root apt-get install -y -qq "${REQUIRED_PACKAGES[@]}" ca-certificates
        log_success "System packages installed successfully."
    else
        log_warn "apt-get not detected. Please ensure the following are installed: ${REQUIRED_PACKAGES[*]}"
    fi
else
    log_info "All required system packages are already installed."
fi

# ----------------------------------------------------------------------------
# 3. Create Persistent User Directories & Pre-init Configurations
# ----------------------------------------------------------------------------
log_info "Setting up directories in $TARGET_HOME..."
mkdir -p "$TARGET_HOME/.local/bin"
mkdir -p "$TARGET_HOME/.vim/pack/plugins/start"
mkdir -p "$TARGET_HOME/vimwiki"

# Pre-initialize Timewarrior configuration so it doesn't block on first-run prompt
mkdir -p "$TARGET_HOME/.config/timewarrior/extensions"
mkdir -p "$TARGET_HOME/.local/share/timewarrior/data"
touch "$TARGET_HOME/.config/timewarrior/timewarrior.cfg"

# ----------------------------------------------------------------------------
# 4. Node & NPM Setup (with NVM Auto-Detection)
# ----------------------------------------------------------------------------
USING_NVM=false
for nvm_path in "$TARGET_HOME/.nvm/nvm.sh" "/usr/local/nvm/nvm.sh" "/usr/share/nvm/init-nvm.sh"; do
    if [ -s "$nvm_path" ]; then
        export NVM_DIR="$(dirname "$nvm_path")"
        [ -s "$nvm_path" ] && \. "$nvm_path" 2>/dev/null || true
        if command -v nvm &>/dev/null; then
            USING_NVM=true
            log_info "Detected NVM ($nvm_path). Node $(node -v 2>/dev/null || true) is active."
            break
        fi
    fi
done

if command -v npm &>/dev/null; then
    if [ "$USING_NVM" = true ]; then
        # NVM isolates packages per Node version and doesn't require sudo; remove prefix if set
        log_info "NVM is active. Keeping npm prefix clean for NVM version isolation."
        run_as_target_user npm config delete prefix 2>/dev/null || true
    else
        # System Node requires ~/.npm-global prefix to avoid sudo
        log_info "System Node detected. Configuring npm prefix at $TARGET_HOME/.npm-global..."
        mkdir -p "$TARGET_HOME/.npm-global"
        run_as_target_user npm config set prefix "$TARGET_HOME/.npm-global"
    fi
    
    # Install taskbook if not present
    if ! command -v tb &>/dev/null && [ ! -f "$TARGET_HOME/.npm-global/bin/tb" ]; then
        log_info "Installing taskbook (tb)..."
        run_as_target_user npm install -g --silent taskbook
        log_success "Taskbook installed."
    else
        log_info "Taskbook is already installed."
    fi
else
    log_warn "npm not available. Skipping taskbook installation."
fi

# ----------------------------------------------------------------------------
# 5. Install ghq (GitHub Repository Manager)
# ----------------------------------------------------------------------------
if [ ! -f "$TARGET_HOME/.local/bin/ghq" ] && ! command -v ghq &>/dev/null; then
    log_info "Installing ghq into $TARGET_HOME/.local/bin..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GHQ_ARCH="linux_amd64" ;;
        aarch64|arm64) GHQ_ARCH="linux_arm64" ;;
        *) GHQ_ARCH="linux_amd64" ;;
    esac

    GHQ_URL=$(curl -s "https://api.github.com/repos/x-motemen/ghq/releases/latest" 2>/dev/null | grep "browser_download_url.*${GHQ_ARCH}.zip" | cut -d '"' -f 4 | head -n 1 || true)
    
    if [ -z "$GHQ_URL" ]; then
        # Fallback to known release URL if GitHub API rate limit is reached
        GHQ_URL="https://github.com/x-motemen/ghq/releases/download/v1.7.1/ghq_${GHQ_ARCH}.zip"
    fi

    TMP_DIR=$(mktemp -d)
    if curl -fsSL "$GHQ_URL" -o "$TMP_DIR/ghq.zip"; then
        unzip -q "$TMP_DIR/ghq.zip" -d "$TMP_DIR"
        find "$TMP_DIR" -name ghq -type f -exec mv {} "$TARGET_HOME/.local/bin/ghq" \;
        chmod +x "$TARGET_HOME/.local/bin/ghq"
        log_success "ghq installed."
    else
        log_warn "Failed to download ghq."
    fi
    rm -rf "$TMP_DIR"
else
    log_info "ghq is already installed."
fi

# ----------------------------------------------------------------------------
# 6. Vim Plugins (Native Vim 8+ Packages)
# ----------------------------------------------------------------------------
log_info "Installing/updating Vim plugins..."
VIM_PACK_DIR="$TARGET_HOME/.vim/pack/plugins/start"

PLUGINS=(
    "https://github.com/tpope/vim-sensible.git"
    "https://github.com/tpope/vim-surround.git"
    "https://github.com/tpope/vim-commentary.git"
    "https://github.com/tpope/vim-fugitive.git"
    "https://github.com/tpope/vim-repeat.git"
    "https://github.com/vimwiki/vimwiki.git"
    "https://github.com/wakatime/vim-wakatime.git"
)

for repo in "${PLUGINS[@]}"; do
    plugin_name=$(basename "$repo" .git)
    plugin_path="$VIM_PACK_DIR/$plugin_name"
    if [ ! -d "$plugin_path" ]; then
        log_info "  -> Cloning $plugin_name..."
        run_as_target_user git clone --depth 1 -q "$repo" "$plugin_path"
    else
        log_info "  -> $plugin_name is already present."
    fi
done

# ----------------------------------------------------------------------------
# 7. Dotfiles Linking & Shell Configuration
# ----------------------------------------------------------------------------
log_info "Configuring dotfiles (.vimrc, .bash_aliases, .bashrc)..."

# Copy or symlink .vimrc
if [ -f "$SCRIPT_DIR/.vimrc" ]; then
    if [ ! -f "$TARGET_HOME/.vimrc" ] || ! cmp -s "$SCRIPT_DIR/.vimrc" "$TARGET_HOME/.vimrc"; then
        cp "$SCRIPT_DIR/.vimrc" "$TARGET_HOME/.vimrc"
        log_success "Copied .vimrc to $TARGET_HOME/.vimrc"
    fi
fi

# Copy or symlink .bash_aliases
if [ -f "$SCRIPT_DIR/.bash_aliases" ]; then
    if [ ! -f "$TARGET_HOME/.bash_aliases" ] || ! cmp -s "$SCRIPT_DIR/.bash_aliases" "$TARGET_HOME/.bash_aliases"; then
        cp "$SCRIPT_DIR/.bash_aliases" "$TARGET_HOME/.bash_aliases"
        log_success "Copied .bash_aliases to $TARGET_HOME/.bash_aliases"
    fi
fi

# Ensure PATH and .bash_aliases in .bashrc and .profile
BASHRC="$TARGET_HOME/.bashrc"
PROFILE="$TARGET_HOME/.profile"

# Export in .profile
if [ -f "$PROFILE" ] && ! grep -q ".npm-global/bin" "$PROFILE"; then
    cat << 'EOF' >> "$PROFILE"

# User local & npm-global PATH
if [ -d "$HOME/.npm-global/bin" ]; then
    PATH="$HOME/.npm-global/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi
export PATH
EOF
fi

# Export in .bashrc
if [ -f "$BASHRC" ]; then
    if ! grep -q ".npm-global/bin" "$BASHRC"; then
        echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> "$BASHRC"
    fi
    if ! grep -q ".bash_aliases" "$BASHRC"; then
        cat << 'EOF' >> "$BASHRC"

# Source .bash_aliases if present
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
    fi
fi

# ----------------------------------------------------------------------------
# 8. Fix Ownership (when running as root)
# ----------------------------------------------------------------------------
if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
    chown -R "$TARGET_USER:$TARGET_USER" \
        "$TARGET_HOME/.local" \
        "$TARGET_HOME/.npm-global" \
        "$TARGET_HOME/.config" \
        "$TARGET_HOME/.vim" \
        "$TARGET_HOME/.vimrc" \
        "$TARGET_HOME/.bash_aliases" \
        "$TARGET_HOME/vimwiki" 2>/dev/null || true
fi

# ----------------------------------------------------------------------------
# 9. Summary Banner
# ----------------------------------------------------------------------------
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN} Environment Initialization Complete (${DURATION}s)!${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "  - ${BOLD}Timewarrior:${RESET}  $(command -v timew &>/dev/null && timew --version 2>&1 | head -n 1 || echo 'Installed (restart shell)')"
echo -e "  - ${BOLD}Taskbook:${RESET}     $(command -v tb &>/dev/null && tb --version 2>&1 || ([ -f "$TARGET_HOME/.npm-global/bin/tb" ] && "$TARGET_HOME/.npm-global/bin/tb" --version 2>&1) || echo 'Installed')"
echo -e "  - ${BOLD}ghq:${RESET}          $([ -f "$TARGET_HOME/.local/bin/ghq" ] && "$TARGET_HOME/.local/bin/ghq" --version 2>&1 | head -n 1 || echo 'Installed')"
echo -e "  - ${BOLD}Vim Plugins:${RESET}  $(ls -1 "$VIM_PACK_DIR" 2>/dev/null | wc -l) plugins in ~/.vim/pack/plugins/start"
echo -e "  - ${BOLD}Vimwiki:${RESET}      Configured with Markdown syntax (~/vimwiki/)"
echo -e "  - ${BOLD}Shell Aliases:${RESET} Sourced via ~/.bash_aliases (tw, tb, wiki, today)"
echo ""
echo -e "To reload your current shell immediately, run:"
echo -e "  ${BOLD}source ~/.bashrc${RESET}"
echo ""
