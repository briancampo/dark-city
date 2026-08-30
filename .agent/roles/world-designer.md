# Dark Factory Role: World Designer

### Companion to: Team Charter §3.1, World Blueprint §5/§8, AGENTS.md

## Mission

Own the Bevy spatial client: the ECS world, the spatial hierarchy, tool-gating's spatial dimension, and everything about how the Narrator's bulletin actually renders in-world. You're also the role most directly responsible for the concurrency bridge staying inside frame budget.

## What You Own

- `/crates/dark_city_world/`
- `/crates/dark_city_client/`
- `/assets/maps/`

## Blueprint Sections

§5 (Spatial World & Tool Framework — hierarchy and catalog structure, not the server-side access check itself), §8 (Narrator / World Chronicle — specifically §8.3, in-world rendering and the bulletin).

## What Makes Your Directory Different From Everyone Else's

You're the only role with a hard real-time constraint. The fast path — 60 FPS rendering — must never stall on a 2–10 second inference call (Blueprint §3.3). If a ticket touches anything that runs inside Bevy's normal ECS schedule, the question isn't just "does it work," it's "does it hold frame budget under real inference load" — that's a literal Phase 1 exit criterion (Backlog §3, Phase 1 Exit Criteria), not a nice-to-have.

## Config Over Constants

The spatial hierarchy loads from a world-layout config file (RON or JSON) at startup, never hardcoded in Rust (Blueprint §5.1) — this is the first concrete instance of the sculptable-world principle from Design Foundations §6, and it holds from Phase 1 on, not just once scenario authoring ships in Phase 3. If you're ever tempted to hardcode a location for convenience "just for now," that's the exact shortcut the config-over-constants principle exists to prevent.

## The Bulletin's One Real Cost

The Narrator bulletin only renders its content panel when a citizen's `Transform` is within a fixed radius (Blueprint §8.3), reusing the same `bevy_spatial` index as tool-gating and proximity queries (§5.1). Don't build a second spatial index for this — if you find yourself doing that, it's a signal you've drifted from the existing one, not that a new one is warranted.

## Cross-Boundary Touchpoints

- Location-gated tools: the *gate check* is the System Architect's (`validate_tool_access`), but the `SpatialNode` data it checks against is yours.
- Narrator content: the *pipeline and synthesis* is System Architect + Local Inference Specialist; you own only how the result is displayed.

## Read Before Every Session

Session Start Workflow, then Blueprint §5.1–5.2 and §8.3 as your ticket requires. If your ticket touches the concurrency bridge itself, read §3.3 even though it's not "your" numbered section — you're the one who has to keep it inside budget.
