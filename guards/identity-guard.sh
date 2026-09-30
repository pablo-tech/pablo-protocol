#!/usr/bin/env bash
# Refuse to COMMIT as an identity this repository does not claim.
#
# Which name and address a commit is made as is machine configuration, not repository
# configuration. A fresh clone carries none of its own, so it is committed to by whoever the
# machine was set up as — and git says nothing about it. The header is written, it is permanent,
# and it is found, if it is found at all, by someone reading `git log` long afterwards. It is also
# the one part of a commit that names a person rather than the work, which is what makes it the
# part that must not travel from one tenant into another's history.
#
# `.protocol/identity` lists the identities this repository's commits may be made as — extended
# regular expressions, one per line — matched case-insensitively against `Name <email>`, for the
# author and for the committer. A repository carrying no such file, or an empty one, claims no
# identity and is not policed.
#
#   --scan-history [<range>]   apply the rules to the commits in <range> (default: HEAD) instead of
#                              to the commit being made, so a header that reached the branch past
#                              the hook is found on the next run rather than never.
#
# Bypass, if you genuinely mean it: git commit --no-verify

set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=policy.sh
. "$(dirname "${BASH_SOURCE[0]}")/policy.sh"

allowed="$(policy identity)" || exit 0
[ -n "$allowed" ] || exit 0
PATTERN="$(printf '%s' "$allowed" | paste -sd'|' -)"

claimed() { grep -qiE -- "$PATTERN" <<<"$1"; }

# `git var` answers with what this commit would actually be made as — the configuration git will
# read, and the GIT_AUTHOR_* environment that overrides it, resolved the same way the commit will
# resolve it. Anything this guard derived itself would be a second implementation of that lookup,
# and would disagree with it on the day the difference mattered.
#
# The answer is `Name <email> 1790800093 -0700`; the trailing timestamp is the machine's clock
# rather than part of who this is, and `% * *` takes the shortest such tail, so a name with spaces
# in it survives.
ident() { local raw; raw="$(git var "$1")" || return 1; printf '%s' "${raw% * *}"; }

offenders=""
if [ "${1:-}" = "--scan-history" ]; then
  headline="commits made as an identity this repository does not claim:"
  range="${2:-HEAD}"
  history="$(git log --format='%h%x09%an <%ae>%x09%cn <%ce>' "${range}" --)" || {
    echo "pre-commit: identity-guard: no history to read at '${range}'" >&2; exit 1; }
  while IFS=$'\t' read -r sha author committer; do
    [ -n "$sha" ] || continue
    claimed "$author" || offenders="$offenders
$sha  author     $author"
    # One identity for both is the ordinary case, and naming it twice reads as two problems.
    [ "$committer" = "$author" ] || claimed "$committer" || offenders="$offenders
$sha  committer  $committer"
  done <<<"$history"
else
  headline="refusing to commit as an identity this repository does not claim:"
  author="$(ident GIT_AUTHOR_IDENT)" || exit 1
  committer="$(ident GIT_COMMITTER_IDENT)" || exit 1
  claimed "$author" || offenders="$offenders
author     $author"
  [ "$committer" = "$author" ] || claimed "$committer" || offenders="$offenders
committer  $committer"
fi

if [ -n "$offenders" ]; then
  echo "pre-commit: $headline"
  printf '%s\n' "$offenders" | sed '/^$/d;s/^/pre-commit:   /'
  echo "pre-commit:"
  echo "pre-commit: .protocol/identity lists the identities this repository's commits may be made"
  echo "pre-commit: as. An identity is configured per machine and a fresh clone carries none of"
  echo "pre-commit: this repository's own, so what is above is whoever that machine was set up as,"
  echo "pre-commit: which is a different question. Answer this one here:"
  echo "pre-commit:"
  echo "pre-commit:   git config user.name  \"<name>\""
  echo "pre-commit:   git config user.email \"<email>\""
  echo "pre-commit:"
  echo "pre-commit: If the identity above is genuinely this repository's, the list is the bug."
  echo "pre-commit: (bypass: git commit --no-verify)"
  exit 1
fi
