# Cortex Code

**Configuration directory:** `SNOWFLAKE_HOME`.

Cortex Code reads `AGENTS.md` from the working directory by itself, so the doctrine needs no
installation step — the adapter exists for tenancy, not for the protocol.

Installs into the tenant:

- `.agents/cortex/` — this tenant's `SNOWFLAKE_HOME`, holding `cortex/settings.json`.
- `.agents/cortex/run` — a launcher exporting `SNOWFLAKE_HOME` before exec'ing the binary, for any
  shell that never sourced a profile.
- Ignore rules for the runtime state Cortex writes into that directory: logs, and the connections
  file. **`connections.toml` is a credential** and belongs in whatever repository this tenant keeps
  credentials in, never here — `guards/credentials-guard.sh` refuses it by shape either way.

Check it worked:

```
.agents/cortex/run skill list
```
