#!/usr/bin/env bash
# bin/doctor against scratch tenants: each question it asks, and the one thing it must not print.
#   bash bin/doctor.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/check.sh"

# Captured rather than piped into `grep -q`: under `pipefail` the closed pipe would report the
# failure on exactly the run being asserted about, which is the trap guards/tenant-guard.sh is
# commented about avoiding.
doctor() { HOME="$t/home" bash "$DIR/doctor" --in "$t/tenant" 2>&1; }
says() { # pattern — doctor's output matched it, and doctor exited 0
  local out rc
  out="$(doctor)"; rc=$?
  grep -q -- "$1" <<<"$out" && [ "$rc" -eq 0 ]
}
refuses() { # pattern — doctor's output matched it, and doctor exited non-zero
  local out rc
  out="$(doctor)"; rc=$?
  grep -q -- "$1" <<<"$out" && [ "$rc" -ne 0 ]
}
record() { printf '%s\n' '# which commit of the protocol installed this tenant' "$@" >"$t/tenant/.protocol/protocol-version"; }
# ref — the receipt bin/adapt would write for the fixture checkout as it stands right now.
at() { record "$1 $(git -C "$pinned" rev-parse --short HEAD) $(git -C "$pinned" log -1 --format=%as)"; }
fresh() { # [--copy] — a tenant installed from this checkout, then repointed at the fixture below
  rm -rf "${t:?}/tenant" "${t:?}/home"; mkdir -p "$t/home"; git init -q "$t/tenant"
  git -C "$t/tenant" config user.email t@example.invalid
  git -C "$t/tenant" config user.name Test
  (cd "$t/tenant" && HOME="$t/home" bash "$DIR/adapt" "$@" --agent claude-code >/dev/null 2>&1)
}

# A protocol checkout of its own: on a branch, with a tag on that branch and an origin to be level
# with or behind. The suite has to put a checkout into each of those states in turn, and cannot do
# that to the checkout it is itself running from.
pinned="$t/pinned-protocol"
mkdir -p "$pinned/doctrine" "$pinned/guards"
printf 'x\n' >"$pinned/doctrine/a.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"$pinned/guards/guards.sh"; chmod +x "$pinned/guards/guards.sh"
git init -q -b main "$pinned"
git -C "$pinned" config user.email t@example.invalid
git -C "$pinned" config user.name Test
git -C "$pinned" add -A && git -C "$pinned" commit -qm x
git -C "$pinned" tag v9.9.9
# No second repository and no network: `origin/main` is a ref like any other, and what doctor reads
# is whatever the last fetch left behind — which is exactly what writing it here by hand produces.
git -C "$pinned" update-ref refs/remotes/origin/main HEAD
repoint() { rm -f "$t/tenant/protocol" && ln -s "$pinned" "$t/tenant/protocol"; }

fresh; repoint; at main
# shellcheck disable=SC2034 # read inside the check expressions below, which shellcheck does not follow
out="$(doctor)"
check "a tenant on the branch it recorded, level with origin, has no problems" "doctor >/dev/null"
check "and is told which branch it tracks, and that it is current" \
  "grep -q 'ok    protocol tracking main, current' <<<\"\$out\""
check "the hook is reported as pointed at" "grep -q 'ok    core.hooksPath' <<<\"\$out\""
check "a seeded denylist that is all comments is reported as policing nothing" \
  "grep -q 'tenancy declares 0 terms' <<<\"\$out\""

# Behind is not broken — nothing is wrong until you commit against doctrine you have not read — so it
# is a note, and it says by how many rather than that something failed.
git -C "$pinned" commit -q --allow-empty -m ahead
git -C "$pinned" update-ref refs/remotes/origin/main HEAD
git -C "$pinned" reset -q --hard HEAD~1
check "a checkout behind its origin is a note, counted" \
  "says 'protocol is 1 commit(s) behind origin/main'"

# The receipt's other half, and the reason it records a commit and not just a branch: `protocol/` is
# current, and the files the installer copied in came from an older commit of it.
git -C "$pinned" reset -q --hard "$(git -C "$pinned" rev-parse origin/main)"
at main
git -C "$pinned" commit -q --allow-empty -m newer
git -C "$pinned" update-ref refs/remotes/origin/main HEAD
check "a checkout that has moved past the commit recorded here is a note, not a fault" \
  "says 'protocol has moved since bin/adapt last ran here'"
record "main 0000000 2026-01-01"
check "and a commit this checkout does not have at all is named as such" \
  "says 'recorded (0000000) is not in this checkout'"

# The branch recorded is not the branch checked out: the doctrine being read here is not the doctrine
# the receipt claims, which is the whole of what this check is for.
at main; git -C "$pinned" checkout -q --detach HEAD
check "a detached checkout recorded as tracking a branch fails" \
  "refuses 'protocol is detached, recorded on main'"
git -C "$pinned" checkout -q -b side
check "and so does one sitting on a different branch, which is named" \
  "refuses 'protocol is on side, recorded on main'"
git -C "$pinned" checkout -q main && git -C "$pinned" branch -q -D side

# "Current" is current with whatever the last fetch left behind. A tip that has not moved in a
# fortnight is a quiet protocol or a stale fetch, and from here those two are the same picture.
GIT_AUTHOR_DATE='2025-01-01T00:00:00Z' GIT_COMMITTER_DATE='2025-01-01T00:00:00Z' \
  git -C "$pinned" commit -q --allow-empty -m long-ago
git -C "$pinned" update-ref refs/remotes/origin/main HEAD
at main
check "current against a tip that has not moved in a fortnight says how long it has been" \
  "says 'origin/main has not moved in'"

