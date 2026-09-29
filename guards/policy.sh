# shellcheck shell=bash
# The per-repo policy files every guard reads, all under `.protocol/` at the committing repo's root.
#
# A guard whose policy file is absent has nothing to enforce and exits 0. That is what makes one
# shared guard chain safe to point at any checkout: a repo opts into a rule by carrying the file
# that configures it, rather than by being recognised by name from inside the guard.

# policy <name>: the file's content lines, or non-zero if the repo carries neither layer.
#
# Two layers, read in order and concatenated: the tracked `.protocol/<name>`, then an untracked
# `.protocol/<name>.local`. Either may be absent; only both being absent is the "no such policy"
# answer a guard exits 0 on.
#
# The overlay exists because a policy file in a repository anyone can read cannot state what it
# protects against — the list would be the disclosure it was written to prevent. So the tracked file
# carries the shapes and the categories, which are safe to publish, and the overlay carries the
# proper nouns, which are not. The overlay is gitignored, so the names stay on the machine that
# needs them and never reach history.
policy() {
  local root file found=1
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  for file in "$root/.protocol/$1" "$root/.protocol/$1.local"; do
    [ -f "$file" ] || continue
    found=0
    sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$file"
  done
  return "$found"
}

# Whole-line comments only: a policy line is a path or a regex and may legitimately contain `#`.
