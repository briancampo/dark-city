# Architecture Decision Log

This directory contains dated, numbered architectural decision records (ADRs) for the Dark City project, maintained by the Steward per Team Charter §6.

| ID                                                  | Title                                                | Date       | Role             | Status   |
| :-------------------------------------------------- | :--------------------------------------------------- | :--------- | :--------------- | :------- |
| [0001](0001-workspace-crate-structure.md)           | Cargo Workspace Crate Decomposition & Role Mapping   | 2026-08-27 | System Architect | Accepted |
| [0002](0002-server-authoritative-simulation.md)     | Server-Authoritative Simulation & Thin Viewer Client | 2026-08-27 | System Architect | Accepted |
| [0003](0003-multi-tenant-world-instances.md)        | Multi-Tenant World Instances                         | 2026-08-28 | System Architect | Accepted |
| [0004](0004-observation-and-world-event-capture.md) | Observation & World-Event Capture                    | 2026-08-29 | System Architect | Accepted |
| [0005](0005-citizen-vs-agent-standardization.md)    | Standardized Terminology: "Citizens" vs. "Agents"    | 2026-08-29 | Steward          | Accepted |

### Guidelines

- Every non-trivial architectural choice or deviation from the World Blueprint must have a decision entry before the implementing PR merges.
- Use `decisions-template.md` as the template for new records (`NNNN-short-slug.md`).
