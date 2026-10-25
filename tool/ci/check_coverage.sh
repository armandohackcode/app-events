#!/usr/bin/env bash
# Fails when line coverage in an lcov file is below a minimum percentage.
# Run tool/ci/coverage_helper.sh first so untested files count as 0%.
#
#   tool/ci/check_coverage.sh coverage/lcov.info 14
set -euo pipefail

lcov=${1:?usage: check_coverage.sh <lcov.info> <min-percent>}
min=${2:?usage: check_coverage.sh <lcov.info> <min-percent>}

# Config generated in CI is not app code.
awk -F: -v min="$min" '
  /^SF:/ { skip = ($2 ~ /(firebase_options|env)\.dart$/); next }
  skip { next }
  /^LF:/ { found += $2 }
  /^LH:/ { hit += $2 }
  END {
    pct = found ? hit * 100 / found : 0
    printf "Line coverage: %.1f%% (%d/%d), minimum %s%%\n", pct, hit, found, min
    if (pct < min) { print "Coverage is below the minimum."; exit 1 }
  }
' "$lcov"
