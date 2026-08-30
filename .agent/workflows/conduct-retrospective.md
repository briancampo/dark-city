---
description:
---

# Dark Factory Workflow: Epic Retrospective (`/conduct-retrospective`)

### v1.0

This workflow guides the **Steward** in facilitating an end-of-Epic retrospective with the development team and the User.

**Facilitator:** Steward
**Co-Lead:** Tech Lead
**Participants:** All Dark Factory Roles (`.agent/roles/*`) and the User.

---

## 1. Retrospective Objectives

1. Review and validate all completed deliverables against the Epic goal.
2. Conduct a **User Live Demo** where the Steward guides the User through running the simulation in their environment.
3. Solicit structured feedback across all specialist roles.
4. Document learnings, metrics, and discoveries in a permanent Epic Retrospective Brief (`docs/retrospectives/epic-<id>-retro.md`).
5. Extract concrete action items to improve subsequent Epics and developer tooling.

---

## 2. Step-by-Step Retrospective Flow

### Step 1: Pre-Retrospective Preparation (Steward & Tech Lead)

- [ ] Verify all Epic stories and tasks are closed and merged on the [DC Board (Project #2)](https://github.com/orgs/Mindstar-Studio/projects/2).
- [ ] Confirm workspace baseline is green (`scripts/gh-task-ops.sh check`).
- [ ] Scaffold the retrospective brief under `docs/retrospectives/epic-<id>-retro.md` using the template at `docs/templates/epic-retrospective-template.md`.

### Step 2: User Live Demo Walkthrough

- [ ] **Steward Guidance:** Guide the User through starting the services (e.g. backend, database, client, or simulation runner) in their environment.
- [ ] **Observe Simulation:** Observe citizen behavior, ECS tick stability, WebSocket streams, and event logs.
- [ ] **Document User Feedback:** Record User reactions, edge case observations, and aesthetic/behavioral notes directly in the retro brief.
- [ ] **Capture New Work:** Capture new work items and features from the walkthrough and add/sequence them in the backlog.

### Step 3: Multi-Role Retrospective Discussion

Solicit structured observations from each role:

- **System Architect:** DB query performance, migration hygiene, multi-tenant isolation, ECS tick stability.
- **Tech Lead:** Contract integrity, test thoroughness, anti-patterns caught, refactoring opportunities.
- **Local Inference Specialist:** Prompt adherence, grammar constraints, inference latency, JSON schema stability.
- **Character Sculptor:** Cognitive coherence, PIANO controller bottlenecking, memory tree growth, dialogue quality.
- **World Designer:** Spatial graph validity, viewer rendering smoothness, scenario package parsing.
- **QA / Instrumentation:** Automated test suite health, AWI metrics signal, violation audits.
- **Steward:** Velocity, slicing accuracy, brief effectiveness, worktree/branch lifecycle friction.

### Step 4: Finalize Retrospective Artifact

- [ ] **Retrospective Cleanup:** Once the retrospective has been approved all Parent Epics and Stories are closed with a comment and marked as accepted.
- [ ] Complete `docs/retrospectives/epic-<id>-retro.md`.
- [ ] Create follow-up action items or refactoring issues for subsequent iterations using `scripts/gh-issue-ops.sh create`.
- [ ] Update `docs/backlog.md` if any subsequent story estimates or dependencies require adjustment based on findings.
