#!/usr/bin/env bash
# bin/doctor against scratch tenants: each of the four questions, and the one thing it must not print.
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
pin()    { printf '%s\n' '# the tag this tenant consumes' "$@" >"$t/tenant/.protocol/protocol-version"; }
fresh() { # [--copy] — a tenant installed from this checkout, then repointed at the tagged one below
  rm -rf "${t:?}/tenant" "${t:?}/home"; mkdir -p "$t/home"; git init -q "$t/tenant"
  git -C "$t/tenant" config user.email t@example.invalid
  git -C "$t/tenant" config user.name Test
  (cd "$t/tenant" && HOME="$t/home" bash "$DIR/adapt" "$@" --agent claude-code >/dev/null 2>&1)
}

# A protocol checkout of its own, at a tag, so the pin can be both right and wrong in this suite
# whatever the checkout the suite is running from happens to be at.
pinned="$t/pinned-protocol"
mkdir -p "$pinned/doctrine" "$pinned/guards"
printf 'x\n' >"$pinned/doctrine/a.md"
printf '#!/usr/bin/env bash\nexit 0\n' >"$pinned/guards/guards.sh"; chmod +x "$pinned/guards/guards.sh"
git init -q "$pinned"
git -C "$pinned" config user.email t@example.invalid
git -C "$pinned" config user.name Test
git -C "$pinned" add -A && git -C "$pinned" commit -qm x
git -C "$pinned" tag v9.9.9
repoint() { rm -f "$t/tenant/protocol" && ln -s "$pinned" "$t/tenant/protocol"; }

fresh; repoint; pin v9.9.9
# shellcheck disable=SC2034 # read inside the check expressions below, which shellcheck does not follow
out="$(doctor)"
check "a tenant wired to the checkout it pins has no problems" "doctor >/dev/null"
check "the pin is reported against what the checkout actually is" \
  "grep -q 'ok    protocol pinned at v9.9.9' <<<\"\$out\""
check "the hook is reported as pointed at" "grep -q 'ok    core.hooksPath' <<<\"\$out\""
check "a seeded denylist that is all comments is reported as policing nothing" \
  "grep -q 'tenancy declares 0 terms' <<<\"\$out\""

pin
check "a tenant that does not pin is not drifting, so this is a note" \
  "says 'note  protocol not pinned'"
pin v0.0.1
check "a pin the checkout is not at fails, and says which it is at" \
  "refuses 'protocol is at v9.9.9, pinned to v0.0.1'"
git -C "$pinned" checkout -q --detach HEAD && git -C "$pinned" commit -q --allow-empty -m y
check "a checkout at no tag at all fails differently, because the fix is different" \
  "refuses 'protocol is not at a tag, pinned to v0.0.1'"
git -C "$pinned" checkout -q v9.9.9

# --copy leaves a directory with no history. Nothing can date it, so the pin is unknowable rather
# than broken, and saying so once beats a MISS on every machine that needed the copy.
fresh --copy; pin v9.9.9
check "a copied protocol is a note, not a failure" \
  "says 'protocol is a copy, not a clone'"

fresh; repoint; pin v9.9.9
ln -s ../protocol/doctrine/gone.md "$t/tenant/skills/gone.md"
git -C "$t/tenant" add -f skills/gone.md
check "a tracked link pointing at nothing is a failure, named" "refuses 'skills/gone.md'"

fresh; repoint; pin v9.9.9
git -C "$t/tenant" config --unset core.hooksPath
check "a clone that nothing pointed git at is a failure" \
  "refuses 'core.hooksPath is not .githooks'"

# The shim decides which checkout the guards come from. A tenant still carrying the shim from before
# that step reads its doctrine from one checkout and runs its guards from another, silently.
fresh; repoint; pin v9.9.9
sed -i'' -e '/protocol\/guards\/guards.sh/d' "$t/tenant/.githooks/pre-commit"
check "a shim that never consults the tenant's own protocol is a failure" \
  "refuses \"never consults this repository's own protocol\""

# The count, and only the count: a doctor that printed the terms would publish, in whatever log it
# runs in, the list the untracked overlay exists to keep out of anything readable.
fresh; repoint; pin v9.9.9
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
