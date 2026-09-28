#!/usr/bin/env bash
# The three flags doctrine/git.md says to ask about first, against command strings.
#   bash adapters/claude-code/command-guards/dangerous-flags.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/../../../bin/check.sh"

guard() { bash "$DIR/dangerous-flags.sh" "$1"; }
denies() { case "$(guard "$1")" in deny\ *) return 0 ;; esac; return 1; }
# Not `guard | grep`: the guard writes its reason and exits, so a grep that stops at the first line
# leaves it writing into a closed pipe, and under pipefail that SIGPIPE read as a failed check.
says() { case "$(guard "$1")" in *"$2"*) return 0 ;; esac; return 1; }

check "--no-verify on a commit is denied" "denies 'git commit --no-verify -m fix'"
check "and the denial says what it turns off" "says 'git commit --no-verify' 'guard chain'"
# --no-verify is not commit's alone: it skips pre-push too, and every guard behind it.
check "--no-verify on a push is denied as well" "denies 'git push --no-verify'"
# The same flag has a one-letter spelling, and short flags bundle — `git commit -nm x` is it too.
check "-n is that flag in one character" "denies 'git commit -n -m x'"
check "and it counts inside a bundle" "denies 'git commit -nm x'"
check "the denial says so" "says 'git commit -n -m x' 'one-letter'"
# Only commit's: the same letter means a dry run to push and a missing diffstat to merge.
check "a dry-run push is not the flag" "! denies 'git push -n origin topic'"
check "nor is a merge asked for no diffstat" "! denies 'git merge -n topic'"
check "nor an ordinary short flag on a commit" "! denies 'git commit -am fix'"
# The same chain is off if git reads its hooks from somewhere else, which no flag announces.
check "pointing core.hooksPath elsewhere for one command is denied" \
  "denies 'git -c core.hooksPath=/dev/null commit -m x'"
check "and setting it there for every later one is too" "denies 'git config core.hooksPath /tmp/none'"
check "as is unsetting it" "denies 'git config --unset core.hooksPath'"
check "and the denial names the directory the chain lives in" \
  "says 'git config core.hooksPath /tmp/none' '.githooks'"
check "the value this protocol sets is ordinary work" "! denies 'git config core.hooksPath .githooks'"
check "reading it is not changing it" "! denies 'git config --get core.hooksPath'"
check "and a search for it is neither" "! denies 'grep -rn core.hooksPath BOOTSTRAP.md'"

check "--amend is denied" "denies 'git commit --amend --no-edit'"
check "a force push is denied" "denies 'git push --force origin topic'"
check "--force-with-lease is still a rewrite, so also denied" "denies 'git push --force-with-lease'"
check "-f is the same flag spelled short" "denies 'git push -f origin topic'"
# `git -C <dir> push` contains neither "git push" nor "push --force" adjacently, and it is how a
# session pushes from outside the checkout — so gating on the literal pair let this through.
check "a force push that names its repository with -C is denied" \
  "denies 'git -C /tmp/repo push --force origin topic'"
check "an ordinary push is not this guard's business" "! denies 'git push origin topic'"
check "nor is an ordinary commit" "! denies 'git commit -m fix'"
# Only git's flags are this guard's; another tool's --force means something else entirely.
check "--force to a tool that is not git is left alone" "! denies 'npm install --force'"

# A flag counts where it is a flag. Reading the line as a bag of words denied searching for one and
# writing a commit message about one, which is work the rule has nothing to say about.
check "a search for the flag is not a use of it" "! denies 'grep -rn -- --no-verify infra/git-hooks/'"
check "nor is a commit message that names it" \
  "! denies \"git commit -m 'stop passing --no-verify in CI'\""
check "nor one that names --amend" "! denies \"git commit -m 'squash instead of --amend'\""
check "a force flag outside a push is not a force push" "! denies 'git log --grep=--force -- scripts/'"
# The clause that carries the flag is the one judged, not the line.
check "a push after an ordinary commit is still judged" "denies 'git commit -m fix && git push --force'"
check "and a commit after an ordinary push is too" "denies 'git push origin topic && git commit --amend'"
check "a clause on a line of its own is judged like any other" \
  "denies 'git add -A
git commit --amend'"

# A body is text, not clauses — and its tag has to survive the quoted-span strip above, which is why
# the body goes first.
# shellcheck disable=SC2034  # both are used inside the eval'd check conditions below.
{
  body=$'git commit -F - <<MSG\nsubject\n\nstop telling people to run git commit --no-verify\nMSG'
  quoted=$'cat > doc.md <<\'EOF\'\nnever: git commit --amend\nEOF'
}
check "a commit body naming a flag is not a use of it" "! denies \"\$body\""
check "nor is a document whose heredoc tag is quoted" "! denies \"\$quoted\""

finish
