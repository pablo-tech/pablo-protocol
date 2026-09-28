#!/usr/bin/env bash
# The clause parser over a command line: which clause is a command of that program, what its verb is,
# and what is merely a word in some other clause — or in no clause at all.
#   bash adapters/claude-code/command-guards/clauses.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/../../../bin/check.sh"
# shellcheck disable=SC1091
source "$DIR/clauses.sh"

one() { git_clauses "$1" | tr '\n' '/'; }

check "a git command is one clause, verb first" "[ \"\$(one 'git push -u origin fix/x')\" = 'push -u origin fix/x/' ]"
check "a command that is not git has no clause" "[ -z \"\$(one 'ls -la')\" ]"
check "nor does a path that merely contains a verb" \
  "[ -z \"\$(one 'cat command-guards/cherry-pick.sh')\" ]"
# The verb is the first non-flag word after git, so the flags git itself takes do not become one.
check "-C and its path are not the verb" "[ \"\$(one 'git -C /tmp/repo push')\" = 'push/' ]"
check "nor is -c and its assignment" "[ \"\$(one 'git -c user.email=t commit -m x')\" = 'commit -m x/' ]"

# Each clause is judged on its own: the whole point of the file.
check "a second command is a second clause" \
  "[ \"\$(one 'git push origin x && git tag v1')\" = 'push origin x/tag v1/' ]"
check "a semicolon ends a clause too" "[ \"\$(one 'git push origin x; git tag v1')\" = 'push origin x/tag v1/' ]"
check "as does a pipe" "[ \"\$(one 'git log -1 | grep x')\" = 'log -1/' ]"
# A multi-line command is ordinary, and word splitting throws the newline away — so the second
# command read as arguments of the first and was judged by nobody.
check "a newline ends a clause as surely as a semicolon" \
  "[ \"\$(one 'git fetch origin
git push origin main')\" = 'fetch origin/push origin main/' ]"
check "and a single ampersand does too" \
  "[ \"\$(one 'git fetch origin & git push origin main')\" = 'fetch origin/push origin main/' ]"
check "a non-git clause between two git ones is skipped" \
  "[ \"\$(one 'git tag v1 && make && git push')\" = 'tag v1/push/' ]"
# What a git command is asked *about* is an argument, not a second command.
check "a verb named as an argument is not a clause of its own" \
  "[ \"\$(one 'git log --grep=push')\" = 'log --grep=push/' ]"

check "git_clause_args prints the named verb's arguments" \
  "[ \"\$(git_clause_args 'git commit -m x && git push -u origin y' push)\" = ' -u origin y' ]"
check "and nothing for a verb that takes none" "[ -z \"\$(git_clause_args 'git status' status)\" ]"
check "it says so when the line holds no such clause" "! git_clause_args 'git commit -m x' push"
check "a verb is not matched by a longer one that starts with it" \
  "! git_clause_args 'git pushx' push"

# A subshell's parentheses end a clause and start one, so what runs inside is judged rather than read
# as arguments of whatever preceded it.
check "a subshell is a clause of its own" \
  "[ \"\$(one '(git push origin main)')\" = 'push origin main/' ]"
check "as is a command substitution" \
  "[ \"\$(one 'echo \$(git push origin main)')\" = 'push origin main/' ]"
check "and a clause before the subshell is still its own" \
  "[ \"\$(one 'cd /tmp && (git push origin main)')\" = 'push origin main/' ]"

# Parentheses inside a quoted span are text, and a backslash before the newline continues one command
# rather than ending it — read otherwise, the first split a message into commands nobody ran and the
# second cut a command in half.
# shellcheck disable=SC2034  # each is used inside an eval'd check condition below.
{
  quoted_parens="echo 'see (git push origin main) here'"
  continued=$'git push \\\n  origin main'
}
check "a quoted span is text, parentheses and all" "[ -z \"\$(one \"\$quoted_parens\")\" ]"
check "a continued line is one clause" "[ \"\$(one \"\$continued\")\" = 'push origin main/' ]"

# The hook is handed the heredoc body too, and once a newline ended a clause every line of it read as
# a command — so writing a document about pushing, or a commit message with one in it, was judged as
# the thing it describes.
# shellcheck disable=SC2034  # each is used inside an eval'd check condition below.
{
  heredoc='git commit -F - <<MSG
subject

body mentions git push origin main
MSG'
  quoted=$'cat > doc.md <<\'EOF\'\ngit push origin main\nEOF'
  indented=$'cat > doc.md <<-EOF\n\tgit push origin main\n\tEOF'
  herestring=$'grep -q x <<<"$out"\ngit push origin main'
  unterminated=$'cat <<EOF\ngit push origin main'
}

check "a heredoc body is not a sequence of commands" "! git_clause_args \"\$heredoc\" push"
check "the command carrying it is still a clause" "git_clause_args \"\$heredoc\" commit >/dev/null"
check "a quoted tag is a tag" "! git_clause_args \"\$quoted\" push"
check "so is one a dash lets the body indent past" "! git_clause_args \"\$indented\" push"
# A here-string carries no body, so reading its `<<` as an unterminated tag would hide the rest.
check "a here-string is not a heredoc" "git_clause_args \"\$herestring\" push >/dev/null"
# An unterminated tag swallows the rest of the line. That is the silent direction, and deliberate:
# nothing after it is judged, rather than a document's contents being judged as commands.
check "a body whose tag never closes hides what follows" "! git_clause_args \"\$unterminated\" push"

# gh is parsed by the same code, and takes no flags before its subcommand.
check "gh clauses come out the same way" \
  "[ \"\$(gh_clauses 'gh pr list -R o/r && gh run list' | tr '\n' '/')\" = 'pr list -R o/r/run list/' ]"
check "a line with no gh command has no gh clause" "[ -z \"\$(gh_clauses 'git push origin main')\" ]"

finish
