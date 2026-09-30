# Security Policy

## Supported versions

Only `main` receives fixes, and nothing is published to a registry. A consumer clones this
repository: a fix reaches a tenant that tracks a branch on the next `git pull` in its protocol
checkout, and a tenant that would rather stay at a tag when it checks out a newer one. Either way
`bin/adapt` is re-run afterwards, which is what refreshes the files installed in the tenant itself.

A tag is a human-readable name for one commit, not a supported branch, and an older tag gets no
backport. [CHANGELOG.md](CHANGELOG.md) is what pulling gets you.

## Scope

The guards are what stands between a diff and history, so in scope is anything that gets material
past them without a person deciding to let it:

- A way to stage another tenant's material without `tenant-guard.sh` failing — a path or content
  form that evades a denylist term which plainly describes it, or content the guard never reads
  because of how the file is encoded, renamed or staged.
- A way to make a commit as an identity `.protocol/identity` does not list without
  `identity-guard.sh` failing, or a way for `--scan-history` to walk a range and miss a header in
  it.
- A way to stage credential material without `credentials-guard.sh` failing, or a way to widen
  `.protocol/credentials-allow-name` or `-allow-content` beyond the paths a tenant listed.
- A way to make `guards.sh` report success having run nothing — a missing, unreadable or
  non-executable guard that is skipped rather than blocking, or a resolution order (§5 of
  [ARCHITECTURE.md](ARCHITECTURE.md)) that can be redirected at a checkout the committer did not
  choose.
- A way for `bin/adapt` or any adapter to overwrite a file the tenant already had, or to write
  outside the tenant directory and the well-known path.
- An adapter that copies protocol content into an agent's own configuration directory, where it
  becomes a second copy no later run refreshes.
- Anything in `doctrine/` or in a shipped template that names a tenant, a machine or an account.
  A leak of that kind is a security issue here, not a documentation defect.

Out of scope: `git commit --no-verify`, which is a deliberate and documented bypass; a repository
that never ran `bin/adapt` and so has no `core.hooksPath` set; a denylist that does not list a
term (a filter catches what it was told to catch — see *What this does not catch* in
[README.md](README.md)); and anything requiring administrative access to the machine, against which
absence is the only control (same section).

## Reporting a vulnerability

Please use GitHub's [private vulnerability
reporting](https://github.com/pablo-tech/pablo-protocol/security/advisories/new) rather than
opening a public issue. Include the repository state that reproduces it — a `.protocol/tenant`
line and the staged content that should have been refused is usually enough.

We aim to acknowledge reports within 5 business days. There is no bug bounty; this is a
volunteer-maintained project.
