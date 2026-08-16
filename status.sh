#!/usr/bin/env bash
# ============================================================================
# status.sh - Environment Configuration Settings & Health Report
# Inspects and reports the health of developer tools, dotfiles, and paths.
# ============================================================================

set -e

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
GRAY="\033[0;90m"
RESET="\033[0m"

PASS_ICON="${GREEN}✔ PASS${RESET}"
WARN_ICON="${YELLOW}▲ WARN${RESET}"
FAIL_ICON="${RED}✖ FAIL${RESET}"

MODE="full"
if [ "$1" = "--json" ]; then
    MODE="json"
elif [ "$1" = "--summary" ] || [ "$1" = "-s" ]; then
    MODE="summary"
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: ./status.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --json       Output status in JSON format"
    echo "  --summary    Output concise single-block summary"
    echo "  --help       Show this help message"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="$(whoami)"
TARGET_HOME="$HOME"

# Counters for health verdict
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

record_check() {
    local status="$1" # PASS, WARN, FAIL
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    case "$status" in
        PASS) PASSED_CHECKS=$((PASSED_CHECKS + 1)) ;;
        WARN) WARNING_CHECKS=$((WARNING_CHECKS + 1)) ;;
        FAIL) FAILED_CHECKS=$((FAILED_CHECKS + 1)) ;;
    esac
}

# ----------------------------------------------------------------------------
# 1. System & Platform Detection
# ----------------------------------------------------------------------------
HOSTNAME_STR=$(hostname 2>/dev/null || echo "unknown")
KERNEL_STR=$(uname -sr 2>/dev/null || echo "unknown")
ARCH_STR=$(uname -m 2>/dev/null || echo "unknown")

if [ -f /etc/os-release ]; then
    OS_NAME=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_NAME=$(uname -s)
fi

PLATFORM="Generic Linux VM"
if [ -n "$CODESPACES" ] || [ -d "/workspaces" ]; then
    PLATFORM="GitHub Codespaces"
elif [ -n "$CLOUD_SHELL" ] || [ -f "$TARGET_HOME/.cloudshell/no-apt-get-warning" ]; then
    PLATFORM="Google Cloud Shell"
elif [ -f /etc/lsb-release ] && grep -qi "chromeos" /etc/lsb-release 2>/dev/null; then
    PLATFORM="ChromeOS (Crostini)"
elif [ -d "/dev/cpt" ] || [ -f "/usr/bin/sommelier" ]; then
    PLATFORM="ChromeOS (Crostini)"
fi

# ----------------------------------------------------------------------------
# 2. Tool Checks Helper
# ----------------------------------------------------------------------------
check_tool() {
    local cmd="$1"
    local fallback_path="$2"
    local version_flag="${3:---version}"
    
    local resolved_path=""
    local version_str="Not installed"
    local status="FAIL"

    if command -v "$cmd" &>/dev/null; then
        resolved_path=$(command -v "$cmd")
        version_str=$("$cmd" $version_flag 2>&1 | head -n 1 | tr -d '\r' || echo "installed")
        status="PASS"
    elif [ -n "$fallback_path" ] && [ -x "$fallback_path" ]; then
        resolved_path="$fallback_path"
        version_str=$("$fallback_path" $version_flag 2>&1 | head -n 1 | tr -d '\r' || echo "installed")
        status="WARN" # Installed but not in active PATH
    fi

    echo "$status|$cmd|$resolved_path|$version_str"
}

# Collect Tool Info
TOOL_RESULTS=()
TOOL_RESULTS+=("$(check_tool timew "$TARGET_HOME/.local/bin/timew" "--version")")
TOOL_RESULTS+=("$(check_tool tb "$TARGET_HOME/.npm-global/bin/tb" "--version")")
TOOL_RESULTS+=("$(check_tool ghq "$TARGET_HOME/.local/bin/ghq" "--version")")
TOOL_RESULTS+=("$(check_tool fzf "$TARGET_HOME/.local/bin/fzf" "--version")")
TOOL_RESULTS+=("$(check_tool vim "" "-v")")
TOOL_RESULTS+=("$(check_tool git "" "--version")")
TOOL_RESULTS+=("$(check_tool gh "" "--version")")
TOOL_RESULTS+=("$(check_tool node "" "-v")")
TOOL_RESULTS+=("$(check_tool npm "" "-v")")

