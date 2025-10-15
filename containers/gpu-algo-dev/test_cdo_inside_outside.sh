#!/bin/bash

set -euo pipefail

echo "========================================================================"
echo "Testing cdo script - both OUTSIDE and INSIDE container"
echo "========================================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure container is running
echo "Ensuring container is running..."
./cdo -u
echo ""

# Test function that runs the same command outside and inside
run_comparison_test() {
    local test_num="$1"
    local description="$2"
    shift 2

    echo "========================================================================"
    echo "Test $test_num: $description"
    echo "Command: $*"
    echo "------------------------------------------------------------------------"

    # Run from OUTSIDE
    echo "[OUTSIDE] Running from host..."
    OUTSIDE_OUTPUT=$(./cdo "$@" 2>&1)
    OUTSIDE_EXIT=$?

    # Run from INSIDE
    echo "[INSIDE]  Running from container..."
    INSIDE_OUTPUT=$(./cdo bash -c "cd '$SCRIPT_DIR' && ./cdo $(printf '%q ' "$@")" 2>&1)
    INSIDE_EXIT=$?

    echo ""
    echo "Results:"
    echo "--------"

    # Compare outputs
    if [[ "$OUTSIDE_OUTPUT" == "$INSIDE_OUTPUT" ]]; then
        echo "✓ Output matches"
        echo "$OUTSIDE_OUTPUT"
    else
        echo "✗ Output differs!"
        echo ""
        echo "OUTSIDE output:"
        echo "$OUTSIDE_OUTPUT"
        echo ""
        echo "INSIDE output:"
        echo "$INSIDE_OUTPUT"
    fi

    # Compare exit codes
    if [[ $OUTSIDE_EXIT -eq $INSIDE_EXIT ]]; then
        echo "✓ Exit codes match: $OUTSIDE_EXIT"
    else
        echo "✗ Exit codes differ! Outside: $OUTSIDE_EXIT, Inside: $INSIDE_EXIT"
    fi

    echo ""
}

# Run all the tests from cdo_examples.sh
run_comparison_test 1 "Simple command" echo "Hello World"

run_comparison_test 2 "Command with single quotes" echo "It's a test"

run_comparison_test 3 "Command with double quotes" echo '"Quoted string"'

run_comparison_test 4 "Command with spaces in argument" grep "pattern with spaces" /etc/hosts

run_comparison_test 5 "Command with dollar signs" bash -c 'echo $HOME'

run_comparison_test 6 "Command with glob patterns" bash -c 'ls *.txt 2>/dev/null || echo "No txt files"'

run_comparison_test 7 "Command with pipes" bash -c 'echo "test" | wc -l'

run_comparison_test 8 "Command with redirects" bash -c 'echo "test" > /tmp/test.txt && cat /tmp/test.txt'

run_comparison_test 9 "Command with semicolons" bash -c 'echo "first"; echo "second"'

run_comparison_test 10 "Command with ampersands" bash -c 'echo "background" & wait'

run_comparison_test 11 "Command with parentheses" bash -c '(echo "subshell")'

run_comparison_test 12 "Command with brackets" bash -c '[[ -f /etc/hosts ]] && echo "File exists"'

run_comparison_test 13 "Command with backslashes" echo "Line 1\\nLine 2"

run_comparison_test 14 "Python with quotes" python3 -c "print('Hello from Python')"

run_comparison_test 15 "Complex find command" find /etc -maxdepth 1 -name "*.conf" -type f 2>/dev/null | head -5

run_comparison_test 16 "Command with newlines" bash -c 'echo -e "Line 1\nLine 2\nLine 3"'

run_comparison_test 17 "Command with tabs" bash -c 'echo -e "Col1\tCol2\tCol3"'

run_comparison_test 18 "Command with special chars" echo '!@#$%^&*()'

run_comparison_test 19 "Command with Unicode" echo "Hello 世界 🌍"

run_comparison_test 20 "Multi-line bash script" bash -c '
for i in 1 2 3; do
    echo "Number: $i"
done
'

run_comparison_test 21 "Check working directory" pwd

run_comparison_test 22 "Check user ID" id -u

run_comparison_test 23 "Environment variable test" bash -c 'TEST_VAR="hello" && echo $TEST_VAR'

echo "========================================================================"
echo "All comparison tests completed!"
echo "========================================================================"
