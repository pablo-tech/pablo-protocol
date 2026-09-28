---
name: tenancy
description: Working for more than one tenant from one set of tools — what a tenant is, why the commit is the only boundary that binds every agent, how .protocol/tenant declares the ones this repo is not, and the four controls in order of what actually carries weight.
---

# Tenancy

A **tenant** is whoever the work belongs to: an employer, a client, a foundation, yourself. One
person routinely works for several, through the same tools, on the same machine, in the same hour.
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

It absorbs a second job for free. Any review that would otherwise ask a human to grep for planning
references, internal codes or infrastructure identifiers before publishing can state those as
patterns instead, and the recurring chore becomes a gate.

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
4. **A separate operating-system user, or a virtual machine.** The escalation, and the trigger is
   specific: if a machine you previously owned outright comes under someone else's device
   management, control 3 stops being sufficient and the tenant moves behind a real boundary.

The ordering matters more than the list. A great deal of effort is commonly spent on 3 while 1 is
quietly violated, which buys nothing.
