---
name: pr-definition-of-done
description: Use as a self-review checklist before opening any Dark Factory PR, and by the Steward & Tech Lead when gating a PR for merge — Charter §7's Dual Definition of Done. Trigger on "is this PR ready," "self-review before I open a PR," "check this against the Definition of Done," or "gate this PR."
---

# PR Definition of Done

Run every item before opening a PR (self-review) and before approving for merge (Steward & Tech Lead dual gate) — Charter §7.

### Steward Gate (Process & Verification)

- [ ] **Tests pass.** `cargo nextest run` clean for the whole project, not just your directory.
- [ ] **Clippy clean.** `cargo clippy --all-targets -- -D warnings` — zero warnings.
- [ ] **`cargo xtask check` & formatting clean.** `cargo fmt --check` and project lints.
- [ ] **New logic has tests alongside it.** Unit/integration tests written continuously (Charter §4).
- [ ] **No dead code, no commented-out blocks, no unexplained TODOs.** (Charter §4).
- [ ] **Public interfaces documented.** Every public fn/struct has a doc comment explaining _why_ it exists.
- [ ] **Decision log entry exists** for anything not already specified by Foundations or Blueprint.
- [ ] **PR references its backlog ticket ID** in the title or description (`[Phase.Epic.Story]`).
- [ ] **Handoff note included** — Session Start Workflow step 10.

### Tech Lead Gate (Technical & Architectural)

- [ ] **Architecture & Blueprint alignment.** Implementation honors Blueprint specs without speculative generality.
- [ ] **Config-over-constants verified.** Configuration/spatial layouts/soul rosters are loadable, not hardcoded.
- [ ] **Cross-boundary type contracts verified.** Tool schemas, database models, and Bevy-Axum bridge DTOs match specs.
- [ ] **Async / Bevy thread safety reviewed.** No blocking calls on the main Bevy ECS schedule.
