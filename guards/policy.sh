# shellcheck shell=bash
# The per-repo policy files every guard reads, all under `.protocol/` at the committing repo's root.
#
# A guard whose policy file is absent has nothing to enforce and exits 0. That is what makes one
# shared guard chain safe to point at any checkout: a repo opts into a rule by carrying the file
# that configures it, rather than by being recognised by name from inside the guard.

# policy <name> [<root>]: the file's content lines, or non-zero if that repo carries neither layer.
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
#
# <root> is the committing repository unless a guard names another. Only `tenant_root` below answers
# with another, and only one guard asks it to.
#
# Whole-line comments only: a policy line is a path or a regex and may legitimately contain `#`.
policy() {
  local root=${2:-} file found=1
  [ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  for file in "$root/.protocol/$1" "$root/.protocol/$1.local"; do
    [ -f "$file" ] || continue
    found=0
    sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$file"
  done
  return "$found"
}

# tenant_root: the tenant this repository is worked on under, if something wired it to one.
#
# A repository worked on under a tenant is deliberately not a tenant — it is given the guard chain
# and nothing else, so that nothing of the tenant's is in its tree for its own contributors and its
# own CI to inherit. That leaves it with nowhere to say which tenant it is worked on under, and
# nowhere it should have to: which tenant a checkout is worked on under is a fact about this
# machine, true of one clone of it and false of the next.
#
# So it is recorded where `core.hooksPath` is, in local git configuration, by whatever wired the
# repository. Local configuration is also what makes it safe for a guard to read. `.git/config` is
# not in the tree and does not travel, so nothing arriving over the network can set this and point a
# guard at a directory of its own choosing.
#
# `pabloProtocol` rather than `protocol`, which is git's own configuration section: a bare
# `protocol.tenant` collides with nothing git reads today, and squatting a reserved section is the
# kind of thing that is discovered years later by the version that starts reading it.
tenant_root() {
  local dir
  dir="$(git config --get pabloProtocol.tenant 2>/dev/null)" || return 1
  [ -n "$dir" ] && [ -d "$dir/.protocol" ] || return 1
  printf '%s' "$dir"
}
