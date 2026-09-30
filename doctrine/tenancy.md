---
name: tenancy
description: Working for more than one tenant from one set of tools — what a tenant is, why the commit is the only boundary that binds every agent, how .protocol/tenant declares the ones this repo is not and .protocol/identity declares whose commits these are, the four controls in order of what actually carries weight, and why a tenant reports a protocol defect on itself rather than upstream.
---

# Tenancy

A **tenant** is whoever the work belongs to. One person routinely works for several, through the
same tools, on the same machine, in the same hour.
The protocol is shared across all of them. The *content* — plans, notes, names, identifiers,
infrastructure — belongs to exactly one, and must not reach another.

## Why the commit is the boundary

It is tempting to enforce this inside the agent: a permission rule, a pre-tool hook, a system prompt
that says do not read that directory. Each of those stops one command in one tool, and says nothing
about a diff produced by a different tool, by an editor, by a script, or by hand. They are also
advisory in the direction that matters — a rule telling a model what not to read is not a control
against the file being readable.

The commit is the one boundary every route passes through. A pre-commit hook and a continuous
integration job judge the diff itself, so they bind every agent equally, including the ones that do
not exist yet. **Put the enforcement in git, not in an agent.**

## The declaration

Each repository carries `.protocol/tenant`: the terms belonging to the tenants this repository is
**not**, one extended regular expression per line. Any staged path or staged byte matching one is
refused, by [`guards/tenant-guard.sh`](../guards/tenant-guard.sh). A repository without that file
declares no tenancy and is not policed.

The list is written as a denylist of the *others* rather than an allowlist of this tenant, because
the allowlist cannot be written: nobody can enumerate in advance every term their own work will
legitimately contain, and a control that refuses unfamiliar material is a control people bypass on
the first false refusal. A denylist of the tenants you actually have is both short and complete.

The same declaration does a second job. A review that would otherwise ask a human to grep for
planning references, internal codes or infrastructure identifiers before publishing can state those
as patterns instead, and the recurring chore becomes a gate.

A repository that will itself be read by others carries the terms in an untracked
`.protocol/<name>.local` beside the tracked file, which the guard appends to it. A denylist read
backwards is a list of what the repository is protecting, so a published one states the shapes and
the categories and leaves the proper nouns on the machine that needs them.

## Whose commits these are

The declaration above refuses another tenant's *material*. The name and address a commit is made as
is not material, and passes through it untouched: it is not a staged path and not a staged byte. It
is also the one line of a commit that names a person rather than the work, and the one that cannot
be corrected afterwards without rewriting every commit that followed it.

Which identity git uses is machine configuration. A fresh clone carries none of its own, so a
commit is made as whoever the machine was set up as, and git says nothing about the difference. On
a machine serving more than one tenant there is one default and several right answers, so the
default is wrong for all but one of them — silently, permanently, and in a header read much later
by somebody who was not there.

So a repository states it, the way it states the tenants it is not. `.protocol/identity` lists the
identities its commits may be made as, one extended regular expression per line, and
[`guards/identity-guard.sh`](../guards/identity-guard.sh) refuses a commit whose author or
committer matches none of them. A repository without that file claims no identity and is not
policed. `--scan-history` applies the same list to the commits already on the branch, which is the
only way a header written on a machine with no hook configured is ever found.

This one is an allowlist where the tenancy declaration is a denylist, for the reason that one is
not: the identities a repository's commits are legitimately made as can be enumerated in advance —
there are one or two — while the terms its work will legitimately contain cannot.

Most of a tenant's commits are not made in the tenant. They are made in the repositories worked on
under it, which are deliberately not tenants and so carry no declaration of their own — and a
repository that declares nothing is policed by nothing, which is the right answer for a denylist
and the wrong one here. So a repository with no `.protocol/identity` of its own falls back to the
list of the tenant it is worked on under, named by `pabloProtocol.tenant` in its local git
configuration by whatever wired it. It is the one policy that does this; the reasoning, and why it
is safe only for a list that tightens, is [`ARCHITECTURE.md`](../ARCHITECTURE.md) §3. A repository
that does carry the file is judged by that and by nothing else.

## The four controls, in order of what carries weight

1. **Absence.** On a machine whose owner can read any file on it, the only real control is that the
   other tenant's material was never cloned there. Nothing configured on that machine improves on
   this, and nothing substitutes for it.
2. **The commit-time guard.** On a machine you do own, the live risk is not exfiltration — it is a
   private plan landing in the other tenant's commit by ordinary mistake. The guard prevents that
   regardless of which agent wrote the diff.
3. **A workspace root per tenant.** Each tenant gets a directory holding its context repository, and
   a launcher that exports every installed agent's configuration-directory variable from it. One
   mechanism, every agent, and the agents keep separate accounts, histories and caches. This is
   hygiene and convenience; it is not a security boundary against the machine's owner.
4. **A separate operating-system user, or a virtual machine.** The escalation. Its trigger is
   specific: where a machine's configuration is not the tenant's to set — device management, backup
   software and administrative access all read the disk — control 3 stops being sufficient and the
   tenant moves behind a real boundary.

The ordering matters more than the list. A great deal of effort is commonly spent on 3 while 1 is
quietly violated, which buys nothing.

## Reporting a defect in the shared protocol

The protocol is the one repository every tenant shares, which makes a pull request against it the
one route by which a tenant's material leaves the tenant without passing the control that protects
it. The guard judges a commit in the tenant's own repository. A branch pushed to the shared
repository is not that, and neither is a pull-request body, a pasted terminal session, an error
message quoted in full, or a path that appears in a diff only as the context around the line being
changed. The shared repository's own denylist cannot close the gap: it carries identifier shapes and
the words a tenancy is described with, and the one thing it must never carry is a tenant's proper
nouns — which are exactly the terms that would have to be listed to catch them.

So the report is filed where the control already runs. **A tenant reports a defect in the protocol
as an issue in its own context repository**, not as an issue or a pull request in the shared one.
Written there it is the tenant's material in the tenant's repository, judged by the tenant's own
denylist like every other line it holds, and readable by exactly whoever is entitled to read that
repository. Whoever maintains the protocol reads it there and writes the fix in the shared
repository, from a machine holding none of that tenant's material.

The round trip is the point rather than the cost. Nothing crosses from a tenant into the shared
layer except a description of a defect, restated as the general thing it is — and a defect that
could only be explained by naming the tenant that found it is one the shared repository could not
have carried anyway.

A tenant whose material is not sensitive gains nothing from an exception here, and granting one is
how the rule stops being a rule: the route that is safe on an ordinary day is the route somebody
takes on the day it is not.
