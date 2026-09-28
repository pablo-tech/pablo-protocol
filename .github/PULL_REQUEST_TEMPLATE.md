## What this changes, and why

<!-- The why. The diff already says the what. -->

## Checklist

- [ ] `bin/test.sh` passes, and new or changed behaviour arrives with the test that pins it.
- [ ] Every commit is signed off (`git commit -s`) — see [CONTRIBUTING.md](../CONTRIBUTING.md).
- [ ] Nothing added names a tenant: no client, employer, machine, account, address or repository
      other than this one. `guards/tenant-guard.sh --scan-tree` is clean.
- [ ] No fact is stated in two places. Where something here is already explained in
      [ARCHITECTURE.md](../ARCHITECTURE.md), this links to it rather than restating it.
- [ ] No new dependency.

Tick only what applies:

- [ ] A doctrine file still carries exactly `name` and `description` frontmatter
      ([ARCHITECTURE.md §1](../ARCHITECTURE.md#1-the-protocol-is-doctrine-everything-else-installs-it-or-enforces-it)).
- [ ] A new or changed guard exits 0 when its policy file is absent, and the chain still fails
      closed when a guard is missing (§3, §4).
- [ ] An adapter creates but never edits a file the tenant already has, and copies no protocol
      content into the agent's own configuration directory (§7).
- [ ] `bin/adapt` is still idempotent: a second run prints only `skip`.
- [ ] [CHANGELOG.md](../CHANGELOG.md) has an entry under `[Unreleased]` for anything a consumer
      would notice on moving their pin.
