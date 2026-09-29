# Architecture

This is the contract, not a tour. [README.md](README.md) argues why the repository exists; this
file states what a consumer may rely on, so that a change which breaks one of these statements is
a breaking change and is announced as one. Sections are numbered so prose elsewhere can cite §4.

## 1. The protocol is `doctrine/`. Everything else installs it or enforces it

The eight files under `doctrine/` are the only normative content. `AGENTS.md` indexes them.
`guards/`, `bin/` and `adapters/` are mechanism: delete all three and the protocol still exists as
documents, which is the property the whole design is arranged to preserve.

A doctrine file carries exactly two frontmatter keys, `name` and `description`, and no others.
That is the minimum one agent's skill format requires and it is inert to every other reader, which
is what lets a skill be a symlink to the doctrine file rather than a copy of it. **Adding a third
key is a breaking change**: it is the contract that makes one file serve two readers.

Doctrine is tenant-free. It may name this repository and its owner and nothing else — no client,
no employer, no machine, no account. §6 is the check that holds this.

## 2. The tenant is the unit

A tenant is whoever the work belongs to: an employer, a client, an estate. Each has one context
repository, and that repository carries four things, all of which `bin/adapt` installs:

| Path | What it is | Who owns it |
|---|---|---|
| `protocol/` | this repository, symlinked; gitignored, being a machine-local path | the installer |
| `AGENTS.md` | the tenant's own facts, and a pointer to `protocol/AGENTS.md` | the tenant |
| `.protocol/*` | one file per guard policy the tenant opts into (§3) | the tenant |
| `.githooks/pre-commit` | the shim that runs `protocol/guards/guards.sh` (§5) | seeded, then the tenant's |

Nothing in this repository knows the name of any tenant, and nothing in a tenant repository is
copied from this one except the seeds, which exist to be edited.

## 3. A guard reads a policy file the tenant carries, and an absent policy means the guard exits 0

`guards/policy.sh` resolves `.protocol/<name>` relative to the committing repository's root,
strips whole-line comments and blank lines, and returns non-zero when the file is absent.

A policy has **two layers**, read in that order and concatenated into one list: the tracked
`.protocol/<name>`, then an untracked `.protocol/<name>.local`. Either may be absent; only both
being absent is the "no such policy" answer a guard exits 0 on. `bin/adapt` gitignores the overlay
in every tenant, before one can exist.

The overlay is what lets a policy file survive being published. A list of the terms a repository
must refuse is, read the other way, a list of what that repository is protecting — so in a
repository anyone can read, the tracked file states the *shapes* and the *categories*, which are
safe to publish, and the overlay states the proper nouns, which are not. A guard sees one list and
cannot tell which layer a term came from, which is the property that keeps this out of every guard.

This is the mechanism that makes one shared guard chain safe to point at any checkout. **A
repository opts into a rule by carrying the file that configures it, never by being recognised by
name from inside the guard.** A guard that special-cased a repository name would have to be edited
every time a repository was added — and would be wrong the first time one was renamed.

The policy files in use:

| File | Guard | Contents |
|---|---|---|
| `.protocol/tenant` | `tenant-guard.sh` | extended regular expressions; the terms belonging to the tenants this repository is **not** |
| `.protocol/credentials-allow-name` | `credentials-guard.sh` | globs exempt from the *shape* rule — a file whose name looks like a credential and holds none |
| `.protocol/credentials-allow-content` | `credentials-guard.sh` | globs that may *contain* credential-shaped text — the suites whose fixtures pin these rules |
| `.protocol/<name>.local` | whichever guard reads `<name>` | the untracked overlay, appended to the tracked file of that name |

Comments are whole-line only. A policy line is a path or a regular expression and may legitimately
contain `#`.

## 4. The guard chain runs in order and fails closed

`guards/guards.sh` is the single entry point. It runs `size-guard.sh`, then
`credentials-guard.sh`, then `tenant-guard.sh`, and stops at the first non-zero exit. A guard that
is missing or not executable **blocks the commit** rather than being skipped: a silently skipped
guard lets the thing it was meant to catch reach history, and the absence never announces itself.

Each guard judges the staged blob, not the file on disk — `git show :<path>`, not `cat <path>` —
because the index is what a commit would record. `size-guard.sh` and `credentials-guard.sh` also
compare against staged size and staged bytes for the same reason.

Two guards take `--scan-tree`, which applies their rules to every tracked file instead of the
staged set. That is the audit mode: it reads the terms from the repository rather than from a
document that then drifts.

The bypass is `git commit --no-verify`, deliberately and universally. A control with no bypass is
a control that gets uninstalled.

## 5. A shim resolves the guards in three steps, in this order

