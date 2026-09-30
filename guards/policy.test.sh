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

# --- reading another repository's policy ----------------------------------------------------------
# The second argument, which only the identity guard passes, and only so that a repository worked
# on under a tenant is held to the tenant's list rather than to none at all.
layers 'alpha' 'beta'
mkdir -p "$t/elsewhere/.protocol"
printf 'gamma\n' >"$t/elsewhere/.protocol/thing"
check "a named root is read instead of the repository the guard is running in" \
  "[ \"\$( (cd \"$t/repo\" && policy thing \"$t/elsewhere\") | paste -sd, -)\" = gamma ]"
# Named rather than searched for: a guard that passes a root has already decided which one, and
# `git rev-parse` from inside it would answer about whatever repository happens to contain it.
check "a named root that carries no such policy is still no such policy" \
  "! (cd \"$t/repo\" && policy nothing \"$t/elsewhere\" >/dev/null)"

# --- the tenant a repository is worked on under ---------------------------------------------------
# Local git configuration, where core.hooksPath is: a repository worked on under a tenant is
# deliberately not a tenant, so it has nowhere in its tree to record this and should not have one.
layers - -
check "a repository nothing wired to a tenant answers with none" \
  "! (cd \"$t/repo\" && tenant_root >/dev/null)"
git -C "$t/repo" config pabloProtocol.tenant "$t/elsewhere"
check "one that was answers with the tenant" \
  "[ \"\$( (cd \"$t/repo\" && tenant_root) )\" = \"$t/elsewhere\" ]"
# A tenant that has moved or been removed leaves the setting behind pointing at nothing. Answering
# with a directory that is not a tenant would have every guard that asked read its policies from a
# path of git configuration's choosing.
git -C "$t/repo" config pabloProtocol.tenant "$t/no-such-directory"
check "a tenant that is no longer there is not a tenant" \
  "! (cd \"$t/repo\" && tenant_root >/dev/null)"

finish
