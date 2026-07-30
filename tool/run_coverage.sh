#!/usr/bin/env bash
# Generate lcov coverage for unit + widget + flow tests.
set -euo pipefail
flutter test --coverage
echo "Coverage written to coverage/lcov.info"
if command -v genhtml >/dev/null 2>&1; then
  genhtml coverage/lcov.info -o coverage/html
  echo "HTML report: coverage/html/index.html"
fi
