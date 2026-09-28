# shellcheck shell=bash
# The two things bin/adapt and every adapter do to a tenant, written once. Both set TENANT to the
# tenant's root before sourcing this.

# One line per change, so a second run visibly does nothing.
say() { printf '  %-6s %s\n' "$1" "$2"; }

# A pattern in the tenant's .gitignore — unless the tenant already has a rule about that path.
#
# Not a comparison of the line: a tenant that answered this in a spelling of its own has answered it,
# and a broader rule appended underneath wins as the last matching pattern and silently undoes the
# exception it carved out. A context repo ignoring `projects/*/*` while keeping `projects/*/memory/*.md`
# tracked loses that memory to a later `/projects/`. The tenant's rules are the tenant's, same as its
# instruction file — an adapter may create, never edit.
ignore() {
  local name="${1#/}" esc
  name="${name%%/*}"
  esc="$(printf '%s' "$name" | sed 's/[.[^$\\*]/\\&/g')"
  grep -qE "^!?/?${esc}([/*]|\$)" "$TENANT/.gitignore" 2>/dev/null && return
  printf '%s\n' "$1" >>"$TENANT/.gitignore"
  say ignore "$1"
}
