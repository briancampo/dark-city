# Research Brief: Environmental & External World Events

**Date:** 2026-08-30
**Status:** Research brief — not yet a dispatched backlog ticket. Same pattern as the Goal Generation brief and Decision 0004's precedent.
**Prepared for:** Steward / Tech Lead review; execution owner (if ratified) likely System Architect, given the schema/producer shape (parallels 2.6.1's ownership).

## Question

Should Dark City add a periodic, no-citizen-actor producer of "outside the walls" content — weather, ambient environmental change, and news/events from beyond the simulated town — so that the world feels less like a sealed box, citizens have something ambient to notice, and the Narrator has something new to report beyond what citizens themselves generate?

## Where This Came From

A prior review of Dark City against the three reference papers flagged that **Emergence World's real-world grounding** (§3.4 of that paper: live weather, live news APIs, general internet access, explicitly justified as reproducing "a property of real deployments that fully sandboxed simulations cannot") had no analog anywhere in Dark City's design, with no record of it being deliberately deferred or rejected — it had simply never been addressed. This brief closes that gap, but proposes a different shape than Emergence World's, for reasons specific to Dark City's own design goals (below).

## Why Not Adopt Emergence World's Approach Directly

Emergence World ties its agents to *real* Earth weather and *real* news because its research goal is studying how agents behave when exposed to genuinely unauthored, unpredictable external signal. Dark City's stated goal (Design Foundations §1) is different: "populate constructed worlds... first for our own study, eventually as the substrate a player steps into" — and §10's sculptable-worlds principle means a given scenario package might not be contemporary-Earth-like at all. Piping real weather.gov data into a fictional 1920s-noir scenario, for example, would be a mismatch, not a feature.

**Recommendation: procedurally/LLM-generated fictional content, steered by scenario-level configuration, not a live external API integration.** Real-world API grounding remains a distinct, larger, and explicitly *un*-adopted option here — parallel to how Decision 0003 explicitly deferred (rather than left ambiguous) an optional cross-world interaction mechanism. If live grounding is ever wanted for a specific scenario, that's a separate future decision, not a default of this one.

## Two Candidate Shapes

**Option A — The Narrator wears a second hat.** Extend the existing Narrator persona (§8.1) with an additional daily pass (separate from its existing 8-in-game-hour edition cadence) that generates weather/external-affairs content directly.

**Option B — A distinct, dedicated persona.** A new non-autonomous, invisible system persona (call it, provisionally, "the Almanac") separate from the Narrator, with its own daily trigger, writing directly to `world_events` with a new `source` value. The Narrator then picks these rows up exactly the way it already picks up any other `world_events` row (§8.2 step 1's existing query needs no change).

**Recommendation: Option B.** This keeps each system persona's job conceptually singular — the Narrator's job is "report on what happened" (§8.1), not also "decide what the weather is." It's also consistent with the precedent this same review cycle already set: the Code Review Agent (Decision 0006) is its own persona doing its own singular job (audit code), not folded into an existing one. One persona per responsibility, communicating only through the tables both already read/write, keeps the pattern uniform.

## Sketch (for the eventual decision, not decided here)

- **New `world_events.source` value: `'environmental'`** (extending the CHECK constraint alongside `scenario_scripted`, `threshold_crossing`, `citizen_triggered`, Decision 0004/Blueprint §4.1). `origin_citizen_id` stays NULL for these rows, same as `scenario_scripted` — no citizen actor at all, so M2-ineligibility (§9.2) holds even more clearly than it does for `threshold_crossing`.
- **A daily-cadence trigger** inside the same per-world headless tick that already drives the Narrator's cron-style trigger (Backlog 2.3.2) and the scripted-event scheduler (2.6.1) — no new scheduling mechanism needed, just a new consumer of the existing tick.
- **A scenario-level steering seed**, extending the scenario package (§10.1) alongside `constitution_seed` and `starting_time` — provisionally `climate` (a short description of the setting's baseline weather/season pattern) and `external_affairs` (a short description of what "outside the walls" is like for this scenario — a nearby war, a bustling trade route, nothing at all). Both optional; an empty value should degrade gracefully to "nothing notable happens externally," not force every scenario to have off-screen lore it doesn't need.
- **Salience assigned by the Almanac persona at creation**, same convention as every other producer under Decision 0004 — no special case.
- **Observation (§3.5) needs no changes.** Citizens near outdoor locations already pick up nearby `observable_events` rows above the salience threshold; an environmental row is just another row in that view.

## Why This Is Worth Doing

Beyond closing a documented gap, this is one of the cheaper, highest-payoff additions available: it reuses the `world_events`/`observable_events` schema, the Narrator's existing query, and the per-world tick's existing scheduling pattern almost entirely as-is — the net-new surface is one persona, one enum value, and two optional scenario fields. It's also the kind of texture Emergence World itself frames as valuable even outside its adversarial "shock event" framing (§3, "Simulation of shock events") — an environment citizens don't fully control or predict, which is exactly what makes their reactions to it meaningful to observe.

## Suggested Backlog Sequencing

New **Epic 2.7 — Environmental & External World Events**, Blueprint § TBD (assigned once ratified):

| ID | Title | Goal | Acceptance Criteria | Owner | Depends On |
|---|---|---|---|---|---|
| 2.7.1 | Environmental world-event research spike & decision | As a System Architect, I want to evaluate the Almanac-persona shape, the new `world_events.source` value, and the scenario-level steering seed against this research brief, so that the eventual design is settled before implementation stories are drafted. | Given this research brief, when the spike concludes, then a decision log entry and a Blueprint amendment draft exist covering: the persona shape (Option A vs. B), the `world_events.source` extension, the daily-trigger mechanism, and the `climate`/`external_affairs` scenario fields — with no implementation code produced by this ticket itself. | System Architect | 2.3.5, 2.6.1 |

Sequenced in **Phase 2** (not Phase 3) since it's a natural extension of already-Phase-2 systems (Narrator, Epic 2.3; world-event production, Epic 2.6) rather than depending on Phase 3 maturity. Implementation stories (2.7.2 onward) get drafted only after 2.7.1's decision is ratified. Once implementation exists, Phase 2 Exit Criteria should gain a bullet confirming at least one environmental event reached both a citizen (via Observation) and a Narrator edition — not added yet, since only the spike is being sequenced here.
