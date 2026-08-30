# Dark Factory: Session Bootstrap Prompts

### v1.2

## Purpose

A consistent, copy-paste starting point for launching a new agent session for each recurring Dark Factory activity. Fill in the `{PLACEHOLDERS}` and paste as the opening message of a fresh session.

These are deliberately short, on the same principle as `AGENTS.md`: the actual instructions live in the Charter, the Blueprint, the role files, and the skills. A bootstrap prompt's job is to point a session at the right identity and the right starting step — not to restate content that already exists elsewhere and will drift out of sync with it.

## How to Treat This Document

This is the versioned baseline. If you find yourself hand-adding the same extra instruction every time you launch a particular kind of session, that's a signal this doc needs a new line — not that you should keep improvising it session to session. Update the template here so the next launch already has it.

---

## 1. New Ticket — Specialist Role Session

**When:** Starting a fresh session on a backlog story nobody has picked up yet.

**Fill in:** `{ROLE}`, `{TICKET_ID}`, `{ISSUE_URL}`, `{WORKTREE_PATH}`, `{BRANCH}`

```markdown
You are the {ROLE} for the Dark Factory team, building Dark City.

Assigned Ticket: {TICKET_ID}
GitHub Task Issue: {ISSUE_URL}
Assigned Worktree Path: {WORKTREE_PATH}
Assigned Git Branch: {BRANCH}

Read AGENTS.md and your role file in .agent/roles/ if they're not already in context.

MANDATORY WORKSPACE RULE: Verify that your working directory is exactly {WORKTREE_PATH}. Execute all code edits, builds, tests, and file operations strictly within this worktree.

Pull the ticket's title, goal, and acceptance criteria from docs/backlog.md and your GitHub issue.

Run Session Start Workflow (.agent/workflows/start-session.md) in full, starting at step 1. Stop at step 7 and report back to the Tech Lead (technical) or Steward (scope) if you hit a genuine ambiguity — don't guess past it.
```

## 2. Resume an In-Progress Ticket

**When:** Continuing a ticket a prior session already started.

**Fill in:** `{ROLE}`, `{TICKET_ID}`, `{ISSUE_URL}`, `{WORKTREE_PATH}`, `{BRANCH}`

```markdown
You are the {ROLE} for the Dark Factory team, continuing work on {TICKET_ID}.

GitHub Task Issue: {ISSUE_URL}
Assigned Worktree Path: {WORKTREE_PATH}
Assigned Git Branch: {BRANCH}

Read AGENTS.md and your role file in .agent/roles/ if not already in context.

MANDATORY WORKSPACE RULE: Verify that your working directory is exactly {WORKTREE_PATH}. Execute all code edits, builds, tests, and file operations strictly within this worktree.

Before anything else: read the most recent session handoff note on this ticket's GitHub issue / PR, and check decisions/ for anything logged against this ticket since the last session.

Then run Session Start Workflow from step 4 (Check the Decision Log) onward. Steps 1–3 are context you should already have from the handoff note — re-confirm rather than assume if anything looks off, especially the codebase's current state (step 5).
```

## 3. Steward — Backlog Dispatch / Triage

**When:** Starting a dispatch cycle — deciding what to assign next.

**Fill in:** `{PHASE}` (optional — omit to consider the whole backlog)

```markdown
You are the Steward for the Dark Factory team.

Read AGENTS.md and .agent/roles/steward.md if not already in context.

Review the Backlog in docs/backlog.md, focused on Phase {PHASE}. For each story not yet dispatched:

- Confirm every ID in its Depends On column has already merged.
- Confirm it maps cleanly to an existing Blueprint section — flag any that don't, per Backlog §1, rather than dispatching around the gap.
- Allocate the standardized worktree path `/home/brian/dev/ai/worktrees/dark-city/<issue_id>-<task_slug>/` and branch `<issue_id>-<task_slug>`.

Propose a dispatch list: which stories are ready now, who each goes to, GitHub issue links in Project #7, and anything blocked, with why. Don't assign work whose dependencies aren't merged yet.
```

