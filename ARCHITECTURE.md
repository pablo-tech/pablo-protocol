# Architecture

This is the contract, not a tour. [`doctrine/README.md`](doctrine/README.md) is what the rules
say, [README.md](README.md) argues why they are a repository rather than a page in an agent's
configuration file, and this file states what a consumer may rely on — so that a change which
breaks one of these statements is a breaking change and is announced as one. Sections are numbered
so prose elsewhere can cite §4.

## 1. The protocol is `doctrine/`. Everything else installs it or enforces it

The eight doctrine documents are the only normative content. `AGENTS.md` indexes them for an
agent and `doctrine/README.md` for a person; that index is a ninth file in the directory and is
not itself doctrine (§7).
`guards/`, `bin/` and `adapters/` are mechanism: delete all three and the protocol still exists as
documents, which is the property the whole design is arranged to preserve.

A doctrine file carries exactly two frontmatter keys, `name` and `description`, and no others.
That is the minimum one agent's skill format requires and it is inert to every other reader, which
is what lets a skill be a symlink to the doctrine file rather than a copy of it. **Adding a third
key is a breaking change**: it is the contract that makes one file serve two readers.

Doctrine is tenant-free. It may name this repository and its owner and nothing else — no tenant,
no machine, no account. §10 is the check that holds this.

## 2. The tenant is the unit

A tenant is whoever the work belongs to. Each has one context repository, and that repository
carries five things, all of which `bin/adapt` installs:

| Path | What it is | Who owns it |
|---|---|---|
| `protocol/` | this repository, symlinked; gitignored, being a machine-local path | the installer |
| `AGENTS.md` | the tenant's own facts, and a pointer to `protocol/AGENTS.md` | the tenant |
| `.protocol/*` | one file per guard policy the tenant opts into (§3) | the tenant |
| `.protocol/protocol-version` | which commit of this protocol installed the tenant (§11) | the installer, rewritten every run |
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

### A repository worked on under a tenant

A repository that is merely *worked on* under a tenant is deliberately not a tenant: it is given the
pre-commit shim and nothing else, so that nothing of the tenant's is in its tree for its own
contributors and its own continuous integration to inherit. That leaves it with no `.protocol/` of
its own, and so carrying every policy file absent — which by the rule above means policed by
nothing. For the tenancy and credentials rules that is the right answer. For identity it is not:
who a commit is made as is a question about this machine, and that repository is where most of this
machine's commits are made.

So whatever wires such a repository records the tenant in its **local git configuration**,
`pabloProtocol.tenant`, alongside the `core.hooksPath` it sets there already. `tenant_root` in
`guards/policy.sh` reads it, and a guard may pass the answer to `policy` as a second argument to
read that tenant's file instead of this repository's. Local configuration is not in the tree and
does not travel, which is also what makes it safe to read: nothing arriving over the network can
set it and point a guard at a directory of its own choosing. The section is `pabloProtocol` rather
than `protocol` because `protocol.*` is git's own.

**A guard opts into that fallback one at a time, and only one does.** A fallback can only be safe
where inheriting tightens: the identity guard inherits an allowlist, so the worked-on repository is
held to more than it was. `credentials-allow-name` and `credentials-allow-content` are exemptions,
and inheriting those would hand a repository the tenant's holes. The rule stands unchanged — the
repository that carries `.protocol/identity` is judged by it and by nothing else, empty or not,
because carrying the file is how a repository opts in and an empty one claims nobody.

**`bin/doctor --in <dir>` reads this shape rather than a tenant missing its install.** It is the one
place the wiring above is visible at all, local configuration being invisible in a tree, and before
it knew the shape it reported a correctly wired repository as a broken tenant and named `bin/adapt`
as the remedy — the one command that must never be run there. What it reports instead: the checkout
the **shim** resolves, which is what decides the guards where there is no `protocol/`, together with
a note where that checkout and the one the tenant reads its doctrine from are not at the same commit
— two separate checkouts is what every machine has, so the commits are what is compared and the
paths are what the note names; the two can differ deliberately, one tenant pinned to a tag while the
machine tracks a branch, and whichever loses does so silently; the identity list from whichever file
the guard would read, named by path; and a `pabloProtocol.tenant` pointing at a directory that is
not a tenant, which resolves to nothing in every guard and so leaves the repository held to no
policy while every outward sign says it is wired.

The policy files in use:

