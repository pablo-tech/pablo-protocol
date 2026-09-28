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

# Runtime state, not configuration: logs, caches and session tokens are written in here.
for line in '/.agents/*/cortex/logs/' '/.agents/*/connections.toml'; do
  ignore "$line"
done

if [ -e "$HOME_DIR/run" ]; then
  say skip .agents/cortex/run
else
  cat >"$HOME_DIR/run" <<'LAUNCH'
#!/usr/bin/env bash
# Cortex Code against this tenant's configuration directory, whatever the caller's environment —
# the path for cron, CI, and any shell that never sourced a profile.
set -euo pipefail
export SNOWFLAKE_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${CORTEX_BIN:-$HOME/.local/bin/cortex}" "$@"
LAUNCH
  chmod +x "$HOME_DIR/run"
  say write .agents/cortex/run
fi
