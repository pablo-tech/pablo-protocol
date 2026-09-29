# The doctrine

*The eight documents in this directory are the whole of the protocol. Everything else in the
repository installs them or enforces them — delete `guards/`, `bin/` and `adapters/` and what
remains is still the protocol.*

Each one is written as a **forcing function** rather than as advice.

> A forcing function is not a reminder. A reminder makes you the control, and a control that
> depends on remembering costs nothing until the hour it matters. A forcing function changes the
> shape of the work, so that the failure it prevents either cannot happen or announces itself
> while it is still cheap to fix.

Read them in any order. [`AGENTS.md`](../AGENTS.md) says which one to open before a particular
piece of work; this page says what each one holds you to, and why it is shaped the way it is.

---

### [Every plan states its objective before its context](planning.md)

> One short paragraph naming what the plan is for and what "done" looks like, at the top, ahead of
> any background. A reader should not have to infer the goal from the remediation.

The rule is about ordering, which is what gives it force. A plan that opens with background reads
as reasonable whatever it proposes, because the reader assembles a goal out of the evidence and
then agrees with themselves. Put the objective first and a plan with no clear objective is
visibly a plan with no clear objective — the defect surfaces in the writing, before anyone has
spent a day executing it.

### [A test must be able to fail](testing.md)

> One that passes whether or not the property holds is not a test.

The usual form of this defect is not a bad test but a green suite, which is the one signal nobody
re-examines. So the rule arrives with a procedure instead of an exhortation: write it red first,
and when a suite written before its implementation reports some checks already passing, those are
the checks to distrust. A check that has never been red is telling you about its own
construction, not about the code.

### [The same fact in two places will drift](clean-code.md)

> The same fact or logic in two places will drift, and one of them becomes a lie with no signal
> which.

The cost is the missing signal, not the duplication. Two copies that disagree both read as
current, so a reader picks one and is right half the time. It is the rule with the widest reach
here, because it does not distinguish between a helper copy-pasted across call sites and a
paragraph copy-pasted across instruction files — a bloated or duplicated document is the same
defect as a bloated or duplicated function, paid by every session instead of by every call.

### [Large files never enter history, and the ceiling is enforced at commit](git.md)

> Large files live in object storage. Repositories keep information extracted from them, never the
> files themselves.

The sharp half is *where* the ceiling sits. A push-time limit is the obvious design and it is
already too late: by the time a push is refused the blob is in local history, and the branch stays
unpushable until history is rewritten, which costs a force-push to every branch carrying it.
Refusing the commit costs one retry. The guard judges the staged blob for the same reason — the
index is what a commit would record.

### [A document found to disagree with the system is corrected in the change that found it](as-built.md)

> The document that describes a system is part of that system.

Not a report about the work, written afterwards by whoever has time. The second half is the part
people argue with: correct it *on discovery*, because the evidence is never again this good.
Whoever found the discrepancy has the system in front of them and knows which of the two is
right. An hour later that is a question someone has to re-open; a week later it is archaeology,
and the usual outcome is that the document is left alone because nobody can still prove it wrong.

### [A warp runs from approval to deployed, and stops at four things](warp.md)

> "warp" means: take the plan from approval to deployed product with no further check-ins.

Delegation is only useful if its edges are fixed in advance, so the document fixes them:
publishing externally, destroying data, spending money above noise, and losing a credential
irreversibly. The fourth cuts the opposite way from the others — a warp is explicitly authorized
to *read* credentials, and stops only where a later step could not recover the value. And a
publish that a merge triggers is still a publish, because the job keys on the push, not on the
paths.

### [The four controls are ordered, and the ordering is the finding](tenancy.md)

> The ordering matters more than the list. A great deal of effort is commonly spent on 3 while 1
> is quietly violated, which buys nothing.

The list itself is unremarkable: absence, the commit-time guard, a workspace root per tenant, and
a separate operating-system user or machine. Stating it in order is what makes it useful, because
effort reliably flows to the visible control rather than the load-bearing one. It is also why
enforcement here lives in git: a rule inside an agent stops one command in one tool, while a
pre-commit hook judges the diff and so binds every agent equally, including the ones that do not
exist yet.

### [One knob per diff](llm-output-trust.md)

> Don't bundle a model swap with a prompt change in the same diff. If quality changes, you cannot
> attribute it.

This one comes from a change that landed three knobs at once and produced a better result — and
from an external review showing nearly all of the gain came from the prompt and the context, not
from the model. Had the cheaper model quietly degraded quality, the prompt wins would have masked
it. Its most reusable finding is next to it: load-bearing context beats model tier.

---

## What a machine checks, and what it does not

Two of the eight are enforced at commit time by [`guards/`](../guards/) — the size ceiling from
*Git*, and the declaration from *Tenancy*. [`ARCHITECTURE.md`
§4](../ARCHITECTURE.md#4-the-guard-chain-runs-in-order-and-fails-closed) is how that chain works
and why it fails closed. The other six are held by whoever reads them, which is the ordinary
condition of a standard and not a gap to be closed: most of what is written here is not the kind
of thing a script can judge.

These documents are opinionated, and they are one practitioner's. Disagree with one, rewrite it in
your fork, and nothing else in this repository breaks — the mechanism reads whatever files are
here, and never their contents.
