# The protocol

This file is the entry point. Every AI coding agent reads `AGENTS.md` from the repository it is
working in, or can be told to; nothing below depends on which one you are.

**The protocol is these documents. Everything else in this repository exists to install them or to
enforce them.** Read the one that applies to what you are about to do.

| Read this | Before |
|---|---|
| [`doctrine/warp.md`](doctrine/warp.md) | executing an approved plan without further check-ins |
| [`doctrine/planning.md`](doctrine/planning.md) | writing a plan, a milestone or a migration document |
| [`doctrine/git.md`](doctrine/git.md) | committing, branching, promoting, or adding a large file |
| [`doctrine/clean-code.md`](doctrine/clean-code.md) | writing code — or prose, which is held to the same standard |
| [`doctrine/testing.md`](doctrine/testing.md) | writing or changing a test, which is any change of behaviour |
| [`doctrine/tenancy.md`](doctrine/tenancy.md) | working for more than one employer or client from one machine |
| [`doctrine/llm-output-trust.md`](doctrine/llm-output-trust.md) | changing the model, prompt or thinking mode of a call a human will act on |

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

```
git clone https://github.com/pablo-tech/pablo-protocol
cd <your context repository>
~/path/to/pablo-protocol/bin/adapt
```

`bin/adapt --list` shows which agents it can wire and which this machine has. It symlinks by default
and takes `--copy` for a machine that will not follow symlinks or whose agent configuration is
centrally managed. Running it twice changes nothing the second time.
