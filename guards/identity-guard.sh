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
# author and for the committer. A repository carrying no such file falls back to the list of the
# tenant it is worked on under, if local git configuration names one (`pabloProtocol.tenant`, see
# policy.sh) — because a repository worked on under a tenant is deliberately not a tenant and so has
# no `.protocol/` of its own to state this in. A repository that carries the file is judged by it
# alone, empty or not: carrying it is how a repository opts in, and an empty one claims nobody.
#
#   --scan-history [<range>]   apply the rules to the commits in <range> (default: HEAD) instead of
#                              to the commit being made, so a header that reached the branch past
#                              the hook is found on the next run rather than never.
#
# Bypass, if you genuinely mean it: git commit --no-verify

set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=policy.sh
. "$(dirname "${BASH_SOURCE[0]}")/policy.sh"

# Whose list this is, which the report below has to say: being refused by a file that is not in the
# repository you are committing to is otherwise unreadable.
whose="this repository"
where=".protocol/identity"
if ! allowed="$(policy identity)"; then
  if tenant="$(tenant_root)"; then
    allowed="$(policy identity "$tenant")" || allowed=""
    whose="this repository's tenant"
    where="$tenant/.protocol/identity"
  else
    allowed=""
  fi
fi
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
  headline="commits made as an identity $whose does not claim:"
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
  headline="refusing to commit as an identity $whose does not claim:"
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
  echo "pre-commit: $where lists the identities $whose claims its commits are made as."
  if [ "$whose" != "this repository" ]; then
    echo "pre-commit: This repository carries no such list of its own, so it is held to that"
    echo "pre-commit: one for as long as this clone is wired to that tenant."
  fi
  echo "pre-commit: An identity is configured per machine and a fresh clone carries none of this"
  echo "pre-commit: repository's own, so what is above is whoever that machine was set up as, which"
  echo "pre-commit: is a different question. Answer this one here:"
  echo "pre-commit:"
  echo "pre-commit:   git config user.name  \"<name>\""
  echo "pre-commit:   git config user.email \"<email>\""
  echo "pre-commit:"
  if [ "$whose" = "this repository" ]; then
    echo "pre-commit: If the identity above is genuinely this repository's, the list is the bug."
  else
    echo "pre-commit: If the identity above is genuinely this repository's, it is not that tenant's"
    echo "pre-commit: to claim: give this repository its own .protocol/identity and it is judged by"
    echo "pre-commit: that and by nothing else."
  fi
  echo "pre-commit: (bypass: git commit --no-verify)"
  exit 1
fi
