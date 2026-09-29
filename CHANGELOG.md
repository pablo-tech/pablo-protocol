# Changelog

All notable changes to the protocol and its mechanism are documented here. This project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**A tag here is a marker, not a distribution.** Nothing is published to a registry; a consumer
clones this repository and pins a tag or a commit, and a tag exists only so that commit has a
human-readable name. This file is where you find out what moving your pin would get you.

Breaking changes are named as such. A change to the doctrine frontmatter contract, to the guard
resolution order, to a policy file's name or meaning, or to the adapter contract breaks every
consumer on the bump they had no reason to read carefully — it happens in a major version and is
announced here first.

## [Unreleased]

### Added

- **Policy files have a second, untracked layer.** `guards/policy.sh` now reads `.protocol/<name>`
  and then appends `.protocol/<name>.local`, and either may be absent. This is a change to policy
  resolution (`ARCHITECTURE.md` §3) and so to the consumer contract, but an additive one: a
  repository with no `.local` file resolves exactly the list it resolved before, and nothing is
  refused that was not refused already. It exists because a policy file that is published cannot
  state what it protects against — the list would be the disclosure — so the tracked file carries
  the shapes and the categories and the overlay carries the proper nouns. `bin/adapt` gitignores
  the overlay in every tenant, before one can exist.
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

[Unreleased]: https://github.com/pablo-tech/pablo-protocol/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/pablo-tech/pablo-protocol/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/pablo-tech/pablo-protocol/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/pablo-tech/pablo-protocol/releases/tag/v0.1.0
