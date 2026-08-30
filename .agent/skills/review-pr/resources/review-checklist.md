# Dark Factory Independent PR Review Checklist

Use this checklist during every Lead Developer PR Review (`/review-pr`). Every item must be actively evaluated against the PR diff.

---

## 1. Architectural Alignment & Domain Boundaries

- [ ] **Directory Ownership:** Files modified belong strictly to the author's role ownership ([Team Charter §3.1](../../../../docs/project-charter.md#3-team-structure)), or an approved RFC exists in `proposals/`.
- [ ] **Cross-Crate Coupling:** No circular crate dependencies or abstraction leaks between `dark_city_core`, `dark_city_server`, `dark_city_world`, `dark_city_cognitive`, `dark_city_inference`, and `dark_city_client`.
  - Strictly guard against unnecessary public visibility.
- [ ] **Multi-Tenancy Scoping:** All database tables, queries, ECS entities, WebSocket topics, and log records include explicit multi-tenancy (e.g. multi-world) partitioning ([Decision 0003](../../../../decisions/0003-multi-tenant-world-instances.md)).
- [ ] **Server Authoritative:** Simulation logic, spatial indexing, and tool gating reside server-side; viewer client is purely a rendering consumer ([Decision 0002](../../../../decisions/0002-server-authoritative-simulation.md)) and user interaction client.
- [ ] **No Speculative Generality:** Code addresses the exact acceptance criteria without unneeded abstractions or unused generic parameters.
- [ ] **Config-Over-Constants:** Thresholds, rates, weights, and timeouts are configurable rather than hardcoded magic values.

---

## 2. Correctness, Failure Modes & Edge Cases

- [ ] **Input Validation:** External inputs (API payloads, WebSocket messages, Soul files, scenario configs) are strictly validated before use.
- [ ] **Boundary Conditions:** Handled empty collections, zero values, max values, and negative inputs cleanly.
- [ ] **No Unchecked Panics:** No `unwrap()`, `expect()`, or `panic!()` in production paths. Handled via domain `Result<T, DomainError>`.
- [ ] **Database Integrity:** Multi-row mutations and state transitions use atomic database transactions with proper rollback semantics.
  - Database changes use migrations that are well constructed and idempotent.
- [ ] **Idempotency & Replay:** Event ingestion and scheduler ticks handle duplicate or out-of-order triggers gracefully.

---

## 3. Concurrency, Thread Safety & Performance

- [ ] **Main ECS Loop Non-Blocking:** Zero synchronous I/O, database blocking calls, or HTTP requests on the main Bevy schedule.
- [ ] **Async Offloading:** Heavy cognitive reasoning and inference requests use `AsyncComputeTaskPool` with non-blocking channel polling.
- [ ] **Resource Contention:** No risk of deadlocks, thread starvation, or unbounded queue memory growth.

---

## 4. Test Integrity & Value (CRITICAL)

- [ ] **Non-Vacuous Assertions:** Tests assert meaningful state changes, mutated database records, and returned values (not just `assert!(res.is_ok())`).
- [ ] **Failure / Negative Testing:** Explicit test cases verify expected error returns for invalid inputs, denied access, or missing prerequisites.
- [ ] **Regression Protection:** Tests are structured such that future breaking changes to business logic or schemas will reliably trigger test failures.
- [ ] **Test Cleanliness:** Tests are deterministic, isolated, and do not leave dangling artifacts or rely on non-reproducible external state.

---

## 5. Code Hygiene & Documentation

- [ ] **Doc Comments on Public API:** Every public struct, enum, trait, function, and configuration field has doc comments explaining _why_ it exists.
- [ ] **No Dead Code:** No commented-out code, debug `println!` statements, or orphan TODOs.
- [ ] **Relative Links:** All markdown documentation links use relative paths.
- [ ] **Machine Gates Clean:** `scripts/gh-task-ops.sh check` (`cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo nextest run`, `cargo xtask check`) is 100% clean.

## 6. Static Analysis

- [ ] **`xtask` Improvements:** Seek opportunities to improve our `xtask` runner to create additional boundary checks and static analysis to catch potential issues during development phase.
- [ ] Review for the following:
  - [ ] **Security Vulnerabilities:** (e.g., SQL injection, XSS, insecure deserialization, race conditions)
  - [ ] **API Misuse:** (e.g., incorrect API usage, deprecated patterns)
  - [ ] **Code Quality:** (e.g., complexity, duplication, poor naming)
  - [ ] **Performance Anti-Patterns:** (e.g., inefficient algorithms, excessive allocations)
  - [ ] **Best Practices:** (e.g., proper error handling, resource management)

## 7. Documentation Consistency

All documentation is reviewed to ensure up-to-date and accurate reflection of code changes.

- [ ] **Decision Records:** Update any related decision records in `/decisions/*.md` that were affected by this change.
- [ ] **Rust Code Documentation:** Ensure inline doc comments and crate-level documentation are updated to reflect new APIs, changed behavior, or added constraints.
- [ ] **Diagrams:**
  - Use mermaid diagrams where possible to help describe complex topics in documentation.
  - Review and update any diagrams to reflect changes in component relationships, data flow, or system architecture.
