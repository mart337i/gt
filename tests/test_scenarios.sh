#!/usr/bin/env bash

# TEST 1: Version command
test_start "gt -v shows version 3.0.0"
output=$(gt -v)
if [[ "$output" == "gt version 3.0.0" ]]; then
    test_pass
else
    test_fail "Expected 'gt version 3.0.0', got '$output'"
fi

# TEST 2: Help command shows usage
test_start "gt -h shows help"
output=$(gt -h)
if echo "$output" | grep -q "usage: gt"; then
    test_pass
else
    test_fail "Help doesn't show usage"
fi

# TEST 3: Register alias
test_start "gt -r registers alias"
mkdir -p "$TEST_ROOT/myproject"
gt -r proj "$TEST_ROOT/myproject" > /dev/null 2>&1
if gt -x proj > /dev/null 2>&1; then
    test_pass
else
    test_fail "Alias not registered"
fi

# TEST 4: List shows registered alias
test_start "gt -l shows registered aliases"
output=$(gt -l)
if echo "$output" | grep -q "proj"; then
    test_pass
else
    test_fail "List doesn't show registered alias"
fi

# TEST 5: Navigate to alias
test_start "gt proj navigates to directory"
(cd /tmp && gt proj && [ "$PWD" = "$TEST_ROOT/myproject" ]) 2>/dev/null
if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Navigation failed"
fi

# TEST 6: Navigate with slash notation
test_start "gt proj/subdir works (slash notation)"
mkdir -p "$TEST_ROOT/myproject/src/components"
(cd /tmp && gt proj/src/components && [ "$PWD" = "$TEST_ROOT/myproject/src/components" ]) 2>/dev/null
if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Slash notation navigation failed"
fi

# TEST 7: Navigate with space notation
test_start "gt proj subdir works (space notation)"
(cd /tmp && gt proj src/components && [ "$PWD" = "$TEST_ROOT/myproject/src/components" ]) 2>/dev/null
if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Space notation navigation failed"
fi

# TEST 8: Tab completion function exists
test_start "Tab completion functions are defined"
if declare -f _complete_gt_bash > /dev/null && declare -f _complete_gt_zsh > /dev/null; then
    test_pass
else
    test_fail "Completion functions not defined"
fi

# TEST 9: Expand alias
test_start "gt -x expands alias to path"
# Register a new alias for this test
mkdir -p "$TEST_ROOT/expand_test"
gt -r expand_me "$TEST_ROOT/expand_test" > /dev/null 2>&1
output=$(gt -x expand_me)
if [ "$output" = "$TEST_ROOT/expand_test" ]; then
    test_pass
else
    test_fail "Expected '$TEST_ROOT/expand_test', got '$output'"
fi

# TEST 10: Unregister alias
test_start "gt -u removes alias"
gt -u expand_me > /dev/null 2>&1
output=$(gt -x expand_me 2>&1)
if echo "$output" | grep -q "does not exist"; then
    test_pass
else
    test_fail "Alias still exists after unregister. Output: $output"
fi

# TEST 11: Invalid alias name rejected
test_start "Invalid alias names are rejected"
gt -r "bad@alias" /tmp > /dev/null 2>&1
if [ $? -ne 0 ]; then
    test_pass
else
    test_fail "Should reject invalid alias name"
fi

# TEST 12: Push/pop directory stack
test_start "gt -p and gt -o work (directory stack)"
mkdir -p "$TEST_ROOT/dir1" "$TEST_ROOT/dir2"
gt -r d1 "$TEST_ROOT/dir1" > /dev/null 2>&1
gt -r d2 "$TEST_ROOT/dir2" > /dev/null 2>&1
(
    cd "$TEST_ROOT/dir1"
    start_dir="$PWD"
    gt -p d2 2>/dev/null
    after_push="$PWD"
    gt -o 2>/dev/null
    after_pop="$PWD"
    [ "$after_push" = "$TEST_ROOT/dir2" ] && [ "$after_pop" = "$start_dir" ]
) 2>/dev/null
if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Push/pop directory stack failed"
fi

# TEST 13: Cleanup removes invalid aliases
test_start "gt -c removes dead aliases"
mkdir -p "$TEST_ROOT/temp_cleanup"
gt -r tempclean "$TEST_ROOT/temp_cleanup" > /dev/null 2>&1
rm -rf "$TEST_ROOT/temp_cleanup"
gt -c > /dev/null 2>&1
output=$(gt -x tempclean 2>&1)
if echo "$output" | grep -q "does not exist"; then
    test_pass
else
    test_fail "Cleanup didn't remove invalid alias. Output: $output"
fi

# TEST 14: Deep path navigation
test_start "Deep path navigation works"
mkdir -p "$TEST_ROOT/deep/path/to/test/directory"
gt -r deep "$TEST_ROOT/deep" > /dev/null 2>&1
(cd /tmp && gt deep/path/to/test/directory && [ "$PWD" = "$TEST_ROOT/deep/path/to/test/directory" ]) 2>/dev/null
if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Deep path navigation failed"
fi

# TEST 15: Real-world developer workflow
test_start "Real-world workflow scenario"
# Setup project structure
mkdir -p "$TEST_ROOT/work"/{backend/api,frontend/src,docs}
gt -r work "$TEST_ROOT/work" > /dev/null 2>&1

# Navigate around like a developer would
(
    cd /tmp
    gt work/backend/api && [ "$PWD" = "$TEST_ROOT/work/backend/api" ] || exit 1
    gt work/frontend/src && [ "$PWD" = "$TEST_ROOT/work/frontend/src" ] || exit 1
    gt work/docs && [ "$PWD" = "$TEST_ROOT/work/docs" ] || exit 1
) 2>/dev/null

if [ $? -eq 0 ]; then
    test_pass
else
    test_fail "Real-world workflow failed"
fi
