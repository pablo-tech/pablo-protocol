# Changelog

All notable changes to the protocol and its mechanism are documented here. This project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**A tag here is a marker, not a distribution.** Nothing is published to a registry; a consumer
clones this repository and tracks a branch, or checks out a tag or a commit if they would rather
not move with it. A tag exists only so that one commit has a human-readable name. This file is
where you find out what pulling gets you.

Breaking changes are named as such, and are what a tag is now cut for. A change to the doctrine
frontmatter contract, to the guard resolution order, to a policy file's name or meaning, or to the
adapter contract breaks every consumer the moment they pull, so it is announced here first and
given a version number — a name for the commit before it, which a consumer who would rather not
move with `main` can stop at.

## [Unreleased]

### Added

- **A tenant reports a defect in the protocol as an issue in its own repository, not as a pull
  request here** (`doctrine/tenancy.md`). The guard a tenant relies on judges a commit in that
  tenant's repository, and a pull request opened here is none of those things — not the branch, not
  the body, not a pasted terminal session, not the unchanged lines a diff carries as context. This
  repository's own denylist cannot cover the gap either, since the terms that would catch a tenant's
  material are the proper nouns it exists in order not to hold. Filing in the tenant's repository
  puts the report back inside the control that was already running when it was written, and what
  crosses into this repository is a description of a defect restated as the general thing it is.
  `CONTRIBUTING.md` says what happens to a pull request that arrives the other way.

## [0.6.0] — 2026-09-30

### Changed

