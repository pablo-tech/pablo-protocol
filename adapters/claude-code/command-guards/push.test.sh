#!/usr/bin/env bash
# push.sh over (command, branch) — the two pushes that are denied, and the silence everything else gets.
#   bash adapters/claude-code/command-guards/push.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/../../../bin/check.sh"

guard() { bash "$DIR/push.sh" "$1" "${2:-}" "${PROTECTED:-}"; }
verdict() { case "$(guard "$1" "${2:-}")" in deny\ *) echo deny ;; ask\ *) echo ask ;; *) echo silent ;; esac; }
# Not `guard | grep`: the guard writes its reason and exits, so a grep that stops at the first line
# leaves it writing into a closed pipe, and under pipefail that SIGPIPE read as a failed check.
says() { case "$(guard "$1" "${2:-}")" in *"$3"*) return 0 ;; esac; return 1; }

check "a push that deletes a remote ref is denied" "[ \"\$(verdict 'git push --delete origin topic' topic)\" = deny ]"
check "spelled -d" "[ \"\$(verdict 'git push -d origin topic' topic)\" = deny ]"
check "or as an empty source refspec" "[ \"\$(verdict 'git push origin :topic' topic)\" = deny ]"
check "and the denial says the remote copy may be the only one" \
  "says 'git push -d origin topic' topic 'only one left'"

check "a push whose destination is main is denied" "[ \"\$(verdict 'git push origin main' topic)\" = deny ]"
check "including through an explicit refspec" "[ \"\$(verdict 'git push origin HEAD:main' topic)\" = deny ]"
# With no refspec the destination is the current branch, which the command never says — so the
# branch the dispatcher resolved is the only thing that can answer.
check "a bare push from a main checkout is denied" "[ \"\$(verdict 'git push' main)\" = deny ]"
check "as is one naming only the remote" "[ \"\$(verdict 'git push origin' main)\" = deny ]"
check "and the denial says main takes merges" "says 'git push' main 'takes merges'"
# HEAD is a refspec, so it silenced the fallback below, and it is not the string main — but from main
# it lands on refs/heads/main like the bare push does.
check "a bare HEAD refspec from main is a push to main" \
  "[ \"\$(verdict 'git push origin HEAD' main)\" = deny ]"
check "and @ is HEAD spelled shorter" "[ \"\$(verdict 'git push origin @' main)\" = deny ]"
check "from a topic branch the same command is ordinary" \
  "[ \"\$(verdict 'git push origin HEAD' fix/x)\" = silent ]"

# Neither flag names a branch, so nothing in the command says main is among what it sends — and from
# a topic branch that read as an ordinary push.
check "a push of every local branch is denied wherever it is run" \
  "[ \"\$(verdict 'git push --all origin' topic)\" = deny ]"
check "so is one that mirrors the repository" "[ \"\$(verdict 'git push --mirror origin' topic)\" = deny ]"
check "and the denial says main goes with it" "says 'git push --all origin' topic 'main included'"
# Tags are not branches, and a flag in another clause belongs to that clause.
check "a push of tags is not a push of branches" "[ \"\$(verdict 'git push origin --tags' topic)\" = silent ]"
check "nor is a log that reads every ref" \
  "[ \"\$(verdict 'git push origin fix/x && git log --all' fix/x)\" = silent ]"

# A branch whose name merely starts with main is a different branch.
check "a branch named mainline is not main" "[ \"\$(verdict 'git push origin mainline' topic)\" = silent ]"

# Every other push is this guard's business only insofar as it is not one of the two above: the
# prompt it used to raise asked a question the guard could not answer, so it asks nothing now.
check "an ordinary push is left alone" "[ \"\$(verdict 'git push -u origin fix/x' fix/x)\" = silent ]"
check "including one with a full refspec" "[ \"\$(verdict 'git push origin fix/x:fix/x' fix/x)\" = silent ]"
check "and one from a branch this guard was given" "[ \"\$(verdict 'git push' fix/x)\" = silent ]"
check "no push produces a prompt" "[ \"\$(verdict 'git push -u origin fix/x' fix/x)\" != ask ]"
check "a push that names its repository with -C is judged like any other" \
  "[ \"\$(verdict 'git -C /tmp/repo push' main)\" = deny ]"
check "a command that is not a push is left alone" "[ \"\$(verdict 'git commit -m fix' main)\" = silent ]"

# The guard is handed the whole command line, and reading it as a bag of words denied the ordinary
# way a branch is shipped — push it, then open the pull request that names main as its base.
check "a clause after the push does not judge it" \
  "[ \"\$(verdict 'git push -u origin fix/x && gh pr create --base main' fix/x)\" = silent ]"
check "nor does a branch deleted afterwards" \
  "[ \"\$(verdict 'git push origin fix/x && git branch -d old' fix/x)\" = silent ]"
check "a path that merely contains push is not one" \
  "[ \"\$(verdict 'git worktree add -b warp/push-guard wt origin/main' fix/x)\" = silent ]"
check "and one on a line of its own is a clause like any other" \
  "[ \"\$(verdict 'git fetch origin
git push origin main' fix/x)\" = deny ]"
check "but a push to main is denied whatever follows" \
  "[ \"\$(verdict 'git push origin main && echo done' fix/x)\" = deny ]"
# The destination is what follows the colon: this one lands on release.
check "local main sent to another branch is not it" \
  "[ \"\$(verdict 'git push origin main:release' main)\" = silent ]"

# A quoted branch is the same branch, and the parser hands the quote characters along with it.
check "a quoted destination is the destination" \
  "[ \"\$(verdict 'git push origin \"main\"' topic)\" = deny ]"
check "including inside a refspec" \
  "[ \"\$(verdict \"git push origin 'HEAD:main'\" topic)\" = deny ]"
check "and a quoted deletion is still a deletion" \
  "[ \"\$(verdict 'git push origin \":topic\"' topic)\" = deny ]"

# The hook sees the heredoc body, and a message that describes a push is not one.
check "a commit message body naming a push to main is not a push" \
  "[ \"\$(verdict 'git commit -F - <<MSG
subject

body mentions git push origin main
MSG' fix/x)\" = silent ]"

# The branch that takes merges is a role, not the name `main`. The dispatcher resolves the name once
# and hands it down as $3, so this guard has no literal to be wrong about.
PROTECTED=release
check "the protected branch is whichever one the dispatcher names" \
  "[ \"\$(verdict 'git push origin release' topic)\" = deny ]"
check "and the denial names it" "says 'git push origin release' topic 'release takes merges'"
check "while main is then an ordinary branch" \
  "[ \"\$(verdict 'git push origin main' topic)\" = silent ]"
check "a bare push from it is still the deploy" "[ \"\$(verdict 'git push' release)\" = deny ]"
PROTECTED=

finish
