# Adapters

An adapter teaches one AI coding agent to read the protocol. It is deliberately the smallest part of
this repository, and it is meant to stay that way: **the protocol is `AGENTS.md` and `doctrine/`, and
an agent that reads neither still gets nothing wrong** — it just reads them as ordinary documents.

Delete every adapter and the protocol is intact. That is the test, and `bin/adapt` runs the machine
without one if it detects none.

## The contract

A directory under `adapters/` with three files:

| File | Contract |
|---|---|
| `detect.sh` | exit 0 if this agent is installed on the machine, non-zero otherwise. No output. |
| `adapt.sh` | `adapt.sh <tenant-dir> <link\|copy>` — wire that tenant for this agent. Idempotent: a second run changes nothing. It may create files; it may not *edit* a file the tenant already has. |
| `README.md` | which environment variable relocates this agent's configuration directory, what the adapter installs, and how to check it worked. |

`adapt.sh` reports each action as `  <verb> <path>`, two spaces in, so a run reads as one list.

## Three rules the contract exists to hold

**Point the tool at the repository; never copy configuration out of it.** Every agent worth adapting
has an environment variable that relocates its configuration directory. Use it. An adapter that
copies files into the agent's own home has created a second copy that will drift, and drift is the
failure this repository exists to prevent.

**An adapter may create, but never edit.** If the tenant already has the file the adapter would
write, the adapter says so and leaves it. A tool that rewrites a person's instruction file is a tool
they stop running.

`.gitignore` is the one file an adapter appends to, because the runtime state an agent writes into
the tenant has to be refused before the first session writes any. The rule still holds there: a
tenant that already has a rule about that path keeps it, exactly as written. A context repo may
ignore `projects/*/*` while keeping `projects/*/memory/*.md` tracked, and a broader `/projects/`
appended underneath would win as the last matching pattern and untrack the memory it meant to keep.

**An adapter carries rules, never a list of repositories.** Where an agent offers a hook, the rule it
enforces has to be one an unrelated reader would recognise — a flag that defeats a check, a branch
that takes merges rather than commits. The moment it needs to know which clone is which or which
merge publishes a package, it has stopped being protocol and started being one tenant's context,
and it belongs in the tenant's own hook beside this one.

## Adding one

Work out which variable relocates the agent's configuration directory, and whether it reads
`AGENTS.md` from the working directory already — several do, and for those the adapter is almost
empty. Then write the three files and add nothing to `bin/adapt`: it discovers the directory.