# ----------------------------------------------------------------------------
# 3. Dotfiles Sync & Config Health
# ----------------------------------------------------------------------------
check_dotfile_sync() {
    local target_file="$1"
    local repo_file="$2"
    local label="$3"

    if [ ! -f "$target_file" ]; then
        echo "FAIL|$label|Missing ($target_file not found)"
    elif [ -f "$repo_file" ] && cmp -s "$target_file" "$repo_file"; then
        echo "PASS|$label|In sync with repo ($target_file)"
    elif [ -f "$repo_file" ]; then
        echo "WARN|$label|Modified locally (differs from repo)"
    else
        echo "PASS|$label|Exists ($target_file)"
    fi
}

SYNC_RESULTS=()
SYNC_RESULTS+=("$(check_dotfile_sync "$TARGET_HOME/.vimrc" "$SCRIPT_DIR/.vimrc" ".vimrc")")
SYNC_RESULTS+=("$(check_dotfile_sync "$TARGET_HOME/.bash_aliases" "$SCRIPT_DIR/.bash_aliases" ".bash_aliases")")

# Timewarrior config check
if [ -d "$TARGET_HOME/.config/timewarrior" ] && [ -d "$TARGET_HOME/.local/share/timewarrior" ]; then
    SYNC_RESULTS+=("PASS|Timewarrior Data|Config & Database initialized")
else
    SYNC_RESULTS+=("WARN|Timewarrior Data|Missing config/data directory")
fi

# Vimwiki directory check
if [ -d "$TARGET_HOME/vimwiki" ]; then
    SYNC_RESULTS+=("PASS|Vimwiki Folder|~/vimwiki exists")
else
    SYNC_RESULTS+=("WARN|Vimwiki Folder|~/vimwiki not created yet")
fi

# ----------------------------------------------------------------------------
# 4. PATH Health Checks
# ----------------------------------------------------------------------------
PATH_RESULTS=()
if [[ ":$PATH:" == *":$TARGET_HOME/.local/bin:"* ]]; then
    PATH_RESULTS+=("PASS|~/.local/bin in PATH|Present")
else
    PATH_RESULTS+=("WARN|~/.local/bin in PATH|Missing from current PATH")
fi

if [[ ":$PATH:" == *":$TARGET_HOME/.npm-global/bin:"* ]]; then
    PATH_RESULTS+=("PASS|~/.npm-global/bin in PATH|Present")
else
    # Check if NVM is active (in which case npm-global is not strictly needed)
    if command -v node &>/dev/null && [[ "$(command -v node)" == *".nvm"* ]]; then
        PATH_RESULTS+=("PASS|Node & NPM PATH|Managed by active NVM environment")
    else
        PATH_RESULTS+=("WARN|~/.npm-global/bin in PATH|Missing from current PATH")
    fi
fi

# ----------------------------------------------------------------------------
# 5. Vim Plugins Count & Integrity
# ----------------------------------------------------------------------------
VIM_PACK_DIR="$TARGET_HOME/.vim/pack/plugins/start"
EXPECTED_PLUGINS=("vim-sensible" "vim-surround" "vim-commentary" "vim-fugitive" "vim-repeat" "vimwiki" "vim-wakatime" "fzf" "fzf.vim")
INSTALLED_PLUGINS=()
MISSING_PLUGINS=()

if [ -d "$VIM_PACK_DIR" ]; then
    for p in "${EXPECTED_PLUGINS[@]}"; do
        if [ -d "$VIM_PACK_DIR/$p" ]; then
            INSTALLED_PLUGINS+=("$p")
        else
            MISSING_PLUGINS+=("$p")
        fi
    done
fi

