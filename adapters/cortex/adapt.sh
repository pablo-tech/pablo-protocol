#!/usr/bin/env bash
# Cortex Code reads AGENTS.md from the working directory natively, so the protocol reaches it for
# free. What the adapter provides is the other half of tenancy: a configuration directory belonging
# to this tenant, so its account, history and logs are not shared with another's.
set -euo pipefail
TENANT="$1"
HOME_DIR="$TENANT/.agents/cortex"
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/bin/tenant.sh"

mkdir -p "$HOME_DIR/cortex"
if [ -e "$HOME_DIR/cortex/settings.json" ]; then
  say skip .agents/cortex
else
  printf '{\n  "cortexAgentConnectionName": "default"\n}\n' >"$HOME_DIR/cortex/settings.json"
  say write .agents/cortex/cortex/settings.json
fi

# Runtime state, not configuration: logs, caches and session tokens are written in here, and
# connections.toml is the one that names an account and points at a key file.
ignore '/.agents/*/cortex/logs/' '/.agents/*/connections.toml'

# Copied, never linked: it is the tenant's entry point and has to keep working when `protocol/` is
# not there. `run` is a file in this adapter rather than a heredoc here, so that the sweep over
# every tracked file with a shebang sees it: a script written from a string inside another script
# is a script nothing checks.
if [ -e "$HOME_DIR/run" ]; then
  say skip .agents/cortex/run
else
  cp "$(dirname "${BASH_SOURCE[0]}")/run" "$HOME_DIR/run"
  chmod +x "$HOME_DIR/run"
  say write .agents/cortex/run
fi