# An installer has to have run for any of this to mean anything, and this file is one it writes
# rather than one a tenant fills in — so nothing recorded is a fault now, where an empty pin was not.
record
check "a tenant with nothing recorded is a failure, the installer never having run" \
  "refuses 'no protocol recorded'"
# Except when the installer ran out of an archive rather than a clone: it wrote what it could, and a
# name it could not check is worth less than saying so.
record unknown
check "a protocol with no history to record is a note, because bin/adapt said so itself" \
  "says 'protocol recorded as unknown'"

# A tag, for a tenant that would rather pin: the protocol still cuts them for breaking changes, and
# the check a pin wants is the one this file has always made.
git -C "$pinned" checkout -q v9.9.9
at v9.9.9
check "a tenant that records a tag is checked against the tag" "says 'ok    protocol pinned at v9.9.9'"
record v0.0.1
check "a tag the checkout is not at fails, and says which it is at" \
  "refuses 'protocol is at v9.9.9, pinned to v0.0.1'"
git -C "$pinned" commit -q --allow-empty -m y
check "a checkout at no tag at all fails differently, because the fix is different" \
  "refuses 'protocol is not at a tag, pinned to v0.0.1'"
# And a bare commit, which is what the installer records when it runs out of a checkout on no branch
# and at no tag — a CI runner's, most often. There is nothing to be behind; there is only whether
# this is still that commit.
at "$(git -C "$pinned" rev-parse --short HEAD)"
check "a checkout on no branch is reported against the commit recorded, not against a tag" \
  "says 'protocol at .*, on no branch'"
git -C "$pinned" checkout -q main

# --copy leaves a directory with no history. Nothing can date it, so what the receipt names is
# unknowable rather than wrong, and saying so once beats a MISS on every machine that needed the copy.
fresh --copy; record v9.9.9
check "a copied protocol is a note, not a failure" \
  "says 'protocol is a copy, not a clone'"

fresh; repoint; at main
ln -s ../protocol/doctrine/gone.md "$t/tenant/skills/gone.md"
git -C "$t/tenant" add -f skills/gone.md
check "a tracked link pointing at nothing is a failure, named" "refuses 'skills/gone.md'"

fresh; repoint; at main
git -C "$t/tenant" config --unset core.hooksPath
check "a clone that nothing pointed git at is a failure" \
  "refuses 'core.hooksPath is not .githooks'"

# The shim decides which checkout the guards come from. A tenant still carrying the shim from before
# that step reads its doctrine from one checkout and runs its guards from another, silently.
fresh; repoint; at main
sed -i'' -e '/protocol\/guards\/guards.sh/d' "$t/tenant/.githooks/pre-commit"
check "a shim that never consults the tenant's own protocol is a failure" \
  "refuses \"never consults this repository's own protocol\""
# `bin/adapt` seeds that file and then never rewrites it, so advising a re-run would be advising a
# no-op — the remedy a tenant follows has to be one that does something.
check "and the remedy it names is the one that works" "refuses tenant-template"
# A tenant that replaced the shim with a dispatcher of its own resolves the guards somewhere this
# cannot read, so the question is not answerable and is not asked. Reporting a fault against a
# repository that is wired correctly is how a check gets scrolled past.
# shellcheck disable=SC2016 # the shim is written out verbatim, not evaluated here
printf '#!/usr/bin/env bash\nexec "$(git rev-parse --show-toplevel)/hooks/mine.sh"\n' \
  >"$t/tenant/.githooks/pre-commit"
check "a shim this protocol did not write is left alone" \
  "! grep -q 'never consults' <<<\"\$(doctor)\""

# A launcher is the adapter's, not the tenant's: written whole, then skipped forever because it
# exists. A tenant installed before the adapter changed keeps the old one with nothing to see.
rm -rf "${t:?}/tenant" "${t:?}/home"; mkdir -p "$t/home"; git init -q "$t/tenant"
git -C "$t/tenant" config user.email t@example.invalid
git -C "$t/tenant" config user.name Test
(cd "$t/tenant" && HOME="$t/home" bash "$DIR/adapt" --agent cortex >/dev/null 2>&1)
check "a launcher matching the one this protocol installs is not mentioned at all" \
  "! grep -q '.agents/cortex/run' <<<\"\$(doctor)\""
printf '\n# edited on the machine\n' >>"$t/tenant/.agents/cortex/run"
check "one that does not match is reported" "says '.agents/cortex/run differs'"
# A note, not a failure: the file is the adapter's, but nothing here knows whether the difference is
# an old install or someone who meant it, and a doctor that fails on both is one nobody runs.
check "as a note, because a tenant may have meant it" \
  "grep -q 'note  .agents/cortex/run' <<<\"\$(doctor)\""

# The count, and only the count: a doctor that printed the terms would publish, in whatever log it
# runs in, the list the untracked overlay exists to keep out of anything readable.
fresh; repoint; at main
printf 'Initech\n' >>"$t/tenant/.protocol/tenant"
printf 'Umbrella\n' >"$t/tenant/.protocol/tenant.local"
# shellcheck disable=SC2034 # as above
counted="$(doctor)"
check "both layers of the policy are counted" "grep -q 'tenancy declared: 2 term(s)' <<<\"\$counted\""
check "and no term is ever printed" "! grep -qiE 'Initech|Umbrella' <<<\"\$counted\""

# shellcheck disable=SC2034 # as above
helped="$(bash "$DIR/doctor" --help)"
check "--help prints the header and stops there" "! grep -q 'set -uo' <<<\"\$helped\""

finish
