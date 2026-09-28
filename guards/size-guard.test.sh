#!/usr/bin/env bash
# size-guard.sh against the index of a scratch repository, on either side of the 25 MB ceiling.
#   bash guards/size-guard.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../bin/check.sh"

MB=1048576
# stage bytes path: a fresh repository whose index holds one file of that size.
stage() { scratch_repo "$t/repo" >/dev/null && truncate -s "$1" "$t/repo/$2" && git -C "$t/repo" add -A; }
guard() { (cd "$t/repo" && bash "$DIR/size-guard.sh" >/dev/null 2>&1); }

stage $((25 * MB)) exactly.bin
check "a file of exactly 25 MB is let through" "guard"
stage $((25 * MB + 1)) over.bin
check "one byte more is refused" "! guard"
stage $((25 * MB + 1)) "with space.bin"
check "a path with a space in it is still measured" "! guard"
stage $((25 * MB + 1)) over.bin
echo small > "$t/repo/over.bin"
check "the staged blob is what counts, not the file on disk" "! guard"
stage $((2 * MB)) two.bin
check "PROTOCOL_MAX_FILE_MB lowers the ceiling" "! (cd '$t/repo' && PROTOCOL_MAX_FILE_MB=1 bash '$DIR/size-guard.sh' >/dev/null 2>&1)"

finish
