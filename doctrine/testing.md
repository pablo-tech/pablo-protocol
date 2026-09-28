---
name: testing
description: Tests held to the same standard as code — one behaviour per test, testability as a property of the design rather than of the suite, real implementations over mocks, and the rule that a test must be able to fail.
---

# Testing

**Tests are code and are held to the Clean Code standard** — the same bar for naming, size, single
responsibility and DRY. What is specific to tests:

- **One behaviour per test, named for the behaviour it pins.** The name is read far more often than
  the body; it is the failure message.
- **F.I.R.S.T.** — fast, isolated, repeatable, self-validating. Asserts, never eyeballed output.
- **Testability is a property of the design, not of the suite.** If exercising a unit needs elaborate
  scaffolding, a network, wall-clock time or a deep mock tree, the production code is the defect. Fix
  the seam: inject the dependency, split the god-function, push the input and output to the edge.
- **Hit real implementations, not mocks**, unless mocking is the only option.
- **Don't test what cannot fail.**
- **New *or modified* behaviour gets its test in the same change**, not a follow-up — changing
  behaviour means changing or adding the test that pins it.
- **Prefer writing the test first.** A test written first cannot pass vacuously, because it has to be
  red before the fix exists.

## A test must be able to fail

One that passes whether or not the property holds is not a test. This is not a theoretical
concern — it is the ordinary result of writing the assertion after the code, of a stub broad enough
to swallow the exact case the test claims to check, or of a suite whose setup silently no-ops.

The red-first discipline is the cheapest defence, and it has a corollary worth stating: when a suite
written before its implementation reports some checks already passing, those checks are the ones to
distrust. A check that "passes" because the thing under test does not yet exist is telling you about
its own construction, not about the code.
