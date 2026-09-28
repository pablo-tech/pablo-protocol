#!/usr/bin/env bash
# bin/adapt against a scratch tenant: what it installs, and that a second run installs nothing.
#   bash bin/adapt.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOCOL="$(cd "$DIR/.." && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/check.sh"

# A HOME of its own, so the run cannot touch the real one's well-known path.
adapt() { (cd "$t/tenant" && HOME="$t/home" bash "$DIR/adapt" "$@" 2>&1); }
fresh() {
  rm -rf "${t:?}/tenant" "${t:?}/home"; mkdir -p "$t/home"; git init -q "$t/tenant"
  # The run gets a HOME of its own, so it carries no identity either — without one the commit
  # checks below would fail on that instead of on the hook, and pass whatever the hook did.
  git -C "$t/tenant" config user.email t@example.invalid
  git -C "$t/tenant" config user.name Test
}

fresh
adapt --agent claude-code >/dev/null
check "the protocol is reachable from the tenant root" "[ -d '$t/tenant/protocol/doctrine' ]"
check "the protocol entry is gitignored, being a machine-local path" "grep -qx '/protocol' '$t/tenant/.gitignore'"
check "the tenant gets an AGENTS.md to fill in" "[ -f '$t/tenant/AGENTS.md' ]"
check "the tenant gets a denylist to fill in" "[ -f '$t/tenant/.protocol/tenant' ]"
check "the pre-commit shim is installed and executable" "[ -x '$t/tenant/.githooks/pre-commit' ]"
check "git is pointed at it, which a clone does not carry" "[ \"\$(git -C '$t/tenant' config --get core.hooksPath)\" = .githooks ]"
check "the well-known path resolves to this checkout" "[ \"\$(readlink -f '$t/home/.pablo-protocol')\" = '$PROTOCOL' ]"

check "every doctrine file is offered as a skill" \
  "[ \"\$(ls '$t/tenant/skills' | wc -l)\" = \"\$(ls '$PROTOCOL/doctrine' | wc -l)\" ]"
check "a skill is a symlink to the doctrine file, not a second copy" "[ -L '$t/tenant/skills/warp/SKILL.md' ]"
check "that symlink resolves through the tenant's own protocol entry" \
  "[ \"\$(readlink -f '$t/tenant/skills/warp/SKILL.md')\" = '$PROTOCOL/doctrine/warp.md' ]"
check "an agent with no instruction file of its own is pointed at AGENTS.md" \
  "grep -q AGENTS.md '$t/tenant/CLAUDE.md'"
check "the command guards are registered as hooks" \
  "grep -q command-guards.sh '$t/tenant/settings.json'"
# The tenant directory is also the agent's configuration directory, so the agent writes its own state
# into the repository. A session transcript records every file read and command run; committing one
# would hand over more than any file the guards read.
mkdir -p "$t/tenant/projects/x"
printf 'transcript\n' >"$t/tenant/projects/x/session.jsonl"
printf 'token\n' >"$t/tenant/.credentials.json"
git -C "$t/tenant" add -A 2>/dev/null
check "the agent's own transcripts and credentials cannot be staged" \
  "[ -z \"\$(git -C '$t/tenant' diff --cached --name-only | grep -E '^(projects/|\\.credentials)')\" ]"
git -C "$t/tenant" reset -q

# shellcheck disable=SC2034 # read inside the check expression below, which shellcheck does not follow
again="$(adapt --agent claude-code)"
check "a second run changes nothing" "! grep -qE '^  (link|copy|seed|write|ignore|config) ' <<<\"\$again\""

# A tenant that already refuses a path in a spelling of its own has answered the question, and an
# ignore rule appended underneath wins as the last matching pattern — so a broader one silently
# undoes the exception the tenant deliberately keeps.
fresh
printf 'projects/*/*\n!projects/*/memory/\n!projects/*/memory/*.md\n' >"$t/tenant/.gitignore"
adapt --agent claude-code >/dev/null
mkdir -p "$t/tenant/projects/p/memory"
printf 'a note\n' >"$t/tenant/projects/p/memory/note.md"
printf 'transcript\n' >"$t/tenant/projects/p/session.jsonl"
git -C "$t/tenant" add -A 2>/dev/null
check "an exception the tenant carved out survives the adapter's own ignore rules" \
  "git -C '$t/tenant' diff --cached --name-only | grep -qx 'projects/p/memory/note.md' &&
   ! git -C '$t/tenant' diff --cached --name-only | grep -q session.jsonl"
git -C "$t/tenant" reset -q

fresh
printf 'my own rules\n' >"$t/tenant/CLAUDE.md"
printf '{"permissions":{}}\n' >"$t/tenant/settings.json"
# shellcheck disable=SC2034 # as above
out="$(adapt --agent claude-code)"
check "an instruction file the tenant already wrote is never edited" \
  "[ \"\$(cat '$t/tenant/CLAUDE.md')\" = 'my own rules' ]"
# Merging into it would be editing it, so the adapter says what is missing and stops.
check "nor is a settings file, which is named rather than merged into" \
  "[ \"\$(cat '$t/tenant/settings.json')\" = '{\"permissions\":{}}' ] &&
   grep -q 'settings.json exists' <<<\"\$out\""

fresh
adapt --copy --agent claude-code >/dev/null
check "--copy leaves no symlink for a machine that will not follow one" \
  "[ -z \"\$(find '$t/tenant' -type l -not -path '*/.git/*')\" ] &&
   [ -f '$t/tenant/skills/warp/SKILL.md' ]"

fresh
adapt >/dev/null
check "a machine with no adapter still gets the protocol" \
  "[ -f '$t/tenant/AGENTS.md' ] && [ -d '$t/tenant/protocol/doctrine' ]"

check "the protocol repository refuses to be its own tenant" \
  "! (cd '$PROTOCOL' && HOME='$t/home' bash '$DIR/adapt' >/dev/null 2>&1)"

# End to end: the shim adapt installed, resolving the guards through the well-known path, running
# the chain against a real commit. Every link between bin/adapt and guards/tenant-guard.sh at once.
fresh
adapt >/dev/null
commit() { (cd "$t/tenant" && HOME="$t/home" git commit -qm x >/dev/null 2>&1); }
printf 'Initech\n' >"$t/tenant/.protocol/tenant"
printf 'the deploy is green\n' >"$t/tenant/notes.md"
git -C "$t/tenant" add -A
check "the installed hook chain lets a clean commit through" "commit"
printf 'met with Initech about the migration\n' >"$t/tenant/notes.md"
git -C "$t/tenant" add -A
check "the installed hook chain refuses another tenant's material" "! commit"

finish
