# Dark City / Dark Factory — Document & Tooling Index

### Organization: [Mindstar Studio](https://github.com/Mindstar-Studio)

### Repository: [Mindstar-Studio/dark-city](https://github.com/Mindstar-Studio/dark-city)

### Project Board: [DC Board (Project #2)](https://github.com/orgs/Mindstar-Studio/projects/2)

Two projects, kept deliberately separate in every document below:

- **Dark City** — the simulated world. AI **citizens**, cognition, memory, tools, governance, instrumentation.
- **Dark Factory** — the team that builds Dark City. Steward, Tech Lead, specialist coding agents, engineering process.

---

## Document Set

| #   | Document                                                           | Layer        | Covers                                                                                                                                                                          | Status |
| --- | ------------------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 1   | [Design Foundations](docs/design-doc.md)                           | Dark City    | Mission, architecture decisions (PIANO, memory, governance, safety, AWI, multi-model, sculptable worlds), phased roadmap                                                        | Done   |
| 2   | [World Blueprint](docs/dark-city-blueprint.md)                     | Dark City    | Full technical spec: citizen cognition, memory schema, spatial/tool system, governance, economy, Narrator, instrumentation, inference gateway, scenario & world-instance format | Done   |
| 3   | [Team Charter](docs/project-charter.md)                            | Dark Factory | Roles & directory ownership, engineering principles, cross-boundary process, decision log, Definition of Done                                                                   | Done   |
| 4   | [AGENTS.md](AGENTS.md)                                             | Dark Factory | Quick-reference orientation for an agent starting cold on the codebase                                                                                                          | Done   |
| 5   | [Session Start Workflow](.agent/workflows/session-start.md)        | Dark Factory | Step-by-step bootstrap checklist run at the start of every session                                                                                                              | Done   |
| 6   | [Backlog](docs/backlog.md)                                         | Bridge       | Phased epics/stories implementing the World Blueprint, executed by the Dark Factory team                                                                                        | Done   |
| 7   | [Decision 0001](decisions/0001-workspace-crate-structure.md)       | Dark Factory | Cargo workspace crate decomposition & role mapping                                                                                                                              | Done   |
| 8   | [Decision 0002](decisions/0002-server-authoritative-simulation.md) | Dark Factory | Server-authoritative headless simulation; the Bevy client is a thin viewer, never the engine                                                                                    | Done   |
| 9   | [Decision 0003](decisions/0003-multi-tenant-world-instances.md)    | Dark Factory | Isolated, multi-tenant world instances — scenario package vs. running world distinguished                                                                                       | Done   |

---

## Developer & Agent Automation Tooling

The repository provides high-signal automation scripts to manage the end-to-end development lifecycle:

| Script                        | Purpose                              | Quick Example                                                                                                                                       |
| :---------------------------- | :----------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`scripts/gh-task-ops.sh`**  | Developer & Agent Task Execution     | `scripts/gh-task-ops.sh assign 1.1.0`<br>`scripts/gh-task-ops.sh check`<br>`scripts/gh-task-ops.sh pr-create`                                       |
| **`scripts/gh-issue-ops.sh`** | Backlog & Issue Hierarchy Management | `scripts/gh-issue-ops.sh scaffold-brief 1.1.2`<br>`scripts/gh-issue-ops.sh create-story 1.1.2 --parent 3`<br>`scripts/gh-issue-ops.sh sub-issues 3` |
| **`cargo xtask check`**       | Unified Quality Gate Runner          | `cargo xtask check` (runs fmt, strict clippy, nextest)                                                                                              |

---

## Recommended Reading Order

For a new Factory agent: Design Foundations → World Blueprint → Team Charter → AGENTS.md → Session Start Workflow (run this one every session, not just read once) → Backlog (find your assigned story). Ensure you understand the server authoritative simulation and multi-tenant world instances design decisions.

For a human reviewer: Design Foundations and World Blueprint together give the full picture of what's being built; Team Charter, AGENTS.md, and Session Start Workflow together give the full picture of how it gets built; the Backlog is where those two halves meet as concrete, dispatchable work.

## What's Next

Epic 1.0 (repository & tooling bootstrap) is complete, including containerized backend deployment. Before Epic 1.1 goes further, two architecture corrections were made and are recorded in the decision log: [Decision 0002](decisions/0002-server-authoritative-simulation.md) moves all simulation state and PIANO module execution into a headless backend ECS App, with the Bevy client reduced to a thin, stateless viewer (`dark_city_client`); [Decision 0003](decisions/0003-multi-tenant-world-instances.md) adds isolated, multi-tenant world instances (a `worlds` table and `world_id` scoping) ahead of Phase 3/4 needing them. The Blueprint, Team Charter, AGENTS.md, and Backlog have all been updated to match — the natural next step is dispatching (or, for 1.1.1, verifying and possibly retrofitting) the revised Epic 1.1 tickets before proceeding into Epic 1.2.

## Notes on This Document Set

- Where a concept comes from the source research (Smallville, Project Sid/PIANO, Emergence World), it's explained in full within these documents rather than referenced abstractly — a developer shouldn't need to read the original papers until they need to deep dive on a topic area.
- The one open architectural item worth remembering going into the Backlog: Design Foundations §14 lists a few parameters (reflection threshold, recency decay, Phase 1 tool catalog size, the scenario-package file format) that are expected to need empirical tuning once there's a real running system to observe. §14 also now flags a lightweight browser-based observer/spectator view and an optional cross-world interaction mechanism as raised-but-not-yet-scoped ideas — worth a look before they're needed rather than after.