VIM_PLUGINS_TOTAL=${#EXPECTED_PLUGINS[@]}
VIM_PLUGINS_INSTALLED=${#INSTALLED_PLUGINS[@]}

if [ "$VIM_PLUGINS_INSTALLED" -eq "$VIM_PLUGINS_TOTAL" ]; then
    PLUGIN_STATUS="PASS"
    PLUGIN_MSG="All $VIM_PLUGINS_TOTAL plugins installed"
elif [ "$VIM_PLUGINS_INSTALLED" -gt 0 ]; then
    PLUGIN_STATUS="WARN"
    PLUGIN_MSG="$VIM_PLUGINS_INSTALLED/$VIM_PLUGINS_TOTAL plugins installed (Missing: ${MISSING_PLUGINS[*]})"
else
    PLUGIN_STATUS="FAIL"
    PLUGIN_MSG="No plugins found in $VIM_PACK_DIR"
fi

# ----------------------------------------------------------------------------
# Compute Check Statistics
# ----------------------------------------------------------------------------
for row in "${TOOL_RESULTS[@]}" "${SYNC_RESULTS[@]}" "${PATH_RESULTS[@]}"; do
    st=$(echo "$row" | cut -d'|' -f1)
    record_check "$st"
done
record_check "$PLUGIN_STATUS"

# ============================================================================
# JSON Output Mode
# ============================================================================
if [ "$MODE" = "json" ]; then
    cat << EOF
{
  "system": {
    "hostname": "$HOSTNAME_STR",
    "os": "$OS_NAME",
    "kernel": "$KERNEL_STR",
    "arch": "$ARCH_STR",
    "user": "$TARGET_USER",
    "home": "$TARGET_HOME",
    "platform": "$PLATFORM"
  },
  "health": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "failed": $FAILED_CHECKS,
    "status": "$([ $FAILED_CHECKS -eq 0 ] && echo "HEALTHY" || echo "DEGRADED")"
  },
  "tools": {
$(
    first=true
    for row in "${TOOL_RESULTS[@]}"; do
        st=$(echo "$row" | cut -d'|' -f1)
        name=$(echo "$row" | cut -d'|' -f2)
        path=$(echo "$row" | cut -d'|' -f3)
        ver=$(echo "$row" | cut -d'|' -f4 | sed 's/"/\\"/g')
        [ "$first" = true ] && first=false || echo ","
        printf '    "%s": {"status": "%s", "path": "%s", "version": "%s"}' "$name" "$st" "$path" "$ver"
    done
)
  },
  "vim_plugins": {
    "status": "$PLUGIN_STATUS",
    "installed_count": $VIM_PLUGINS_INSTALLED,
    "total_expected": $VIM_PLUGINS_TOTAL,
    "installed": [$(printf '"%s",' "${INSTALLED_PLUGINS[@]}" | sed 's/,$//')],
    "missing": [$(printf '"%s",' "${MISSING_PLUGINS[@]}" | sed 's/,$//')]
  }
}
EOF
    [ $FAILED_CHECKS -eq 0 ] && exit 0 || exit 1
fi

# ============================================================================
# Summary Output Mode
# ============================================================================
if [ "$MODE" = "summary" ]; then
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✔ Environment Healthy${RESET} ($PASSED_CHECKS/$TOTAL_CHECKS checks passed, $WARNING_CHECKS warnings) | Platform: $PLATFORM | User: $TARGET_USER"
        exit 0
    else
        echo -e "${RED}✖ Environment Degraded${RESET} ($FAILED_CHECKS failed, $WARNING_CHECKS warnings, $PASSED_CHECKS passed) | Platform: $PLATFORM"
        exit 1
    fi
fi

# ============================================================================
# Full Colorized Terminal Output Mode
# ============================================================================
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║            Environment Configuration Settings Report            ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Section 1: System Info
echo -e "${BOLD}${BLUE}── System & Host Context ──────────────────────────────────────────${RESET}"
printf "  %-20s %s\n" "Platform:" "${BOLD}$PLATFORM${RESET}"
printf "  %-20s %s\n" "Operating System:" "$OS_NAME ($ARCH_STR)"
printf "  %-20s %s\n" "Kernel:" "$KERNEL_STR"
printf "  %-20s %s (%s)\n" "User & Home:" "$TARGET_USER" "$TARGET_HOME"
printf "  %-20s %s\n" "Shell:" "$SHELL"
echo ""

# Section 2: Core Tools
echo -e "${BOLD}${BLUE}── Developer Tools & Binaries ─────────────────────────────────────${RESET}"
printf "  %-8s %-14s %-24s %s\n" "STATUS" "TOOL" "VERSION" "PATH"
echo -e "  ${GRAY}──────   ────────────── ──────────────────────── ────────────────────${RESET}"

for row in "${TOOL_RESULTS[@]}"; do
    st=$(echo "$row" | cut -d'|' -f1)
    name=$(echo "$row" | cut -d'|' -f2)
    path=$(echo "$row" | cut -d'|' -f3)
    ver=$(echo "$row" | cut -d'|' -f4 | cut -c 1-22)

    case "$st" in
        PASS) icon="$PASS_ICON" ;;
        WARN) icon="$WARN_ICON" ;;
        FAIL) icon="$FAIL_ICON" ;;
    esac

    printf "  %-17b %-14s %-24s %s\n" "$icon" "${BOLD}$name${RESET}" "$ver" "${GRAY}$path${RESET}"
