# [0001] Cargo Workspace Crate Decomposition & Role Mapping

**Date:** 2026-08-27
**Ticket:** [1.0.1], [1.0.2]
**Role:** System Architect

## Question

How should the Dark City codebase be organized at the Cargo level to balance compile times, modularity, strict role ownership boundaries, and dependency management?

## Options Considered

1. **Monolithic single crate with module subtrees (`/src/server`, `/src/world`, etc.):** Simpler root Cargo.toml, but creates tight coupling, longer rebuild times, and weak compiler-enforced boundary isolation between specialist domains.
2. **Multi-crate Cargo workspace under `/crates/*` plus `/xtask`:** Clean compilation units, explicit dependency DAG, strong compiler-enforced API boundaries, matching the Team Charter §3.1 role ownership.

## Decision

Adopt Option 2: A Cargo workspace structured under `/crates/` and `/xtask`:
- `dark_city_core`: Shared domain models, IDs, error types, config definitions.
- `dark_city_inference`: Gateway client, JSON schema / grammar enforcement, multi-model router.
- `dark_city_cognitive`: PIANO Blackboard (`CitizenState`), Cognitive Controller bottleneck, memory retrieval scoring, reflection, planning trees.
- `dark_city_world`: Spatial hierarchy loader, Bevy ECS systems, concurrency bridge. Future consideration for user interface to interact with the world and view game-style interface of the world and its activities. 
- `dark_city_server`: Axum REST / WebSocket backend, Postgres migrations, credit ledger, governance engine.
- `dark_city_instrumentation`: AWI metrics pipeline, structured event logging, M10 classification audit.
- `xtask`: Repository automation CLI (`cargo xtask check`).

## Why

This enables:
1. Fast incremental builds by isolating heavy dependencies (e.g. `axum`/`sqlx` in server, `bevy` in world).
2. Clean contract boundaries between specialist roles.
3. Verification that domain rules and types in `core` remain agnostic of specific transport or rendering engines.