- **`.protocol/protocol-version` is a receipt rather than a pin, and a tenant is expected to track
  a branch** (breaking: a policy file's meaning changes — `ARCHITECTURE.md` §11). The file used to
  hold a tag a tenant wrote and moved by hand, and was read as the answer to which protocol judges
  that tenant's commits. It could never be that answer: `protocol/` is a symlink, and what judges a
  commit is whatever that symlink resolves to at the moment of the commit, with no file in the
  tenant changing when it moves. So the two questions are separated. `bin/adapt` now **rewrites**
  the file on every run — printed as `record`, in place of the `skip` and the never-shipped `keep`
  — with `<ref> <short-sha> <date>` read out of the checkout it ran from, which answers only the
  question it can: which protocol the files installed in this tenant came from. Every field being
  derived from that checkout is what keeps the run idempotent, so a second run from the same commit
  still leaves the tenant byte for byte as it was.

  `bin/doctor` asks the other question live. Where the recorded ref is a branch it reports whether
  `protocol/` is still on it and how far behind `origin/<ref>` the last fetch left it, as a note —
  being behind breaks nothing until you commit against doctrine you have not read — and it says how
  old that ref's tip is, so "current" cannot quietly mean current with a stale fetch. **Where the
  ref is a tag, the check is exactly the one made before**, so a consumer who would rather pin
  changes nothing but keeps getting fixes only when they move. Either way it reports separately when
  the checkout has moved past the commit recorded, which is the install going stale rather than the
  protocol.

  **For a tenant:** check the protocol clone out on `main`, re-run `bin/adapt`, and commit the line
  it writes. Do not hand-edit that line again — it claims an install that never happened, and the
  next run overwrites the claim.

- **A plan is warp-ready or it is not a plan** (`doctrine/planning.md`). The rule was already
  there and hedged: "a warp-ready plan by default" named an exception without saying what earns
  one, so the plan that reached for it was always the small change — which is exactly the plan that
  then arrives with no worktree, no pre-phase SHA and no per-phase undo. The hedge is gone. It also
  closes the reading that the seven fields may be carried once for a whole plan rather than per
  phase, which the section above it already forbade.

### Fixed

- **The well-known path was reported as an absolute home directory rather than `~/...`.** In
  `${var/pat/repl}` an unquoted `~` in the replacement half is tilde-expanded back to `$HOME`, so
  the one line written to shorten a home path printed it in full, on every run, for every tenant.

## [0.5.2] — 2026-09-30

### Fixed

- **`bin/doctor` no longer reports a fault against a tenant that wrote its own pre-commit shim.**
  The check reads the guard resolution order out of the file, which it can do for a shim that came
  from `tenant-template/` and cannot do for a dispatcher it has never seen — so it now asks the
  question only of the former, recognised by the `PROTOCOL_GUARDS` every version of that template
  has named. A tenant dispatching guards of its own alongside these was being told its hook never
  consults its own `protocol/` while it did, and a check that is wrong about a correctly wired
  repository is one people learn to scroll past. `ARCHITECTURE.md` §5 says so where the order is
  written down.

## [0.5.1] — 2026-09-29

### Fixed

- **`bin/doctor`'s remedy for a stale pre-commit shim named an action that does nothing.** It said
  to re-run `bin/adapt`, which seeds that file and then skips it forever because it exists — so a
  tenant that followed the advice saw the installer say nothing and the fault persist. It now names
  the copy from `tenant-template/` and says outright that the installer will not do it. A remedy a
  reader can carry out and still be wrong is worse than no remedy.
- **The cortex launcher is a file in the adapter rather than a heredoc inside it.**
  `adapters/cortex/run` is tracked and copied into the tenant unchanged, so the sweep that
  shellchecks every tracked file with a shebang covers the script tenants actually run: a script
  written from a string inside another script is a script no checker can see. The SC2155 it had
  been carrying — `export SNOWFLAKE_HOME="$(cd ...)"`, whose exit status is `export`'s, so a `cd`
  into a directory that had moved would be silently successful — is fixed in the same move, and
  every tenant installed from an earlier version still has it.

### Added

- **`bin/doctor` reports a launcher that differs from the one this protocol installs**, as a note
  rather than a fault. A launcher is not a seed: the adapter writes it whole and the tenant does
  not own it, but `bin/adapt` skips it forever once it exists, so a tenant installed before the
  adapter changed keeps the old one with nothing anywhere to say so — the same shape of drift the
  pin check exists for, one directory down. A note because nothing here can tell an old install
  from a tenant that meant it, and a doctor that fails on both is one nobody runs.

## [0.5.0] — 2026-09-29

### Added

- **`.protocol/protocol-version` is part of the tenant contract** (`ARCHITECTURE.md` §11). The
  tenant's `protocol/` is a symlink, so the checkout behind it can be moved to another tag and no
  file in the tenant changes: it would read different doctrine and be judged by different guards
  with nothing to see in a diff. `bin/adapt` now writes the tag it installed from into that file,
  or a `# unpinned` comment when the checkout is not at one, and **never rewrites an existing
  value** — moving a pin is reading what changed, checking out, and editing the file, not a side
  effect of re-running the installer. `tenant-template/` carries the file with its header and no
  value, so the documented `cp -r tenant-template/. .` install still works.
- **`bin/doctor`** — what a tenant can check about its own wiring, written once here rather than
  once per tenant. Four questions, each with a silent wrong answer: the pin against the checkout,
  every tracked symlink against its target, `core.hooksPath` against a fresh clone that does not
  carry it, and a `.protocol/tenant` that parses to zero terms. It counts terms and never prints
  one, for the reason `ARCHITECTURE.md` §3 gives, and reuses `guards/policy.sh` to count them
  rather than carrying a second parser of the same file.

### Changed

- **The pre-commit shim consults the tenant's own `protocol/guards` before the well-known path**
  (`ARCHITECTURE.md` §5, now four steps). The well-known path is one per machine, so a machine
  holding two tenants at two pins had one guard chain between them and one of the two was judged
  by the other's version. Additive: a tenant with no `protocol/` entry resolves exactly as before.
- **`bin/adapt` sets `core.hooksPath` when `.git` is a file, not only a directory.** In a worktree
  or a submodule `.git` is a file, so the shim was installed, never pointed at, and nothing said
  so — every file present and no guard running.
- **An adapter's ignore rules are installed as one set, and the "tenant already said something
  about this path" test runs against the tenant's own lines with that set removed.** Matching on
  the first path segment alone meant the first rule an adapter wrote silenced every later rule
  under the same directory: the cortex adapter's `/.agents/*/connections.toml` — the file naming
  an account and a key path — was never written, because `/.agents/*/cortex/logs/` was written
  first. The behaviour that rule exists for is unchanged: an exception a tenant carved out for
  itself is still never buried by a broader pattern appended underneath it.
- **`bin/adapt --copy` strips the copied `protocol/.git`.** A copy is not a checkout; carrying the
  `.git` in had git answer about the repository the copy was taken from, so the copy reported
  whatever that repository is at *now* — a version claim that is worse than no answer, and one
  `bin/doctor` then has no way to notice.

## [0.4.0] — 2026-09-29

### Added

- **`doctrine/README.md`** — the doctrine's own front door, and the page the directory URL should
  have opened on all along. It is what each of the eight documents holds you to and why it is
  shaped that way, which is a different axis from `AGENTS.md`'s table of which one to read before
  which piece of work, so neither restates the other. Not a doctrine document itself: it carries
  no `name`/`description` frontmatter, and an adapter walking `doctrine/*.md` now excludes it
  (`ARCHITECTURE.md` §7) rather than installing a skill no agent could read.

### Changed

- **The README is two named sections instead of five interleaved paragraphs.** *The doctrine*
  comes first, with all eight rules quoted and two worked out in full; *A doctrine only holds if
  it travels* carries everything mechanical. The worked example's protagonist changes from an
  install to a rule — the 25 MB ceiling, from the sentence that states it to the commit the guard
  refuses — and its anchor moves with it, from `#a-new-tenant-end-to-end` to
  `#a-rule-from-written-to-enforced`. `AGENTS.md` and `START-HERE.md` are repointed. Documentation
  only: no guard, policy file or adapter behaviour changes, so a consumer who never moves their
  pin sees nothing.
- `START-HERE.md`'s reading track opens on the rules rather than on the argument for why they are
  a repository, and no longer tells a reader to stop before they have seen one.

### Fixed

- `ARCHITECTURE.md` §1 cited §6 for the check that keeps doctrine tenant-free. §6 is *Environment
  variables*; the check is §10.
- The README enumerated seven of the eight skills a tenant gets, omitting `as-built`.
- `START-HERE.md` gave two counts — "Four paragraphs", "Four limits" — that a reader could
  falsify by scrolling, and neither was still true.

## [0.3.0] — 2026-09-29

### Added

- **Policy files have a second, untracked layer.** `guards/policy.sh` now reads `.protocol/<name>`
  and then appends `.protocol/<name>.local`, and either may be absent. This is a change to policy
  resolution (`ARCHITECTURE.md` §3) and so to the consumer contract, but an additive one: a
  repository with no `.local` file resolves exactly the list it resolved before, and nothing is
  refused that was not refused already. It exists because a policy file that is published cannot
  state what it protects against — the list would be the disclosure — so the tracked file carries
  the shapes and the categories and the overlay carries the proper nouns. `bin/adapt` gitignores
  the overlay in every tenant, before one can exist.
- **The Claude Code adapter installs commands as well as skills**, one symlink per file under
  `adapters/claude-code/commands/`: `phase-done` (snapshot a phase into its plan document, then
  `/clear`) and `turn-cost` (what the last turn cost, from real token counts). Both existed only
  inside one tenant's configuration and would have been rewritten by hand for the next; they are
  rules about how work is done, so they belong here. The commands layout is flat where the skills
  one is nested, so the link target is one level shallower — a check pins that, because the wrong
  depth gives a dangling link that `-e` fails and `-L` then skips on every run afterwards.
- `PROTOCOL_PROTECTED_BRANCH` (`ARCHITECTURE.md` §6). The two branch-aware command guards held the
  name `main` as a literal in three places each; the branch that takes merges rather than commits is
  a role, and a tenant whose deploy branch is called something else now sets one variable instead of
  editing a guard. The default is `main`, so nothing changes for a tenant that does not set it.
- `doctrine/as-built.md`: the document that describes a system is part of that system, updated in
  the same change that changes the system. Its second half is the novel part — a document *found*
  to disagree with the system is corrected in the change that found it, because the evidence is
  never again as good as at the moment of discovery. An eighth doctrine file, so the counts in
  `ARCHITECTURE.md`, `README.md` and `START-HERE.md` move with it.

### Changed

- **`.protocol/tenant` no longer lists proper nouns.** The tracked half now carries only identifier
  shapes and the handful of words a tenancy is described with; the names moved to the untracked
  overlay this release added. A denylist in a public repository cannot name what it denies — read
  backwards, the list is what the repository is protecting, which is the disclosure the file was
  written to prevent. `ARCHITECTURE.md` §10, `CONTRIBUTING.md` and the CI step said this repository
  enforced the rule against itself; the file is exempt from the scan it configures, so that was a
  guarantee none of the three could make. All three now describe the split that does make it.
- The rule now reaches the argument, not only the names. A document that explains a rule by who
  someone works for is refused on the same commit hook as one naming a repository, so the papyrus
  rule is a gate rather than a review note.
- The documents no longer argue from the situation that produced them. `README.md`, `doctrine/`
  and the guard comments stated rules as things that had happened to a particular reader; they now
  state them as properties of the design. No mechanism changed and every rule keeps its force.

### Fixed

- `cherry-pick.sh` attributed to `doctrine/git.md` a `dev`-to-`main` promotion the document does not
  state. It says promote whole, never by cherry-pick, and names no branch.
- `bin/adapt --help` printed three lines of the script's own source. The help text ended at a line
  number, and the block it described grew past it.

## [0.2.0] — 2026-09-28

### Added

- The public documentation set: `README.md`, `ARCHITECTURE.md`, `START-HERE.md`, `CONTRIBUTING.md`,
  `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `LICENSE` and this file. `ARCHITECTURE.md` is
  the first statement of what a consumer may rely on, and so of what counts as a breaking change.
- CI: every suite, `shellcheck` over every script, `guards/tenant-guard.sh --scan-tree` over the
  whole tree, and a Developer Certificate of Origin sign-off check that exempts `[bot]` authors.

## [0.1.1] — 2026-09-28

### Fixed

- An adapter's `.gitignore` rules no longer override a rule the tenant already wrote about that
  path. A tenant ignoring `projects/*/*` while keeping `projects/*/memory/*.md` tracked lost that
  memory to a broader pattern appended underneath, because the last matching pattern wins.

## [0.1.0] — 2026-09-28

### Added

- The protocol as seven documents under `doctrine/`, indexed by `AGENTS.md`, each carrying only
  `name` and `description` frontmatter so one file serves an agent's skill loader and every other
  reader at once.
- `guards/` — `size-guard.sh`, `credentials-guard.sh` and the new `tenant-guard.sh`, dispatched by
  `guards.sh` and configured by per-tenant policy files under `.protocol/`.
- `bin/adapt`, idempotent, symlinking by default and taking `--copy`; `adapters/claude-code/` and
  `adapters/cortex/`; `tenant-template/`.
- The agent's own runtime state — session transcripts above all — is refused by the Claude adapter's
  ignore rules before the first session can write any.

[Unreleased]: https://github.com/pablo-tech/pablo-protocol/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.5.2...v0.6.0
[0.5.2]: https://github.com/pablo-tech/pablo-protocol/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/pablo-tech/pablo-protocol/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/pablo-tech/pablo-protocol/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/pablo-tech/pablo-protocol/releases/tag/v0.1.0
