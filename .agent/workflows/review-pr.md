---
description:
---

# Dark Factory Workflow: Lead Developer PR Review (`/review-pr`)

### v1.0

This workflow guides the **Tech Lead** (or designated senior reviewer) through conducting an independent, critical Pull Request review before code is merged into `main`.

---

## 1. Core Reviewer Mandate & Philosophy

> [!IMPORTANT]
> **The Independent Reviewer Mandate:**
> The primary purpose of a PR review is **not** to simply confirm that the implementer did what they set out to do. The reviewer must bring a fresh, senior, independent perspective to **find what the implementer was not thinking of**.
>
> You are the safeguard against hidden regressions, unhandled edge cases, concurrency deadlocks, spec drift, and vacuous tests. For an autonomous multi-agent engineering team, software quality depends entirely on the rigor of this independent review.

---

## 2. Review Process Checklist

### Step 1: Context & Artifact Retrieval

- [ ] Read the original **Mission Brief** (`working/briefs/<id>-brief.md`) to understand the strategic goal, Blueprint references, and dispatched acceptance criteria.
- [ ] Read the implementer's **Review Brief** (`working/briefs/<id>-review.md`) and **Session Handoff Note** to understand the author's declared changes and self-identified risks.
- [ ] Consult the relevant **World Blueprint** sections and any active **ADRs** (`decisions/`) to anchor your architectural invariants.

### Step 2: Environment & Machine Gate Verification

- [ ] Switch to the PR worktree / branch.
- [ ] Run the complete machine verification suite:
  ```bash
  cargo xtask check
  ```
  `xtask` should run all of the following: `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo nextest run`
- [ ] Ensure all automated tests pass with zero warnings and zero lints.

### Step 3: The 5 Dimensions of Quality Audit

Deeply evaluate the diff against the 5 dimensions of Dark Factory quality:

#### Dimension 1: Architectural Alignment & Contract Integrity

- [ ] **Crate & Domain Ownership:** Changes respect crate boundaries ([Team Charter §3.1](../../docs/project-charter.md#3-team-structure)). No unauthorized cross-crate imports or circular dependencies.
- [ ] **Multi-Tenant Scoping:** All database tables/queries, ECS queries, WebSocket channels, and event logs are strictly partitioned by `world_id` ([Decision 0003](../../decisions/0003-multi-tenant-world-instances.md)).
- [ ] **Server-Authoritative Invariant:** Simulation state and spatial gating live strictly server-side in `dark_city_server` / `dark_city_world`; `dark_city_client` remains a thin renderer ([Decision 0002](../../decisions/0002-server-authoritative-simulation.md)).
- [ ] **No Speculative Generality & Config-over-Constants:** No unneeded abstractions or hardcoded configuration parameters ([Team Charter §4](../../docs/project-charter.md#4-engineering-principles)).

#### Dimension 2: Correctness, Failure Modes & Edge Cases

- [ ] **Edge Cases Audited:** What happens on empty collections, boundary values, zero balances, missing DB records, network disconnects?
- [ ] **No Naked Panics:** No `unwrap()`, `expect()`, or `panic!()` in production paths. Errors are properly typed using domain `Result<T, DomainError>` enums.
- [ ] **Transactional Atomicity:** Multi-step database updates (e.g., transfers, proposal passage) execute within atomic SQL transactions.

#### Dimension 3: Concurrency, Thread Safety & Runtime Performance

- [ ] **Main Bevy Schedule Safety:** Zero blocking I/O, synchronous DB operations, or blocking HTTP requests on the main ECS schedule.
- [ ] **Async Bridge Integrity:** Long-running cognitive or inference tasks use `AsyncComputeTaskPool` and communicate via non-blocking channels ([Blueprint §3.3](../../docs/dark-city-blueprint.md)).
- [ ] **Lock Contention:** No unconstrained mutex locks or potential deadlock cycles across threads.

#### Dimension 4: Test Value, Rigor & Integrity (CRITICAL)

- [ ] **No Vacuous Assertions:** Tests do not simply check `is_ok()` or `assert!(true)`. They must assert exact expected state mutations, database records, and returned values.
- [ ] **Negative & Failure Mode Coverage:** Tests explicitly exercise error conditions (insufficient energy, location denial, malformed input, unauthorized access).
- [ ] **Regression Value:** Would these tests fail if a future developer introduces a logic bug? If not, demand stronger assertions. Our tests must protect the project against future regressions through feedback.

#### Dimension 5: Code Hygiene & Documentation

- [ ] **Public Interface Documentation:** Every `pub` struct, enum, function, and field includes doc comments explaining _why_ it exists. Ensure all public visibility is expressly necessary and not a leaky abstraction.
- [ ] **Clean Codebase:** Zero dead code, zero commented-out code blocks, zero orphan TODOs.
- [ ] **Relative Links:** All markdown and doc links use relative repository paths.

---

## 3. Review Output & Decision

1. Fill out the **PR Review Report** using the template at `.agent/skills/review-pr/resources/review-template.md`.
2. Categorize all review findings into standardized severity tiers:
   - **🔴 Blocker (P0):** Critical defect, security/safety violation, vacuous test, panic risk, or architecture break. Blocks merge.
   - **🟠 Major (P1):** Significant robustness, missing negative test, or error handling defect. Requires remediation before merge.
   - **🟡 Minor (P2):** Clarity, doc comment, non-blocking cleanup. Remediate or track.
   - **🔵 Suggestion (P3):** Optional optimization or future polish idea.
3. Submit review verdict on the Pull Request (`APPROVE` or `REQUEST CHANGES`).
4. If approved, hand off to the **Steward** for final process verification, provide feedback to user and indicate to user the work is ready for squash-merge via `scripts/gh-task-ops.sh finish`.
