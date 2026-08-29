# Dark City: Perception & World-Event Capture — Research & Design Brief

**Status:** Open research/design question, not yet a decision or a Blueprint section.
**Prepared for:** Whichever Dark Factory agent (likely Character Sculptor for the cognitive-module half, System Architect for the schema/pipeline half — see §7) picks this up next.
**Prepared by:** Prior session with Brian, distilled into this brief so a fresh session can continue without that conversation in context.

---

## 1. Purpose of This Document

This is a **research and design brief**, not a spec and not a ticket. Nothing here should be implemented as-is. Your job, if you're picking this up, is to:

1. Read the required context below and the linked documents until you actually understand the gap, not just this summary of it.
2. Research and compare concrete design options for the two problems in §4 (they are related but genuinely separate — don't assume one fix covers both until you've checked).
3. Produce the deliverables in §8 — principally a decision record and a draft Blueprint amendment — for Brian's review.

This brief exists because Brian asked a simple question — "is the only way to capture that something happened in the world that citizens talk about it?" — and the honest answer turned out to be "yes, and it's worse than that," which is enough of a design gap to warrant its own session rather than a quick patch.

## 2. Required Reading Before Starting

Read in this order if you haven't already this session:

1. [AGENTS.md](AGENTS.md) — terminology and orientation.
2. [Design Foundations](docs/design-doc.md) — especially §4 (PIANO), §5 (Memory System).
3. [World Blueprint](docs/dark-city-blueprint.md) — especially §3 (Agent Cognitive Architecture, including §3.4 Viewer Client), §4 (Memory System), §5.1–5.2 (Spatial/Tool Gating), §8 (Narrator), §9 (AWI), §10 (Scenario Packages & World Instances).
4. [Decision 0002](decisions/0002-server-authoritative-simulation.md) — the simulation is server-authoritative and headless; the Bevy client is a thin viewer. **Any mechanism you design must run as a system inside the backend's headless ECS, never client-side.**
5. [Decision 0003](decisions/0003-multi-tenant-world-instances.md) — worlds are isolated and `world_id`-scoped throughout the schema. **Any new table or mechanism you design must respect this scoping.**
6. [Team Charter](docs/project-charter.md) §4 (Engineering Principles) and §6 (Decision Log) — governs how you're expected to work and document this.

