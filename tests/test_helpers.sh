#!/usr/bin/env bash
# ============================================================================
# tests/test_helpers.sh - Assertion helpers for the dotfiles test suite
# ============================================================================

# Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

CURRENT_TEST=""

begin_test() { CURRENT_TEST="$1"; TESTS_RUN=$((TESTS_RUN + 1)); }

pass()  { TESTS_PASSED=$((TESTS_PASSED + 1)); echo -e "${GREEN}  ✔ PASS${RESET} ${BOLD}$CURRENT_TEST${RESET}${1:+ - $1}"; }
fail()  { TESTS_FAILED=$((TESTS_FAILED + 1)); echo -e "${RED}  ✖ FAIL${RESET} ${BOLD}$CURRENT_TEST${RESET}${1:+ - $1}"; }
skip()  { TESTS_SKIPPED=$((TESTS_SKIPPED + 1)); echo -e "${YELLOW}  ↷ SKIP${RESET} ${BOLD}$CURRENT_TEST${RESET}${1:+ - $1}"; }

assert_cmd() {
    local cmd="$1" fallback="${2:-}"
    if command -v "$cmd" &>/dev/null; then
        pass "$(command -v "$cmd")"; return 0
    elif [ -n "$fallback" ] && [ -x "$fallback" ]; then
        pass "$fallback (not in PATH but binary exists)"; return 0
    else
        fail "Command '$cmd' not found"; return 1
    fi
}

assert_file() {
    [ -f "$1" ] && pass "$1" || { fail "File not found: $1"; return 1; }
}

assert_dir() {
    [ -d "$1" ] && pass "$1" || { fail "Directory not found: $1"; return 1; }
}

assert_exit_ok() {
    local cmd="$1" msg="${2:-$1}"
    if eval "$cmd" &>/dev/null; then pass "$msg"; return 0
    else fail "$msg (non-zero exit)"; return 1; fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    if echo "$haystack" | grep -qF "$needle"; then
        pass "${msg:-contains '$needle'}"; return 0
    else
        fail "${msg:-Expected '$needle' not found}"; return 1
    fi
}

assert_files_equal() {
    cmp -s "$1" "$2" && pass "In sync: $(basename "$1")" || { fail "Differ: $(basename "$1")"; return 1; }
}

assert_in_path() {
    [[ ":$PATH:" == *":$1:"* ]] && pass "$1 in PATH" || { fail "$1 is not in PATH"; return 1; }
}

assert_bash_syntax() {
    if bash -n "$1" 2>/dev/null; then
        pass "Syntax OK: $(basename "$1")"
    else
        fail "Syntax error in $(basename "$1"): $(bash -n "$1" 2>&1)"; return 1
    fi
}

assert_time_limit() {
    local max="$1" actual="$2" msg="${3:-execution time}"
    [ "$actual" -le "$max" ] && pass "$msg: ${actual}s (limit: ${max}s)" || { fail "$msg: ${actual}s exceeded ${max}s"; return 1; }
}

assert_valid_json() {
    local input="$1" msg="${2:-valid JSON}"
    if command -v python3 &>/dev/null; then
        echo "$input" | python3 -m json.tool &>/dev/null && pass "$msg" || { fail "$msg (invalid JSON)"; return 1; }
    else
        local opens closes
        opens=$(echo "$input" | tr -cd '{' | wc -c)
        closes=$(echo "$input" | tr -cd '}' | wc -c)
        [ "$opens" -gt 0 ] && [ "$opens" -eq "$closes" ] && pass "$msg (basic check)" || { fail "$msg (could not validate)"; return 1; }
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Test Results Summary${RESET}"
    echo -e "${BOLD}═══════════════════════════════════════════════════${RESET}"
    echo -e "  Total:   $TESTS_RUN"
    echo -e "  ${GREEN}Passed:  $TESTS_PASSED${RESET}"
    echo -e "  ${RED}Failed:  $TESTS_FAILED${RESET}"
    echo -e "  ${YELLOW}Skipped: $TESTS_SKIPPED${RESET}"
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}✔ ALL TESTS PASSED${RESET}"; echo ""; return 0
    else
        echo -e "  ${RED}${BOLD}✖ $TESTS_FAILED TEST(S) FAILED${RESET}"; echo ""; return 1
    fi
}