| File | Guard | Contents |
|---|---|---|
| `.protocol/tenant` | `tenant-guard.sh` | extended regular expressions; the terms belonging to the tenants this repository is **not** |
| `.protocol/identity` | `identity-guard.sh` | extended regular expressions; the identities this repository's commits may be made as. The one policy with a fallback — see above |
| `.protocol/credentials-allow-name` | `credentials-guard.sh` | globs exempt from the *shape* rule — a file whose name looks like a credential and holds none |
| `.protocol/credentials-allow-content` | `credentials-guard.sh` | globs that may *contain* credential-shaped text — the suites whose fixtures pin these rules |
| `.protocol/<name>.local` | whichever guard reads `<name>` | the untracked overlay, appended to the tracked file of that name |

Comments are whole-line only. A policy line is a path or a regular expression and may legitimately
contain `#`.

## 4. The guard chain runs in order and fails closed

`guards/guards.sh` is the single entry point. It runs `size-guard.sh`, then
`credentials-guard.sh`, then `tenant-guard.sh`, then `identity-guard.sh`, and stops at the first
non-zero exit. A guard that is missing or not executable **blocks the commit** rather than being
skipped: a silently skipped guard lets the thing it was meant to catch reach history, and the
absence never announces itself.

Each guard that reads the tree judges the staged blob, not the file on disk — `git show :<path>`,
not `cat <path>` — because the index is what a commit would record. `size-guard.sh` and
`credentials-guard.sh` also compare against staged size and staged bytes for the same reason.

Two guards take `--scan-tree`, which applies their rules to every tracked file instead of the
staged set, and `identity-guard.sh` takes `--scan-history`, which applies its list to the commits
already on the branch. That is the audit mode: it reads the terms from the repository rather than
from a document that then drifts — and for the history it is also the only mode there is, since a
header a machine with no hook configured wrote is past the hook by the time anyone looks.

`identity-guard.sh` is the one guard that does not read the staged set at all. Which identity a
commit is made as is neither a staged path nor a staged byte: it is `git var GIT_AUTHOR_IDENT`,
asked of git rather than derived, so the guard judges the identity the commit will actually carry
rather than a second implementation of that lookup.

The bypass is `git commit --no-verify`, deliberately and universally. A control with no bypass is
a control that gets uninstalled.

## 5. A shim resolves the guards in four steps, in this order

`.githooks/pre-commit` decides *which checkout of the protocol* it loads, and nothing else. That
choice has to be made before anything can be read from the protocol, which is why it is the one
decision the shim owns rather than `guards.sh`:

1. `PROTOCOL_GUARDS`, if set — an explicit override, for a checkout under test.
2. `<repo>/guards/guards.sh`, if it exists — this repository guarding itself.
3. `<repo>/protocol/guards/guards.sh`, if it exists — the checkout this repository's own doctrine
   is read from, and so the one its receipt (§11) names.
4. `${PROTOCOL_DIR:-$HOME/.pablo-protocol}/guards` — the well-known path `bin/adapt` symlinks to
   whatever clone the machine uses.

Step 3 exists because step 4 is **one path per machine**, where a tenant's own `protocol/` is one
per repository. Where the two resolve to different checkouts — one tenant that pins a tag while
the machine tracks a branch, or two tenants wired to separate clones — step 4 alone would judge
one of them by the other's guards, a tenant reading its doctrine from one checkout and being
refused, or not refused, by another. Step 3 is the entry that always agrees with what that tenant
reads, because it is the same entry it reads through.

The well-known path is what keeps a machine-local path out of every tenant's committed hook.
`bin/adapt` creates it and **never repoints an existing one**: where it already exists, that is
somebody's choice.

**A tenant may write its own shim, and some do** — one that dispatches guards of its own alongside
these, for instance. Then this order is that tenant's to honour, and `bin/doctor` says nothing
about it: it can read the order out of a shim that came from `tenant-template/`, and not out of a
dispatcher it has never seen. A check that reported a fault against a correctly wired repository
would be a check people learn to scroll past.

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
| `PROTOCOL_PROTECTED_BRANCH` | `main` | the branch those guards refuse a push or a pick onto |

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
  clone is which, it has stopped being protocol and started being one tenant's context.
- **`doctrine/README.md` is the directory's index, not a doctrine document**, and an adapter that
  walks `doctrine/*.md` excludes it. It carries no `name`/`description` frontmatter, so wiring it
  would install something the agent cannot read.
