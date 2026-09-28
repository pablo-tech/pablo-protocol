#!/usr/bin/env bash
# doctrine/git.md: never --no-verify, --force or --amend on published commits without asking first.
#
# All three defeat a check rather than pass it: --no-verify skips the whole shared guard chain,
# --amend and --force rewrite what other clones already have. Denied rather than asked, because the
# legitimate case is rare enough to be worth typing the command by hand — and because an `ask` on a
# history rewrite is a yes/no on a question the prompt cannot show enough of to answer.
#
# A flag counts only where it is a flag: in the arguments of the git clause that takes it, and outside
# any quoted string — a message that names a flag, or a grep for one, is not a use of it.
set -uo pipefail
cmd="${1:-}"
case "$cmd" in *git*) ;; *) exit 0 ;; esac
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/clauses.sh"

# Heredoc bodies go first: the quoted-span strip below would eat a `<<'TAG'` delimiter and leave the
# body looking like commands.
bare="$(strip_heredocs "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")"

skip=""
case "$(git_clauses "$bare")" in *--no-verify*) skip=1 ;; esac

# `-n` is the same flag in one character, and short flags bundle, so `git commit -nm x` is it too. Only
# commit's: `git push -n` is a dry run and `git merge -n` is about diffstats.
set -f
for w in $(git_clause_args "$bare" commit); do
  case "$w" in
    --*) ;;
    -*n*) skip=1 ;;
  esac
done
set +f

if [ -n "$skip" ]; then
  echo "deny --no-verify (or its one-letter -n) skips the whole shared pre-commit guard chain — the size,
credentials and tenant guards at once — so it is the one flag that turns
every other mechanism here off. doctrine/git.md says ask first. Fix what the hook objects to, or ask."
  exit 0
fi

# The flag is not the only way off that chain: git reads the hook directory from core.hooksPath, so
# pointing it elsewhere skips the same guards — for one command with `-c`, or for every later one with
# `git config`. `.githooks` is the value `bin/adapt` sets; any other is the bypass.
hooks_off=""
case "$bare" in
  *"-c core.hooksPath=.githooks"*) ;;
  *"-c core.hooksPath="*) hooks_off=1 ;;
esac
case " $(git_clause_args "$bare" config) " in
  *" core.hooksPath .githooks "*) ;;
  *" --unset "*core.hooksPath*|*" core.hooksPath "?*) hooks_off=1 ;;
esac
if [ -n "$hooks_off" ]; then
  echo "deny this points core.hooksPath away from .githooks, which turns off the same shared pre-commit chain
--no-verify does — the size, credentials and tenant guards. Fix what the
hook objects to, or ask."
  exit 0
fi

case " $(git_clause_args "$bare" commit) " in
  *--amend*)
    echo "deny --amend rewrites a commit others may already have. doctrine/git.md says ask first on a published
commit, and a hook cannot tell whether this one is pushed. Add a new commit, or ask."
    exit 0 ;;
esac

case " $(git_clause_args "$bare" push) " in
  *--force-with-lease*|*--force*|*" -f "*)
    echo "deny a force push replaces history other clones already have, and nothing in this protocol overrides
that silently — doctrine/git.md says ask first. --force-with-lease is safer but still a rewrite. Ask, or
land the change as a new commit." ;;
esac
