---
name: session-handoff-toolkit
description: Use at the end of any Dark Factory working session, whether or not the ticket is finished — Session Start Workflow step 10 and Charter §8 both require one before a PR opens. Trigger on "session-handoff-toolkit", "write a handoff note," "wrap up this session," or "what does the next session need to know."
---

# Session Handoff Toolkit (`session-handoff-toolkit`)

## Purpose (Charter §8)

Short-term, in-progress state for whoever picks up this ticket next — including a future instance of you. Deliberately separate from the decision log: the decision log is permanent architecture rationale that outlives the ticket; the handoff note is scoped to the ticket and can go stale the moment it closes. Don't put anything here that belongs in a decision log entry instead — if it's a rationale for an architecture choice, it goes in `/decisions/`, not here.

## Where It Goes

The PR description, per Session Start Workflow step 10. If the ticket isn't done yet and there's no PR open, a short comment on the ticket/issue itself is the fallback.

## Template

```markdown
## Session Handoff — [Ticket ID]

**Status:** [in progress / ready for review / blocked]

**Done this session:**
- ...

**Still open:**
- ...

**Next session needs to know:**
- Anything not already captured in a decision log entry — a half-finished approach you tried and abandoned, a test that's flaky for a reason you haven't root-caused yet, a question you're planning to raise but haven't yet.
```

## Session Completion Checklist (Charter §8)

At the conclusion of an implementation session:
1. **Work Log Entry:** Append a high-level summary of work and key discoveries to `logs/work-log.md`.
2. **Review Brief:** Scaffold and enrich `working/briefs/<id>-review.md` using `scripts/gh-task-ops.sh scaffold-review`.
3. **Session Handoff Note:** Include in review brief and attach to the PR description (or issue if in progress).
4. **Machine Verification:** Run `scripts/gh-task-ops.sh check` to confirm clean fmt, clippy, tests, and xtask.
5. **Open Pull Request:** Run `scripts/gh-task-ops.sh pr-create` including a body with relevant information.

## What Doesn't Belong Here

- Architecture rationale → `decision-log-entry` skill instead.
- A cross-boundary need you've identified but not yet drafted → `cross-boundary-rfc` skill instead, and mention here that it's pending.
- Anything the Definition of Done already checks mechanically (tests passing, clippy clean) — that's redundant with CI, not handoff information.
