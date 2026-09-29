# pablo-protocol

*πρωτόκολλον — the first sheet glued to a papyrus roll, before the text began: not part of the
work, but the leaf that said what the roll was and who stood behind it. It travelled with the
roll and belonged to none of its contents.*

[![CI](https://github.com/pablo-tech/pablo-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/pablo-tech/pablo-protocol/actions/workflows/ci.yml)
[![Community Health](https://img.shields.io/badge/dynamic/json?url=https://api.github.com/repos/pablo-tech/pablo-protocol/community/profile&query=$.health_percentage&suffix=%25&label=community%20health)](https://github.com/pablo-tech/pablo-protocol/community)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A working standard — that a plan states its objective before its context, that a test must be able
to fail, that large files never enter history — is usually written into the file an AI coding agent
reads. That is the one place it cannot hold, and it gives way in two directions at once.

**It is not portable across agents.** The file is named for one vendor's tool. A second agent on
the same machine reads nothing, so the rules are copied into its configuration too, and the same
rule now exists twice and drifts. Worse, the rules only ever bound *that* agent: a diff written by
a different agent, by an editor, or by hand passes every one of them untouched.

**It is not separable from the work it was written beside.** The same file that holds *how work is
done* holds *whose work it is* — which repositories exist, where credentials live, which account is
which. The moment the standard is worth having in a second place, there is no way to hand over the
first half without the second. And nothing stops one tenant's material landing in another tenant's
history by ordinary mistake, because no tool on the machine knows the difference.

The obvious fixes each fail:

- **Copy the rules into each repository.** Now every repository has its own copy of the working
  standard, and they disagree within a month. One of them is a lie and nothing says which.
- **Ship it as a plugin for the agent you use.** That fixes distribution and deepens the lock-in:
  the protocol now requires that vendor to be installed to exist at all, and still says nothing
  about a commit made by anything else.
- **Keep it in the agent's configuration and just be careful.** This is what fails in practice.
  Discipline is the control that costs nothing until the hour it matters.

**This repository is the protocol as plain documents, plus the commit-time guards that enforce
it.** The documents are markdown under [`doctrine/`](doctrine/) and the entry point is
[`AGENTS.md`](AGENTS.md), the filename most AI coding agents already read; any agent that does not
still reads it when told to, because it is prose. The guards are shell scripts that run from a
repository's `pre-commit` hook, which is the one gate every route to history passes through —
whichever agent, editor or hand wrote the diff.

Nothing here knows who you are. A **tenant** — whoever a given body of work belongs to — keeps its
own context repository with its own facts and its own denylist, and installs this one into it.
Two tenants share every word of the protocol and not one word about each other.

> **New here?** [`START-HERE.md`](START-HERE.md) has two ways in: ten minutes reading, or ten
> minutes running it.

## One file, two readers

Each doctrine file carries exactly two lines of frontmatter, `name` and `description`. That is the
whole of what one agent's skill format requires, and it is inert to every other reader — a person,
a different agent, a diff. So the installer wires a skill as a **symlink to the doctrine file**,
never a copy of it:

```
<tenant>/skills/warp/SKILL.md  ->  ../../protocol/doctrine/warp.md
```

Edit the doctrine, and the agent's skill changed, because there was only ever one file. This is
the shape the whole repository is built around: adapters point a tool at the protocol and never
copy configuration out of it. Delete every adapter and the protocol is intact —
[`adapters/README.md`](adapters/README.md) states that as the contract each one is held to.

## A new tenant, end to end

The worked example is not "how to install this." It is the argument for why the protocol is a
separate repository with a guard attached, rather than a well-written page in your agent's config.

**Scenario.** Two tenants, one machine, one set of tools, often in the same hour. Each keeps a
context repository holding its own names, identifiers and plans, and neither repository may contain
a word of the other's.

**Before — both obvious options fail.** Put the working standard in each repository's agent
configuration and you maintain two copies that drift, which is how a rule quietly stops being
enforced in one of them. Keep one shared configuration for both and each tenant's facts are present
in the other's sessions, including on any machine whose configuration is not yours to set. And in
either arrangement, nothing stops the commit: an agent working in one tenant's repository will
happily write a plan that names the other, because to that agent it is just text under discussion.

**After.**

1. **Create the tenant.** Copy [`tenant-template/`](tenant-template/) into a new repository. It
   is four files: an `AGENTS.md` with headings and no content, a denylist, a `pre-commit` shim,
   and the directory they live in.

   ```bash
   git init my-context && cd my-context
   cp -r ~/pablo-protocol/tenant-template/. .
   ```

2. **Install the protocol.** One command, from inside the tenant:

   ```bash
   ~/pablo-protocol/bin/adapt
   ```

   It symlinks this repository in as `protocol/`, gitignores that path because it is machine-local,
   seeds any of the four template files the tenant lacks, points `core.hooksPath` at `.githooks`,
   and creates `~/.pablo-protocol` — the well-known path the shim falls back to, so no hook ever
   carries a machine-local path. Then it detects which AI coding agents the machine has and wires
   each one. Run it twice and the second run prints `skip` for every line.

3. **Declare who this tenant is not.** `.protocol/tenant` takes one extended regular expression
   per line — the other tenants' names, their repository and product names, the identifier shapes
   that are always somebody's infrastructure:

   ```
   initech
   (^|[^0-9.])(10|192\.168)\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}
   ```

   It is a denylist of the *other* tenants, never an allowlist of this one. Nobody can enumerate
   in advance every term their own work will legitimately contain, and a control that refuses
   unfamiliar material is a control people bypass on the first false refusal.

   A repository that will itself be read by others carries the names in an untracked
   `.protocol/tenant.local` instead, appended to the tracked file. A denylist read backwards is a
   list of what the repository is protecting, so a published one states shapes and leaves the
   proper nouns on the machine — [`ARCHITECTURE.md`](ARCHITECTURE.md) §3.

4. **Watch the same file load in two different agents.** With the tenant as the configuration
   directory, one agent lists `warp`, `planning`, `git`, `clean-code`, `testing`, `tenancy` and
   `llm-output-trust` as skills. Point a second agent at its own adapter directory and it reads
   the identical files. There is no second copy to keep in sync, because step 2 made links, not
   copies — and an agent with no adapter at all still gets the protocol, as `AGENTS.md`.

5. **Try to commit the thing that must not be committed.** Write a note in this tenant's
   repository that names one of the others, and commit it:

   ```
   pre-commit: refusing to commit another tenant's material into this repository:
   pre-commit:   notes.md: Initech
   pre-commit:
   pre-commit: Each term above is listed in .protocol/tenant, which names the tenants this
   pre-commit: repository is not. Put the material in that tenant's own repository instead.
   ```

   It is refused for the staged path as well as the staged bytes, and
   `guards/tenant-guard.sh --scan-tree` applies the same rules to every tracked file — which is
   how you audit a repository before publishing it, rather than re-reading it by hand.

6. **Change the protocol once.** A new rule lands in `doctrine/`, both tenants move their pin, and
   both agents in both tenants have it. Nothing was copied anywhere, so nothing can disagree.

**The point.** Step 5 is refused no matter which agent wrote the file, or whether an agent wrote
it at all — the guard reads the diff, not the conversation. Step 4 is the same bytes reaching two
different tools. Neither is achievable from inside one agent's configuration file, and that is the
entire reason this is a repository.

## What is in here

| Path | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | the entry point an agent reads, indexing the doctrine below |
| [`doctrine/`](doctrine/) | the protocol itself — eight documents, and nothing else is normative |
| [`guards/`](guards/) | the commit-time enforcement: file size, credentials, tenancy |
| [`bin/adapt`](bin/adapt) | the installer, idempotent, `--copy` for a machine that will not follow symlinks |
| [`adapters/`](adapters/) | one small directory per AI coding agent, each holding `detect.sh` and `adapt.sh` |
| [`tenant-template/`](tenant-template/) | the four files a new tenant starts from |

A guard reads its policy from a file the *tenant* carries under `.protocol/`, and a guard whose
policy file is absent exits 0. That is what makes one shared chain safe to point at any checkout:
a repository opts into a rule by carrying the file that configures it, never by being recognised
by name from inside the guard. [`ARCHITECTURE.md`](ARCHITECTURE.md) is the contract for all of it.

## What this does not catch

**It gates commits, not reads.** The guards run at `pre-commit`. Nothing here stops an agent from
*reading* another tenant's files, or from putting their contents in a prompt that leaves the
machine. If a tenant's material must not be readable at all, it must not be on the machine —
absence is the only control that survives an adversary with root, and on a device someone else
manages that adversary is the device.

**A symlinked adapter does not survive a centrally-managed configuration directory.** `--copy`
exists for exactly that machine, and it buys back the drift that symlinks eliminate: a copied
doctrine file is a copy, and it goes stale the moment the protocol moves. Re-running `bin/adapt`
is the only thing that refreshes it, and nothing reminds you.

**A denylist is a filter, not a proof.** It catches the terms you thought to write down, spelled
the way you wrote them. It will not catch a tenant described without naming it, a paraphrased
figure, or a screenshot. `--scan-tree` narrows this by auditing the whole tree rather than one
diff, and `--no-verify` widens it back to nothing.

**Permission rules constrain an agent, not a machine's owner.** An adapter can tell one tool which
commands to refuse. It cannot stop device management software, a backup agent, or anyone with
administrative access to a machine from reading what is on its disk.

**Nothing here is a secret store.** The credentials guard refuses to let a secret *into* a commit.
Where secrets actually live, and how they reach a process, is the tenant's problem and belongs in
the tenant's own documentation.

## License

MIT — see [LICENSE](LICENSE). The protocol documents under `doctrine/` are covered by the same
licence as the code: take them, fork them, rewrite them for how your own work is done.
