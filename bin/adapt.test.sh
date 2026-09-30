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
# Empty as it is seeded, so it polices nothing until somebody fills it in. A tenant that never
# does is exactly where it was before the file existed, which is what makes seeding it safe.
check "and an identity allowlist, which claims nobody until it is filled in" \
  "[ -f '$t/tenant/.protocol/identity' ] &&
   [ -z \"\$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' '$t/tenant/.protocol/identity')\" ]"
check "the pre-commit shim is installed and executable" "[ -x '$t/tenant/.githooks/pre-commit' ]"
check "git is pointed at it, which a clone does not carry" "[ \"\$(git -C '$t/tenant' config --get core.hooksPath)\" = .githooks ]"
check "the well-known path resolves to this checkout" "[ \"\$(readlink -f '$t/home/.pablo-protocol')\" = '$PROTOCOL' ]"
# And is reported as ~/..., which it was not. An unquoted ~ in the replacement half of
# ${var/pat/repl} is tilde-expanded back to $HOME, so the one line written to shorten a home path
# printed it in full; quoting the ~ fixed that from bash 4 on and printed '~'/... under the 3.2
# macOS ships, which is why neither form survives here.
check "and is reported under ~, not as somebody's absolute home" \
  "grep -qE '^  (link|skip) +~/\\.pablo-protocol$' <<<\"\$(adapt)\""

# The directory's own index is written for a person and carries none of the frontmatter a SKILL.md
# needs, so a skill wired from it would install once and be unreadable to the loader ever after.
wired=0
for f in "$PROTOCOL"/doctrine/*.md; do [ "${f##*/}" = README.md ] || wired=$((wired+1)); done
check "every doctrine file is offered as a skill" \
  "[ \$(ls '$t/tenant/skills' | wc -l) -eq $wired ]"
check "but the index beside them is not, not being a doctrine document" \
  "[ ! -e '$t/tenant/skills/README' ] && [ ! -L '$t/tenant/skills/README' ]"
check "a skill is a symlink to the doctrine file, not a second copy" "[ -L '$t/tenant/skills/warp/SKILL.md' ]"
check "that symlink resolves through the tenant's own protocol entry" \
  "[ \"\$(readlink -f '$t/tenant/skills/warp/SKILL.md')\" = '$PROTOCOL/doctrine/warp.md' ]"
# The commands layout is flat where the skills one is nested, so the link target is one level
# shallower. Copying the skills loop's `../../` gives a dangling link, which `-e` fails and `-L`
# then skips forever — the install would report `link` once and never be readable.
cmds="$PROTOCOL/adapters/claude-code/commands"
check "every command the adapter carries is offered" \
  "[ \$(ls '$t/tenant/commands' | wc -l) -eq \$(ls '$cmds' | wc -l) ]"
check "a command is a symlink, not a second copy" "[ -L '$t/tenant/commands/turn-cost.md' ]"
check "and it resolves through the tenant's own protocol entry" \
  "[ \"\$(readlink -f '$t/tenant/commands/turn-cost.md')\" = \\
    '$PROTOCOL/adapters/claude-code/commands/turn-cost.md' ]"
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
# The untracked half of a policy file (§3). It holds the names the tenant must enforce and must not
# publish, so staging it is the one mistake that undoes the whole reason it is a separate file.
printf 'Initech\n' >"$t/tenant/.protocol/tenant.local"
# The second artifact of that kind rather than mere noise: the agent syncs the account's copy of the
# bundled skills into a directory named after the account and the organization, beside the skills
# this adapter installs. Which is why the rule is `/skills/synced/` — a rule on `/skills/` would take
# the tracked symlinks with it, and this pair is what says so.
mkdir -p "$t/tenant/skills/synced/acct1234_org5678/.staging"
printf '{}\n' >"$t/tenant/skills/synced/acct1234_org5678/manifest.json"
git -C "$t/tenant" add -A 2>/dev/null
check "the agent's own transcripts and credentials cannot be staged" \
  "[ -z \"\$(git -C '$t/tenant' diff --cached --name-only | grep -E '^(projects/|\\.credentials)')\" ]"
check "nor can a policy file's untracked overlay" \
  "[ -z \"\$(git -C '$t/tenant' diff --cached --name-only | grep 'tenant\\.local')\" ]"
