---
name: clean-code
description: The Clean Code standard, applied to prose as well as to code — no comments without a non-obvious why, ruthless DRY, small single-responsibility units, and the Boy Scout rule with its limit.
---

# Clean Code

This applies to code *and* to prose — instruction files, prompts, skills, agent configuration,
runbooks. A bloated or duplicated document is the same defect as a bloated or duplicated function,
just paid by every session instead of by every call.

- **No comments unless the *why* is non-obvious** — a hidden constraint, a subtle invariant, a
  workaround for a known bug. No docstrings on obvious functions.
- **Don't handle what cannot happen.** Trust the guarantees the framework already makes.
- **Don't introduce abstractions beyond what the task requires.**
- **No half-finished implementations.** No `TODO` left behind unless one was asked for.
- **DRY, ruthlessly.** The same fact or logic in two places will drift, and one of them becomes a lie
  with no signal which. This is why a cross-cutting fact gets exactly one home and everything else
  links to it; the same rule governs a helper copy-pasted across call sites.
- **Small, single-responsibility units.** A function or module doing one thing, named for that thing,
  beats a god-function dispatching on twenty flags or a 900-line file owning every concern in a
  domain. Split by responsibility, not to hit a line count.
- **The why is a line, not a paragraph.** A comment, a document section or a note states the rule and,
  where needed, one line of reason. An incident post-mortem belongs in a dated history — a changelog,
  a decision record, the commit log — not reloaded in full as live policy forever.
- **Boy Scout rule:** leave the code and documents you touch cleaner than you found them — but that
  is not licence to refactor or reorganize beyond what the task requires.
- **Introduce the one thing that was asked for.** Don't restructure or rename what already works
  along the way.
- **Clean up after yourself, and only after yourself.** "Cleanup" means the worktrees, branches,
  scratch files and test artefacts *this* session created. Anything already in the tree is someone
  else's in-flight work: name it if it is in the way, and leave it where it is.
