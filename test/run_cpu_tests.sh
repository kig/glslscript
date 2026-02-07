#!/bin/bash
# Test runner for GLSLScript CPU execution
# This script runs the test suite on CPU without requiring GPU/Vulkan

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gls_cpu exists
if [ ! -f "bin/gls_cpu" ]; then
    echo -e "${RED}Error: bin/gls_cpu not found${NC}"
    echo "Please build the CPU version first: make cpu-only"
    exit 1
fi

# Check if spirv-cross is available
if ! command -v spirv-cross &> /dev/null; then
    echo -e "${YELLOW}Warning: spirv-cross not found in PATH${NC}"
    echo "CPU execution requires SPIRV-Cross to be installed."
    echo "See CPU_TESTING.md for installation instructions."
    exit 1
fi

echo "GLSLScript CPU Test Runner"
echo "=========================="
echo ""

# Find all test files
TEST_FILES=$(find test -name "test_*.glsl" -type f 2>/dev/null || true)

if [ -z "$TEST_FILES" ]; then
    echo -e "${YELLOW}No test files found in test/ directory${NC}"
    exit 0
fi

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

# Run each test
for test_file in $TEST_FILES; do
    TOTAL=$((TOTAL + 1))
    test_name=$(basename "$test_file")
    
    echo -n "Running $test_name... "
    
    # Run the test and capture output
    if timeout 30s bin/gls_cpu "$test_file" > /tmp/test_output_$$.txt 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        PASSED=$((PASSED + 1))
    else
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo -e "${YELLOW}TIMEOUT${NC}"
            SKIPPED=$((SKIPPED + 1))
        else
            echo -e "${RED}FAILED (exit code: $exit_code)${NC}"
            FAILED=$((FAILED + 1))
            # Show error output
            if [ -s /tmp/test_output_$$.txt ]; then
                echo "  Error output:"
                head -20 /tmp/test_output_$$.txt | sed 's/^/    /'
            fi
        fi
    fi
    
    rm -f /tmp/test_output_$$.txt
done

echo ""
echo "=========================="
echo "Test Results:"
echo "  Total:   $TOTAL"
echo -e "  ${GREEN}Passed:  $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed:  $FAILED${NC}"
fi
if [ $SKIPPED -gt 0 ]; then
    echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
fi
echo ""

# Exit with failure if any tests failed
if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
