---
description: How to bootstrap a new work session with proper context loading. Use when starting a new agent session on any domain.
---

# Dark Factory: Session Start Workflow

**Version:** v1.2

Run this at the start of every session, before writing any code — whether it's your first session on a ticket or a continuation of one already in progress. It's short by design; skipping steps to save time is exactly the kind of shortcut the Team Charter exists to prevent.

## 1. Orient & Confirm Worktree

- Confirm your assigned **Role**, **Ticket ID**, and corresponding **GitHub Issue ID** (from [GitHub Project #7](https://github.com/users/briancampo/projects/7)).
- Verify your active working directory matches your designated isolated worktree:
  `/home/brian/dev/ai/worktrees/dark-city/<issue_id>-<task_slug>/`
- Confirm your git branch matches `<issue_id>-<task_slug>`.
- **STRICT BOUNDARY:** Perform all reading, editing, and command execution strictly within this worktree.
- If `AGENTS.md` isn't already in context, read it now (`../../AGENTS.md`).

## 2. Read the Ticket

Get the ticket's title, role/goal statement, Gherkin acceptance criteria, and any Blueprint or Foundations sections it references. If it doesn't reference specific sections, figure out which ones apply before proceeding — don't start writing code against an assumed spec.

## 3. Read the Relevant Spec

Read the exact World Blueprint section(s) the ticket touches, and the corresponding Design Foundations section if one's referenced. If you're unsure whether something is in your directory's ownership, check [Team Charter §3.1](../../docs/project-charter.md#3-team-structure).

## 4. Check the Decision Log

Search `../../decisions/` for anything already resolved in this ticket's area. If a prior session already settled a question this ticket raises, use that answer — don't silently re-decide it, and don't ignore it because it's inconvenient.

## 5. Check the Codebase's Current State

Run `cargo check`, `cargo clippy --all-targets -- -D warnings`, `cargo nextest run`, and `cargo xtask check`. If the baseline isn't green, that's a blocker to investigate and raise before starting new work — not something to build on top of or work around quietly. Read the existing code relevant to your ticket before writing anything new.

## 6. Check Open Cross-Boundary Proposals

Scan `../../proposals/` for anything open that touches your directory or this ticket's area, so you're not about to collide with in-flight work from another role.

## 7. Plan Before Writing Code

Sketch your approach. If the ticket is bigger than something reviewable in one sitting, decompose it into a sequence of smaller tasks ([Team Charter §4](../../docs/project-charter.md#4-engineering-principles)).

**If you hit a genuine ambiguity — stop here.**

- For **technical or architectural ambiguity** (Blueprint interpretation, contract design, typing/abstraction questions): raise to the **Tech Lead**.
- For **scope, sequencing, or dependency ambiguity**: raise to the **Steward**.
- Proceeding on a guess is the failure mode this whole process exists to prevent; a short pause is always cheaper than an undocumented wrong assumption compounding through later work.

## 8. Implement

Apply [Team Charter §4](../../docs/project-charter.md#4-engineering-principles) as you go:

- Write unit/integration tests alongside the logic they cover.
- Add doc comments on public interfaces explaining _why_ they exist.
- Ensure all markdown links in docs are relative paths.
- Leave no dead code or unexplained TODOs.

## 9. Self-Review Against the Definition of Done

Before opening a PR, check against [Team Charter §7](../../docs/project-charter.md#7-definition-of-done-pr-dual-gate) in full using the `pr-definition-of-done` skill:

- All tests pass (`cargo nextest run`)
- Clippy is clean (`cargo clippy --all-targets -- -D warnings`)
- `cargo fmt --check` and `cargo xtask check` pass
- Public interfaces documented
- Relative markdown links verified
- Decision log entry recorded if applicable
- Backlog ticket and GitHub issue ID referenced

## 10. Log and Hand Off

- Write any decision log entries the session's work requires before opening the PR.
- Write a short handoff note in the PR / issue description: what's done, what's still open, and anything the next session needs to know.
- Open the PR, reference the ticket and issue IDs, and request Steward & Tech Lead dual review.

---

### Quick Reference

Orient & Check Worktree → read ticket → read spec → check decisions → check green baseline → check proposals → plan (stop if blocked) → implement → self-review against DoD → log, hand off, open PR.
