# The protocol

This file is the entry point. Every AI coding agent reads `AGENTS.md` from the repository it is
working in, or can be told to; nothing below depends on which one you are.

**The protocol is these documents. Everything else in this repository exists to install them or to
enforce them.** Each is written as a forcing function rather than as advice: a rule shaped so the
failure it prevents either cannot happen or announces itself while it is still cheap to fix. Read
the one that applies to what you are about to do.

| Read this | Before |
|---|---|
| [`doctrine/warp.md`](doctrine/warp.md) | executing an approved plan without further check-ins |
| [`doctrine/planning.md`](doctrine/planning.md) | writing a plan, a milestone or a migration document |
| [`doctrine/git.md`](doctrine/git.md) | committing, branching, promoting, or adding a large file |
| [`doctrine/clean-code.md`](doctrine/clean-code.md) | writing code — or prose, which is held to the same standard |
| [`doctrine/testing.md`](doctrine/testing.md) | writing or changing a test, which is any change of behaviour |
| [`doctrine/as-built.md`](doctrine/as-built.md) | changing how a system works, or finding a document that disagrees with one |
| [`doctrine/tenancy.md`](doctrine/tenancy.md) | working for more than one tenant from one machine |
| [`doctrine/llm-output-trust.md`](doctrine/llm-output-trust.md) | changing the model, prompt or thinking mode of a call a human will act on |

That table is which one to open. [`doctrine/README.md`](doctrine/README.md) is the other axis over
the same eight — what each holds you to, and why it is shaped that way — for reading rather than
for routing.

## The two rules that hold the rest together

**One canonical home per fact.** A fact, a mechanism or a number is written down once, in the
document that owns it, and linked from everywhere else. Two copies drift, and one becomes a lie with
no signal which. This is why the protocol is a repository rather than a paragraph pasted into each
project's instruction file.

**Enforcement lives in git, not in an agent.** A rule written into one tool's configuration stops
one command in one tool, and says nothing about a diff produced by a different tool, by an editor,
or by hand. The guards in [`guards/`](guards/) run at commit time, so they bind every agent equally —
including the ones that do not exist yet.

## What a tenant repository carries

A tenant is whoever the work belongs to. Its context repository carries four things, all of which
`bin/adapt` installs:

```
protocol/            this repository (symlinked; gitignored — it is a machine-local path)
AGENTS.md            the tenant's own file: its facts, and a pointer to protocol/AGENTS.md
.protocol/tenant     the terms belonging to the tenants this repository is NOT
.githooks/pre-commit the shim that runs protocol/guards/guards.sh
```

Anything an agent needs that is true of *this tenant only* — which repository owns what, where its
credentials live, how its machines are set up — goes in the tenant's own `AGENTS.md`, never here.

## Installing it

[`README.md`](README.md#a-rule-from-written-to-enforced) follows one doctrine rule end to end, from
the sentence that states it to the commit the guards refuse. The short of it is `bin/adapt`, run
from inside the tenant, and `bin/adapt --list` to see which agents this machine has.

What a consumer may rely on, and what counts as a breaking change to it, is
[`ARCHITECTURE.md`](ARCHITECTURE.md).
