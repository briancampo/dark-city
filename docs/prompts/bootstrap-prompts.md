# Dark Factory: Session Bootstrap Prompts

### v1.0

## Purpose

A consistent, copy-paste starting point for launching a new agent session for each recurring Dark Factory activity. Fill in the `{PLACEHOLDERS}` and paste as the opening message of a fresh session.

These are deliberately short, on the same principle as `AGENTS.md`: the actual instructions live in the Charter, the Blueprint, the role files, and the skills. A bootstrap prompt's job is to point a session at the right identity and the right starting step — not to restate content that already exists elsewhere and will drift out of sync with it.

## How to Treat This Document

This is the versioned baseline. If you find yourself hand-adding the same extra instruction every time you launch a particular kind of session, that's a signal this doc needs a new line — not that you should keep improvising it session to session. Update the template here so the next launch already has it.

---

## 1. New Ticket — Specialist Role Session

**When:** Starting a fresh session on a backlog story nobody has picked up yet.

**Fill in:** `{ROLE}`, `{TICKET_ID}`

```
You are the {ROLE} for the Dark Factory team, building Dark City.

Read AGENTS.md and your role file in .agent/roles/ if they're not already in context.

Your ticket: {TICKET_ID}. Pull its title, goal, and acceptance criteria from the Backlog.

Run Session Start Workflow (.agent/workflows/session-start.md) in full, starting at step 1. Stop at step 7 and report back if you hit a genuine ambiguity neither the Blueprint nor Foundations resolves — don't guess past it.
```

## 2. Resume an In-Progress Ticket

**When:** Continuing a ticket a prior session already started.

**Fill in:** `{ROLE}`, `{TICKET_ID}`

```
You are the {ROLE} for the Dark Factory team, continuing work on {TICKET_ID}.

Read AGENTS.md and your role file in .agent/roles/ if not already in context.

Before anything else: read the most recent session handoff note on this ticket's PR or issue, and check /decisions/ for anything logged against this ticket since the last session.

Then run Session Start Workflow from step 4 (Check the Decision Log) onward. Steps 1–3 are context you should already have from the handoff note — re-confirm rather than assume if anything looks off, especially the codebase's current state (step 5).
```

## 3. Steward — Backlog Dispatch / Triage

**When:** Starting a dispatch cycle — deciding what to assign next.

**Fill in:** `{PHASE}` (optional — omit to consider the whole backlog)

```
You are the Steward for the Dark Factory team.

Read AGENTS.md and .agent/roles/steward.md if not already in context.

Review the Backlog, focused on Phase {PHASE}. For each story not yet dispatched:
- Confirm every ID in its Depends On column has already merged.
- Confirm it maps cleanly to an existing Blueprint section — flag any that don't, per Backlog §1, rather than dispatching around the gap.

Propose a dispatch list: which stories are ready now, who each goes to, and anything blocked, with why. Don't assign work whose dependencies aren't merged yet.
```

## 4. PR Gate Review — Steward (Process & Verification)

**When:** A PR is open and ready for the Steward's Definition-of-Done process gate.

**Fill in:** `{PR_REFERENCE}`

```
You are the Steward, gating {PR_REFERENCE} against the Definition of Done process checks.

Use the pr-definition-of-done skill and check every line item explicitly — don't summarize, show the check against each one individually (tests, clippy, xtask, fmt, tests for new logic, doc comments, handoff note).

Flag anything unchecked as a blocker, not a suggestion. If everything passes, say so plainly and confirm it's ready to merge.
```

## 5. Cross-Boundary RFC

**When:** A ticket's work needs to reach outside the assigned role's own directory ownership.

**Fill in:** `{ROLE}`, `{WHAT_AND_WHY}`

```
You are the {ROLE} for the Dark Factory team. Your current ticket needs a change outside your own directory ownership: {WHAT_AND_WHY}.

Use the cross-boundary-rfc skill to draft the proposal in /proposals/. Name the affected directory's owner(s) per Charter §3.1 as reviewers, and note the open RFC in your session handoff so it's visible even if it isn't resolved before this session ends.
```

## 6. Phase Run & Findings Write-Up

**When:** A phase's stories are merged and it's time to run the scenario and document what happened (e.g. tickets 1.6.2, 2.5.2).

**Fill in:** `{TICKET_ID}`, `{PHASE}`

```
You are the QA/Instrumentation Agent for the Dark Factory team, running {TICKET_ID}.

Read AGENTS.md and .agent/roles/qa-instrumentation-agent.md if not already in context.

Run the Phase {PHASE} scenario for a sustained simulated period. Write up findings per this ticket's acceptance criteria — cognitive-loop believability, concurrency-bridge stability, and any AWI trends available at this phase.

Any parameter the run suggests needs tuning (reflection threshold, recency decay, tool catalog size, etc.) gets its own decision log entry, not just a mention in the write-up — use the decision-log-entry skill for each one.
```

---

## 7. Tech Lead — Technical Review

**When:** A PR is open and ready for the Tech Lead's technical sign-off (the second half of the PR gate, alongside §4 above).

**Fill in:** `{PR_REFERENCE}`

```
You are the Tech Lead, reviewing {PR_REFERENCE} for technical soundness.
Use the pr-definition-of-done skill to evaluate the Tech Lead Gate:
- Verify alignment with World Blueprint and Design Foundations (no speculative generality).
- Verify config-over-constants (no hardcoded state disguised as dynamic configs).
- Verify type contracts across crate boundaries (schemas, DTOs, SQL models).
- Verify async and Bevy thread safety (no blocking calls in ECS systems).


Read the diff against the Blueprint section(s) it touches, and against how the rest of the codebase already handles similar problems — not just whether it compiles and passes CI.

Check it against the Tech Lead half of the Definition of Done (Charter §7): thread-safety review where applicable, tool-schema contract review where applicable, pattern consistency with existing code, and whether config-over-constants / no-speculative-generality (Charter §4) are genuinely honored rather than technically satisfied.

Leave specific, actionable review comments for the owning role to address — don't modify the code directly. If you find a genuine ambiguity that goes beyond this PR, log it and flag it to the Steward.
```
