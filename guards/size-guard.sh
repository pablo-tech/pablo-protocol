#!/usr/bin/env bash
# CANONICAL oversized-file guard.
#
# Policy: heavy files live in cloud storage. Repos keep information extracted from them, never the
# files themselves. Threshold below, overridable via PROTOCOL_MAX_FILE_MB.
#
# Why at COMMIT rather than push: GitHub hard-rejects any blob over 100 MiB, and by the time a push
# is refused the blob is already in local history — the branch then stays unpushable until history
# is rewritten, which costs a force-push to every branch that carries it.
#
# Run directly to check the current index:  guards/size-guard.sh
# Emergency bypass (in the calling repo):   git commit --no-verify

MAX_MB="${PROTOCOL_MAX_FILE_MB:-25}"
MAX_BYTES=$((MAX_MB * 1024 * 1024))

toobig=""
# -z so paths containing spaces survive; records carry them.
while IFS= read -r -d '' path; do
  sha="$(git rev-parse ":$path" 2>/dev/null)" || continue
  # Size of the blob as STAGED, not as on disk: the index is what a commit would record.
  size="$(git cat-file -s "$sha" 2>/dev/null)" || continue
  if [ "$size" -gt "$MAX_BYTES" ]; then
    toobig="$toobig\n  $((size / 1048576)) MB  $path"
  fi
done < <(git diff --cached --name-only --diff-filter=AM -z)

if [ -n "$toobig" ]; then
  echo "pre-commit: refusing to commit file(s) over ${MAX_MB} MB:"
  printf "%b\n" "$toobig"
  echo "pre-commit:   keep only what you extract from the file, not the file."
  echo "pre-commit:   unstage with:  git restore --staged <path>"
  echo "pre-commit:   if it is a build artifact or dependency, gitignore it instead."
  echo "pre-commit: (bypass: git commit --no-verify)"
  exit 1
fi
exit 0