check "nor the skills the account syncs, while the ones installed here still stage" \
  "[ -z \"\$(git -C '$t/tenant' diff --cached --name-only | grep 'skills/synced')\" ] &&
   git -C '$t/tenant' diff --cached --name-only | grep -qx 'skills/warp/SKILL.md'"
git -C "$t/tenant" reset -q

# The rest of what the agent writes as it runs. Each of these was found by reading `git status` in a
# tenant and patched into that one tenant's .gitignore, which left the next tenant to find it again.
for pattern in /cache/ /plans/ /plugins/ /policy-limits.json '/*.stamp.json' /tasks/; do
  check "the agent's $pattern is ignored" "grep -qxF -- '$pattern' '$t/tenant/.gitignore'"
done
# The agent writes into its settings file at runtime — a theme chosen in a session lands there — so a
# personal preference would otherwise arrive as a diff in a file every machine of this tenant shares.
check "the settings the agent writes into are machine-local, both files" \
  "grep -qx '/settings.json' '$t/tenant/.gitignore' &&
   grep -qx '/settings.local.json' '$t/tenant/.gitignore'"

# Every file in the tenant, hashed: `record` below rewrites rather than skips, so "a second run
# changes nothing" stopped being readable off the output alone and is measured instead.
digest() { find "$t/tenant" -name .git -prune -o -type f -print0 | sort -z | xargs -0 -r sha256sum | sha256sum; }
# shellcheck disable=SC2034 # read inside the check expressions below, which shellcheck does not follow
before="$(digest)"
# shellcheck disable=SC2034 # as above
again="$(adapt --agent claude-code)"
check "a second run installs nothing" \
  "! grep -qE '^  (link|copy|seed|write|ignore|config|strip) ' <<<\"\$again\""
# `record` is deliberately not in that list: the receipt is rewritten on every run, because one that
# states an install other than the last is the drift it exists to report. What keeps the run
# idempotent is that every field it writes is read out of the protocol checkout, so the same commit
# writes the same bytes — which is the thing worth asserting, and is asserted.
check "and leaves every file in the tenant byte for byte as it was" \
  "[ \"\$(digest)\" = \"\$before\" ]"

# The receipt. `protocol/` is a symlink, so the checkout behind it can be moved on with no file in
# the tenant changing; what is written down is which commit the files installed here came from, and
# bin/doctor reads it back. What is asserted here is that the installer records the checkout it ran
# out of, rather than anything a reader typed.
fresh
ref="$(git -C "$PROTOCOL" symbolic-ref --short -q HEAD 2>/dev/null \
  || git -C "$PROTOCOL" describe --tags --exact-match 2>/dev/null \
  || git -C "$PROTOCOL" rev-parse --short HEAD)"
