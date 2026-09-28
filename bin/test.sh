#!/usr/bin/env bash
# Every suite in the repository, one line of verdict each.
#   bin/test.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
fails=0
for suite in guards/*.test.sh bin/*.test.sh; do
  [ -f "$suite" ] || continue
  echo "== $suite"
  bash "$suite" || fails=$((fails + 1))
done
[ "$fails" -eq 0 ] && echo "all suites passed" || { echo "$fails suite(s) failed"; exit 1; }
