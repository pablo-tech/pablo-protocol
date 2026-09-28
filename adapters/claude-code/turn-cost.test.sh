#!/usr/bin/env bash
# turn-cost.sh on a scratch transcript: two turns, the last with one request logged twice (one line per content
# block, the same usage on each), as Claude Code writes them.
#   bash adapters/claude-code/turn-cost.test.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# shellcheck disable=SC1091
source "$DIR/../../bin/check.sh"

u() { printf '{"type":"assistant","requestId":"%s","message":{"usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"output_tokens":%s}}}\n' "$@"; }
{
  echo '{"type":"user","message":{"content":"an earlier prompt"}}'
  u old 1000 0 0 100
  echo '{"type":"user","message":{"content":"this turn"}}'
  u b 10 1000 100000 500
  echo '{"type":"user","message":{"content":[{"type":"tool_result","content":"ok"}]}}'
  u b 10 1000 100000 500
  u c 0 0 50000 100
} >"$t/turn.jsonl"
echo '{"type":"user","message":{"content":"nothing answered yet"}}' >"$t/empty.jsonl"

# b once and c: 10*15 + 1000*18.75 + 150000*1.5 + 600*75 per Mtok. b twice would be $0.4953, the earlier turn $0.3114.
check "costs this turn only, each request once" \
  "bash '$DIR/turn-cost.sh' '$t/turn.jsonl' | grep -cF 'Turn cost: \$0.2889  ·  in 10 · cache-w 1k · cache-r 150k · out 600 tok' >/dev/null"
check "as a hook, says it as a systemMessage" \
  "echo '{\"transcript_path\":\"$t/turn.jsonl\"}' | bash '$DIR/turn-cost.sh' --hook | jq -er '.systemMessage | startswith(\"Turn cost: \$0.2889\")' >/dev/null"
check "says nothing for a turn with no requests" "[ -z \"\$(bash '$DIR/turn-cost.sh' '$t/empty.jsonl')\" ]"

finish
