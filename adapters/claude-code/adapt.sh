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
# shellcheck disable=SC1091
. "$PROTOCOL/bin/tenant.sh"

# The tenant directory IS the configuration directory, so the agent writes its runtime state into
# the repository. `projects/` is the one that matters: it holds full session transcripts, which carry
# every file read and every command run — the most disclosing artifact this design has to keep out of
# a commit. Ignored before anything else is installed, so a first run cannot stage them.
for line in '/.claude.json' '/.claude.json.backup' '/.credentials.json' '/backups/' '/file-history/' \
            '/history.jsonl' '/projects/' '/sessions/' '/shell-snapshots/' '/statsig/' '/todos/'; do
  ignore "$line"
done

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

# Commands are discovered at <config-dir>/commands/<name>.md, and that layout is flat — one level
# deep, where a skill is two. The link target differs with it: the skills loop above reaches the
# tenant's `protocol` entry through `../../`, and copying that here gives a dangling link — `-e`
# fails it, and `-L` then skips it on every run afterwards.
mkdir -p "$TENANT/commands"
for src in "$PROTOCOL"/adapters/claude-code/commands/*.md; do
  name="$(basename "$src" .md)"
  dst="$TENANT/commands/$name.md"
  if [ -e "$dst" ] || [ -L "$dst" ]; then say skip "commands/$name"; continue; fi
  if [ "$MODE" = copy ]; then cp "$src" "$dst"
  else ln -s "../protocol/adapters/claude-code/commands/$name.md" "$dst"; fi
  say "$MODE" "commands/$name"
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
