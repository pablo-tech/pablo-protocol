# shellcheck shell=bash
# The per-repo policy files every guard reads, all under `.protocol/` at the committing repo's root.
#
# A guard whose policy file is absent has nothing to enforce and exits 0. That is what makes one
# shared guard chain safe to point at any checkout: a repo opts into a rule by carrying the file
# that configures it, rather than by being recognised by name from inside the guard.

# policy <name>: the file's content lines, or non-zero if the repo does not carry that policy.
policy() {
  local root file
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  file="$root/.protocol/$1"
  [ -f "$file" ] || return 1
  sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$file"
}

# Whole-line comments only: a policy line is a path or a regex and may legitimately contain `#`.