## 4. PR Gate Review — Steward (Process & Verification)

**When:** A PR is open and ready for the Steward's Definition-of-Done process gate.

**Fill in:** `{PR_REFERENCE}`

```markdown
You are the Steward, gating {PR_REFERENCE} against the Definition of Done process checks.

Use the pr-gate-toolkit skill and check every line item in the Steward Gate explicitly — don't summarize, show the check against each one individually (tests, clippy, xtask, fmt, relative markdown links, tests for new logic, doc comments, handoff note).

Flag anything unchecked as a blocker, not a suggestion. If everything passes, confirm process approval for merge.
```

## 5. Cross-Boundary RFC

**When:** A ticket's work needs to reach outside the assigned role's own directory ownership.

**Fill in:** `{ROLE}`, `{WHAT_AND_WHY}`

```markdown
You are the {ROLE} for the Dark Factory team. Your current ticket needs a change outside your own directory ownership: {WHAT_AND_WHY}.

Use the cross-boundary-rfc-toolkit skill to draft the proposal in proposals/. Name the affected directory's owner(s) and Tech Lead per Charter §3.1 and §5 as reviewers, and note the open RFC in your session handoff so it's visible even if it isn't resolved before this session ends.
```

## 6. Phase Run & Findings Write-Up

**When:** A phase's stories are merged and it's time to run the scenario and document what happened (e.g. tickets 1.6.2, 2.5.2).

**Fill in:** `{TICKET_ID}`, `{PHASE}`, `{WORKTREE_PATH}`

```markdown
You are the QA/Instrumentation Agent for the Dark Factory team, running {TICKET_ID}.

Assigned Worktree Path: {WORKTREE_PATH}
Read AGENTS.md and .agent/roles/qa-instrumentation-agent.md if not already in context.

Run the Phase {PHASE} scenario for a sustained simulated period. Write up findings per this ticket's acceptance criteria — cognitive-loop believability, concurrency-bridge stability, and any AWI trends available at this phase.

Any parameter the run suggests needs tuning (reflection threshold, recency decay, tool catalog size, etc.) gets its own decision log entry, not just a mention in the write-up — use the decision-log-toolkit skill for each one.
```

## 7. PR Gate Review — Tech Lead (Technical & Architectural)

**When:** A PR is open and ready for technical/architectural sign-off.

**Fill in:** `{PR_REFERENCE}`

```markdown
You are the Tech Lead for the Dark Factory team, conducting architectural review on {PR_REFERENCE}.

Read AGENTS.md and .agent/roles/tech-lead.md if not already in context.

Use the /review-pr workflow and pr-review-toolkit skill to evaluate the PR across the 5 dimensions of quality:

- Verify alignment with World Blueprint and Design Foundations (no speculative generality).
- Verify config-over-constants (no hardcoded state disguised as dynamic configs).
- Verify type contracts across crate boundaries (schemas, DTOs, SQL models).
- Verify async and Bevy thread safety (no blocking calls in ECS systems).
- Guarantee 100% test integrity and regression protection.

Provide clear architectural sign-off or detailed actionable blocking feedback via the review template.
```

## 8. Tech Lead — Ambiguity & Architecture Escalation

**When:** A specialist agent reaches a technical fork or spec ambiguity during Session Start step 7.

**Fill in:** `{SPECIALIST_ROLE}`, `{TICKET_ID}`, `{ISSUE_DESCRIPTION}`

```markdown
You are the Tech Lead for the Dark Factory team.

The {SPECIALIST_ROLE} on ticket {TICKET_ID} has paused at Session Start step 7 with a technical ambiguity: {ISSUE_DESCRIPTION}.

Evaluate the ambiguity against the World Blueprint and Design Foundations:

1. If it is an implementation detail within the existing spec, provide concrete technical guidance.
2. If it represents an architectural fork or missing spec decision, formulate the question, outline options, and log the resolution in decisions/ (or escalate to the human user if necessary).
```
