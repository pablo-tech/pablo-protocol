#!/usr/bin/env bash
# What the last turn actually cost, from the session transcript.
#
# Token counts are read verbatim (real usage, deduped per API request); the dollar figures apply the
# list prices in the jq below, which are the one thing here that goes stale — they are a vendor's
# published numbers, not a measurement, so re-check them before trusting a figure:
#   input $15/Mtok · cache-write(5m) $18.75/Mtok · cache-read $1.50/Mtok · output $75/Mtok
#   >200K-input requests bill at the long-context tier (input/cache x2, output x1.5).
#
# Modes:
#   turn-cost.sh --hook        read Stop-hook JSON on stdin, emit {systemMessage}
#   turn-cost.sh <transcript>  use the given transcript, print a plain line
#   turn-cost.sh               auto-detect newest transcript for $PWD, plain line

# Resolved once, and not as a bare `jq`: a hook runs on a PATH the session does not control.
JQ="$(command -v jq || echo /usr/bin/jq)"

emit_json=0
tx=""
if [ "${1:-}" = "--hook" ]; then
  emit_json=1
  tx=$(cat | "$JQ" -r '.transcript_path // empty')
elif [ -n "${1:-}" ]; then
  tx="$1"
else
  proj=$(printf '%s' "$PWD" | sed 's/[^a-zA-Z0-9]/-/g')
  # shellcheck disable=SC2012 # newest by mtime; transcript names are UUIDs
  # The transcript follows the config dir, which is how one machine keeps two tenants apart.
  tx=$(ls -t "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$proj"/*.jsonl 2>/dev/null | head -1)
fi
if [ -z "$tx" ] || [ ! -f "$tx" ]; then exit 0; fi

# shellcheck disable=SC2016 # a jq program: $ups and $from are jq variables, not shell ones
line=$("$JQ" -rs '
  # Index of the last genuine user prompt (string content, or an array with no
  # tool_result block). Everything after it is the current turn.
  [ range(0; length) as $i
    | select(.[$i].type == "user")
    | select(
        (.[$i].message.content | type == "string")
        or ([ .[$i].message.content[]? | select(.type == "tool_result") ] | length == 0)
      )
    | $i ] as $ups
  | (if ($ups | length) > 0 then ($ups | last) + 1 else 0 end) as $from
  # Assistant messages in the turn, one usage per unique request (block-lines
  # of a single response repeat the same usage — keep only the first).
  | [ .[$from:][]
      | select(.type == "assistant" and (.message.usage != null))
      | { rid: (.requestId // .message.id), u: .message.usage } ]
  | reduce .[] as $m ({}; if has($m.rid) then . else .[$m.rid] = $m.u end)
  | [ .[] ]
  | map(
      (.input_tokens // 0) as $i | (.cache_creation_input_tokens // 0) as $w
      | (.cache_read_input_tokens // 0) as $r | (.output_tokens // 0) as $o
      | (($i + $w + $r) > 200000) as $big
      | (if $big then {i:30e-6, w:37.5e-6, r:3e-6, o:112.5e-6}
                 else {i:15e-6, w:18.75e-6, r:1.5e-6, o:75e-6} end) as $p
      | { cost: ($i*$p.i + $w*$p.w + $r*$p.r + $o*$p.o), i:$i, w:$w, r:$r, o:$o, ctx: ($i+$w+$r) }
    )
  # ctx = context carried INTO the most expensive request this turn; the >200K
  # long-context tier doubles cache price, so this is the number that predicts spend.
  | reduce .[] as $x ({c:0,i:0,w:0,r:0,o:0,ctx:0};
      .c += $x.cost | .i += $x.i | .w += $x.w | .r += $x.r | .o += $x.o
      | .ctx = (if $x.ctx > .ctx then $x.ctx else .ctx end))
  | def k: if . >= 1000 then "\(((. / 100) | round) / 10)k" else (. | tostring) end;
    (if .ctx > 200000 then "  ⚠ context \(.ctx|k) tok — billing at 2× long-context tier; /clear or delegate reads to a subagent"
     elif .ctx > 150000 then "  ⚠ context \(.ctx|k) tok — approaching the 200K 2× cliff; consider /clear at the next phase boundary"
     else "" end) as $warn
    | if .c == 0 then empty
    else "Turn cost: $\(((.c * 10000) | round) / 10000)  ·  in \(.i|k) · cache-w \(.w|k) · cache-r \(.r|k) · out \(.o|k) tok (actual tokens, Opus list price)" + $warn
    end
' "$tx")

[ -z "$line" ] && exit 0
if [ "$emit_json" = "1" ]; then
  printf '%s' "$line" | "$JQ" -Rs '{systemMessage: .}'
else
  printf '%s\n' "$line"
fi
