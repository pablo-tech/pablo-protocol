#!/usr/bin/env bash
# Claude Code reads its configuration from the directory CLAUDE_CONFIG_DIR names, and discovers
# skills at <config-dir>/skills/<name>/SKILL.md.
#
# Each doctrine file carries exactly `name` and `description` frontmatter, which is all a SKILL.md
# requires and is inert to every other reader — so a skill here is a symlink to the doctrine file,
# not a copy of it. One file, two readers, nothing to drift.
set -euo pipefail
TENANT="$1"; MODE="${2:-link}"
PROTOCOL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
say() { printf '  %-6s %s\n' "$1" "$2"; }

mkdir -p "$TENANT/skills"
for src in "$PROTOCOL"/doctrine/*.md; do
  name="$(basename "$src" .md)"
  dst="$TENANT/skills/$name/SKILL.md"
  if [ -e "$dst" ] || [ -L "$dst" ]; then say skip "skills/$name"; continue; fi
  mkdir -p "$(dirname "$dst")"
  # Relative, through the tenant's own `protocol` entry, so the link survives the tenant moving.
  if [ "$MODE" = copy ]; then cp "$src" "$dst"; else ln -s "../../protocol/doctrine/$name.md" "$dst"; fi
  say "$MODE" "skills/$name"
done

# Claude Code falls back to AGENTS.md, so this file is a pointer rather than a second protocol. It is
# created only when the tenant has none: an adapter never edits an instruction file someone wrote.
if [ -e "$TENANT/CLAUDE.md" ]; then
  grep -q 'AGENTS.md' "$TENANT/CLAUDE.md" || say note "CLAUDE.md exists and does not mention AGENTS.md"
  say skip CLAUDE.md
else
  # shellcheck disable=SC2016 # markdown backticks, not command substitution
  printf '%s\n' \
    'Read [AGENTS.md](AGENTS.md) first. It is the entry point for every agent, this one included,' \
    'and it indexes the protocol under `protocol/doctrine/`.' \
    '' \
    'Anything below is true of this tenant alone.' >"$TENANT/CLAUDE.md"
  say write CLAUDE.md
fi

# The hooks are convenience, not control: they stop one command in one tool and say nothing about a
# diff written by another agent, by hand or by an IDE. The pre-commit chain is what binds — see
# doctrine/tenancy.md. `settings-fragment.json` is the one copy of what they are; this writes it
# whole where there is nothing to overwrite, and otherwise names it, because an adapter that merged
# into a file someone wrote would be editing it.
FRAGMENT="$(dirname "${BASH_SOURCE[0]}")/settings-fragment.json"
if [ -e "$TENANT/settings.json" ]; then
  if grep -q 'command-guards.sh' "$TENANT/settings.json"; then
    say skip settings.json
  else
    say note "settings.json exists — add the hooks from $FRAGMENT by hand"
  fi
else
  cp "$FRAGMENT" "$TENANT/settings.json"
  say write settings.json
fi
