---
name: decision-log-entry
description: Use when writing an entry to /decisions/ under the Dark Factory Team Charter — for any deviation from the World Blueprint or Design Foundations, any question those documents leave genuinely open, or any ambiguity the Steward resolved during a session. Trigger on "log this decision," "write a decision log entry," "document why we chose X," or when Session Start Workflow step 10 or Definition of Done (Charter §7) calls for one.
---

# Decision Log Entry

## When You Need One (Charter §6, §7)

An entry is required for:
- Any deviation from what the World Blueprint or Design Foundations specifies.
- Any question those two documents leave genuinely open (Design Foundations §14 lists several known-open parameters — reflection threshold, recency decay, Phase 1 tool catalog size — that will need one the first time they're actually tuned).
- Any ambiguity the Steward resolved on your behalf during Session Start Workflow step 7, however small.
- The outcome of a cross-boundary proposal (Charter §5 step 3) — approved or rejected, the Steward logs it either way.

An entry is **not** required for an implementation choice the Blueprint already specifies exactly — following the spec isn't a decision. When in doubt, write the entry; a redundant entry costs a paragraph, a missing one costs a future session re-deriving or re-deciding something already settled.

## Timing

Before the PR that depends on it merges. Not after. This is a Definition of Done line item (Charter §7) — a missing entry blocks merge the same as a failing test does.

## File Convention

One dated, numbered Markdown file per decision in `/decisions/`:

```
/decisions/0001-reflection-threshold-tuning.md
```

Number sequentially; never reuse or renumber a prior entry, even if a later decision supersedes it — supersede by adding a new entry that references the old one, so the history stays intact.

## Template

```markdown
# [NNNN] Short Decision Title

**Date:** YYYY-MM-DD
**Ticket:** [backlog ID, e.g. 1.3.3]
**Role:** [your Dark Factory role]

## Question
What was actually undecided or ambiguous?

## Options Considered
Brief — a sentence or two per option is enough. Don't write a design doc here.

## Decision
What was chosen.

## Why
The reasoning. This is the part a future session actually needs — the "what" is usually visible in the code; the "why" often isn't.

## Supersedes / Related
Optional. Link a prior decision this changes, if any.
```

Keep the whole entry to a paragraph or two per section — Charter §6 is explicit that these should stay short. If you need more than that, the decision is probably big enough to also warrant a Blueprint amendment (Backlog §7), not just a log entry.