`.githooks/pre-commit` decides *which checkout of the protocol* it loads, and nothing else. That
choice has to be made before anything can be read from the protocol, which is why it is the one
decision the shim owns rather than `guards.sh`:

1. `PROTOCOL_GUARDS`, if set — an explicit override, for a checkout under test.
2. `<repo>/guards/guards.sh`, if it exists — this repository guarding itself.
3. `${PROTOCOL_DIR:-$HOME/.pablo-protocol}/guards` — the well-known path `bin/adapt` symlinks to
   whatever clone the machine uses.

The well-known path is what keeps a machine-local path out of every tenant's committed hook.
`bin/adapt` creates it and **never repoints an existing one**: where it already exists, that is
somebody's choice.

`core.hooksPath` is local configuration and does not travel with a clone, so a fresh clone runs no
hooks until `bin/adapt` (or `git config core.hooksPath .githooks`) is run in it. There is no way
around this in git, which is the second reason the guards are not the only control.

## 6. Environment variables

The complete set. All are optional and all are read at run time.

| Variable | Default | Effect |
|---|---|---|
| `PROTOCOL_GUARDS` | unset | the `guards/` directory to run, overriding resolution (§5) |
| `PROTOCOL_DIR` | `$HOME/.pablo-protocol` | the well-known protocol path |
| `PROTOCOL_MAX_FILE_MB` | `25` | the size ceiling `size-guard.sh` enforces |
| `PROTOCOL_COMMAND_GUARDS` | unset | the command-guard directory one adapter's hooks run |

## 7. The adapter contract

An adapter is a directory under `adapters/` holding `detect.sh`, `adapt.sh` and `README.md`.
`bin/adapt` discovers it by directory listing; adding an adapter changes no other file.

- `detect.sh` exits 0 if the agent is installed on this machine, non-zero otherwise, and prints
  nothing.
- `adapt.sh <tenant-dir> <link|copy>` wires that tenant for that agent, idempotently, reporting
  each action as two spaces followed by a verb and a path.
- **An adapter may create a file; it may never edit one the tenant already has.** Where the file
  exists, the adapter says what is missing and stops. The single exception is `.gitignore`, which
  an adapter appends to — and even there, a tenant that already has a rule about that path keeps
  it exactly as written, because a broader pattern appended underneath wins as the last match and
  would silently undo an exception the tenant carved out.
- **An adapter carries rules, never a list of repositories.** The moment it needs to know which
  clone is which, it has stopped being protocol and started being somebody's estate.

The guarantee a consumer may rely on: **deleting every adapter leaves the protocol intact.**
`bin/adapt` runs on a machine with none and says so.

## 8. `bin/adapt` is idempotent and additive

It skips anything already present, prints one line per change, and never removes or rewrites. A
second run prints only `skip`. `--copy` substitutes copies for symlinks throughout, for a machine
that will not follow a link or whose agent configuration directory is centrally managed; it
dereferences on copy, because the machine that needs `--copy` is exactly the machine that cannot
read a link.

`bin/adapt` refuses to run with this repository as its own tenant.

## 9. Testing

Every script has a `*.test.sh` beside it. `bin/test.sh` finds them rather than listing them, so an
adapter that brings its own suites is tested by existing. `bin/check.sh` is the assertion helper
they share. The suites are bash and take no arguments, no network and no fixtures outside their own
`mktemp -d`.

`bin/adapt.test.sh` ends with an end-to-end case: it installs into a scratch tenant, then makes a
real commit through the shim that run installed, resolving the guards through the well-known path.
Every link between `bin/adapt` and `guards/tenant-guard.sh` is exercised at once, because each of
them individually is the kind of thing that passes its own unit test and is wired to nothing.

## 10. Explicitly out of scope

- **Runtime enforcement.** The guards run at `pre-commit`. Nothing here observes what an agent
  reads, what it sends to a model, or what it writes outside a repository.
- **Secret storage.** The credentials guard refuses to let a secret into a commit. Where secrets
  live and how a process receives them belongs to the tenant.
- **A package registry.** Nothing here is published to one. Consumers clone and pin a tag or a
  commit; a tag is a human-readable name for one commit, not a distribution channel.
- **Configuration merging.** No adapter merges into a file a tenant wrote (§7). There is
  deliberately no schema-aware merge of an agent's settings file, because a tool that rewrites a
  person's configuration is a tool they stop running.
- **Windows.** The scripts are bash and use symlinks, `git`, and POSIX tools. They are not tested
  anywhere else.
- **Anything that identifies a tenant.** No repository names, no client names, no machine names,
  no accounts, no addresses. This repository's own `.protocol/tenant` enforces it against itself.
