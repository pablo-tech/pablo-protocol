---
name: git
description: Commit and branch discipline — who decides to commit and push, what a commit message says, how a promotion works, why the file-size ceiling is enforced at commit rather than push, and why every repo-scoped command names its repo.
---

# Git

- **Don't commit unless asked. Don't push unless asked.** A warp lifts both for the scope of one
  approved plan, and nothing else does.
- Never use `--no-verify`, `--force`, or `--amend` on published commits without asking first.
- Commit messages: imperative mood, one line, focused on *why* rather than *what*.
- **Every repository-scoped command names its repository** — `gh -R owner/repo`, `git -C <path>`,
  `repos/owner/repo/...` for an API call. This includes commands handed to a person to run, which
  may execute outside any checkout. A command that relies on the current directory is a command that
  eventually runs in the wrong one.

## Branch protection does not have an organization-wide default

GitHub has no organization-wide default for branch protection, head-branch deletion, labels or
required checks, so every repository drifts alone. The answer belongs in one declarative file that a
script reconciles, run after creating a repository or an organization — not re-decided per repository.

## Promote whole, never by cherry-pick

A promotion merges all of the source branch, and only once that branch is clean: checks green,
nothing unsoaked or half-done. If part of it is not ready, fix or revert it on the source branch
first. A cherry-picked target branch diverges, and the next whole promotion conflicts.

## Heavy files: a ceiling enforced at commit

**Large files live in object storage. Repositories keep information extracted from them, never the
files themselves.** Build artefacts and dependencies get ignored rather than moved — they are
neither records nor information.

The ceiling is 25 MB per file, enforced by [`guards/size-guard.sh`](../guards/size-guard.sh). That
script is the single source and every repository carries only a thin `.githooks/pre-commit` shim
that calls it, so the threshold changes in one place. Do not copy the logic into a repository.

**Why at commit rather than at push:** GitHub hard-rejects any blob over 100 MiB, and by the time a
push is refused the blob is already in local history — the branch then stays unpushable until history
is rewritten, which costs a force-push to every branch that carries it. Refusing the commit is the
cheap end of that trade.

`core.hooksPath` is local configuration and does **not** travel with a clone. On a fresh clone:
`git config core.hooksPath .githooks`. The shim fails closed if the guards cannot be found.
