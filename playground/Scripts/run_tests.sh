#!/bin/bash
# Run unit tests and fix errors automatically
# Usage: ./run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🧪 Running unit tests..."
echo ""

# Find the Xcode project
PROJECT_FILE=$(find . -name "*.xcodeproj" -o -name "*.xcworkspace" | head -1)

if [ -z "$PROJECT_FILE" ]; then
    echo "❌ Error: No Xcode project found"
    exit 1
fi

PROJECT_DIR=$(dirname "$PROJECT_FILE")
PROJECT_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
PROJECT_NAME=$(basename "$PROJECT_NAME" .xcworkspace)

# Try to find scheme
SCHEME="$PROJECT_NAME"
if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    SCHEMES=$(xcodebuild -workspace "$PROJECT_FILE" -list 2>/dev/null | grep -A 20 "Schemes:" | grep -v "Schemes:" | xargs)
    if [ -n "$SCHEMES" ]; then
        SCHEME=$(echo "$SCHEMES" | awk '{print $1}')
    fi
else
    SCHEMES=$(xcodebuild -project "$PROJECT_FILE" -list 2>/dev/null | grep -A 20 "Schemes:" | grep -v "Schemes:" | xargs)
    if [ -n "$SCHEMES" ]; then
        SCHEME=$(echo "$SCHEMES" | awk '{print $1}')
    fi
fi

echo "Project: $PROJECT_FILE"
echo "Scheme: $SCHEME"
echo ""

MAX_ATTEMPTS=5
ATTEMPT=1
FIXED_ANY=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test attempt $ATTEMPT of $MAX_ATTEMPTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Run tests and capture output
    TEST_OUTPUT_FILE=$(mktemp)
    if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
        xcodebuild test \
            -workspace "$PROJECT_FILE" \
            -scheme "$SCHEME" \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:CalCalculatorTests 2>&1 | tee "$TEST_OUTPUT_FILE" || true
    else
        xcodebuild test \
            -project "$PROJECT_FILE" \
            -scheme "$SCHEME" \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:CalCalculatorTests 2>&1 | tee "$TEST_OUTPUT_FILE" || true
    fi
    
    TEST_OUTPUT=$(cat "$TEST_OUTPUT_FILE")
    rm "$TEST_OUTPUT_FILE"
    
    # Check if tests passed
    if echo "$TEST_OUTPUT" | grep -qE "Test Suite.*passed|Executed.*tests.*with.*failures.*\(0\)|Testing.*succeeded"; then
        echo ""
        echo "✅ All tests passed!"
        exit 0
    fi
    
    # Extract compilation errors
    COMPILE_ERRORS=$(echo "$TEST_OUTPUT" | grep -E "error:.*\.swift:[0-9]+:[0-9]+" || true)
    TEST_FAILURES=$(echo "$TEST_OUTPUT" | grep -E "failed|FAILED|Test Case.*failed" || true)
    
    if [ -z "$COMPILE_ERRORS" ] && [ -z "$TEST_FAILURES" ]; then
        # Check for other success indicators
        if echo "$TEST_OUTPUT" | grep -qE "Testing.*succeeded|Test Suite.*completed"; then
            echo ""
            echo "✅ Tests completed successfully"
            exit 0
        fi
    fi
    
    echo "❌ Issues found:"
    if [ -n "$COMPILE_ERRORS" ]; then
        echo "  Compilation errors:"
        echo "$COMPILE_ERRORS" | head -5 | sed 's/^/    /'
    fi
    if [ -n "$TEST_FAILURES" ]; then
        echo "  Test failures:"
        echo "$TEST_FAILURES" | head -5 | sed 's/^/    /'
    fi
    echo ""
    
    # Try to fix errors
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "🔧 Attempting to fix errors..."
        FIXED_THIS_ROUND=false
        
        # Fix missing imports in test files
        TEST_FILES=$(find . -path "*/CalCalculatorTests/*.swift" -type f 2>/dev/null || true)
        
        if [ -n "$TEST_FILES" ]; then
            for test_file in $TEST_FILES; do
                # Fix missing XCTest import
                if grep -q "@Test\|XCTestCase\|XCTAssert" "$test_file" 2>/dev/null && ! grep -q "^import XCTest" "$test_file" 2>/dev/null; then
                    echo "  Adding XCTest import to $test_file"
                    sed -i '' '1i\
import XCTest
' "$test_file"
                    FIXED_THIS_ROUND=true
                fi
                
                # Fix missing Testing import for Swift Testing
                if grep -q "@Test\|#expect" "$test_file" 2>/dev/null && ! grep -q "^import Testing" "$test_file" 2>/dev/null; then
                    echo "  Adding Testing import to $test_file"
                    sed -i '' '1i\
import Testing
' "$test_file"
                    FIXED_THIS_ROUND=true
                fi
                
                # Fix missing @testable import
                if grep -q "playground\." "$test_file" 2>/dev/null && ! grep -q "@testable import playground" "$test_file" 2>/dev/null; then
                    echo "  Adding @testable import to $test_file"
                    # Find first import line and add after it
                    if grep -q "^import " "$test_file" 2>/dev/null; then
                        sed -i '' '/^import /a\
@testable import playground
' "$test_file"
                        FIXED_THIS_ROUND=true
                    fi
                fi
            done
        fi
        
        if [ "$FIXED_THIS_ROUND" = true ]; then
            FIXED_ANY=true
            echo "  ✅ Applied fixes, retrying..."
        else
            echo "  ⚠️  Could not auto-fix errors"
        fi
        
        echo ""
        sleep 2
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

echo ""
if [ "$FIXED_ANY" = true ]; then
    echo "⚠️  Some fixes were applied but tests still failing"
    echo "Please review the errors above"
else
    echo "❌ Tests failed after $MAX_ATTEMPTS attempts"
    echo "Please review the errors above and fix manually"
fi
exit 1

