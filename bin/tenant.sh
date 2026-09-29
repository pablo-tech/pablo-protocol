# shellcheck shell=bash
# The two things bin/adapt and every adapter do to a tenant, written once. Both set TENANT to the
# tenant's root before sourcing this.

# One line per change, so a second run visibly does nothing.
say() { printf '  %-6s %s\n' "$1" "$2"; }

# Patterns for the tenant's .gitignore — unless the tenant already has a rule about that path.
#
# Not a comparison of the line: a tenant that answered this in a spelling of its own has answered it,
# and a broader rule appended underneath wins as the last matching pattern and silently undoes the
# exception it carved out. A context repo ignoring `projects/*/*` while keeping `projects/*/memory/*.md`
# tracked loses that memory to a later `/projects/`. The tenant's rules are the tenant's, same as its
# instruction file — an adapter may create, never edit.
#
# Which is why one caller's whole set arrives in one call. "Has the tenant said anything about this
# path" is a question about the tenant's lines, and a pattern the caller is installing beside this one
# is not the tenant saying anything. Two rules under one directory would otherwise have the first
# silence the second on the very first run — and the second is the one that was holding a credential
# out of the index.
ignore() {
  local file="$TENANT/.gitignore" theirs pattern name esc
  # The tenant's own lines: the file, less the patterns this call is installing.
  theirs="$(grep -vxF -f <(printf '%s\n' "$@") -- "$file" 2>/dev/null)" || true
  for pattern in "$@"; do
    grep -qxF -- "$pattern" "$file" 2>/dev/null && continue
    name="${pattern#/}"
    name="${name%%/*}"
    esc="$(printf '%s' "$name" | sed 's/[.[^$\\*]/\\&/g')"
    grep -qE "^!?/?${esc}([/*]|\$)" <<<"$theirs" && continue
    printf '%s\n' "$pattern" >>"$file"
    say ignore "$pattern"
  done
}
