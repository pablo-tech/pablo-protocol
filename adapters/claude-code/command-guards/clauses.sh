#!/usr/bin/env bash
# A guard is handed the whole command line, and the command it judges is often one clause of several.
# Read as a bag of words that line says things it does not do: `git push -u origin x && gh pr create
# --base main` is not a push to main, `cat cherry-pick.sh` is not a cherry-pick, and a commit whose
# message names a flag is not that flag. Every guard that judges a command asked its own question of
# the whole string until two of them answered wrong.
#
# Sourced by the guards beside it, never dispatched: `git_clauses` and `gh_clauses` print one line per
# clause of that program — the verb, then its arguments — and `git_clause_args` prints one verb's
# arguments, or returns 1 when the line holds no such clause. The verb is the first non-flag word
# after the program, past any flag that takes a value, which is how `git -C <dir> push` reads.
#
# Quoting is not honoured: an argument is whatever whitespace separates, so a quoted string arrives as
# several words and the quote characters stay attached. A guard that must not judge the contents of a
# message strips the quoted spans itself before calling, and one that compares a word to a name strips
# the characters — the over-match is wrong for a flag and right for a destination, so the choice
# belongs to the guard and not here.
set -uo pipefail

# The hook sees the heredoc body too, and since a newline became a clause separator every
# line of it read as a command. A commit message or a document that quotes a command is not that
# command, so the body goes before anything is parsed. An unterminated tag swallows the rest of the
# line, which is the silent direction — nothing after it is judged.
strip_heredocs() { # line
  local line tag="" rest out="" l
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$tag" ]; then
      l="$line"
      while [ "${l#[[:space:]]}" != "$l" ]; do l="${l#[[:space:]]}"; done
      [ "$l" = "$tag" ] && tag=""
      continue
    fi
    out="$out$line
"
    # `<<<` is a here-string, which carries no body and must not be read as an unterminated tag.
    l="${line//<<</ }"
    case "$l" in
      *"<<"*)
        rest="${l#*<<}"; rest="${rest#-}"
        while [ "${rest# }" != "$rest" ]; do rest="${rest# }"; done
        rest="${rest#\"}"; rest="${rest#\'}"
        tag="${rest%%[!A-Za-z0-9_]*}" ;;
    esac
  done <<<"$1"
  printf '%s' "$out"
}

# A subshell's parentheses start and end a command, and inside a quoted span of either kind they are
# literal text — a commit message saying `(again)` is not two commands.
#
# Walked a character at a time this cost 400ms of every hook invocation on a long line, so it jumps
# from quote to quote instead and replaces whole spans at once.
split_commands() { # line
  local rest="$1" out="" seg q
  while :; do
    seg="${rest%%[\"\']*}"
    if [ "$seg" = "$rest" ]; then out="$out${rest//[()]/ ; }"; break; fi
    out="$out${seg//[()]/ ; }"
    rest="${rest#"$seg"}"; q="${rest:0:1}"; rest="${rest:1}"
    seg="${rest%%"$q"*}"
    # A span the line never closes is the rest of it.
    if [ "$seg" = "$rest" ]; then out="$out$q$rest"; break; fi
    rest="${rest#"$seg$q"}"
    out="$out$q$seg$q"
  done
  printf '%s' "$out"
}

clauses() { # line program value-taking-flags
  local w state=out verb="" args="" end line prog="$2" valflags=" ${3:-} " valued
  line="$(strip_heredocs "$1")"
  # A backslash before the newline continues one command rather than ending it, so joining comes
  # first: split as a separator, it left the destination in a clause with no command in it.
  line="${line//\\$'\n'/ }"
  # A newline ends a command as surely as `;` does, and neither it nor the characters below survive
  # the word splitting, so all of them become the separator that does.
  line="${line//$'\n'/ ; }"
  case "$line" in *[\(\)]*) line="$(split_commands "$line")" ;; esac
  set -f
  for w in $line; do
    end=""
    case "$w" in *";") w="${w%;}"; end=1 ;; esac
    case "$state" in
      value) state=prog ;;
      args)
        case "$w" in
          "&&"|"||"|"|"|"&") end=1 ;;
          "") ;;
          *) args="$args $w" ;;
        esac ;;
      *)
        case "$w" in
          "&&"|"||"|"|"|"&"|"") state=out ;;
          "$prog") state=prog ;;
          *)
            valued=""
            [ "$state" = prog ] && case "$valflags" in *" $w "*) valued=1 ;; esac
            if [ -n "$valued" ]; then state=value
            else
              case "$w" in
                -*) ;;
                *)
                  if [ "$state" = prog ]; then verb="$w"; args=""; state=args; else state=out; fi ;;
              esac
            fi ;;
        esac ;;
    esac
    if [ -n "$end" ]; then
      [ -n "$verb" ] && printf '%s%s\n' "$verb" "$args"
      state=out; verb=""; args=""
    fi
  done
  [ -n "$verb" ] && printf '%s%s\n' "$verb" "$args"
  set +f
  return 0
}

clause_args() { # line program value-taking-flags verb
  local clause
  while IFS= read -r clause; do
    case "$clause" in
      "$4"|"$4 "*) printf '%s' "${clause#"$4"}"; return 0 ;;
    esac
  done < <(clauses "$1" "$2" "$3")
  return 1
}

# git takes -C and -c before the verb, each with a value; gh takes nothing before its subcommand.
git_clauses() { clauses "$1" git "-C -c"; }
git_clause_args() { clause_args "$1" git "-C -c" "$2"; }
gh_clauses() { clauses "$1" gh ""; }