Decisions 0002 and 0003 are recent (this session's predecessor) and correct real architectural mistakes from the original v1.0 documents. If anything you read in the Blueprint's older prose seems to assume a client-authoritative or single-world design, the decision records win — flag the mismatch rather than propagating it.

## 3. How This Gap Was Found

Brian was reviewing the memory and instrumentation design and noticed that everything currently described captures **citizen-caused** activity — what a citizen did, said, or called a tool for — and asked whether "something happened in the world" is only ever knowable because a citizen talked about it. Digging into the actual module and schema specs (not just the prose describing them) surfaced two distinct, compounding gaps, laid out in §4.

## 4. Problem Statement

### 4.1 Problem A — There is no general Perception mechanism

The PIANO module list (Design Foundations §4, Blueprint §3.2) is: Cognitive Controller, Memory, Reflection, Planning, Action Awareness, Social Awareness, Talking, Skill Execution. **There is no Perception module.** The only two things that currently write an "observation" into a citizen's episodic memory stream are:

- **Action Awareness** — compares the citizen's _own_ intended action against what actually happened. This only covers the citizen's own outcomes.
- **Social Awareness** — interprets social cues from a _direct interaction_. This only covers dialogue/interaction the citizen is a party to.

Neither covers a citizen simply being present for something they didn't do and weren't spoken to about — another citizen starting a fire nearby, a visible public argument between two other citizens, someone posting a proposal at the town hall while they happen to be standing there. As specified, a citizen has no defined pathway to ever notice any of that.

This is a real fidelity gap against the project's own stated source material: Design Foundations §3 credits Smallville/"Generative Agents" as where "Dark City's memory and planning design comes from," but the actual Smallville architecture includes an explicit **perceive** step every tick that feeds anything within an agent's observation radius into its memory stream. Dark City's spec carried over Smallville's memory _storage and retrieval scoring_ (§4.2's recency+importance+relevance formula) but not the perceive step that's supposed to feed it from ambient events, not just self-action and direct dialogue.

This plausibly matters for **Phase 1**, not just later phases — "whether the cognitive loop produces believable moment-to-moment behavior" is a Phase 1 exit criterion (Backlog §3, Phase 1 Exit Criteria), and citizens who can only ever know about things they personally did or were personally told are a hard ceiling on that believability, even at a population of 3–5.

### 4.2 Problem B — There is no source for events with no citizen actor at all

Separately: even if Problem A is fixed, there is still no mechanism for a world event that **no citizen caused** — weather, a scenario-scripted disaster, a scarcity threshold being crossed, a scheduled festival, an "episode" beat. Some evidence this is a real gap and not an intentional non-goal:

- The Narrator's editorial template (Blueprint §8.2) already has a standing "Economy & Frontier" section explicitly meant to cover "resource scarcity events" — but nothing anywhere in the spec defines what triggers a scarcity event or writes one down. It's aspirational text with no producer behind it.
- Ledger balances (§7) are computed at read time via decay (`current_balance = last_recorded_balance - decay_rate * hours_since(last_entry)`), which is good for avoiding a fragile background job, but it also means a balance crossing a meaningful threshold (e.g., a citizen going broke) never produces a discrete event anywhere — it's just a different number the next time someone reads it.
- Scenario packages are meant to eventually support "episode seeds" to start a run with specific conditions — which strongly implies scripted world events (a fire on day 3, a caravan arriving, a resource shock) are part of the intended long-term design, just not specified yet anywhere in the Blueprint's §10.1 sketch.

### 4.3 Why these are two problems, not one

Problem A is about **citizens noticing things** (a perception/cognition-side gap — likely a Character Sculptor concern, `dark_city_cognitive`). Problem B is about **there being a thing to notice in the first place when no citizen caused it** (a producer/pipeline gap — likely a System Architect or World Designer concern, `dark_city_server` / `dark_city_world`). It's entirely possible to fix Problem A and still have a world where nothing except citizen action and citizen speech ever happens — Problem B is what would make a fixed Problem A actually pay off. Don't assume the same design artifact solves both; evaluate them separately, then check whether your chosen solutions compose cleanly (they likely share infrastructure — see §5 — even if the mechanisms themselves are distinct).

## 5. Existing Infrastructure Worth Reusing (Don't Reinvent These)

- **`bevy_spatial` proximity index** (Blueprint §5.1) — already used for location-gated tools (§5.2) and bulletin visibility (§8.3, computed server-side per Decision 0002). A "what's near me" query already exists; Problem A likely wants to reuse this rather than building a second spatial index.
- **`simulation_events` table** — as currently specified (see [1_1_1-brief.md](1_1_1-brief.md), revised per Decision 0003), this table is implicitly **citizen-attributed**: every row carries a `world_id` and is indexed on `agent_id` / `occurred_at`. There is no current way to log an event with no citizen behind it. Whether to loosen this table (nullable `agent_id` + a `source` discriminator) or split out a dedicated `world_events` table is an open question — see §6.4.
- **Retrieval/importance scoring** (Blueprint §4.2–§4.3) — the existing recency+importance+relevance formula and the LLM-assigned 1–10 importance score are the natural filter to prevent a naive Perception module from flooding a citizen's memory stream with irrelevant ambient noise (every citizen doesn't need a memory of every leaf falling within radius). Reuse this rather than inventing a second relevance concept.
- **Narrator editorial pipeline** (§8.2) — this is a **downstream consumer** of the event log on a 12-hour cadence, not a capture mechanism. It cannot fix either problem on its own; it can only report what's already been captured. Don't confuse "the Narrator will mention it eventually" with "the event was captured."
- **AWI M2 (Safety & Public Order)** — already assumes "hard-violation actions" are logged somehow. Worth checking during your research whether a system-caused incident (e.g., a scenario-scripted disaster) should ever be able to register as a hard-violation-equivalent event for instrumentation purposes, or whether M2 is deliberately citizen-culpability-only.
- **Decision 0002's headless ECS tick** — whatever you design for Problem A almost certainly wants to be a system registered into the per-world headless App (fast/reflexive if it's pure proximity-and-importance filtering; possibly offloaded per §3.3 if relevance filtering needs an LLM call). Whatever you design for Problem B's producer likely wants to run on its own schedule inside the same per-world tick loop, similar in spirit to the Narrator's 12-hour cadence.

## 6. Open Design Questions to Research (Not to Assume the Answer To)

1. **Is Perception a new formal PIANO module, or an extension of an existing one?** Options include: a new named module (would require amending Design Foundations §4's module table and Blueprint §3.2, with a decision log entry); folding ambient observation into Memory's existing "writes new observations" responsibility; or generalizing Action Awareness/Social Awareness rather than adding a fourth "awareness" concept. Each has different implications for the Cognitive Controller bottleneck (§3.2) — does a perceived-but-unacted-on event ever need to pass through the Controller, or can it write to memory directly the way Action Awareness's outcome-comparison does?

2. **What's the actual mechanism?** A candidate shape: reuse the `bevy_spatial` index to find citizens within some radius of a newly-logged event, then apply an importance/relevance-style filter before writing anything to their memory stream — but the radius, the filter, and whether it needs an LLM call at all (vs. a cheap heuristic) are all undetermined. Research what Smallville and Project Sid/PIANO actually did here (the source PDFs are in the project) rather than inventing this from scratch.

3. **Fast/reflexive or slow/offloaded?** Per Blueprint §3.3, this determines whether it's a plain synchronous system in the backend's tick or an async task via `AsyncComputeTaskPool`. Pure proximity math is fast-path; "does this citizen find this event worth remembering" arguably needs the same LLM-backed judgment Memory's importance scoring already uses. Consider the compute-cost tradeoff at Phase 1 scale (3–5 citizens) vs. Phase 2 (~10) vs. later.

4. **Schema for Problem B's events:** loosen `simulation_events` (nullable `agent_id`, add a `source` enum: `citizen_action` / `system` / `scenario_scripted`) vs. a dedicated `world_events` table. Check the impact on existing agent-keyed queries (Backlog 1.6.1's structured event logging, and any AWI query that assumes `agent_id` is always present) before picking one — this is exactly the kind of schema decision that's cheap now and expensive after Phase 2 data exists, the same reasoning that drove Decision 0003's `world_id` scoping.

