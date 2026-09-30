# Start here

The doctrine is more than anyone reads in order, and two different people arrive here wanting
different things. This page routes you and then gets out of the way.

**Its one rule: nothing is explained twice.** Where this file would restate a mechanism, it links
to the document that owns it. If you find an explanation here that also exists elsewhere, that is
a bug in this file.

- [A · Ten minutes, no shell](#a--ten-minutes-no-shell) — what this is and whether it is for you
- [B · Ten minutes, running it](#b--ten-minutes-running-it) — a scratch tenant on your own machine
- [Where everything lives](#where-everything-lives) — the map, once you have picked a track

---

## A · Ten minutes, no shell

**1. The rules** — [`doctrine/README.md`](doctrine/README.md), which is what each of the eight
documents holds you to and why it is shaped that way. Then open whichever one or two are closest
to what you actually do; they are opinionated and short, and they are the only part of this
repository that is normative. Everything else exists to install or enforce them, which means you
can disagree with a doctrine file, rewrite it in your fork, and nothing else here breaks.
[AGENTS.md](AGENTS.md) is the same eight on the other axis: which to open before which piece of
work.

**2. Why it is a repository and not a page in your agent's config** —
[README.md](README.md#a-doctrine-only-holds-if-it-travels). The two directions a standard gives
way when it lives in one tool's configuration file, the fixes that look obvious and fail, and one
rule followed from written to enforced.

**3. What it costs** — [*What this does not
catch*](README.md#what-this-does-not-catch), stated plainly. The one about a denylist being a
filter and not a proof is what people are most often surprised by later.

You now know enough to decide. If you are adopting it, track B; if you are changing it,
[CONTRIBUTING.md](CONTRIBUTING.md); if you are relying on it, [ARCHITECTURE.md](ARCHITECTURE.md),
which is the list of things a change here is not allowed to break.

## B · Ten minutes, running it

The [worked example](README.md#a-rule-from-written-to-enforced) in the README is this track, in six
numbered steps: one doctrine rule from the sentence that states it to the commit it refuses. Run it
against a scratch directory rather than a real repository — `bin/adapt` writes only inside the
tenant you point it at and one symlink in your home directory, but a first run is a first run.

Two things worth knowing before you start, both of which the example assumes:

- `bin/adapt --list` tells you which AI coding agents this repository can wire and which of them
  this machine has. **None is a valid answer** — the protocol is documents, and an agent with no
  adapter reads `AGENTS.md` like any other file. The example still works.
- The guards only run once `core.hooksPath` points at the tenant's `.githooks`, which `bin/adapt`
  does for you. Git cannot make that travel with a clone, which is why every fresh clone of every
  tenant needs the installer run in it once ([ARCHITECTURE.md §5](ARCHITECTURE.md#5-a-shim-resolves-the-guards-in-four-steps-in-this-order)).

Then run `bin/test.sh`. It is the same suite CI runs, it takes seconds, and watching
`bin/adapt.test.sh` build a tenant, commit through the installed hook and get refused is the
fastest way to see the whole thing work at once.

## Where everything lives

| If you want | Read |
|---|---|
| why this exists | [README.md](README.md) |
| the rules themselves | [`doctrine/README.md`](doctrine/README.md) |
| which rule to read before which piece of work | [AGENTS.md](AGENTS.md) → [`doctrine/`](doctrine/) |
| what you may rely on, and what a breaking change is | [ARCHITECTURE.md](ARCHITECTURE.md) |
| to add support for another AI coding agent | [adapters/README.md](adapters/README.md) |
| to change anything here | [CONTRIBUTING.md](CONTRIBUTING.md) |
| what your next pull gets you | [CHANGELOG.md](CHANGELOG.md) |
| to report something that gets past a guard | [SECURITY.md](SECURITY.md) |
