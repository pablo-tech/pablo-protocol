---
description: Snapshot one phase's progress into the plan document, then prompt a /clear so the next phase starts on a fresh context.
---

You are closing out one phase of a plan. The point is to end this session's context growth here: a
long-running session re-reads its whole transcript every turn, and past the long-context tier that
costs double. The plan document is the handoff artefact, and the next phase resumes from it in a
fresh session.

Do this now:

1. Identify the plan document this session has been working from. It lives in the context
   repository, under a path mirroring the one it would have had inside the repository it plans for
   — see `protocol/doctrine/planning.md`. If more than one could be meant, ask which.

2. Append or update a short **Progress** entry in it, carrying only what a fresh session needs to
   continue. Not a transcript:
   - which phase just completed, and its outcome — shipped, gate result, commit SHA
   - the exact next phase, and its first concrete step
   - any decision or gotcha found this phase that is not already written down
   - `file:line` anchors for where the next phase starts

3. Leave committing to whoever asked for the work, unless they have already said otherwise.

4. Then say, in one line, that the phase is snapshotted and that they should run `/clear` before
   starting the next one — you cannot run it yourself.

Keep the edit tight. Do not re-read large source files to write it: this session already holds what
it needs.
