---
name: epic-planning-toolkit
description: Plan, assess, decompose, and scaffold a new Dark Factory Epic or Sprint. Provides Context-Window & Complexity Bounded Slicing guidelines and GitHub project hierarchy structures. Trigger on "epic-planning-toolkit", "plan epic", "epic planning", "start epic", "sprint planning", or "decompose epic".
---

# Dark Factory Skill: Epic Planning Toolkit (`epic-planning-toolkit`)

Use this skill when initiating a new Epic, conducting pre-flight gap analysis, slicing stories into context-bounded tasks, configuring GitHub project hierarchies, and scaffolding enriched mission briefs.

---

## When to Use
- At the start of any new Epic, iteration, or milestone phase.
- When an Epic needs pre-flight gap analysis against the Blueprint and codebase.
- When slicing high-level stories into single-session developer tasks.

---

## Core Planning Activities

### 1. Gap Analysis & Architecture Assessment
Audit the Epic against:
- `docs/backlog.md`
- `docs/dark-city-blueprint.md`
- `docs/design-doc.md`
- Existing codebase and active ADRs in `decisions/`.

### 2. User Inception Alignment
Engage the user in an interactive discussion to resolve open architectural questions, confirm design trade-offs, and ratify any required ADRs.

### 3. Context-Window & Complexity Bounded Slicing
Slice work items into cohesive units of work bounded by single-session cognitive capacity:
- Avoid micro-task thrash.
- Avoid multi-system monolithic sprawl.
- Ensure 100% test integrity requirements and clear single-role ownership.

### 4. Issue Dispatch & GitHub Project Structure
- Link issues hierarchically: `Epic -> Story -> Task` (`scripts/gh-issue-ops.sh link`).
- Apply standard labels: `type:epic`, `type:story`, `type:task`, `domain:<area>`.
- Set actionable leaf tasks to `Ready`; keep parent Epics/Stories in `Backlog`.

### 5. Enriched Brief Scaffolding
- Scaffold brief with `scripts/gh-issue-ops.sh scaffold-brief <id>`.
- Steward & Tech Lead enrich the scaffold with architectural context, invariants, and test strategies.
