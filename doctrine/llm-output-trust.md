---
name: llm-output-trust
description: Apply before changing the model, thinking mode, or system/user prompt of any LLM call whose output is presented to a human as a recommendation, finding or decision. Three rules — one knob per diff, an external cross-check, and the patterns that recur.
---

# Trusting LLM synthesis output

When you modify a feature that asks a language model to synthesize structured advice from structured
data, and the output reaches a human who will act on it, do these three things *before* committing.

## 1. Isolate variables — one knob per diff

Don't bundle a model swap with a prompt change in the same diff. If quality changes, you cannot
attribute it.

The change this rule came from landed three knobs at once: a model downgrade, measured-value
anchoring added to the user message, and structured domain context added to the system prompt. The
output was better — and an external review made clear that nearly all of the improvement came from
the prompt and context, not from the model. Had the cheaper model silently *degraded* quality, the
prompt wins would have masked it.

Land each knob with its own validation pass, in this order:

1. Prompt and context changes first, on the same model — establish the new quality bar.
2. The model swap second — verify the cheaper model preserves that bar.

## 2. Cross-check with an external model

Before shipping a synthesis change, put the new output into a *different* model and ask: *are there
statements here that are incorrect in this domain? Any alarm or conclusion the data does not
support?* The check costs a few cents and catches what an internal validator structurally cannot:

- **False positives that are well-formed.** A validator checking that a value parses, that a low
  bound is below a high bound, and that units match, has no way to notice that the conclusion drawn
  from those well-formed values is wrong. A shipped recommendation to escalate, against an input that
  was in fact within the normal band, passes every schema check there is.
- **Stale cross-references.** Stored summaries cite thresholds that have since moved. A content hash
  over the summary does not invalidate it when the *threshold* changes.
- **Quietly wrong ranges from unit ambiguity.** Where the same unit string is used by two scales
  differing by an order of magnitude, a model with no measured values in the prompt picks one, and
  may invert "high" and "low" while producing a perfectly plausible range.

## 3. Patterns that recur

- **Adaptive thinking can over-elaborate on small tasks.** On structured-output calls whose system
  prompt already carries strong framing, extended thinking compounds the framing bias and produces
  over-tightened results. For mechanical lookup-and-personalize tasks, test the no-thinking variant
  before assuming thinking helps.
- **Ambiguous scales need measured-value anchoring.** Include the actual values in the user message
  and instruct the model: *if the measurements lie entirely above or entirely below the range you are
  considering, you have picked the wrong scale.*
- **Load-bearing context beats model tier.** Adding real domain context produced a bigger lift than
  any model upgrade could have. Generic inputs produce generic findings; inputs carrying the
  situation, the history and the constraints produce findings a professional can act on.
- **Stored summaries decay when their inputs change.** When a summary is generated from an input and
  you mutate the input, surface the staleness — invalidate the summary (preferred) or annotate it
  with the input version it was generated against. Hash both.
- **Cheaper models skip "required but conditional" schema fields.** They follow instructions less
  elastically, so a conditional requirement has to be unmissable in the user turn rather than buried
  in the system prompt.

## Checklist

- [ ] One knob per diff — model, or prompt, or thinking, not all three.
- [ ] Regenerated a representative output and read it as the end user would.
- [ ] Put that output through a second model and asked for factual errors.
- [ ] Verified any stored downstream summaries are regenerated or explicitly marked stale.
- [ ] Confirmed the validator catches schema violations, and accepted that it cannot catch semantic
      ones — that is what the cross-check is for.

If anything looks off, fix the root cause before regenerating. Re-running the same prompt against the
same model typically reproduces the same error.
