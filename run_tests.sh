#!/bin/bash

# Find all test files in the Tests directory and run them
pass=true
for test_file in Tests/*.spec.lua; do
    echo "Running test: $test_file"
    lune run "$test_file"
    if [ $? -ne 0 ]; then
        echo "❌ TEST FAILED: $test_file"
        pass=false
    else
        echo "✅ TEST PASSED: $test_file"
    fi
    echo ""
done

if [ "$pass" = true ]; then
    echo "All tests passed successfully!"
else
    echo "Some tests failed."
fi
