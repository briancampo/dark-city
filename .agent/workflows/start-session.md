---
description: How to bootstrap a new work session with proper context loading. Use when starting a new agent session on any domain.
---

# Dark Factory: Session Start Workflow

### v1.0

Run this at the start of every session, before writing any code — whether it's your first session on a ticket or a continuation of one already in progress. It's short by design; skipping steps to save time is exactly the kind of shortcut the Team Charter exists to prevent.

## 1. Orient

Confirm your role and the specific ticket ID you've been assigned. If `AGENTS.md` isn't already in context, read it now — don't rely on memory of a previous session.

## 2. Read the Ticket

Get the ticket's title, role/goal statement, Gherkin acceptance criteria, and any Blueprint or Foundations sections it references. If it doesn't reference specific sections, figure out which ones apply before proceeding — don't start writing code against an assumed spec.

## 3. Read the Relevant Spec

Read the exact World Blueprint section(s) the ticket touches, and the corresponding Design Foundations section if one's referenced. If you're unsure whether something is in your directory's ownership, check Team Charter §3.1.

## 4. Check the Decision Log

Search `/decisions/` for anything already resolved in this ticket's area. If a prior session already settled a question this ticket raises, use that answer — don't silently re-decide it, and don't ignore it because it's inconvenient.

## 5. Check the Codebase's Current State

Verify you are in your assigned worktree. Run `scripts/gh-task-ops.sh check` (or `cargo xtask check`, which executes `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, and `cargo nextest run`). If the baseline isn't green, that's a blocker to investigate and raise before starting new work — not something to build on top of or work around quietly. Read the existing code relevant to your ticket before writing anything new; don't assume you know its current shape from a previous session.

## 6. Check Open Cross-Boundary Proposals

Scan `/proposals/` for anything open that touches your directory or this ticket's area, so you're not about to collide with in-flight work from another role. If dependencies or conflicts, raise to the user.

## 7. Plan Before Writing Code

Sketch your approach. If the ticket is bigger than something completable in one sitting, decompose it into a sequence of smaller tasks (Team Charter §4) and create task issues to work through the list.

## PAUSE And Reflect

**If you hit a genuine ambiguity — something neither the Blueprint nor Foundations resolves — stop here.** Raise it to the Steward (and user if needed). Proceeding on a guess is the failure mode this whole process exists to prevent; a short pause is always cheaper than an undocumented wrong assumption compounding through later work.

## 8. Implement

Apply the Team Charter §4 engineering principles as you go — tests alongside the logic they cover, doc comments on public interfaces, no dead code left "for later." These are cheaper to do continuously than to retrofit before a PR.

## 9. Self-Review Against the Definition of Done

Before opening a PR, check it against Team Charter §7 in full: tests, clean clippy, tool-schema contract review if applicable, no dead code, documented interfaces, a decision log entry if warranted, and a reference to the ticket ID. Run `scripts/gh-task-ops.sh check` to confirm machine gates are green.

## 10. Log and Hand Off

- Write any decision log entries the session's work requires (Charter §6) — before opening the PR, not after.
- Append a session summary to `logs/work-log.md` capturing key deliverables, decisions, and downstream impact.
- Scaffold and populate the review brief in `working/briefs/<id>-review.md` using `scripts/gh-task-ops.sh scaffold-review` to prime the independent review and then enrich with additional context.
- Open the PR using `scripts/gh-task-ops.sh pr-create`, which automatically attaches the Definition of Done checklist and session handoff section in the PR description.
- Engage the User for their review and provide:
  - Synopsis, any issues, and request independent Lead Developer review (`/review-pr`) begin.

---

### Quick Reference (once this is second nature)

Orient → read ticket → read spec → check decisions → check codebase is green → check proposals → plan (stop if genuinely blocked) → implement → self-review against DoD → log (work-log & review brief), open PR, hand off to user to start /review-pr.
