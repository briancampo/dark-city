# [0002] Server-Authoritative Simulation & Thin Viewer Client

**Date:** 2026-08-28
**Ticket:** Pre-Epic-1.1 architecture correction (raised ahead of dispatch to prevent Epic 1.1/1.2 building against the wrong contract)
**Role:** Steward (facilitated), for Tech Lead ratification

## Question

Where should authoritative citizen simulation state and PIANO module execution live, and how should the Bevy spatial client relate to that state? Blueprint v1.0 §3.1–§3.3 described `AgentState` as a Bevy ECS component and PIANO's fast modules as Bevy systems, with `agent_cognitive_tick` querying it directly — implying the **windowed Bevy client** owned simulation truth and Axum was invoked reactively, only for LLM-backed work. This was a scoping miscommunication, not a deliberate choice: Bevy was always intended as the **viewer**, not the simulation engine.

Left uncorrected, this has two concrete costs:

1. **Deployability.** A backend that only reacts to a connected client's requests cannot run continuously, headlessly, in our containerized infrastructure (per Design Foundations §12 / Blueprint §2's deployment model) — nothing ticks without a client attached.
2. **Multi-client safety.** Any future second viewer client would hold its own independent copy of `AgentState`, independently decide when a citizen needs cognition, and independently write results — duplicate LLM calls, divergent world state between clients, and racing Postgres writes, with no arbitration.

It also produces a real Team Charter §3.1 ownership collision already latent in the backlog: Action Awareness (Blueprint §3.2, "a plain synchronous Bevy system") is assigned to the **Character Sculptor** (owns `crates/dark_city_cognitive/`), but a Bevy system as described could only run inside the client app, which is **World Designer**-owned territory (`crates/dark_city_world/`) — implying the Character Sculptor would need to write code in another role's directory.

## Options Considered

1. **Status quo (client-authoritative):** Bevy client owns `AgentState` as ECS components, runs PIANO's fast modules as Bevy systems, decides when cognition fires, calls Axum reactively only for LLM-backed modules.
2. **Server-authoritative headless simulation:** `dark_city_server` runs a headless `bevy_app::App` (via `MinimalPlugins` — no rendering, no window, no asset loading) that owns `AgentState`, runs *all* PIANO modules (fast and slow) on its own independent tick schedule, and broadcasts state deltas over WebSocket. The Bevy client becomes a thin renderer/subscriber holding zero simulation state.
3. **Non-Bevy backend:** drop the `App`/`Plugin`/`Schedule` machinery entirely and hand-roll a scheduler around bare `bevy_ecs` (`World`, `Query`, `Component` only, no `App`).

## Decision

**Option 2.** `dark_city_server` hosts a headless `bevy_app::App` (`MinimalPlugins`) as the authoritative simulation. The previously-planned windowed Bevy client becomes a new crate, `dark_city_client` — a thin renderer with no simulation logic, subscribing to per-world state deltas over `/ws/world/:world_id`.

## Why

- **Matches actual intent.** Bevy was always meant to be the viewer, corollary to the game client this project reuses tooling from — never the simulation engine. This decision restates that correctly rather than introducing something new.
- **Continuous, headless operation.** The backend can now run its own tick loop in containerized infrastructure with zero clients attached, which the client-authoritative model could not do.
- **Multi-client safety by construction.** Because there is exactly one authoritative `AgentState` and exactly one place that decides when a citizen cognizes, any number of thin viewer clients can attach — to the same world or different worlds (see Decision 0003) — without any coordination between them. They cannot race each other because they hold no state to race over.
- **Minimal conceptual rewrite.** `MinimalPlugins` preserves Bevy's `App`/`Schedule` ergonomics headlessly, so Blueprint §3.2's framing of PIANO modules as "systems... at their own cadence" doesn't need to change conceptually — only *where* it executes.
- **Resolves the §3.1 ownership collision.** All PIANO systems — including Action Awareness — now run inside `dark_city_server`'s composed headless App, built from systems each domain crate (`dark_city_cognitive`, `dark_city_world`) registers on its own. The Character Sculptor implements and owns Action Awareness's logic entirely within `dark_city_cognitive`; no directory boundary is crossed.
- **Sets up the future observer-UI question cheaply.** Once the backend broadcasts state deltas to arbitrary thin subscribers, a lightweight browser-based spectator view (raised separately, not yet scoped) becomes another thin subscriber on the same feed later, rather than requiring a second full Bevy client to build.

## Impact

- **Supersedes** the client-side portions of Decision 0001's description of `crates/dark_city_world/` ("Future consideration for user interface to interact with the world..."). `dark_city_world` remains World-Designer-owned but is now a **library** (spatial hierarchy, tool gating) composed into `dark_city_server`'s headless App, not a runnable client itself.
- **New crate:** `crates/dark_city_client/` — thin viewer, World-Designer-owned, zero simulation state.
- World Blueprint §2, §3.1–§3.3 (new §3.4 added), §5.1, §8.3, §12 revised.
- Team Charter §3.1 role/ownership table revised; AGENTS.md mirrors it.
- Backlog: 1.1.2, 1.1.3, 1.2.1, 1.2.7, 1.4.1 revised; new stories 1.1.5 (headless App bootstrap) and 1.1.6 (World Session Manager — see Decision 0003) added per Backlog §7's append-don't-renumber convention.