#!/bin/bash

echo "Testing cdo with various edge cases..."
echo "========================================="

run_test() {
    local description="$1"
    shift
    echo ""
    echo "Test: $description"
    echo "Command: $*"
    echo "---"
    ./cdo "$@"
    local exit_code=$?
    echo "Exit code: $exit_code"
    echo "---"
    return $exit_code
}

echo "Prerequisites: Container must be running (make up)"
echo ""

run_test "Simple command" echo "Hello World"

run_test "Command with single quotes" echo "It's a test"

run_test "Command with double quotes" echo '"Quoted string"'

run_test "Command with spaces in argument" grep "pattern with spaces" /etc/hosts

run_test "Command with dollar signs" bash -c 'echo $HOME'

run_test "Command with glob patterns" bash -c 'ls *.txt 2>/dev/null || echo "No txt files"'

run_test "Command with pipes" bash -c 'echo "test" | wc -l'

run_test "Command with redirects" bash -c 'echo "test" > /tmp/test.txt && cat /tmp/test.txt'

run_test "Command with semicolons" bash -c 'echo "first"; echo "second"'

run_test "Command with ampersands" bash -c 'echo "background" & wait'

run_test "Command with parentheses" bash -c '(echo "subshell")'

run_test "Command with brackets" bash -c '[[ -f /etc/hosts ]] && echo "File exists"'

run_test "Command with backslashes" echo "Line 1\\nLine 2"

run_test "Python with quotes" python -c "print('Hello from Python')"

run_test "Complex find command" find /etc -maxdepth 1 -name "*.conf" -type f 2>/dev/null | head -5

run_test "Command with newlines" bash -c 'echo -e "Line 1\nLine 2\nLine 3"'

run_test "Command with tabs" bash -c 'echo -e "Col1\tCol2\tCol3"'

run_test "Command with special chars !@#" echo '!@#$%^&*()'

run_test "Command with Unicode" echo "Hello 世界 🌍"

run_test "Multi-line bash script" bash -c '
for i in 1 2 3; do
    echo "Number: $i"
done
'

echo ""
echo "========================================="
echo "All tests completed!"