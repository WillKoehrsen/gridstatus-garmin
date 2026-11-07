#!/usr/bin/env bash
# Runs the unit tests in the simulator, which must already be open.
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_root"

device="${GRIDSTATUS_DEVICE:-fr255m}"
scripts/build.sh bin/GridStatusTests.prg --unit-test

# monkeydo exited 1 on a run where every test passed, so the output decides the result.
test_output="$(monkeydo bin/GridStatusTests.prg "$device" -t 2>&1 || true)"
echo "$test_output"
if echo "$test_output" | grep -q 'FAIL\|ERROR'; then
    exit 1
fi
echo "$test_output" | grep -q '^PASSED'