- **A script the adapter installs is a file in the adapter, never a heredoc inside `adapt.sh`.**
  `adapters/cortex/run` is the example: tracked here, copied into the tenant unchanged, and so
  covered by the sweep that shellchecks every tracked file with a shebang. A script written from a
  string inside another script is a script no checker can see, and the tenant runs it anyway.
  `bin/doctor` compares each `adapters/*/run` with the tenant's copy for the same reason the receipt
  is compared with the checkout: the adapter writes the file whole and `bin/adapt` then skips it
  forever, so a tenant installed before the adapter changed keeps the old one silently. It reports
  the difference as a note, because a tenant may have meant it.

The guarantee a consumer may rely on: **deleting every adapter leaves the protocol intact.**
`bin/adapt` runs on a machine with none and says so.

## 8. `bin/adapt` is idempotent and additive

It skips anything already present, prints one line per change, and never removes anything. A second
run installs nothing: `skip` for each file already there. The one file it rewrites rather than skips
is the receipt in `.protocol/protocol-version` (§11), printed as `record`, and every field of that
line is read out of the protocol checkout — so a second run from the same commit writes the same
bytes and the tenant is left byte for byte as it was. `--copy` substitutes copies for symlinks throughout, for a machine
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
- **A package registry.** Nothing here is published to one. Consumers clone this repository and
  track a branch, or check out a tag or a commit if they would rather not move with it; a tag is a
  human-readable name for one commit, not a distribution channel.
- **Configuration merging.** No adapter merges into a file a tenant wrote (§7). There is
  deliberately no schema-aware merge of an agent's settings file, because a tool that rewrites a
  person's configuration is a tool they stop running.
- **Windows.** The scripts are bash and use symlinks, `git`, and POSIX tools. They are not tested
  anywhere else.
- **Anything that identifies a tenant.** No tenant names, no repository names, no machine names,
  no accounts, no addresses. `guards/tenant-guard.sh --scan-tree` enforces it against this tree on
  every commit and in CI, over identifier shapes and over the words a tenancy is described with.
  The proper nouns it would otherwise have to list are in the untracked overlay (§3), because a
  denylist in a public repository cannot name what it denies — the list would be the disclosure.
  `.protocol/tenant` is exempt from the scan it configures, which is why keeping the names out of
  the tracked half is structural rather than a habit.

## 11. A tenant records which protocol installed it, and the record is a receipt rather than a pin

`protocol/` is a symlink. The checkout behind it can be moved by whoever develops this protocol and
no file in the tenant changes — the tenant would read different doctrine and be judged by different
guards with nothing to see in a diff. That is two questions wearing one answer, and they separate
cleanly:

1. **Which protocol judges a commit.** Decided live, by following `protocol/` at the moment of the
   commit. No file in the tenant can answer it, because no file in the tenant changes when the
   answer does.
2. **Which protocol installed the files that are here** — the shim, the seeded policy files, the
   agent launchers, each written once and skipped forever after. Frozen at the last `bin/adapt` run.

`.protocol/protocol-version` answers the second, and only the second. One line, the first that is
neither blank nor a whole-line comment: `<ref> <short-sha> <date>`, where `ref` is the branch the
installing checkout was on, or the tag it was exactly at, or the bare commit when it was on
neither. `bin/adapt` **rewrites it on every run**, because a receipt stating an install other than
the last one is precisely the drift it exists to report; every field comes from the checkout, so
two runs from the same commit write the same bytes. It is not edited by hand — an edit claims an
install that never happened, and the next run overwrites the claim.

`bin/doctor` asks the first question live and reads the second off that line. Where the ref names a
branch, it reports whether `protocol/` is still on it and how far behind `origin/<ref>` the last
fetch left it — a note, because being behind breaks nothing until you commit against doctrine you
have not read. Where it names a tag, it checks the checkout is at that tag, which is the whole of
what a consumer who would rather pin wants. Either way it reports separately when the checkout has
moved past the commit recorded, because that is the install going stale rather than the protocol.

`bin/doctor`, run in a tenant, also
reports the failures that are otherwise silent because nothing reads them until something else
fails: a skill symlink whose target has moved, `core.hooksPath` unset in a fresh clone, and a
`.protocol/tenant` that parses to zero terms. It counts those terms and never prints one, for the
reason §3 gives.

Where there is no receipt to read, because the repository is one worked on under a tenant rather
than a tenant, the first question is still which protocol judges a commit — and the shim answers
it. So
`bin/doctor` resolves the guards the way `tenant-template/.githooks/pre-commit` does, in that order,
and reports the checkout it lands on. That duplicates the shim's order in a second place, which is a
cost paid deliberately: the shim ends in an `exec` of the chain against the index, so the only way
to report what it would resolve without committing is to resolve it again.
