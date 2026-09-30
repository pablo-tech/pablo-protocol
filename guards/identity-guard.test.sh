#!/usr/bin/env bash
# identity-guard.sh against a scratch repository carrying a .protocol/identity allowlist.
#   bash guards/identity-guard.test.sh
#
# Under its own HOME, because the thing under test is whichever identity git resolves: a suite that
# read the real machine's would pass or fail on how the person running it has configured their own.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../bin/check.sh"

export HOME="$t/home"
mkdir -p "$HOME"
# The machine's own identity, which no allowlist below names. A repository that wants to pass says
# so for itself, which is the whole shape of the thing.
git config --global user.name "machine"
git config --global user.email "machine@example.invalid"

# claims <identity-lines>: a fresh repository allowing those identities.
claims() {
  scratch_repo "$t/repo" >/dev/null
  mkdir -p "$t/repo/.protocol" && printf '%s\n' "$1" >"$t/repo/.protocol/identity"
  git -C "$t/repo" add -A
}
# as name email: what this clone of that repository commits as.
as() { git -C "$t/repo" config user.name "$1"; git -C "$t/repo" config user.email "$2"; }
commit() { git -C "$t/repo" commit -qm "${1:-x}" --no-verify --allow-empty; }
guard() { (cd "$t/repo" && bash "$DIR/identity-guard.sh" >/dev/null 2>&1); }
scan() { (cd "$t/repo" && bash "$DIR/identity-guard.sh" --scan-history "$@" >/dev/null 2>&1); }

scratch_repo "$t/repo" >/dev/null
check "a repository that claims no identity is not policed" "guard"

claims '# nobody is named here'
check "nor is one whose list is only comments" "guard"

claims 'someone@example\.test'
as "Someone" "someone@example.test"
check "the identity the repository claims commits" "guard"

claims 'someone@example\.test'
as "Someone Else" "else@example.test"
check "an identity it does not claim is refused" "! guard"

claims 'someone@example\.test'
check "and so is the machine's own, which is what a fresh clone would commit as" "! guard"

claims 'SOMEONE@EXAMPLE\.TEST'
as "Someone" "someone@example.test"
check "the match ignores case" "guard"

claims '@example\.test>$'
as "Anyone At All" "anyone@example.test"
check "a line is an extended regex, so a whole domain is one line" "guard"

claims 'someone@example\.test
other@example\.test'
as "Other" "other@example.test"
check "any one line of the allowlist is enough" "guard"

# The author is who wrote it and the committer is who applied it, and they are separately settable —
# a rebase, an amend, a patch applied on someone else's behalf. Checking only the first would let
# the second through on exactly those routes.
claims 'someone@example\.test'
as "Someone" "someone@example.test"
check "the committer is checked too, not only the author" \
  "! (cd '$t/repo' && GIT_COMMITTER_EMAIL=nobody@example.invalid \
      bash '$DIR/identity-guard.sh' >/dev/null 2>&1)"

# The overlay is the half that is not published: an address is a person, and a repository anyone
# can read cannot state whose commits it expects any more than it can state its denylist's nouns.
claims '# the names are in the untracked layer beside this file'
printf '/.protocol/*.local\n' >"$t/repo/.gitignore"
printf 'someone@example\\.test\n' >"$t/repo/.protocol/identity.local"
as "Someone" "someone@example.test"
check "an identity carried only by the untracked overlay is claimed" "guard"
as "Someone Else" "else@example.test"
check "and the overlay is the only thing that claims it" "! guard"

# --- what reached the branch anyway ---------------------------------------------------------------
claims 'someone@example\.test'
as "Someone" "someone@example.test"
commit "one this repository claims"
check "--scan-history passes a history that is entirely claimed" "scan"

as "Someone Else" "else@example.test"
commit "one it does not"
check "--scan-history finds a commit made past the hook" "! scan"
check "and a range excluding it still passes" "scan HEAD~1"

# A commit's author survives a rebase and its committer does not, so a history rewritten by anyone
# else carries two identities and the scan has to read both.
as "Someone" "someone@example.test"
GIT_COMMITTER_NAME="Nobody" GIT_COMMITTER_EMAIL="nobody@example.invalid" \
  git -C "$t/repo" commit -qm "applied on someone's behalf" --no-verify --allow-empty
check "--scan-history reads the committer of each commit as well as the author" "! scan HEAD~1.."

finish
