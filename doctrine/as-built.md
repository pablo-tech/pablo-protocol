---
name: as-built
description: The document that describes a system is part of that system — changed in the same change that changes the system, and corrected on the spot when it is merely found to be wrong.
---

# As-built

**The document that describes a system is part of that system.** It is not a report about the work,
written afterwards by whoever has time. A reader who cannot trust it has to re-derive the system from
the system, which is the cost the document existed to remove.

- **A change to a system updates the document that describes it, in the same change.** Not a
  follow-up, not a ticket. This is the documentation analogue of the rule that new or modified
  behaviour gets its test in the same change, and it holds for the same reason: the change and the
  record of it are one unit of work, and splitting them means one of the halves does not happen.
- **State what is, not what was decided.** The document describes the system as it stands. The
  reasoning that led there belongs in the plan, the commit message or a decision record — places that
  are dated by construction and are not read as current.
- **A setting observed is a setting changed, for this purpose.** Reading a live system and finding it
  configured differently from its document is a discrepancy that has already happened; the reading is
  simply when it was noticed.
- **Correct on discovery.** See "Found wrong" below.
- **If nothing describes it, that is the finding.** A system with no document is not exempt from this
  rule — it is the case the rule is most expensive to have skipped. Write the short true version now
  rather than the complete one later.

## Found wrong

**A document found to disagree with the system is corrected in the change that found it**, at the
moment of discovery, not queued.

The reason is that the evidence is never again this good. Whoever found the discrepancy has the
system in front of them, knows what they ran to see it, and knows which of the two is right. An hour
later that is a question someone has to re-open; a week later it is an archaeology task, and the
usual outcome is that the document is left alone because nobody can prove it wrong any more.

The cost of deferring is not the edit that was postponed. It is that every reader between the
discovery and the correction is misled by a document someone already knew was false — and they act on
it, because the document is the thing that exists to be acted on.

Two consequences worth stating, because they are the ones people argue with:

- **A correction is in scope by definition.** It is not scope creep to fix the document your change
  just falsified, and it is not scope creep to fix the one you happened to disprove on the way. The
  boundary is the discrepancy you found, not the file it lives in.
- **Small and true beats complete and late.** A one-line correction landed today is worth more than
  the rewrite that would have been thorough. The rewrite is a separate piece of work, and it is
  allowed to be planned; the correction is not allowed to wait for it.

## What this is not

It is not a mandate to document everything, and it does not license a rewrite of a document you
merely dislike. The obligation is symmetrical with the change: what the change touched, or what the
reading disproved. Beyond that boundary the ordinary rule applies — leave it cleaner than you found
it, and do not use that as license to reorganize what already works.
