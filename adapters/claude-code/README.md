# Claude Code

**Configuration directory:** `CLAUDE_CONFIG_DIR` — it relocates the whole of it, credentials
included, and two sessions running with different values do not interfere. That is what makes one
machine able to serve two tenants.

Installs into the tenant:

- `skills/<name>/SKILL.md` — a symlink per doctrine file. Claude Code follows symlinked skills.
- `CLAUDE.md` — a pointer to `AGENTS.md`, written only if the tenant has none.

Check it worked:

```
CLAUDE_CONFIG_DIR=<tenant> claude
/skills            # the doctrine names, and nothing belonging to another tenant
```

**What this does not do.** It does not install hooks or permission rules to enforce tenancy. Those
constrain one tool, and the boundary has to bind every tool — see
[`doctrine/tenancy.md`](../../doctrine/tenancy.md). Enforcement is the pre-commit guards.
