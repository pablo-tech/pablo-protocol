#!/usr/bin/env bash
# Single entry point for every shared pre-commit guard.
#
# A repo carries a thin `.githooks/pre-commit` shim that runs THIS file, so a new shared rule is
# added in one place and every repo picks it up without a commit each. Do not copy a guard's logic
# into a repo — that is the drift this indirection exists to prevent.
#
# Each guard exits non-zero to block the commit and is expected to explain itself. A guard whose
# policy file the repo does not carry exits 0, so the chain is safe to point at any checkout.

set -uo pipefail
# The guards beside this file. WHICH checkout that is belongs to the shim, because the choice has to
# be made before this file can be read — deriving it here would only describe the tree already chosen.
DIR="${PROTOCOL_GUARDS:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

for g in size-guard.sh credentials-guard.sh tenant-guard.sh identity-guard.sh; do
  if [ ! -x "$DIR/$g" ]; then
    # Fail closed. A silently skipped guard is worse than a missing one: the thing it was meant to
    # catch reaches history, and the absence never announces itself.
    echo "pre-commit: shared guard missing or not executable: $DIR/$g"
    echo "pre-commit:   clone pablo-tech/pablo-protocol and run its bin/adapt,"
    echo "pre-commit:   or point PROTOCOL_GUARDS at a checkout of its guards/."
    echo "pre-commit: (bypass: git commit --no-verify)"
    exit 1
  fi
  "$DIR/$g" || exit $?
done
