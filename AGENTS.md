# AGENTS.md

Quick reference for any Dark Factory agent starting work on this codebase. This file is deliberately short — it points you at the right document for depth rather than repeating it. If something here and a linked document disagree, the linked document wins; flag the mismatch so AGENTS.md can be fixed.

## Read in This Order

1. **Design Foundations** — why this project exists and the architecture decisions that follow from that.
2. **World Blueprint** — the technical spec of Dark City: cognitive architecture, memory, world/tools, governance, instrumentation.
3. **Team Charter** — how the Dark Factory team works: roles, engineering principles, PR gate, decision log.
4. **This file** — quick reference once you've read the above.
5. **Session Start Workflow** — the concrete checklist you run right now, at the top of every session.

You don't need to re-read all four every session — Session Start Workflow tells you what to actually check each time.

## What You're Building, in One Paragraph

Dark City is a platform for populating constructed worlds with AI agents and observing how they organize, interact, and change those worlds — built on a full PIANO cognitive architecture (concurrent specialized modules bottlenecked through a single Cognitive Controller for coherence), a three-tier memory system, a fully decentralized governance model, and instrumentation (AWI) for understanding what a given world produced. It's built in Rust (Axum backend, Bevy 0.19 client, Postgres/pgvector), designed from the start to eventually support sculptable worlds — different maps, character rosters, and starting scenarios loaded as configuration rather than hardcoded.

## Who You Are

| Role                       | Owns                                          | Blueprint sections  |
| -------------------------- | --------------------------------------------- | ------------------- |
| Steward                    | Coordination, decision log, PR gate (process) | —                   |
| Tech Lead                  | Cross-cutting review, PR gate (technical)     | — (all, for review) |
| System Architect           | `/src/server/`, `/migrations/`                | §2, §6, §7, §12     |
| Local Inference Specialist | `/src/inference/`, `/grammars/`               | §3.3, §11           |
| World Designer             | `/src/world/`, `/assets/maps/`                | §5, §8              |
| Character Sculptor         | `/src/cognitive/persona.rs`, `/assets/souls/` | §4                  |
| QA/Instrumentation         | `/tests/`, `/src/instrumentation/`            | §9                  |

Full detail, including the QA agent's cross-cutting test authority, the Tech Lead's cross-cutting review authority, and how `Cargo.toml` changes are handled, is in Team Charter §3.

## How We Work, Condensed

- No merged code without passing tests and clean `cargo clippy`. No dead code. No commented-out blocks.
- Every PR needs sign-off from both the Steward (process) and the Tech Lead (technical soundness) before merge — two independent checks, not a formality.
- Small PRs. Decompose big tickets rather than opening one large PR.
- Public interfaces get doc comments explaining _why_, not just what.
- Anything the Blueprint/Foundations don't already specify gets a decision log entry (`/decisions/`) before the PR merges — not after.
- Need to touch something outside your directory? Open an RFC in `/proposals/` first. Don't just do it.
- Hit a real ambiguity? Stop and ask the Steward. Don't guess silently — a wrong guess that ships is more expensive to unwind than a short pause.

Full version: Team Charter §4–§7.

## Commands

`cargo xtask check` is a separate cargo crate developed early on in the project to capture and check project specific lints, rules, and other elements that ensure the quality of the project's code and infrastrcuture.

```
cargo check
cargo clippy --all-targets -- -D warnings
cargo nextest run
cargo fmt --check
cargo xtask check
```

All four should be clean before you open a PR. If the toolchain or command set changes as the project matures, update this section — don't let it go stale.

## Where Things Live

```
/src/server/               System Architect
/migrations/               System Architect
/src/inference/            Local Inference Specialist
/grammars/                 Local Inference Specialist
/src/world/                World Designer
/assets/maps/              World Designer
/src/cognitive/persona.rs  Character Sculptor
/assets/souls/             Character Sculptor
/tests/                    QA/Instrumentation (cross-cutting)
/src/instrumentation/      QA/Instrumentation
/decisions/                Everyone reads; Steward maintains
/proposals/                Cross-boundary RFCs
```

## If You're Blocked

Pause. Scope or process questions go to the Steward; technical or architecture questions go to the Tech Lead — either way, don't proceed on a guess. Small implementation questions get resolved on the spot; real architecture forks get escalated to the human. Either way, the resolution gets logged in `/decisions/` so the next session doesn't hit the same fork blind.

## Start Here

Go to **Session Start Workflow** (`.agent/workflows/session-start.md`) now — it's the actual checklist for this session, not just background reading.
