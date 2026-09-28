---
name: warp
description: The delegation mode. Say "warp" to take an approved plan from approval to deployed product with no further check-ins — what that authorizes, the four things it still stops for, and the report it ends with.
---

# Warp

**"warp" means: take the plan from approval to deployed product with no further check-ins.**
Commit, push, open and merge the pull requests, run the migrations, set the secrets, deploy to
production, and make every decision along the way by best judgement. The authority is delegated at
the moment the word is said, and it overrides a standing "don't commit or push unless I ask".

A warp is scoped to one approved plan. It is not a standing grant, and it does not carry into the
next request.

## What it still stops for

Warp covers reversible work. Four things are not reversible, and each one stops and asks however
small it looks:

- **Publishing externally.** Making a repository public, publishing a package, posting to anything
  the world can read. A minute of public is public forever; indexing and forks do not honour a
  reversal.
- **Destroying data.** Destructive migrations, dropping a table, deleting a bucket or a repository.
- **Spending money above noise.**
- **Losing a credential irreversibly.** This is the only one that is about *reading* rather than
  writing, and it cuts the other way: a warp is explicitly authorized to read credentials, and to
  commit one to the repository that holds them. It stops only where a later step could not recover
  the value. The ordering that follows is: salvage the credential first, then delete whatever held it.

**A publish that a merge triggers is still a publish.** Where merging to a branch runs a release
job, that merge belongs to the owner however small the diff, and *the diff not touching the
published artefact is not an exemption* — the job keys on the push, not on the paths.

## Working around other sessions

Sessions run in parallel, so no session's work waits on another's checkout. A shared checkout often
holds someone else's uncommitted work, sometimes on its own branch. Leave it exactly as found and
say nothing about it: it is not the warp's to commit, stash, revert or report. Route around it — the
warp's own work happens in a separate worktree off the deploy branch, which is a plain
`git worktree add`, no coordination and nothing to wait for.

A session that finishes by reporting itself blocked on where someone else parked a checkout has not
finished.

## The closing report

A warp ends with a report: an **Executive Summary** first, then the itemized list of what was done,
the decisions made, how to test it, and the rollback.

**The Executive Summary is written for an architect who does not know this codebase** — no
continuous-integration, web or product implementation background assumed. What was broken, what it
cost, what changed, what it costs now, and what is still open. Name a tool or a file only when the
sentence fails without it, and spell out any acronym the first time. The itemized sections below it
stay as technical as they need to be; the summary is the part someone can act on without reading them.

**The report is filed, not just printed.** A warp confined to one repository updates that repository's
own planning document with the outcome, and *that* is the record — no second file. A warp spanning
several has no such home and is filed once, under a dated path, report first with the approved plan
below it. Either way the scratch plan goes: it is working material, not a record, and leaving the
outcome only there files nothing.

The report is what happened; a planning document is the intent. A lesson meant to outlive the warp
belongs in the planning document it concerns, not restated in the report.

## Cleanup

Once the goal is deployed and verified, remove the warp's worktrees and delete its local and remote
branches. A merged branch left behind is noise the next session must re-audit.

Clean up after yourself, and **only** after yourself: the worktrees, branches, scratch files and test
artefacts *this* session created, nothing else.
