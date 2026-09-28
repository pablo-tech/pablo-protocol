#!/usr/bin/env bash
# The dispatcher: what it reads from stdin, what it emits, and that it fails closed rather than open.
#   bash adapters/claude-code/command-guards.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../../bin/check.sh"

payload() { jq -cn --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}'; }
# Run the hook the way the harness does — payload on stdin — from a repository on a known branch, so
# the branch the dispatcher resolves is the test's choice rather than wherever the suite was started.
hook() { (cd "${2:-$t/topic}" && payload "$1" | bash "$DIR/command-guards.sh"); }
field() { jq -r ".hookSpecificOutput.$1 // \"\"" 2>/dev/null; }
decision() { hook "$@" | field permissionDecision; }
# `| grep -q` stops reading at the first match, leaving the producer writing into a closed pipe — and
# under pipefail that SIGPIPE read as a failed check, at random, a few runs in a hundred.
has() { case "$2" in *"$1"*) return 0 ;; esac; return 1; }

# A commit, because `symbolic-ref` is asked for the branch and an unborn one answers nothing.
for branch in topic main; do
  git init -q -b "$branch" "$t/$branch"
  git -C "$t/$branch" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
done

check "a guard's denial comes back as a PreToolUse deny" "[ \"\$(decision 'git push --force')\" = deny ]"
check "with the guard's own reason, not the dispatcher's" \
  "has 'force push' \"\$(hook 'git push --force' | field permissionDecisionReason)\""
check "the event name is the one the harness matches on" \
  "[ \"\$(hook 'git push --force' | field hookEventName)\" = PreToolUse ]"
check "a command no guard objects to gets no output at all" "[ -z \"\$(hook 'ls -la')\" ]"
# Two guards need the branch and the command never says it, so the dispatcher resolves it once and
# passes it in — which is the only reason a bare `git push` can be judged at all.
check "the branch the command acts on is resolved from the repository, not the command" \
  "[ \"\$(decision 'git push' \"\$t/main\")\" = deny ] && [ -z \"\$(hook 'git push' \"\$t/topic\")\" ]"
check "and from the -C path when the command names one" \
  "[ \"\$(decision \"git -C \$t/main cherry-pick abc123\" \"\$t/topic\")\" = deny ]"
# A guarded command quoted inside some other tool's input is text, not a command.
check "a tool that is not Bash is not this hook's business" \
  "[ -z \"\$(jq -cn '{tool_name: \"Write\", tool_input: {content: \"git push --force\"}}' | bash '$DIR/command-guards.sh')\" ]"

# The whole chain, over the command lines a session actually types. Each guard's own suite pins its
# rule; this battery is the audit that found the rules right and the reading of the line wrong — a
# push to main hidden inside a subshell went unjudged, and a document that merely described one was
# denied. It is deliberately not exhaustive about what a shell can do: a command inside a quoted
# string handed to another shell (`bash -c "git push origin main"`, `eval`) is still text here.
verdict() { local d; d="$(decision "$@")"; printf '%s' "${d:-silent}"; }

check "a push to main is denied" "[ \"\$(verdict 'git push origin main')\" = deny ]"
check "quoting the branch does not make it another one" \
  "[ \"\$(verdict 'git push origin \"main\"')\" = deny ]"
check "nor does spelling the ref out" \
  "[ \"\$(verdict 'git push origin refs/heads/main')\" = deny ]"
check "or sending HEAD to it" \
  "[ \"\$(verdict 'git push origin HEAD:refs/heads/main')\" = deny ]"
check "or naming HEAD from a main checkout" \
  "[ \"\$(verdict 'git push origin HEAD' \"\$t/main\")\" = deny ]"
check "a hook directory pointed at nothing is the guard chain turned off" \
  "[ \"\$(verdict 'git -c core.hooksPath=/dev/null commit -m x')\" = deny ]"
check "a subshell is still this shell's business" \
  "[ \"\$(verdict '(git push origin main)')\" = deny ]"
check "including one entered by cd" \
  "[ \"\$(verdict 'cd /tmp && (cd repo; git push origin main)')\" = deny ]"
# The branch is resolved before the line runs, so a line that moves first was judged against where the
# session started — and `git checkout main && git push` pushed main from a topic branch unjudged.
check "a checkout earlier in the line is the branch the push acts on" \
  "[ \"\$(verdict 'git checkout main && git push')\" = deny ]"
check "switch is the same move by its other name" \
  "[ \"\$(verdict 'git switch main && git cherry-pick abc123')\" = deny ]"
check "and so is moving into a checkout that is on main" \
  "[ \"\$(verdict \"cd \$t/main && git push\")\" = deny ]"
check "pushd moves the same way cd does" \
  "[ \"\$(verdict \"pushd \$t/main && git push\")\" = deny ]"
# Two -C paths in one line were read from the last alone, so which repository got judged depended on
# the order they were written in.
check "a -C onto main counts wherever in the line it is" \
  "[ \"\$(verdict \"git -C \$t/main push origin && git -C \$t/topic log -1\")\" = deny ]"
check "restoring a path out of main is not moving onto it" \
  "[ \"\$(verdict 'git checkout main -- README.md && git push')\" = silent ]"