# shellcheck disable=SC2034 # as above
want="$ref $(git -C "$PROTOCOL" rev-parse --short HEAD) $(git -C "$PROTOCOL" log -1 --format=%as)"
receipt() { sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$t/tenant/.protocol/protocol-version"; }
adapt >/dev/null
check "the tenant gets the receipt file, seeded from the template" \
  "[ -f '$t/tenant/.protocol/protocol-version' ]"
check "and the install writes the ref, commit and date it installed from" \
  "[ \"\$(receipt)\" = \"\$want\" ]"
# The seed's header is what tells the next reader not to edit the line under it, so the rewrite keeps
# it. A `>` that took the whole file would delete the instructions on its first run.
check "under the header the template carries, which the rewrite keeps" \
  "[ \"\$(head -1 '$t/tenant/.protocol/protocol-version' | cut -c1)\" = '#' ]"
# Unlike every other file here, which is written once and skipped forever: a hand-edited line claims
# an install that never happened, and there is no reading of this file under which that is true.
printf '%s\n' 'v0.0.1' >"$t/tenant/.protocol/protocol-version"
adapt >/dev/null
check "a line edited by hand is overwritten, not kept" "[ \"\$(receipt)\" = \"\$want\" ]"
# And says which line it wrote. `skip <path>` is printed for this file by the seed, so a second word
# for the same path would read as the installer repeating itself rather than as two separate answers.
check "the receipt it wrote is named, not reported as another skipped file" \
  "grep -qE '^  record +[^ ]+ +[0-9a-f]{7,} +[0-9]{4}-[0-9]{2}-[0-9]{2}$' <<<\"\$(adapt)\""
check "so no path is reported skipped twice in one run" \
  "[ \"\$(adapt | awk '\$1 == \"skip\"' | sort | uniq -d)\" = '' ]"

# `.git` is a file, not a directory, in a worktree. Testing for a directory left the shim installed
# and nothing pointed at it — the one failure mode where every file is present and no guard runs.
fresh
git -C "$t/tenant" commit -q --allow-empty -m x
git -C "$t/tenant" worktree add -q -b w "$t/wt" >/dev/null 2>&1
HOME="$t/home" bash "$DIR/adapt" --into "$t/wt" >/dev/null 2>&1
check "a tenant whose .git is a file is still pointed at its hooks" \
  "[ -f '$t/wt/.git' ] && [ \"\$(git -C '$t/wt' config --get core.hooksPath)\" = .githooks ]"

# The second agent, and the reason the ignore rules arrive as a set: its two runtime paths share a
# first segment, and the second of them is the file holding an account name and a key path.
fresh
adapt --agent cortex >/dev/null
check "the tenant gets a configuration directory of its own for the second agent" \
  "[ -f '$t/tenant/.agents/cortex/cortex/settings.json' ]"
check "and a launcher that points the agent at it, executable" \
  "[ -x '$t/tenant/.agents/cortex/run' ]"
# Copied whole and never edited on the way in: it is a tracked file of this repository, so the sweep
# that shellchecks every file with a shebang sees the thing the tenant actually runs, and
# `bin/doctor` can tell an old install's launcher from the current one by comparing them.
check "identical to the one this repository ships, byte for byte" \
  "cmp -s '$DIR/../adapters/cortex/run' '$t/tenant/.agents/cortex/run'"
check "its logs are ignored" "grep -qx '/.agents/\*/cortex/logs/' '$t/tenant/.gitignore'"
check "and so is the connection file beside them, which names an account and a key path" \
  "grep -qx '/.agents/\*/connections.toml' '$t/tenant/.gitignore'"
# shellcheck disable=SC2034 # as above
twice="$(adapt --agent cortex)"
check "a second run of that adapter changes nothing either" \
  "! grep -qE '^  (link|copy|seed|write|ignore|config|strip) ' <<<\"\$twice\""
printf 'account = "x"\n' >"$t/tenant/.agents/cortex/connections.toml"
git -C "$t/tenant" add -A 2>/dev/null
check "so a git add -A cannot stage it" \
  "[ -z \"\$(git -C '$t/tenant' diff --cached --name-only | grep connections.toml)\" ]"
git -C "$t/tenant" reset -q

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

# Ignoring that file is the adapter's answer to the agent writing into it, not a rule about what a
# tenant may share. A tenant that tracks it has answered for itself, and an ignore rule appended
# under a tracked file is inert anyway — a line that says something untrue about the tree.
fresh
printf '{"permissions":{}}\n' >"$t/tenant/settings.json"
git -C "$t/tenant" add settings.json
adapt --agent claude-code >/dev/null
check "a settings file the tenant tracks is left tracked, with no rule appended about it" \
  "! grep -qx '/settings.json' '$t/tenant/.gitignore'"
check "and the local overlay beside it is ignored regardless" \
  "grep -qx '/settings.local.json' '$t/tenant/.gitignore'"

fresh
adapt --copy --agent claude-code >/dev/null
check "--copy leaves no symlink for a machine that will not follow one" \
  "[ -z \"\$(find '$t/tenant' -type l -not -path '*/.git/*')\" ] &&
   [ -f '$t/tenant/skills/warp/SKILL.md' ] && [ -f '$t/tenant/commands/turn-cost.md' ]"

fresh
adapt >/dev/null
check "a machine with no adapter still gets the protocol" \
  "[ -f '$t/tenant/AGENTS.md' ] && [ -d '$t/tenant/protocol/doctrine' ]"

check "the protocol repository refuses to be its own tenant" \
  "! (cd '$PROTOCOL' && HOME='$t/home' bash '$DIR/adapt' >/dev/null 2>&1)"

# The help block is the only documentation of the flags, and it ended at a line number until the
# block grew past it and --help started printing the script's own source.
check "--help prints the header and stops there" \
  "! bash '$DIR/adapt' --help | grep -q 'set -euo'"

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
