---
name: Adapter or doctrine proposal
about: Support for another AI coding agent, or a change to the protocol itself
labels: enhancement
---

**Which is this** — an adapter for an agent, or a change to a `doctrine/` document?

**For an adapter:** which environment variable relocates that agent's configuration directory, and
does it already read `AGENTS.md` from the working directory? Those two answers are most of the
work; [adapters/README.md](../../adapters/README.md) is the contract for the rest.

**For doctrine:** the rule you want changed, and the situation where the current one produced the
wrong outcome. Doctrine is opinion and it changes on evidence, not on preference — a case where
following it cost something is the argument.

**What it must not require.** A new dependency, a copy of protocol content into an agent's own
configuration directory, or anything that names a particular tenant, are the three things this
repository does not take. If your proposal needs one, say so — the constraint may be the thing
worth discussing.
