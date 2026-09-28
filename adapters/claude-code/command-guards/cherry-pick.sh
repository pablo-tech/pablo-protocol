#!/usr/bin/env bash
# doctrine/git.md: promote dev to main whole, never by cherry-pick — a cherry-picked main diverges and the
# next whole promotion conflicts. The damage is not the pick, it is every promotion after it.
#
# It used to judge any command line carrying the words, which denied reading this very file from a
# checkout sitting on main, and to ask when the branch would not resolve — a branch resolves to
# nothing only when HEAD is detached or the command is not in a repository at all, and neither can
# land a pick on branch main, so the answer was always yes (owner decision).
#
#   $1 the command, $2 the branch it would land on (the dispatcher resolves it)
set -uo pipefail
cmd="${1:-}"
branch="${2:-}"
case "$cmd" in *cherry-pick*) ;; *) exit 0 ;; esac
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/clauses.sh"

git_clause_args "$cmd" cherry-pick >/dev/null || exit 0
[ "$branch" = main ] || exit 0

echo "deny a cherry-pick onto main makes it diverge from dev, and the next whole promotion conflicts —
doctrine/git.md: promote dev to main whole, never by cherry-pick. Merge all of dev instead, once dev is
clean."
