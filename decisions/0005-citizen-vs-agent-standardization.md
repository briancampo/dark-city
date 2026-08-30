# [0005] Standardized Terminology: In-World "Citizens" vs. AI Developer "Agents"

**Date:** 2026-08-29  
**Ticket:** Pre-Epic-1.1 Terminology Governance & Architectural Standardization  
**Role:** Steward (facilitated), for Tech Lead ratification  

---

## Question

How should the project disambiguate simulated in-world characters living inside Dark City from the AI specialist developer agents on the Dark Factory engineering team, general AI agent concepts, and tooling agents? 

Prior to this decision, the term "agent" was overloaded across the repository: it referred simultaneously to simulated in-game inhabitants (e.g., `AgentId`, `AgentState`, `agents` table, `agent_memories`), AI coding agents developing the platform (Steward, Tech Lead, System Architect, etc.), and general LLM agent concepts. This created ambiguity in prompts, documentation, domain types, and architectural discussions.

---

## Options Considered

1. **Retain "Agent" for in-world characters, rename developer roles to "Developers / Bots".**  
   Fails to solve ambiguity when interacting with general LLM agent literature or when AI coding assistants process instructions referencing both the team and in-game actors.
2. **Context-dependent "Agent" (status quo).**  
   Rely on context clues to distinguish in-game characters from AI developers and general agents. Highly error-prone for autonomous AI developer agents, resulting in semantic drift, incorrect database references, and prompt confusion.
3. **Strict Separation: "Citizen" for simulated characters, "Agent" / "Developer Agent" for Dark Factory AI roles.**  
   Exclusively use **Citizen** for simulated in-world inhabitants living within Dark City. Exclusively use **Agent** or **Developer Agent** for the AI coding specialists on the Dark Factory development team (Steward, Tech Lead, System Architect, Local Inference Specialist, World Designer, Character Sculptor, QA/Instrumentation).

---

## Decision

**Adopt Option 3:**

1. **In-World Characters -> "Citizen":**
   - In-game simulated inhabitants are strictly termed **citizens** across all documentation, code symbols, database schemas, and API contracts.
   - **Rust Identifiers:** `CitizenId`, `CitizenState`, `ToolCall::SayToCitizen`, `ToolCall::PayCitizen`, `SimulationEvent.citizen_id`, `citizen_positions`, `citizen_energy`, `actor_citizen_id`, `origin_citizen_id`.
   - **Database Tables & Columns:** `citizens`, `citizen_memories`, `citizen_relationships`, `citizen_plans`, `from_citizen`, `to_citizen`.
2. **Development Team -> "Agent" / "Developer Agent":**
   - The specialist AI coding agents building Dark City are strictly termed **developer agents** or **agents** (Steward, Tech Lead, System Architect, Local Inference Specialist, World Designer, Character Sculptor, QA/Instrumentation).
3. **Research Metric Acronym:**
   - **AWI (Agent World Index)** is retained as the standardized research metric acronym (M1–M11), but all underlying metrics definitions, SQL queries, and code comments reference active citizens and `citizen_created_tools`. This is because it refers the citizen's agentic nature not the citizen itself. 
4. **Permanent Invariant:**
   - No future developer agent, ticket, or PR may reintroduce "agent" for in-world simulated characters. Any PR attempting to use `AgentId`, `AgentState`, or `agents` table for in-world entities must be rejected at the Steward and Tech Lead gates.

---

## Why

- **Eliminates Semantic Drift & Prompt Poisoning:** Autonomous coding agents operate within LLM context windows. Overloaded terms lead to subtle prompt confusion where instructions intended for the developer agent get conflated with character behaviors or vice versa.
- **Crystal-Clear Domain Modeling:** Looking at a struct (`CitizenState`), table (`citizens`), or API route (`/api/v1/worlds/:world_id/citizens`), any developer agent or human engineer immediately knows the scope without guessing.
- **Enforces Clean Boundary:** Reinforces Team Charter §1 ("Dark Factory has no presence inside the simulated world, ever"). Developers write software; citizens inhabit the simulation.

---

## Impact

- **`AGENTS.md` & `docs/project-charter.md`:** Codified standardized terminology definitions and PR Dual-Gate validation rules.
- **Rust Domain Types (`crates/dark_city_core`, `dark_city_cognitive`, `dark_city_world`, `dark_city_server`):** `AgentId` -> `CitizenId`, `AgentState` -> `CitizenState`, `ToolCall::{SayToCitizen, PayCitizen}`.
- **Postgres Migrations (`migrations/`, `working/briefs/1.1.1-brief.md`):** Base schema defines `citizens`, `citizen_memories`, `citizen_relationships`, `citizen_plans`, and `origin_citizen_id`.
- **System Architecture & Blueprints (`docs/dark-city-blueprint.md`, `docs/design-doc.md`, `docs/backlog.md`):** Updated all references to citizen state, citizen memory, and citizen lifecycle.
- **Decisions & Proposals:** Decisions 0001 through 0004 and active proposals aligned with the standard.
