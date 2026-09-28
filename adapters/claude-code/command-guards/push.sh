#!/usr/bin/env bash
# doctrine/git.md: main takes merges, not commits; a deleted branch is gone. Both are absolute, so this
# guard denies both and says nothing about any other push.
#
# It used to ask on every other push, for "don't push unless asked". That prompt put a question to
# the owner that the guard had already admitted it could not answer — a warp is authorized to push
# and no command string distinguishes one from a stray push — so the answer was always yes and the
# prompt was pure latency (owner decision). "Don't push unless asked" stays a rule the
# session follows, deliberately unmechanized.
#
#   $1 the command, $2 the branch it would act on (the dispatcher resolves it)
set -uo pipefail
cmd="${1:-}"
branch="${2:-}"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/clauses.sh"

args="$(git_clause_args "$cmd" push)" || exit 0
# A destination is a name, and `git push origin "main"` names the same branch as the bare word does —
# so the quote characters go, unlike the quoted spans dangerous-flags.sh drops whole.
args="${args//\"/}"; args="${args//\'/}"

case " $args " in
  *--delete*|*" -d "*|*" :"*)
    echo "deny this push deletes a remote ref. If that branch is not merged, the remote copy is the only one left,
and nothing in this protocol delegates deleting it. Delete it after the merge, by hand."
    exit 0 ;;
esac

# Neither flag names a refspec, so the loop below counts only the remote and the branch the session
# happens to be on decides — which is how a push of every local branch, main included, went unjudged
# from a topic branch.
case " $args " in
  *" --all "*|*" --mirror "*)
    echo "deny this push sends every local branch, main included, whatever branch you are on — and --mirror also
deletes every remote ref this repository does not have. Push the one branch you mean, by name."
    exit 0 ;;
esac

# A refspec names the destination; with none, the destination is the current branch, which the
# command does not say. The destination is what follows the colon when there is one, so a push of
# local `main` somewhere else is not a push to main.
on_main=""
refs=0
set -f
for w in $args; do
  case "$w" in -*) continue ;; esac
  refs=$((refs + 1))
  dest="${w##*:}"; dest="${dest#+}"; dest="${dest#refs/heads/}"
  # HEAD is the branch the session is on, which only the dispatcher knows — and naming it counted as a
  # refspec, so the fallback below stopped applying and `git push origin HEAD` from main went unjudged.
  case "$dest" in HEAD|@) dest="$branch" ;; esac
  [ "$dest" = main ] && on_main=1
done
set +f
[ "$refs" -le 1 ] && [ "$branch" = main ] && on_main=1

if [ -n "$on_main" ]; then
  echo "deny main takes merges here, not commits: a push straight to it is the deploy, skipping the pull request and
every check required on it. Open a pull request from a branch and merge that."
fi
