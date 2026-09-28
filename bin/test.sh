#!/usr/bin/env bash
# Every suite in the repository, one line of verdict each.
#   bin/test.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
fails=0
# Found rather than listed: an adapter that brings its own suites is then tested by existing here,
# which is the same reason bin/adapt discovers adapters by directory.
while IFS= read -r suite; do
  echo "== $suite"
  bash "$suite" || fails=$((fails + 1))
done < <(find . -name '*.test.sh' -not -path './.git/*' | sort)
if [ "$fails" -eq 0 ]; then echo "all suites passed"; else echo "$fails suite(s) failed"; exit 1; fi
