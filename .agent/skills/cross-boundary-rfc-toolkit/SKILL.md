---
name: cross-boundary-rfc-toolkit
description: Use when a Dark Factory agent needs to change something outside its own directory ownership (Charter §3.1) — including any Cargo.toml or workspace-level dependency change, regardless of size. Trigger on "cross-boundary-rfc-toolkit", "I need to touch someone else's directory," "this requires a workspace dependency change," "draft an RFC," or "open a cross-boundary proposal."
---

# Cross-Boundary RFC Toolkit (`cross-boundary-rfc-toolkit`)

## When This Applies (Charter §5)

Any time your change reaches outside your own owned directories (Charter §3.1 / AGENTS.md table). This includes `Cargo.toml` and any workspace-level dependency — that one has no single owner and always goes through this process, no matter how small the change looks.

This process is entirely internal to the Dark Factory codebase. It has nothing to do with Dark City's own in-world governance system (Blueprint §6) — don't confuse the two, and don't gate this process on anything inside the simulated world (an earlier draft of this project's own documentation made exactly that mistake).

## The Process (Charter §5)

1. **Draft.** You (the requesting agent) write a short RFC in `/proposals/` using the template below.
2. **Review.** The owner(s) of the affected directory leave review comments.
3. **Arbitrate.** The Steward approves or rejects, logging the outcome via the `decision-log-entry` skill either way.
4. **Merge.** Only after approval does the cross-boundary PR get opened.

Don't skip to step 4. An approved-in-spirit verbal go-ahead isn't the same as a logged decision — the log entry is what the next session finds.

## File Convention

```
/proposals/0001-short-slug.md
```

## Template

```markdown
# [NNNN] Short Proposal Title

**Requesting Role:** [your role]
**Date:** YYYY-MM-DD
**Affects:** [directory/directories outside your own ownership]

## What's Changing
Concrete description of the change.

## Why
What this unblocks or fixes, and why it can't be done inside your own directory instead.

## What It Touches Outside My Directory
Be specific — file paths, not just "the server." This is what the affected owner actually reviews.

## Status
awaiting / approved / rejected — Steward updates this and links the decision log entry once resolved.
```
