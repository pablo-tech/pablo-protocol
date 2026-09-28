# Claude Code

**Configuration directory:** `CLAUDE_CONFIG_DIR` — it relocates the whole of it, credentials
included, and two sessions running with different values do not interfere. That is what makes one
machine able to serve two tenants.

Installs into the tenant:

- `skills/<name>/SKILL.md` — a symlink per doctrine file. Claude Code follows symlinked skills.
- `CLAUDE.md` — a pointer to `AGENTS.md`, written only if the tenant has none.
- `settings.json` — the hooks below, written only if the tenant has none. Where one exists the
  adapter names [`settings-fragment.json`](settings-fragment.json) and stops: merging into a file
  someone wrote is editing it, which no adapter does.

Check it worked:

```
CLAUDE_CONFIG_DIR=<tenant> claude
/skills            # the doctrine names, and nothing belonging to another tenant
```

## The hooks are convenience, not control

`command-guards.sh` is a `PreToolUse` hook for `Bash`: it reads the command, asks each guard in
`command-guards/` in turn, and the first with an opinion decides. The three are
[`dangerous-flags.sh`](command-guards/dangerous-flags.sh) (`--no-verify`, `--amend`, `--force`, and
a `core.hooksPath` pointed away from `.githooks` — every way of turning the commit-time chain off),
[`push.sh`](command-guards/push.sh) (a push straight to `main`, a remote-ref deletion, `--all`,
`--mirror`) and [`cherry-pick.sh`](command-guards/cherry-pick.sh) (a pick landing on `main`). Each
is one rule of [`doctrine/git.md`](../../doctrine/git.md), and the dispatcher fails closed — a guard
that is missing, unexecutable or unreadable denies rather than approves.

`turn-cost.sh` is a `Stop` hook reporting what the turn cost. Its token counts are read from the
transcript; its **dollar figures are a vendor's published list prices, hard-coded in the jq**, so
they are the one thing here that silently goes stale. Re-check them before trusting a figure.

None of this is the boundary. A hook stops one command in one tool and says nothing about a diff
written by another agent, by hand or by an IDE — see [`doctrine/tenancy.md`](../../doctrine/tenancy.md).
The pre-commit guards are what bind, because they judge the diff rather than the typist.

## What a tenant adds for itself

The chain deliberately carries no rule that is a **list of repositories** — which merges publish a
package, which owners exist, which clone is which. Those are tenant facts, and a protocol that
shipped one would be shipping somebody's estate. A tenant that wants them registers its own
`PreToolUse` hook beside this one; the harness runs every matching hook and takes the first refusal,
so the two chains compose without either knowing about the other.