done
echo ""

# Section 3: Dotfiles & Configs
echo -e "${BOLD}${BLUE}── Dotfiles & Configuration Health ────────────────────────────────${RESET}"
for row in "${SYNC_RESULTS[@]}"; do
    st=$(echo "$row" | cut -d'|' -f1)
    label=$(echo "$row" | cut -d'|' -f2)
    msg=$(echo "$row" | cut -d'|' -f3)

    case "$st" in
        PASS) icon="$PASS_ICON" ;;
        WARN) icon="$WARN_ICON" ;;
        FAIL) icon="$FAIL_ICON" ;;
    esac

    printf "  %-17b %-22s %s\n" "$icon" "${BOLD}$label${RESET}" "$msg"
done
echo ""

# Section 4: PATH & Environment
echo -e "${BOLD}${BLUE}── Shell PATH & Exports ───────────────────────────────────────────${RESET}"
for row in "${PATH_RESULTS[@]}"; do
    st=$(echo "$row" | cut -d'|' -f1)
    label=$(echo "$row" | cut -d'|' -f2)
    msg=$(echo "$row" | cut -d'|' -f3)

    case "$st" in
        PASS) icon="$PASS_ICON" ;;
        WARN) icon="$WARN_ICON" ;;
        FAIL) icon="$FAIL_ICON" ;;
    esac

    printf "  %-17b %-26s %s\n" "$icon" "${BOLD}$label${RESET}" "$msg"
done
echo ""

# Section 5: Vim Plugins
echo -e "${BOLD}${BLUE}── Vim Plugins (~/.vim/pack/plugins/start) ────────────────────────${RESET}"
case "$PLUGIN_STATUS" in
    PASS) icon="$PASS_ICON" ;;
    WARN) icon="$WARN_ICON" ;;
    FAIL) icon="$FAIL_ICON" ;;
esac
printf "  %-17b %s (%d/%d active)\n" "$icon" "$PLUGIN_MSG" "$VIM_PLUGINS_INSTALLED" "$VIM_PLUGINS_TOTAL"

if [ "$VIM_PLUGINS_INSTALLED" -gt 0 ]; then
    echo -e "  ${GRAY}Active:${RESET} $(echo "${INSTALLED_PLUGINS[*]}" | tr ' ' ', ')"
fi
echo ""

# Section 6: Overall Verdict
echo -e "${BOLD}${BLUE}── Overall Health Verdict ─────────────────────────────────────────${RESET}"
if [ "$FAILED_CHECKS" -eq 0 ] && [ "$WARNING_CHECKS" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✔ ALL SYSTEMS OPERATIONAL${RESET} ($PASSED_CHECKS/$TOTAL_CHECKS checks passed with 0 warnings)"
elif [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "  ${YELLOW}${BOLD}▲ OPERATIONAL WITH WARNINGS${RESET} ($PASSED_CHECKS passed, $WARNING_CHECKS warnings)"
else
    echo -e "  ${RED}${BOLD}✖ ACTION REQUIRED${RESET} ($FAILED_CHECKS checks failed, $WARNING_CHECKS warnings, $PASSED_CHECKS passed)"
fi
echo ""

[ "$FAILED_CHECKS" -eq 0 ] && exit 0 || exit 1
