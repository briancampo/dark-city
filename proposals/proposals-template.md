<!--
Cross-Boundary Proposal RFC Template — Dark Factory Team Charter §5.
Copy this file to /proposals/NNNN-short-slug.md, fill it in, and number sequentially.
See the cross-boundary-rfc skill for full guidance on the review process.
-->

# [NNNN] Short Proposal Title

**Requesting Role:** [Role]
**Date:** YYYY-MM-DD
**Status:** `draft` / `in-review` / `approved` / `rejected`
**Affects:** [Crates / Directories outside the requesting role's ownership]
**Related Research Brief:** [Link if originating from a research brief, or N/A]
**Target Phase / Epic:** [Phase N, Epic X]

---

## 1. What's Changing

<!-- Concrete technical description of the proposed architectural change. -->

---

## 2. Motivation & Architectural Rationale

<!-- What this unblocks, fixes, or enables, and why it cannot be achieved within the requesting role's directory ownership alone. -->

---

## 3. Detailed Cross-Boundary Impact Analysis

<!-- Be specific: list exact crates, files, structs, traits, database migrations, and API contracts touched. -->

- **Crate:** `crates/...`
  - Changes: ...
- **Database Migrations:**
  - Changes: ...
- **Contracts & DTOs:**
  - Changes: ...

---

## 4. Concurrency, Invariants & Multi-Tenancy

- **Bevy Schedule Safety:** [Confirm non-blocking main schedule invariant]
- **Multi-Tenant Isolation:** [Confirm world_id partitioning on state and queries]
- **Error Handling:** [Confirm explicit error enums]

---

## 5. Alternatives Considered

| Alternative | Trade-offs | Reason Rejected |
| :---------- | :--------- | :-------------- |
| Option A    | ...        | ...             |
| Option B    | ...        | ...             |

---

## 6. Integration & Backlog Sequencing Plan

<!-- How and when will this proposal be integrated into the project backlog? -->

- **Decision ADR:** Target `decisions/NNNN-*.md`
- **World Blueprint Updates:** Section §...
- **Backlog Deliverables:** Stories/Tasks to create in Phase N.
