# AGENTS.md

Quick reference for any Dark Factory agent starting work on this codebase. This file is deliberately short — it points you at the right document for depth rather than repeating it. If something here and a linked document disagree, the linked document wins; flag the mismatch so AGENTS.md can be fixed.

## Standardized Terminology

To prevent confusion between the simulation and the development team, strictly adhere to these terms:

- **Citizen:** An in-world simulated character living inside Dark City (e.g. Elena Vance, Samuel Ward). Never refer to in-game characters simply as "agents".
- **Agent / Developer Agent:** A specialist AI coding agent on the Dark Factory development team (Steward, Tech Lead, System Architect, Local Inference Specialist, World Designer, Character Sculptor, QA/Instrumentation).
- **Dark City:** The simulated world, runtime environment, and game systems.
- **Dark Factory:** The development team, engineering processes, and repository automation.

## Read in This Order

1. **[Design Foundations](docs/design-doc.md)** — why this project exists and the architecture decisions that follow from that.
2. **[World Blueprint](docs/dark-city-blueprint.md)** — the technical spec of Dark City: cognitive architecture, memory, world/tools, governance, instrumentation.
3. **[Team Charter](docs/project-charter.md)** — how the Dark Factory team works: roles, worktrees, engineering principles, Dual-Gate PR review, decision log.
4. **This file** — quick reference once you've read the above.
5. **[Session Start Workflow](.agent/workflows/session-start.md)** — the concrete checklist you run right now, at the top of every session.

You don't need to re-read all four every session — Session Start Workflow tells you what to actually check each time.

## What You're Building, in One Paragraph

Dark City is a platform for populating constructed worlds with AI **citizens** and observing how they organize, interact, and change those worlds — built on a full PIANO cognitive architecture (concurrent specialized modules bottlenecked through a single Cognitive Controller for coherence), a three-tier memory system, a fully decentralized governance model, and instrumentation (AWI) for understanding what a given world produced. It's built in Rust (Axum backend, Bevy 0.19 client, Postgres/pgvector), designed from the start to eventually support sculptable worlds — different maps, citizen rosters, and starting scenarios loaded as configuration rather than hardcoded.

## Git Worktree & Session Isolation Rules

Every development task and agent session operates in an isolated git worktree created for that specific GitHub task issue.

- **GitHub Project Tracking:** All issues are managed in [GitHub Project #7](https://github.com/users/briancampo/projects/7).
- **Worktree Location Standard:** `/home/brian/dev/ai/worktrees/dark-city/<issue_id>-<task_slug>/`
- **Branch Naming Standard:** `<issue_id>-<task_slug>`
- **STRICT WORKSPACE BOUNDARY:** You MUST execute all commands and edits strictly inside your assigned worktree directory. Never perform file operations, builds, or git commits outside your assigned worktree path.
- **Relative Markdown Links:** All documentation and markdown references in the repository MUST use relative paths (e.g. `docs/design-doc.md`, `../references/project-sid.md`) so links resolve properly across any worktree and GitHub UI without depending on root filesystem absolute paths.

## Who You Are

| Role                       | Owns                                            | Blueprint sections       |
| -------------------------- | ----------------------------------------------- | ------------------------ |
| Steward                    | Backlog dispatch, decision log, PR process gate | —                        |
| Tech Lead                  | Technical oversight, architecture, PR tech gate | All `/crates/` & `/src/` |
| System Architect           | `crates/dark_city_server/`, `migrations/`       | §2, §6, §7, §12          |
| Local Inference Specialist | `crates/dark_city_inference/`, `grammars/`      | §3.3, §11                |
| World Designer             | `crates/dark_city_world/`, `assets/maps/`       | §5, §8                   |
| Character Sculptor         | `crates/dark_city_cognitive/`, `assets/souls/`  | §4                       |
| QA/Instrumentation         | `crates/dark_city_instrumentation/`, `tests/`   | §9                       |

Full detail, including QA and Tech Lead cross-cutting authorities and how workspace `Cargo.toml` changes are handled, is in [Team Charter §3](docs/project-charter.md#3-team-structure).

## How We Work, Condensed

- **Isolated Worktree:** Verify your current working directory matches your assigned worktree before making any changes.
- **Dual-Gate PR Approval:** Every PR requires sign-off from both the Steward (process & verification) and the Tech Lead (architectural soundness & contracts) per [Team Charter §7](docs/project-charter.md#7-definition-of-done-pr-dual-gate).
- **Clean CI:** No merged code without passing tests (`cargo nextest run`) and clean `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, and `cargo xtask check`.
- **Atomic PRs:** Decompose large tickets rather than opening monolithic PRs.
- **Public Interface Documentation:** Public functions and structs get doc comments explaining _why_ they exist.
- **Log Decisions:** Anything the Blueprint/Foundations don't specify gets an ADR in `decisions/` before PR merge.
- **Cross-Boundary Changes:** Open an RFC in `proposals/` before modifying files outside your role's directory ownership.
- **Escalation:**
  - **Technical / architecture ambiguity:** Pause and raise to the **Tech Lead**.
  - **Scope / dependency ambiguity:** Pause and raise to the **Steward** and/or User as necessary.
  - Never guess silently — a wrong guess is expensive to unwind.

## Commands

```bash
cargo check
cargo clippy --all-targets -- -D warnings
cargo nextest run
cargo fmt --check
cargo xtask check
```

All commands must be clean before you open a PR.

## Where Things Live

```
crates/dark_city_core/            Shared domain types, IDs, error enums (Tech Lead / Shared)
crates/dark_city_server/          Axum backend & DB logic (System Architect)
migrations/                       Postgres SQL migrations (System Architect)
crates/dark_city_inference/       Inference client & schema routing (Local Inference Specialist)
grammars/                         BNF / JSON grammars (Local Inference Specialist)
crates/dark_city_world/           Spatial ECS & tool gating (World Designer)
assets/maps/                      Map configs (World Designer)
crates/dark_city_cognitive/       PIANO blackboard & controller (Character Sculptor)
assets/souls/                     Soul Markdown files (Character Sculptor)
crates/dark_city_instrumentation/ AWI metrics pipeline (QA/Instrumentation)
tests/                            Integration tests (QA/Instrumentation cross-cutting)
xtask/                            Repository CI runner (System Architect / QA)
decisions/                        Architecture decision records (Steward maintains)
proposals/                        Cross-boundary RFCs (Tech Lead & Steward arbitrate)
```

## If You're Blocked

Pause. Raise technical questions to the Tech Lead and backlog/scope questions to the Steward. Small implementation questions get resolved on the spot; real architecture forks get escalated to the human. Either way, the resolution is recorded in `decisions/`.

## Start Here

Go to **[Session Start Workflow](.agent/workflows/session-start.md)** now — it's the actual checklist for this session, not just background reading.
