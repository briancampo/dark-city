# Dark Factory Review Brief: Ticket [{ticket_id}]

**Author / Implementer:** {author_role}
**Assigned Reviewer:** Tech Lead (/review-pr)
**Process Gate:** Steward
**Sprint / Epic:** Epic {epic_id} — {epic_title}
**Ticket:** `[{ticket_id}] {ticket_title}`
**Pull Request:** [PR #{pr_number} / Link]
**Worktree / Branch:** `{branch_name}`

---

## 1. Summary of Changes

<!-- Concise summary of what was built and why -->

- **Primary Deliverables:**
  - ...
- **Key Files Modified/Added:**
  - `crates/...`

---

## 2. Architectural Invariants & Key Decisions

<!-- Note any architectural choices, pattern applications, or ADR references -->

- **Decisions Followed:**
  - [e.g. Decision 0002 (Server Authoritative), Decision 0003 (Multi-tenant), etc.]
- **Invariants Maintained:**
  - [e.g. No blocking I/O on Bevy main schedule, explicit world_id partitioning on queries]

---

## 3. Implementer Self-Identified Risk Areas & Edge Cases

<!-- What was tricky? Where should the reviewer look extra carefully? -->

- **Concurrency / Threading:**
  - ...
- **Boundary / Error Paths:**
  - ...
- **Potential Fragilities:**
  - ...

---

## 4. Test Coverage & Verification Evidence

- **New Tests Added:**
  - `...`
- **Quality Gates Run:**
  - [x] `cargo xtask check` clean // verify the following are included in this check and then remove from this list.
    - [x] `cargo fmt --check` clean
    - [x] `cargo clippy --all-targets -- -D warnings` clean
    - [x] `cargo nextest run` clean
    - [x] Static analysis, lint, and boundary checks (do these happen in the check already?)

---

## 5. Independent Review Guidance (For Tech Lead / Reviewer)

> [!TIP]
> **Reviewer Mandate:** Do not simply verify that the author's code does what the author intended. Conduct an independent, senior-perspective critical evaluation per the `/review-pr` workflow and `review-checklist.md`:
>
> 1. Look for unhandled edge cases, concurrency hazards, and race conditions.
> 2. Scrutinize test assertions for real regression value (no vacuous checks).
> 3. Verify no speculative generality or hardcoded constants.
> 4. Ensure public doc comments explain _why_ types and methods exist. Evaluate for leaky abstraction and unnecessary public visibility.
