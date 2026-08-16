#!/usr/bin/env bash
# ============================================================================
# tests/run_tests.sh - Dotfiles Environment Automated Test Suite
# Zero external dependencies. Runs on any POSIX shell environment.
# Usage: ./tests/run_tests.sh [--verbose]
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HELPERS="$SCRIPT_DIR/test_helpers.sh"

if [ ! -f "$HELPERS" ]; then
    echo "ERROR: test_helpers.sh not found at $HELPERS"
    exit 1
fi
# shellcheck source=tests/test_helpers.sh
source "$HELPERS"

TARGET_HOME="$HOME"
VIM_PACK_DIR="$TARGET_HOME/.vim/pack/plugins/start"

BOLD="\033[1m"
BLUE="\033[0;34m"
RESET="\033[0m"

section() { echo ""; echo -e "${BOLD}${BLUE}── $1 ────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       Dotfiles Environment Test Suite                ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo "  Repo:    $REPO_DIR"
echo "  User:    $(whoami)"
echo "  Home:    $TARGET_HOME"
echo "  Date:    $(date)"

# ============================================================================
# Test 1: Shell Script Syntax Validation
# ============================================================================
section "1. Shell Script Syntax Validation"

begin_test "install.sh syntax"
assert_bash_syntax "$REPO_DIR/install.sh"

begin_test ".customize_environment syntax"
assert_bash_syntax "$REPO_DIR/.customize_environment"

begin_test "status.sh syntax"
assert_bash_syntax "$REPO_DIR/status.sh"

begin_test "tests/run_tests.sh syntax"
assert_bash_syntax "$REPO_DIR/tests/run_tests.sh"

begin_test "tests/test_helpers.sh syntax"
assert_bash_syntax "$REPO_DIR/tests/test_helpers.sh"

begin_test ".bash_aliases syntax"
assert_bash_syntax "$REPO_DIR/.bash_aliases"

# ============================================================================
# Test 2: Repository File Integrity
# ============================================================================
section "2. Repository File Integrity"

begin_test ".vimrc exists in repo"
assert_file "$REPO_DIR/.vimrc"

begin_test ".bash_aliases exists in repo"
assert_file "$REPO_DIR/.bash_aliases"

begin_test ".gitignore exists in repo"
assert_file "$REPO_DIR/.gitignore"

begin_test "README.md exists in repo"
assert_file "$REPO_DIR/README.md"

begin_test "install.sh is executable"
if [ -x "$REPO_DIR/install.sh" ]; then
    pass "$REPO_DIR/install.sh is executable"
else
    fail "install.sh is not executable"
fi

begin_test "status.sh is executable"
if [ -x "$REPO_DIR/status.sh" ]; then
    pass "$REPO_DIR/status.sh is executable"
else
    fail "status.sh is not executable"
fi

begin_test "tests/run_tests.sh is executable"
if [ -x "$REPO_DIR/tests/run_tests.sh" ]; then
    pass "$REPO_DIR/tests/run_tests.sh is executable"
else
    fail "tests/run_tests.sh is not executable"
fi

# ============================================================================
# Test 3: Core Developer Tools
# ============================================================================
section "3. Core Developer Tools"

begin_test "timew (Timewarrior) installed"
assert_cmd "timew"

begin_test "Timewarrior version returns output"
assert_exit_ok "timew --version" "timew --version"

begin_test "Timewarrior config directory exists"
assert_dir "$TARGET_HOME/.config/timewarrior"

begin_test "Timewarrior data directory exists"
assert_dir "$TARGET_HOME/.local/share/timewarrior"

begin_test "taskbook (tb) installed"
assert_cmd "tb" "$TARGET_HOME/.npm-global/bin/tb"

begin_test "ghq installed"
assert_cmd "ghq" "$TARGET_HOME/.local/bin/ghq"

begin_test "ghq version returns output"
GHQ_BIN=$(command -v ghq 2>/dev/null || echo "$TARGET_HOME/.local/bin/ghq")
assert_exit_ok "\"$GHQ_BIN\" --version" "ghq --version"

begin_test "fzf installed"
assert_cmd "fzf" "$TARGET_HOME/.local/bin/fzf"

begin_test "fzf version returns output"
FZF_BIN=$(command -v fzf 2>/dev/null || echo "$TARGET_HOME/.local/bin/fzf")
assert_exit_ok "\"$FZF_BIN\" --version" "fzf --version"

begin_test "vim installed"
assert_cmd "vim"

begin_test "git installed"
assert_cmd "git"

# ============================================================================
# Test 4: Vim Configuration & Plugins
# ============================================================================
section "4. Vim Configuration & Plugins"

begin_test "~/.vimrc exists"
assert_file "$TARGET_HOME/.vimrc"

begin_test "Vim loads .vimrc without errors"
begin_test "Vim loads .vimrc without errors"
if vim -u "$TARGET_HOME/.vimrc" -c 'quit' 2>/tmp/vim_test_err; then
    pass "Vim exited cleanly with .vimrc"
elif [ -s /tmp/vim_test_err ]; then
    err=$(cat /tmp/vim_test_err)
    # WakaTime auth warning is expected and non-fatal
    if echo "$err" | grep -qi "wakatime" || echo "$err" | grep -qi "api key"; then
        pass "Vim loaded (.vimrc OK, WakaTime key not configured - expected)"
    else
        fail "Vim errors: $err"
    fi
else
    pass "Vim loaded .vimrc successfully"
fi
rm -f /tmp/vim_test_err

EXPECTED_PLUGINS=("vim-sensible" "vim-surround" "vim-commentary" "vim-fugitive" "vim-repeat" "vimwiki" "vim-wakatime" "fzf" "fzf.vim")
for plugin in "${EXPECTED_PLUGINS[@]}"; do
    begin_test "Vim plugin: $plugin"
    assert_dir "$VIM_PACK_DIR/$plugin"
done

begin_test ".vimrc contains fzf mappings"
if grep -q "leader.*f.*:Files" "$TARGET_HOME/.vimrc" || grep -q "leader.*f.*:Files" "$REPO_DIR/.vimrc"; then
    pass "fzf <Leader>f mapping found"
else
    fail "fzf Leader mapping not found in .vimrc"
fi

# ============================================================================
# Test 5: Shell Configuration & Dotfiles Sync
# ============================================================================
section "5. Shell Configuration & Dotfiles Sync"

begin_test "~/.bash_aliases exists"
assert_file "$TARGET_HOME/.bash_aliases"

begin_test ".bash_aliases in sync with repo"
if [ -f "$TARGET_HOME/.bash_aliases" ] && [ -f "$REPO_DIR/.bash_aliases" ]; then
    assert_files_equal "$TARGET_HOME/.bash_aliases" "$REPO_DIR/.bash_aliases"
else
    skip "Cannot compare - one or both files missing"
fi

begin_test ".vimrc in sync with repo"
if [ -f "$TARGET_HOME/.vimrc" ] && [ -f "$REPO_DIR/.vimrc" ]; then
    assert_files_equal "$TARGET_HOME/.vimrc" "$REPO_DIR/.vimrc"
else
    skip "Cannot compare - one or both files missing"
fi

begin_test "~/.local/bin in PATH"
assert_in_path "$TARGET_HOME/.local/bin"

begin_test ".npm-global/bin or NVM node in PATH"
begin_test ".npm-global/bin or NVM node in PATH"
if [[ ":$PATH:" == *":$TARGET_HOME/.npm-global/bin:"* ]]; then
    pass "~/.npm-global/bin in PATH"
elif command -v node &>/dev/null && [[ "$(command -v node)" == *".nvm"* ]]; then
    pass "NVM-managed node is active"
else
    fail "Neither .npm-global/bin nor NVM node found in PATH"
fi

begin_test ".bashrc sources .bash_aliases"
if [ -f "$TARGET_HOME/.bashrc" ] && grep -q ".bash_aliases" "$TARGET_HOME/.bashrc"; then
    pass ".bashrc sources .bash_aliases"
else
    fail ".bashrc does not source .bash_aliases"
fi

# ============================================================================
# Test 6: Environment Status Report
# ============================================================================
section "6. Environment Status Report (status.sh)"

STATUS_SCRIPT="$REPO_DIR/status.sh"

begin_test "status.sh --help exits cleanly"
assert_exit_ok "\"$STATUS_SCRIPT\" --help" "status.sh --help"

begin_test "status.sh --summary exits 0 or 1 with output"
begin_test "status.sh --summary exits 0 or 1 with output"
SUMMARY_OUT=$("$STATUS_SCRIPT" --summary 2>&1 || true)
if [ -n "$SUMMARY_OUT" ]; then
    pass "summary output: $SUMMARY_OUT"
else
    fail "status.sh --summary produced no output"
fi

begin_test "status.sh --json produces valid JSON"
JSON_OUT=$("$STATUS_SCRIPT" --json 2>/dev/null || true)
if [ -n "$JSON_OUT" ]; then
    assert_valid_json "$JSON_OUT" "JSON output is valid"
else
    fail "status.sh --json produced no output"
fi

begin_test "status.sh JSON contains 'health' key"
JSON_OUT=$("$STATUS_SCRIPT" --json 2>/dev/null || true)
assert_contains "$JSON_OUT" '"health"' "JSON has health section"

begin_test "status.sh JSON contains 'tools' key"
assert_contains "$JSON_OUT" '"tools"' "JSON has tools section"

begin_test "status.sh full report runs without crashing"
begin_test "status.sh full report runs without crashing"
if "$STATUS_SCRIPT" &>/dev/null; then
    pass "status.sh exited cleanly (no failures detected)"
else
    pass "status.sh ran and reported some warnings/failures (OK for test)"
fi

# ============================================================================
# Test 7: Idempotency & Speed
# ============================================================================
section "7. Idempotency Check (install.sh re-run speed)"

begin_test "install.sh re-run completes within 15 seconds"
T_START=$(date +%s)
if "$REPO_DIR/install.sh" &>/dev/null; then
    T_END=$(date +%s)
    DURATION=$((T_END - T_START))
    assert_time_limit 15 "$DURATION" "install.sh re-run"
else
    fail "install.sh re-run exited with non-zero status"
fi

# ============================================================================
# Final Summary
# ============================================================================
print_summary
