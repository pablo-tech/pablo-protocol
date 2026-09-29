#!/usr/bin/env bash
# The one PreToolUse hook for Bash. It reads the payload once, extracts the command, and asks each
# guard beside it in turn; the first guard with an opinion decides.
#
# Same shape as guards/guards.sh, and for the same reason: a rule that belongs to one
# command gets one small file named after it, and the plumbing every rule shares — reading stdin,
# needing jq, emitting the hook's JSON — is written once here. A guard is a pure function of the
# command string: it takes the command as $1 and prints `deny <reason>`, `ask <reason>`, or nothing.
#
# `deny` vs `ask` is a judgement each guard makes, not a default: deny what no tenant overrides, ask
# where the command alone cannot say whether the rule applies — push.sh does both.
set -uo pipefail
# Overridable for the same reason guards.sh takes PROTOCOL_GUARDS: a suite has to be able to point
# this at a directory of stubs to exercise what happens when a guard is missing or answers nonsense.
DIR="${PROTOCOL_COMMAND_GUARDS:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/command-guards}"
GUARDS="dangerous-flags.sh push.sh cherry-pick.sh"
# The branch that takes merges rather than commits, passed to every guard as $3. `main` is the
# usual name for it and the default; a tenant whose deploy branch is called something else sets
# this rather than editing a guard, because the rule is the branch's role, not its name.
PROTECTED="${PROTOCOL_PROTECTED_BRANCH:-main}"
# A checkout sitting on it is what the branch resolution below has to notice.
on_protected() { [ "$(git -C "$1" symbolic-ref --short HEAD 2>/dev/null)" = "$PROTECTED" ]; }

# Only consulted when the payload cannot be parsed at all, where a substring test over the raw bytes
# can over-match but never under-match — so nothing guarded escapes and an unrelated command is
# untouched. It is deliberately the union of what the guards below look for, not a fourth rule.
looks_guarded() {
  case "$1" in
    *--no-verify*|*--force*|*--amend*|*"git push"*|*cherry-pick*) return 0 ;;
  esac
  return 1
}

# jq is the normal emitter. The fallback has to answer without it, so every reason that reaches it is
# a literal written here with no quote or backslash to escape.
decide() {
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg d "$1" --arg r "$2" '{hookSpecificOutput: {hookEventName: "PreToolUse",
      permissionDecision: $d, permissionDecisionReason: $r}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  fi
  exit 0
}

payload="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  looks_guarded "$payload" && decide deny "jq is not on this hook PATH, so it cannot read the command it was asked to check. This command looks like one of the ones this protocol guards, and a command the guard cannot read stays denied. Install jq, or run it by hand knowing what the rule says."
  exit 0
fi

if ! cmd="$(printf '%s' "$payload" | jq -r 'select(.tool_name == "Bash") | .tool_input.command // ""' 2>/dev/null)"; then
  looks_guarded "$payload" && decide deny "this hook could not parse the tool payload, and a command it cannot read stays denied when the raw payload looks like one of the ones this protocol guards."
  exit 0
fi
[ -n "$cmd" ] || exit 0

# Which branch a command would act on is not in the command, and two guards need it, so it is resolved
# once here rather than in each: the first `-C <path>` the command names, else wherever the session is.
# Passing it in also keeps every guard a pure function of its arguments, so a suite needs no repository.
repo="."
dirs=""
case "$cmd" in
  *"-C "*)
    set -f
    prev=""
    for w in $cmd; do
      [ "$prev" = "-C" ] && dirs="$dirs $w" && [ "$repo" = "." ] && repo="$w"
      prev="$w"
    done
    set +f ;;
esac
branch="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)"

# The line itself can move before the command that acts on it runs: `git checkout main && git push`
# pushed the protected branch while this read the session's own, and so did a `cd` into a checkout
# sitting on it. A line may only make the branch the protected one, never make it something else —
# reading a checkout as licence to stop judging a push is the wrong direction for a parse to be
# wrong in.
# Only the two git guards take the branch, so a line without git pays nothing for this.
case "$cmd" in
  *git*)
    # shellcheck disable=SC1091
    . "$(dirname "${BASH_SOURCE[0]}")/command-guards/clauses.sh"
    while IFS= read -r clause; do
      case "$clause" in
        "checkout "*|"switch "*)
          case " $clause " in
            *" -- "*) ;;
            *" $PROTECTED "*) branch=$PROTECTED ;;
          esac ;;
      esac
    done < <(git_clauses "$cmd")
    case "$cmd" in
      *"cd "*|*"pushd "*)
        dir="$(printf ' %s' "$cmd" | tr '\n' ' ' |
          sed -nE 's#.*[^-A-Za-z0-9_/](pushd|cd)[[:space:]]+([^[:space:];&|]+).*#\2#p')"
        case "$dir" in "~"*) dir="$HOME${dir#\~}" ;; esac
        [ -n "$dir" ] && on_protected "$dir" && branch=$PROTECTED ;;
    esac
    # A line naming two repositories was read from the last -C alone, which is the wrong one half the
    # time: any of them sitting on the protected branch is what this has to notice.
    set -f
    for dir in $dirs; do
      on_protected "$dir" && branch=$PROTECTED
    done
    set +f ;;
esac

for g in $GUARDS; do
  # Fail closed, exactly as guards.sh does: a silently skipped guard is worse than a missing one,
  # because the thing it was meant to catch goes through and the absence never announces itself.
  if [ ! -x "$DIR/$g" ] || ! verdict="$("$DIR/$g" "$cmd" "$branch" "$PROTECTED")"; then
    decide deny "a guard this hook dispatches is missing, not executable, or failed while deciding. Every command stays denied until that is fixed rather than going through unchecked."
  fi
  case "$verdict" in
    "") ;;
    deny\ *) decide deny "${verdict#deny }" ;;
    ask\ *) decide ask "${verdict#ask }" ;;
    *) decide deny "a guard returned a verdict this hook cannot read, so the command stays denied rather than going through unchecked." ;;
  esac
done