5. **What actually produces a Problem-B event?** A scenario-scripted timeline (extending the scenario package format, §10.1, and connecting to the "episode seed" concept already gestured at in project notes but not yet specified)? A system-computed threshold-crossing detector (something watching ledger balances, population health, or other AWI-adjacent aggregates and emitting an event when a threshold is crossed)? Both, with different triggers? What's the emission cadence — event-driven (fires the instant a threshold crosses) or polled on a schedule like the Narrator's 12-hour cycle?

6. **Does this connect to the safety stack?** (§9.1, §9.3) — if citizens can now perceive things they didn't do or say, does the M10 soft-violation classifier ever need to run against _witnessed_ content, not just spoken/logged content? Probably out of scope for this brief's first pass, but worth a paragraph in your writeup either way.

7. **Phasing.** Problem A plausibly belongs in **Phase 1** — it affects the Phase 1 exit criterion around believable moment-to-moment behavior, and Phase 1 already has a small population and minimal world where a basic version would be cheap to build and easy to observe. Problem B's producer more naturally fits **Phase 2+** (alongside the Narrator and governance work, since Phase 1 explicitly has no governance and a deliberately minimal world) — but confirm this rather than assuming it; if scenario-scripted events are cheap to seed even minimally in Phase 1 (the same "cheap now, expensive later" logic that justified building `world_id` scoping ahead of need in Decision 0003), that's worth surfacing as an option rather than defaulting to "later."

## 7. Constraints & Non-Negotiables

These come from the existing governing documents and apply regardless of which design you land on:

- **Must be compatible with Decision 0002.** No proposal may put simulation state, perception logic, or event-detection logic into `dark_city_client`. Everything runs in the backend's headless ECS.
- **Must be compatible with Decision 0003.** Any new or modified table is `world_id`-scoped; no mechanism leaks state across worlds.
- **No speculative generality** (Team Charter §4). Design for what Phase 1 believability and the Narrator's already-stated needs actually require — not a maximally general "universal event bus" built for hypothetical future use cases that don't exist yet.
- **Decision log discipline** (Team Charter §6). Your output includes a decision record _before_ any Blueprint text changes, following the same Question / Options Considered / Decision / Why / Impact shape as [0002](decisions/0002-server-authoritative-simulation.md) and [0003](decisions/0003-multi-tenant-world-instances.md).
- **Terminology.** Citizens perceive; Dark Factory agents (you) design. Don't blur this in whatever you write.
- **Config over constants** if this touches scenario packages — any scripted-event timeline format should be loadable configuration, consistent with §10.1's existing principle, not hardcoded.

## 8. Expected Deliverables

1. A short written comparison of **at least 2–3 concrete options** for Problem A, and **at least 2–3 concrete options** for Problem B, evaluated separately per §4.3, with your recommendation and reasoning for each.
2. A new decision record in `decisions/` (check the current highest number before assigning the next one — do not assume it's 0004 without checking, in case other decisions have landed since this brief was written).
3. A **draft** Blueprint amendment — likely a new subsection following the existing §3.4 (Viewer Client) pattern for Problem A, plus updates to §8.2, §9, and/or §10.1 for Problem B as your design requires. Draft only; confirm with Brian before merging it into the live Blueprint document.
4. If you propose schema changes, a note on which existing Backlog tickets are affected (e.g., 1.6.1's structured event logging, or 1.1.1's `simulation_events` shape) and what would need to change — following the Backlog's own "extend, don't renumber" convention (Backlog §7).
5. An explicit Phase-placement recommendation (Phase 1 vs. Phase 2+, possibly split between the two problems) with reasoning tied to the actual Phase exit criteria, not just intuition.

## 9. Where to Start

Re-read Blueprint §3.2–§3.3 (module scheduling) and §4.2–§4.3 (retrieval and reflection) closely — Problem A's design lives at the intersection of those two. Then re-read §8.2 (Narrator pipeline) and §10.1 (scenario package) for Problem B — notice how much of the "shape" Problem B needs is already implied by text that has no backing mechanism yet. If you have access to the source research PDFs in the project (Smallville, Project Sid/PIANO), check what Smallville's actual perceive step looks like before designing Problem A from scratch — Design Foundations §3 already claims we're building on it, so a genuine gap-check against the source is warranted, not just useful.

## 10. If You Get Stuck

This is a design/research task, so more ambiguity than usual is expected and fine to work through yourself — that's the point of the session. But per Session Start Workflow step 7, if you hit a fork that's a genuine **product or vision** call rather than a technical one — e.g., "should Dark City ever support a world event dramatic enough to threaten citizen survival at population scarcity" is a design-philosophy question, not an engineering one — stop and raise it to Brian rather than guessing. Document the fork and your reasoning either way in the decision record.
