# Dark City / Dark Factory — Document Index

### Last updated: this session

Two projects, kept deliberately separate in every document below:

- **Dark City** — the simulated world. Agents, cognition, memory, tools, governance, instrumentation.
- **Dark Factory** — the team that builds Dark City. Steward, five specialist coding agents, engineering process.

## Document Set

| #   | Document                                                    | Layer        | Covers                                                                                                                                                       | Status |
| --- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| 1   | [Design Foundations](docs/design-doc.md)                    | Dark City    | Mission, architecture decisions (PIANO, memory, governance, safety, AWI, multi-model, sculptable worlds), phased roadmap                                     | Done   |
| 2   | [World Blueprint](docs/dark-city-blueprint.md)              | Dark City    | Full technical spec: agent cognition, memory schema, spatial/tool system, governance, economy, Narrator, instrumentation, inference gateway, scenario format | Done   |
| 3   | [Team Charter](docs/project-charter.md)                     | Dark Factory | Roles & directory ownership, engineering principles, cross-boundary process, decision log, Definition of Done                                                | Done   |
| 4   | [AGENTS.md](AGENTS.md)                                      | Dark Factory | Quick-reference orientation for an agent starting cold on the codebase                                                                                       | Done   |
| 5   | [Session Start Workflow](.agent/workflows/session-start.md) | Dark Factory | Step-by-step bootstrap checklist run at the start of every session                                                                                           | Done   |
| 6   | [Backlog](docs/backlog.md)                                  | Bridge       | Phased epics/stories implementing the World Blueprint, executed by the Dark Factory team                                                                     | Done   |

## Recommended Reading Order

For a new Factory agent: Design Foundations → World Blueprint → Team Charter → AGENTS.md → Session Start Workflow (run this one every session, not just read once) → Backlog (find your assigned story).

For a human reviewer: Design Foundations and World Blueprint together give the full picture of what's being built; Team Charter, AGENTS.md, and Session Start Workflow together give the full picture of how it gets built; the Backlog is where those two halves meet as concrete, dispatchable work.

## What's Next

The full document set is complete: Design Foundations and World Blueprint define Dark City; Team Charter, AGENTS.md, and Session Start Workflow define how Dark Factory works; the Backlog turns the World Blueprint into 64 phased stories across 18 epics, ready for the Steward to track and for conversion into GitHub issues. The natural next step is standing up the actual repository (Backlog Epic 1.0) and starting Phase 1.

## Notes on This Document Set

- Where a concept comes from the source research (Smallville, Project Sid/PIANO, Emergence World), it's explained in full within these documents rather than referenced abstractly — a developer shouldn't need to read the original papers until they need to deep dive on a topic area.
- The one open architectural item worth remembering going into the Backlog: Design Foundations §14 lists a few parameters (reflection threshold, recency decay, Phase 1 tool catalog size, the scenario-package file format) that are expected to need empirical tuning once there's a real running system to observe.
