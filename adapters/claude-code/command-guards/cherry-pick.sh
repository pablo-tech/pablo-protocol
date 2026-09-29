#!/usr/bin/env bash
# doctrine/git.md: promote whole, never by cherry-pick — a cherry-picked target branch diverges and
# the next whole promotion conflicts. The damage is not the pick, it is every promotion after it.
#
#   $1 the command, $2 the branch it would land on, $3 the protected one — the dispatcher resolves
#   the last two
set -uo pipefail
cmd="${1:-}"
branch="${2:-}"
protected="${3:-main}"
case "$cmd" in *cherry-pick*) ;; *) exit 0 ;; esac
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/clauses.sh"

git_clause_args "$cmd" cherry-pick >/dev/null || exit 0
[ "$branch" = "$protected" ] || exit 0

echo "deny a cherry-pick onto $protected makes it diverge, and the next whole promotion conflicts —
doctrine/git.md: promote whole, never by cherry-pick. Merge all of the source branch instead, once
it is clean."
