# [0003] Multi-Tenant World Instances (Isolated by Default)

**Date:** 2026-08-28
**Ticket:** Pre-Epic-1.1 architecture correction (companion to Decision 0002)
**Role:** Steward (facilitated), for Tech Lead ratification

## Question

Once the backend is server-authoritative (Decision 0002), should one `dark_city_server` deployment be able to run more than one concurrent, independent simulation — distinct citizens, distinct spatial worlds, distinct clocks — rather than exactly one global world per deployment? This is explicitly **not** about multiple viewer clients watching the same world (solved by 0002's thin-client model); it's about multiple *separate worlds*, each potentially with its own viewer(s), existing side by side.

Note that the current backlog already implicitly assumes this is possible without any schema support for it: Story 4.2.2 requires running "two runs (one homogeneous, one heterogeneous) with otherwise-matching scenarios" and comparing them "side by side." Nothing in Blueprint v1.0 §4.1/§6/§7/§10 supports two runs existing at once — every table is an unscoped singleton. Better to add the scoping seam now, while it's schema-only, than to retrofit it once Phase 3/4 tooling depends on its absence.

## Options Considered

1. **Single global world per deployment (status quo).** Matches Phase 1's original scope exactly; simplest possible schema.
2. **Multiple independent, isolated concurrent world instances per deployment**, each created by loading a scenario package, scoped throughout the schema and API by a `world_id`, with no mechanism for worlds to interact.
3. **Same as 2, plus an optional, configurable cross-world interaction mechanism** (e.g., a shared trade route or shared Narrator content between two specific worlds).

## Decision

**Option 2 now.** Introduce a `worlds` table as the running-instance record, explicitly distinct from a **scenario package** (Blueprint §10), which remains a reusable *template* — the same scenario package can instantiate multiple independent worlds, concurrently or sequentially. Every existing per-run table (`agents`, `agent_memories`, `agent_relationships`, `agent_plans`, `proposals`, `votes`, `ledger`, `narrator_editions`, `articles`, `simulation_events`) gains a `world_id` scoping column. The API and WebSocket surface become world-scoped (`/api/v1/worlds/:world_id/...`, `/ws/world/:world_id`). A new **World Session Manager** inside `dark_city_server` owns creating and tearing down world instances, each with its own independent headless-ECS tick loop (Decision 0002) and zero shared mutable state with any other running world.

**Option 3 is explicitly deferred, not designed, and not stubbed.** No placeholder column, no reserved schema surface for it — see "Why" below for the reasoning, which is a direct application of Team Charter §4's no-speculative-generality principle.

## Why

- **Distinguishes template from instance.** The original §10 sketch used `scenario_id` as if it were the running world's identity. Separating "scenario package" (reusable definition) from "world" (a specific instantiation, with its own clock and its own citizens' evolving state) is the correct shape regardless of how many worlds we run at once, and it directly serves the research goal from Design Foundations §1 of running the *same* scenario multiple times to see whether outcomes are stable or divergent.
- **Cheap now, expensive later.** Adding `world_id` to every table and route is close to free at this stage — no data exists yet to migrate. Retrofitting it after Phase 2–3 tables and queries assume a singleton world would be a much larger, riskier change, for the same reason the config-over-constants principle (Foundations §6) argues for building the scenario-loading seam early rather than late.
- **Isolation-by-default is the right complexity level for now.** No current research question requires worlds to interact. Building option 3 now would mean designing a cross-world consistency/consent/security model with no concrete use case driving its shape — precisely the "flexible abstraction invented to save hypothetical future effort" that Team Charter §4 rules out. Explicit `world_id` foreign keys (rather than an implicit, assumed singleton) are what make an *opt-in* interaction mechanism additive later rather than a retrofit, if and when a real scenario needs it — so the door stays open without anything being built or reserved against it today.
- **Serves an existing backlog gap.** Story 4.2.2 already needed this; it just didn't have schema support. This decision gives it that support well ahead of Phase 4, at effectively zero cost to Phase 1 (Phase 1 still populates exactly one world).

## Impact

- New `worlds` table (id, scenario_id, name, status, sim_clock, created_at).
- `world_id` added to every existing per-run table in Blueprint §4.1, §6, §7.
- Blueprint §10 restructured into §10.1 (scenario package, unchanged in shape) and new §10.2 (world instances & multi-tenancy).
- Blueprint §12 API surface becomes world-scoped; new `/api/v1/worlds` collection routes.
- New World Session Manager component, System-Architect-owned, inside `dark_city_server`.
- AWI dashboard and Narrator (§8, §9) become per-world by construction (each query already scopes to a world's own tables).
- Backlog: new story 1.1.6 (World Session Manager & world instance lifecycle); 1.1.1's acceptance criteria revised to include the `worlds` table; 1.5.1/1.5.2 revised to reference instantiation via the Session Manager; Epic 2.4/3.4 note their queries are implicitly world-scoped.
- **Flag for the Steward:** if ticket 1.1.1 has already merged without the `worlds` table / `world_id` columns, this decision requires a follow-up migration story rather than an amendment to a closed ticket — check current state before dispatching the revised 1.1.1 acceptance criteria as-is.