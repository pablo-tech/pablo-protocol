---
name: planning
description: What a plan has to contain before it can be executed without further check-ins — objective first, a worktree named as step one, per-phase summaries and rollback, and where the document lives.
---

# Planning

A plan is not a build artefact and does not ship. **Planning documents live in the context
repository, under a path mirroring the one they would have had inside the repository they plan for**
— never inside that repository. Leaving a plan where it applies means every repository re-derives
its own answer to "where do plans live" and drifts.

A repository's own `docs/` still holds **operational** reference: runbooks, architecture-as-built,
ops documents. The line is forward-looking intent ("what we are going to do and why") against
current-state description ("how this works today"). When genuinely unsure, treat anything titled
plan, milestone, roadmap, evaluation or migration as planning.

## Every plan states its objective before its context

One short paragraph naming what the plan is for and what "done" looks like, at the top, ahead of any
background. A reader should not have to infer the goal from the remediation.

## Every plan is drafted to be warped

Assume approval is the last check-in and the plan runs straight through to production — so anything
the executing session would otherwise come back and ask about belongs in the plan. Concretely: the
branches and worktrees and the merge order, the migrations and the secrets or resources to set, the
deploy targets, how to verify each step, and which steps are irreversible enough to stop and ask.

**All of that is stated per phase, not once for the plan.** A milestone is executed and unwound
phase by phase, so a plan that states its worktree, its rollback and its verification globally still
sends the executing session back to ask. Each phase names:

| | |
|---|---|
| Summary | see below |
| Worktree | the command that creates it and the command that removes it |
| Pre-phase SHA | the exact commit this phase can be rewound to |
| Deploys to | what changes in the world when this phase lands, or "nothing" |
| Work | what is done |
| Verify | how the phase is known to have worked — a command, not an inspection |
| Undo | the one command that reverses it |

**Every phase opens with a brief executive summary**, in the voice the closing report's summary uses:
what is broken, what changes, what it costs, what the risk is — written for an architect who does not
know this codebase. A plan is read and approved phase by phase, so a summary that exists only at the
top is not available at the moment anyone needs it.

**A code task raised in planning mode means a warp-ready plan by default** — not a sketch to discuss
and then re-plan.

## Every plan sets up its own worktree, and names it as its first step

A plain `git worktree add -b <branch> <path> origin/<deploy-branch>`, created before the plan's first
edit and removed at cleanup. A plan that does not name its worktree is not ready to execute.

**Never edit in a standing checkout.** A standing checkout is what a machine runs, what another
session may be mid-change in, and what a deploy fast-forwards — an edit there is live before anyone
has reviewed it, and a branch switch takes whatever reads that tree with it. Run
`git branch --show-current` before the first edit, not after the last.

## Every plan has a Rollback section

The exact pre-deploy commits or tags of each deploy branch, which merge commits to revert, whether
the migrations are additive, what secrets or resources were added, and the commands that undo it. A
plan without one is not ready to warp.

**Every phase is reversible on its own.** A phase that cannot be undone is split until it can, or it
stops and asks. Ordering is itself a rollback property: sequence the phases so the thing being
replaced is still in place until its replacement is proven, and so the irreversible step is last.
