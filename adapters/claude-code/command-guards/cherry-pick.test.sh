#!/usr/bin/env bash
# cherry-pick.sh over (command, branch) — denied onto main, and silent about every line that merely
# carries the words.
#   bash adapters/claude-code/command-guards/cherry-pick.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/../../../bin/check.sh"

guard() { bash "$DIR/cherry-pick.sh" "$1" "${2:-}" "${PROTECTED:-}"; }
verdict() { case "$(guard "$1" "${2:-}")" in deny\ *) echo deny ;; ask\ *) echo ask ;; *) echo silent ;; esac; }
# Not `guard | grep`: the guard writes its reason and exits, so a grep that stops at the first line
# leaves it writing into a closed pipe, and under pipefail that SIGPIPE read as a failed check.
says() { case "$(guard "$1" "${2:-}")" in *"$3"*) return 0 ;; esac; return 1; }

check "a cherry-pick onto main is denied" "[ \"\$(verdict 'git cherry-pick abc123' main)\" = deny ]"
check "and the denial says to promote dev whole" "says 'git cherry-pick abc123' main whole"
check "a cherry-pick onto a topic branch is ordinary work" \
  "[ \"\$(verdict 'git cherry-pick abc123' fix/x)\" = silent ]"
check "--continue on main is still landing a commit there" \
  "[ \"\$(verdict 'git cherry-pick --continue' main)\" = deny ]"
check "another git command on main is left alone" "[ \"\$(verdict 'git merge origin/dev' main)\" = silent ]"

# The guard is handed the whole command line, and judging it as a bag of words denied reading this
# guard's own source from a checkout sitting on main, which is where a lot of reading happens.
check "a file whose name carries the words is not a cherry-pick" \
  "[ \"\$(verdict 'cat command-guards/cherry-pick.sh' main)\" = silent ]"
check "nor is a log search for them" "[ \"\$(verdict 'git log --grep=cherry-pick' main)\" = silent ]"
check "but a pick in a later clause is still one" \
  "[ \"\$(verdict 'git fetch origin && git cherry-pick abc123' main)\" = deny ]"
check "and so is one on a line of its own" \
  "[ \"\$(verdict 'git fetch origin
git cherry-pick abc123' main)\" = deny ]"
# A document written from a checkout on main may describe the thing this guard forbids.
check "a heredoc body describing one is not one" \
  "[ \"\$(verdict 'cat > doc.md <<EOF
never: git cherry-pick abc123
EOF' main)\" = silent ]"

# A branch resolves to nothing only where HEAD is detached or the command is not in a repository, and
# neither can land a pick on branch main — so the prompt this used to raise had one possible answer.
check "an unresolved branch is not a prompt" "[ \"\$(verdict 'git cherry-pick abc123' '')\" = silent ]"
check "nor is a detached HEAD" "[ \"\$(verdict 'git cherry-pick abc123' HEAD)\" = silent ]"
check "this guard asks nothing at all" "[ \"\$(verdict 'git cherry-pick abc123' '')\" != ask ]"

# The branch a pick must not land on is a role, not the name `main` — the dispatcher names it as $3.
PROTECTED=release
check "the protected branch is whichever one the dispatcher names" \
  "[ \"\$(verdict 'git cherry-pick abc123' release)\" = deny ]"
check "and the denial names it" "says 'git cherry-pick abc123' release 'onto release'"
check "while main is then an ordinary branch" \
  "[ \"\$(verdict 'git cherry-pick abc123' main)\" = silent ]"
PROTECTED=

finish
