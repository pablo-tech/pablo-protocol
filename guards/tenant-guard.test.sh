#!/usr/bin/env bash
# tenant-guard.sh against the index of a scratch repository carrying a .protocol/tenant denylist.
#   bash guards/tenant-guard.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../bin/check.sh"

# tenant <denylist-lines>: a fresh repository that declares those terms as OTHER tenants'.
tenant() {
  scratch_repo "$t/repo" >/dev/null
  mkdir -p "$t/repo/.protocol" && printf '%s\n' "$1" >"$t/repo/.protocol/tenant"
  git -C "$t/repo" add -A
}
# stage path content
stage() { mkdir -p "$t/repo/$(dirname "$1")" && printf '%s\n' "$2" >"$t/repo/$1" && git -C "$t/repo" add -A; }
guard() { (cd "$t/repo" && bash "$DIR/tenant-guard.sh" >/dev/null 2>&1); }
scan() { (cd "$t/repo" && bash "$DIR/tenant-guard.sh" --scan-tree >/dev/null 2>&1); }

scratch_repo "$t/repo" >/dev/null
stage notes.md "anything at all"
check "a repo that declares no tenant policy is not policed" "guard"

tenant 'Initech'
stage notes.md "the deploy is green"
check "a commit naming no other tenant passes" "guard"

tenant 'Initech'
stage notes.md "met with Initech about the migration"
check "a commit naming another tenant in its content is refused" "! guard"

tenant 'Initech'
stage notes.md "met with initech about the migration"
check "the match ignores case" "! guard"

tenant 'Initech'
stage "initech/plan.md" "nothing sensitive here"
check "a path naming another tenant is refused even when the content is clean" "! guard"

tenant 'Initech
Acme Corp'
stage notes.md "quarterly review at Acme Corp"
check "any one line of the denylist is enough" "! guard"

tenant 'Acme-[0-9]+'
stage notes.md "carried over from Acme-42"
check "a denylist line is an extended regex, not a literal" "! guard"

tenant '# only a comment

Initech'
stage notes.md "the deploy is green"
check "comments and blank lines in the denylist match nothing" "guard"

tenant 'Initech'
check "the denylist naming the terms is not itself an offence" "guard"

tenant 'Initech'
stage notes.md "the deploy is green"
git -C "$t/repo" commit -qm x --no-verify
printf 'Initech\n' >"$t/repo/notes.md"
check "--scan-tree reads the working tree, not the staged set" "! scan"

finish
