# Contributing

Bash and `git`. No build, no package manager, no dependencies. One command runs everything CI
runs:

```bash
bin/test.sh
```

It finds every `*.test.sh` in the tree rather than listing them, so a new suite is tested by
existing. `shellcheck` is run in CI over every script and is worth having locally.

[ARCHITECTURE.md](ARCHITECTURE.md) is the contract behind all of it — read it before changing a
guard, an adapter or the installer, because most of what looks like an odd choice is §-numbered
there with its reason. [CHANGELOG.md](CHANGELOG.md) gets an entry under `[Unreleased]` for
anything a consumer would notice on moving their pin.

## Inbound contributions are under the MIT licence, certified by a sign-off

Every commit carries a [Developer Certificate of Origin](https://developercertificate.org)
sign-off:

```bash
git commit -s
```

That adds a `Signed-off-by:` line and is the whole of it — there is no CLA to sign. No copyright is
aggregated anywhere here, so a CLA would buy a signing service to guarantee what
[the licence](LICENSE) already grants. CI checks the line is present on every commit in a pull
request, and exempts authors whose name ends in `[bot]`: the bots that open pull requests here
commit without a sign-off, and a required check they cannot satisfy buys an admin-bypass habit
rather than a stronger guarantee.

## Four things that look like bugs and are deliberate

A pull request that "fixes" one of these needs to argue with the reason, not just the code.

- **A guard whose policy file is absent exits 0, and a guard that is *missing* blocks the commit.**
  Those look inconsistent and are opposites on purpose (ARCHITECTURE §3, §4). An absent policy is a
  repository that did not opt in. An absent guard is a chain that has been broken, and skipping it
  silently is exactly the failure the chain exists to prevent.
- **`bin/adapt` never edits a file the tenant already has** — not even to merge one hook into a
  settings file it could parse. It prints what is missing and stops (§7). A tool that rewrites
  somebody's instruction file is a tool they stop running.
- **The `.gitignore` rules an adapter appends are skipped when the tenant already has any rule
  about that path**, rather than when the line matches exactly. A tenant ignoring `projects/*/*`
  while keeping `projects/*/memory/*.md` tracked loses that memory to a broader pattern appended
  underneath, because the last matching pattern wins.
- **`--no-verify` is documented in the refusal message of every guard.** A control with no bypass
  is a control that gets uninstalled the first time it is wrong at an inconvenient hour. The guards
  are a floor, not a cage; [README.md](README.md#what-this-does-not-catch) says what they are not.

## Two rules that decide most review comments

**One canonical home per fact.** A mechanism is explained once, in the document that owns it, and
linked from everywhere else. A pull request that restates something `ARCHITECTURE.md` already says
will be asked to link instead — two copies drift and one becomes a lie with no signal which.

**Nothing here may name a tenant.** No client, employer, machine, account, address or repository
other than this one. This repository's own `.protocol/tenant` enforces it against itself, and CI
runs `guards/tenant-guard.sh --scan-tree` over the whole tree. If the check refuses something
legitimate, the denylist is the bug — narrow it in the same pull request and say why.

## Adding an adapter for another AI coding agent

Most of the work is finding out which environment variable relocates that agent's configuration
directory, and whether it already reads `AGENTS.md` from the working directory — several do, and
for those the adapter is nearly empty. Then write the three files
[`adapters/README.md`](adapters/README.md) specifies and add nothing to `bin/adapt`: it discovers
the directory. Bring a `*.test.sh` if the adapter does anything a shell can assert.

## Style

- No comment explaining *what* code does. A comment earns its place by explaining a non-obvious
  *why* — a constraint, an invariant, a workaround. Most of the comments here are that.
- New or changed behaviour arrives with the test that pins it, in the same pull request. A test
  that passes whether or not the property holds is not a test; write it red first where you can.
- No new dependencies. The value of a guard chain is partly that it is small enough to audit in
  one sitting, and it has to run on a machine where installing things is somebody else's decision.
- Prose in `doctrine/` is held to `doctrine/clean-code.md`, which applies to documents for the same
  reason it applies to functions: a bloated or duplicated document is paid for by every reader.

## Reporting a security issue instead of filing a pull request

See [SECURITY.md](SECURITY.md) — vulnerabilities go through GitHub's private vulnerability
reporting, not a public issue or pull request, until triaged.