check "an ordinary push is silent" "[ \"\$(verdict 'git push -u origin fix/x')\" = silent ]"
check "a commit message naming the denied push is not one" \
  "[ \"\$(verdict 'git commit -m \"note: git push origin main is denied\"')\" = silent ]"
check "nor is a commit body that names it" \
  "[ \"\$(verdict 'git commit -F - <<MSG
subject

body mentions git push origin main
MSG')\" = silent ]"
check "nor a document written about it" \
  "[ \"\$(verdict 'cat > doc.md <<EOF
To ship: git push origin main
EOF')\" = silent ]"

# Stubs, for the failures a real guard cannot be made to have. The names come from the dispatcher
# itself rather than a second copy of the list — the list drifting is one of the things this pins.
guard_names() { sed -n 's/^GUARDS="\(.*\)"$/\1/p' "$DIR/command-guards.sh"; }
stubs() {
  rm -rf "$t/g" && mkdir -p "$t/g"
  for g in $(guard_names); do printf '#!/usr/bin/env bash\nexit 0\n' >"$t/g/$g"; chmod +x "$t/g/$g"; done
}
stubbed() { (cd "$t/topic" && payload "$1" | PROTOCOL_COMMAND_GUARDS="$t/g" bash "$DIR/command-guards.sh"); }

check "the dispatcher names guards that exist and are executable" \
  "[ -n \"\$(guard_names)\" ] && for g in \$(guard_names); do [ -x '$DIR/command-guards/'\$g ] || exit 1; done"
stubs
check "a full set of silent guards says nothing" "[ -z \"\$(stubbed 'git push --force')\" ]"
# Fail closed, like guards.sh: a chain that cannot run is not a chain that approves.
stubs && rm "$t/g/push.sh"
check "a missing guard denies, whatever the command was" \
  "[ \"\$(stubbed 'ls -la' | field permissionDecision)\" = deny ]"
stubs && chmod -x "$t/g/push.sh"
check "so does one that is not executable" "[ \"\$(stubbed 'ls -la' | field permissionDecision)\" = deny ]"
stubs && printf '#!/usr/bin/env bash\nexit 3\n' >"$t/g/push.sh"
check "and one that fails while deciding" "[ \"\$(stubbed 'ls -la' | field permissionDecision)\" = deny ]"
stubs && printf '#!/usr/bin/env bash\necho maybe\n' >"$t/g/push.sh"
check "a verdict the dispatcher cannot read denies rather than being ignored" \
  "[ \"\$(stubbed 'ls -la' | field permissionDecision)\" = deny ]"
stubs && printf '#!/usr/bin/env bash\necho "ask something only the owner can answer"\n' >"$t/g/push.sh"
check "a guard's ask comes back as an ask, not a deny" \
  "[ \"\$(stubbed 'ls -la' | field permissionDecision)\" = ask ]"
# The harness takes one decision, so the order in GUARDS is the precedence: the first opinion wins.
stubs
printf '#!/usr/bin/env bash\necho "deny first opinion"\n' >"$t/g/dangerous-flags.sh"
printf '#!/usr/bin/env bash\necho "deny second opinion"\n' >"$t/g/push.sh"
check "the first guard with an opinion is the one that answers" \
  "has 'first opinion' \"\$(stubbed 'git push --force' | field permissionDecisionReason)\""

# Without jq the payload cannot be parsed at all, so the raw bytes are all there is. A substring test
# over them can over-match and never under-match, which is the side of that error to be on.
mkdir -p "$t/nojq"
for tool in bash cat sed git dirname head; do ln -sf "$(command -v $tool)" "$t/nojq/$tool"; done
nojq() { (cd "$t/topic" && payload "$1" | PATH="$t/nojq" bash "$DIR/command-guards.sh"); }
check "with no jq on the hook PATH a guarded command is denied" \
  "[ \"\$(nojq 'git push --force' | field permissionDecision)\" = deny ]"
check "and the reason survives the emitter that has no jq to escape with" \
  "has 'jq is not on this hook PATH' \"\$(nojq 'git push --force' | field permissionDecisionReason)\""
check "an unrelated command is untouched even then" "[ -z \"\$(nojq 'ls -la')\" ]"

unparseable() { (cd "$t/topic" && printf '%s' "$1" | bash "$DIR/command-guards.sh"); }
check "a payload that is not JSON is denied when it mentions something guarded" \
  "[ \"\$(unparseable 'not json at all: git push --force' | field permissionDecision)\" = deny ]"
check "and lets anything else through" "[ -z \"\$(unparseable 'not json at all: ls -la')\" ]"

# A dispatcher no adapter installs is decoration, and the fragment is the only copy of what is
# installed — so it is the fragment this asks, not a settings.json some tenant may have edited.
check "the settings fragment runs this dispatcher as its Bash PreToolUse hook" \
  "jq -e '.hooks.PreToolUse[] | select(.matcher == \"Bash\") | .hooks[]
    | select(.command | contains(\"command-guards.sh\"))' '$DIR/settings-fragment.json' >/dev/null"
check "and turn-cost on Stop" \
  "jq -e '.hooks.Stop[].hooks[] | select(.command | contains(\"turn-cost.sh\"))' \
    '$DIR/settings-fragment.json' >/dev/null"

finish
