#!/usr/bin/env bash
set +e  # Don't exit on error - we're testing!

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
TOTAL=0

# Test tracking
CURRENT_TEST=""

# Setup
setup() {
    export TEST_ROOT=$(mktemp -d)
    export GT_DB="$TEST_ROOT/.gt_test_db"
    export ORIGINAL_PWD="$PWD"
    cd "$TEST_ROOT"
    source "$ORIGINAL_PWD/gt.sh"
}

# Teardown
teardown() {
    cd "$ORIGINAL_PWD"
    rm -rf "$TEST_ROOT"
    unset GT_DB
}

# Test helpers
test_start() {
    CURRENT_TEST="$1"
    TOTAL=$((TOTAL + 1))
    echo -ne "${BLUE}Testing:${NC} $CURRENT_TEST ... "
}

test_pass() {
    PASS=$((PASS + 1))
    echo -e "${GREEN}✓ PASS${NC}"
}

test_fail() {
    FAIL=$((FAIL + 1))
    echo -e "${RED}✗ FAIL${NC}"
    [ -n "$1" ] && echo "  ${RED}Reason:${NC} $1"
}

# Run test suite
run_tests() {
    echo ""
    echo "═══════════════════════════════════════"
    echo "         GT TEST SUITE"
    echo "═══════════════════════════════════════"
    echo ""
    
    setup
    source "$ORIGINAL_PWD/tests/test_scenarios.sh"
    teardown
}

# Show summary
show_summary() {
    echo ""
    echo "═══════════════════════════════════════"
    echo "TEST SUMMARY"
    echo "═══════════════════════════════════════"
    echo "Total:  $TOTAL"
    echo -e "Passed: ${GREEN}$PASS${NC}"
    [ $FAIL -gt 0 ] && echo -e "Failed: ${RED}$FAIL${NC}" || echo "Failed: 0"
    echo "═══════════════════════════════════════"
    
    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC} 🎉"
        echo ""
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        echo ""
        exit 1
    fi
}

# Main
run_tests
show_summary
