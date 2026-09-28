# shellcheck shell=bash
# Sourced by the shell suites that are a list of checks rather than a table of verdicts.
fails=0
# name condition: the condition is eval'd, so each check reads as what it asserts.
check() { if eval "$2"; then printf "  ok    %s\n" "$1"; else printf "  FAIL  %s\n" "$1"; fails=$((fails+1)); fi; }
# The last line, and the exit status test.sh reads as the verdict.
finish() {
  local name=${0##*/}
  name=${name%.test.sh}
  if [ "$fails" -eq 0 ]; then echo "$name: all passed"; else echo "$name: $fails failed"; exit 1; fi
}
# scratch_repo dir path...: a fresh repository at dir whose index holds just these paths.
scratch_repo() {
  local repo=$1 path
  shift
  rm -rf "$repo" && git init -q "$repo"
  for path in "$@"; do mkdir -p "$repo/$(dirname "$path")" && echo x >"$repo/$path"; done
  git -C "$repo" add -A
}
