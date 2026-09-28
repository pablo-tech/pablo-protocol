#!/usr/bin/env bash
# Refuse to COMMIT one tenant's material into another tenant's repository.
#
# One person works for several tenants — an employer, clients, their own estate — through the same
# tools, often on the same machine, in the same hour. No AI coding tool can tell which tenant a
# diff belongs to, and a rule written into one tool's config says nothing about a diff produced by
# another tool, by an editor, or by hand. The commit is the one boundary every route passes through.
#
# `.protocol/tenant` lists the terms belonging to the OTHER tenants — as extended regular
# expressions, one per line — and any staged path or staged content matching one is refused. A repo
# without that file declares no tenancy and is not policed.
#
#   --scan-tree   apply the rules to every tracked file on disk instead of the staged set, so an
#                 audit reads the terms from the repo rather than from a doc that then drifts.
#
# Bypass, if you genuinely mean it: git commit --no-verify

set -uo pipefail
# shellcheck source-path=SCRIPTDIR source=policy.sh
. "$(dirname "${BASH_SOURCE[0]}")/policy.sh"

terms="$(policy tenant)" || exit 0
[ -n "$terms" ] || exit 0
PATTERN="$(printf '%s' "$terms" | paste -sd'|' -)"

# The denylist is the one file that legitimately spells the terms out.
POLICY_PATH=".protocol/tenant"

# Returns the first term that matched, so the refusal names what to look for rather than only where.
# Captures before trimming rather than piping into `head`: under `pipefail` the closed pipe would
# make the pipeline report failure on exactly the file the guard was meant to catch.
first_match() { # text
  local found
  found="$(grep -oiE -- "$PATTERN" <<<"$1")" || return 1
  printf '%s' "${found%%$'\n'*}"
}

offence() { # path content -> prints the matched term
  [ "$1" = "$POLICY_PATH" ] && return 1
  first_match "$1" && return 0
  first_match "$2"
}

# Nulls are stripped before the substitution sees them: the tree holds images and fonts, and bash
# warns once per null-carrying file otherwise. A check whose passing run prints warnings is a check
# people stop reading. Nothing is skipped — the path rule still sees the file.
offenders=""
if [ "${1:-}" = "--scan-tree" ]; then
  while IFS= read -r path; do
    [ -f "$path" ] || continue
    term="$(offence "$path" "$(tr -d '\0' <"$path" 2>/dev/null)")" && offenders="$offenders
$path: $term"
  done < <(git ls-files)
else
  while IFS= read -r path; do
    term="$(offence "$path" "$(git show ":$path" 2>/dev/null | tr -d '\0')")" && offenders="$offenders
$path: $term"
  done < <(git diff --cached --name-only --diff-filter=AM)
fi

if [ -n "$offenders" ]; then
  echo "pre-commit: refusing to commit another tenant's material into this repository:"
  printf '%s\n' "$offenders" | sed '/^$/d;s/^/pre-commit:   /'
  echo "pre-commit:"
  echo "pre-commit: Each term above is listed in .protocol/tenant, which names the tenants this"
  echo "pre-commit: repository is not. Put the material in that tenant's own repository instead."
  echo "pre-commit:"
  echo "pre-commit:   unstage with:  git restore --staged <path>"
  echo "pre-commit:"
  echo "pre-commit: If the term is genuinely this tenant's, the denylist is the bug — narrow it."
  echo "pre-commit: (bypass: git commit --no-verify)"
  exit 1
fi
