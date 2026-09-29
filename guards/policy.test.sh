#!/usr/bin/env bash
# policy.sh's two layers: the tracked `.protocol/<name>` and the untracked `.protocol/<name>.local`.
#   bash guards/policy.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../bin/check.sh"
# shellcheck source-path=SCRIPTDIR source=policy.sh
source "$DIR/policy.sh"

# layers <tracked> <overlay>: a fresh repository carrying whichever of the two is not `-`.
layers() {
  rm -rf "${t:?}/repo" && git init -q "$t/repo" && mkdir -p "$t/repo/.protocol"
  [ "$1" = - ] || printf '%s\n' "$1" >"$t/repo/.protocol/thing"
  [ "$2" = - ] || printf '%s\n' "$2" >"$t/repo/.protocol/thing.local"
}
# The resolved lines, flattened with commas so a check can state the whole answer on one line.
resolve() { (cd "$t/repo" && policy thing) | paste -sd, -; }
# The status alone, which is what a guard branches on.
found() { (cd "$t/repo" && policy thing >/dev/null); }

layers - -
check "a repository carrying neither layer has no such policy" "! found"

layers 'alpha' -
check "a tracked policy alone reads as it always has" "found && [ \"\$(resolve)\" = alpha ]"

layers 'alpha' 'beta'
check "an overlay is appended to the tracked file, in that order" "[ \"\$(resolve)\" = alpha,beta ]"

layers - 'beta'
check "an overlay alone is a policy, with no tracked file" "found && [ \"\$(resolve)\" = beta ]"

layers 'alpha' '# a name nobody else needs

beta'
check "the overlay is comment-stripped like the tracked file" "[ \"\$(resolve)\" = alpha,beta ]"

layers 'alpha ' 'beta	'
check "trailing whitespace is trimmed from either layer" "[ \"\$(resolve)\" = alpha,beta ]"

finish
