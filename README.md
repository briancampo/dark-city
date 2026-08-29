# Dark City / Dark Factory — Document & Tooling Index

### Organization: [Mindstar Studio](https://github.com/Mindstar-Studio)
### Repository: [Mindstar-Studio/dark-city](https://github.com/Mindstar-Studio/dark-city)
### Project Board: [DC Board (Project #2)](https://github.com/orgs/Mindstar-Studio/projects/2)

Two projects, kept deliberately separate in every document below:

- **Dark City** — the simulated world. AI **citizens**, cognition, memory, tools, governance, instrumentation.
- **Dark Factory** — the team that builds Dark City. Steward, Tech Lead, specialist coding agents, engineering process.

---

## Document Set

| #   | Document                                                    | Layer        | Covers                                                                                                                                                       | Status |
| --- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| 1   | [Design Foundations](docs/design-doc.md)                    | Dark City    | Mission, architecture decisions (PIANO, memory, governance, safety, AWI, multi-model, sculptable worlds), phased roadmap                                     | Done   |
| 2   | [World Blueprint](docs/dark-city-blueprint.md)              | Dark City    | Full technical spec: citizen cognition, memory schema, spatial/tool system, governance, economy, Narrator, instrumentation, inference gateway, scenario format | Done   |
| 3   | [Team Charter](docs/project-charter.md)                     | Dark Factory | Roles & directory ownership, engineering principles, cross-boundary process, decision log, Definition of Done                                                | Done   |
| 4   | [AGENTS.md](AGENTS.md)                                      | Dark Factory | Quick-reference orientation for an agent starting cold on the codebase                                                                                       | Done   |
| 5   | [Session Start Workflow](.agent/workflows/session-start.md) | Dark Factory | Step-by-step bootstrap checklist run at the start of every session                                                                                           | Done   |
| 6   | [Backlog](docs/backlog.md)                                  | Bridge       | Phased epics/stories implementing the World Blueprint, executed by the Dark Factory team                                                                     | Done   |

---

## Developer & Agent Automation Tooling

The repository provides high-signal automation scripts to manage the end-to-end development lifecycle:

| Script | Purpose | Quick Example |
| :--- | :--- | :--- |
| **`scripts/gh-task-ops.sh`** | Developer & Agent Task Execution | `scripts/gh-task-ops.sh assign 1.1.0`<br>`scripts/gh-task-ops.sh check`<br>`scripts/gh-task-ops.sh pr-create` |
| **`scripts/gh-issue-ops.sh`** | Backlog & Issue Hierarchy Management | `scripts/gh-issue-ops.sh scaffold-brief 1.1.2`<br>`scripts/gh-issue-ops.sh create-story 1.1.2 --parent 3`<br>`scripts/gh-issue-ops.sh sub-issues 3` |
| **`cargo xtask check`** | Unified Quality Gate Runner | `cargo xtask check` (runs fmt, strict clippy, nextest) |

---

## Recommended Reading Order

For a new Factory agent: [Design Foundations](docs/design-doc.md) → [World Blueprint](docs/dark-city-blueprint.md) → [Team Charter](docs/project-charter.md) → [AGENTS.md](AGENTS.md) → [Session Start Workflow](.agent/workflows/session-start.md) (run this one every session, not just read once) → [Backlog](docs/backlog.md) (find your assigned story).

For a human reviewer: Design Foundations and World Blueprint together give the full picture of what's being built; Team Charter, AGENTS.md, and Session Start Workflow together give the full picture of how it gets built; the Backlog is where those two halves meet as concrete, dispatchable work.
