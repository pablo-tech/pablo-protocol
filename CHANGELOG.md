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
