# Dark Factory PR Review Report: PR #[Number] — [Title]

**Reviewer:** Tech Lead (/review-pr)
**Implementer / Author:** [Author Role]
**Ticket:** `[ID] Title`
**Review Date:** YYYY-MM-DD
**Review Status:** `APPROVE` / `REQUEST CHANGES`

---

## 1. Executive Assessment & Senior Perspective

<!--
Provide a high-level critical assessment of the PR from an independent, senior perspective.
Highlight architectural strengths and identify any systemic risks or blind spots.
-->

---

## 2. Findings by Severity

### 🔴 Blocker (P0) — Must Resolve Before Merge

<!--
Critical bugs, spec/Blueprint/Architecture violations, safety hazards, panic risks, maintainability issues, or vacuous/missing tests.
-->

- [ ] **[P0-1] Description:** ...
  - **File - line number:** `crates/...`
  - **Impact:** ...
  - **Remediation:** ...

### 🟠 Major (P1) — Requires Remediation

<!--
Design Pattern misalignment and fragilities, unhandled edge cases, leaky abstractions/unnecessary public visibility, poor error handling/types.
-->

- [ ] **[P1-1] Description:** ...
  - **File - line number:** `crates/...`
  - **Impact:** ...
  - **Remediation:** ...

### 🟡 Minor (P2) — Non-Blocking Improvements

<!--
Doc comment clarity, naming consistency, small cleanups.
-->

- [ ] **[P2-1] Description:** ...
  - **File - line number:** `crates/...`
  - **Impact:** ...
  - **Remediation:** ...

### 🔵 Suggestions (P3) — Future Considerations

<!--
Optional optimizations, ideas for subsequent epics/stories.
-->

- **[P3-1] Description:**
  - **File - line number:** `crates/...`
  - **Impact:** ...
  - **Remediation:** ...

---

## 3. Test Value & Integrity Evaluation

- **Test Coverage Rating:** `Comprehensive` / `Adequate` / `Insufficient`
- **Assertion Rigor:** `Non-vacuous, strong regression protection` / `Needs deeper state assertions`
- **Negative Paths Verified:** `Yes` / `Gaps identified (see above)`

---

## 4. Dual-Gate Review Checklist

- [ ] Architectural alignment & crate boundaries verified
- [ ] Technical Debt and/or maintainability issues
- [ ] Concurrency & Bevy schedule safety verified (no blocking operations)
- [ ] Multi-tenant `world_id` isolation verified
- [ ] Error propagation cleanly typed without unchecked panics
- [ ] Tests provide genuine, non-vacuous regression protection
- [ ] Public interfaces documented explaining _why_
- [ ] `cargo xtask check` runs 100% clean

---

## 5. Review Verdict & Next Steps

- **Verdict:** `APPROVE` / `REQUEST CHANGES`
- **Actionable Next Steps:**
  - ...
