---
description: Show what the most recent completed turn in this session cost, from real token counts.
allowed-tools: Bash(${CLAUDE_CONFIG_DIR:-$HOME/.claude}/protocol/adapters/claude-code/turn-cost.sh)
---

Run `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/protocol/adapters/claude-code/turn-cost.sh` with the Bash
tool. It finds this project's newest session transcript and prints one line: what the most recent
completed turn cost, from real token counts deduplicated per API request.

Report its output verbatim. If it prints nothing, say that no completed turn was found for this
project's transcript directory.

Its **dollar figures are a vendor's published list prices, hard-coded in the script's jq**, so they
are the one thing here that silently goes stale. Re-check them before trusting a figure.
