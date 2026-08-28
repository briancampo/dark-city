# Dark City: World Design Foundations

### The Dark Factory Development Project — v1.0

## 1. What We're Building

Dark City is a platform for populating constructed worlds with AI agents and watching how they organize, interact, and change those worlds over time. The point isn't to answer one narrow research question (governance, safety, or otherwise) — it's to build the capability to define a **setting**, populate it with a **roster of characters**, drop in a **starting scenario**, and then observe what happens: what relationships form, what norms emerge, what economies and institutions the agents build or fail to build, and how believable and interesting the resulting world is. Governance is one of the things that shows up when you give agents the ability to organize — it's a big part of what we'll watch, but it isn't the goal. The goal is a platform for building and directing AI-inhabited worlds, first for our own study, eventually as the substrate a player steps into.

This is a continuous, iterative effort, not a single build-and-ship project. Every phase in the roadmap (§12) is scoped to produce something we can actually run end-to-end, observe, and learn from — not just a technical component that only becomes useful once every later phase is also done. We expect each phase to change our mind about parts of the next one.

## 2. Two Projects: Dark City and Dark Factory

**Dark City** is the simulation itself — the world layer. Everything in this document about agents, cognition, memory, the spatial world, tools, governance, and instrumentation describes Dark City. Dark City has no concept of a development team; nothing here should ever reference build tooling, PR gates, or coding-agent roles. It is a virtual world where agents simulate a setting, scenario, and activities over some simulated amount of time.

**Dark Factory** is the team that builds Dark City — the platform and build layer. It's a set of specialist AI coding agents (System Architect, Local Inference Specialist, World Designer, Character Sculptor, QA/Instrumentation) orchestrated by a **Steward**, which ingests backlog tickets, assigns work by role, enforces workspace boundaries, and gates pull requests before merge. The Steward manages the coding-agent team writing Rust — it has no presence in, and no authority over, the simulated world Dark City describes. That boundary matters enough to restate: if a document ever describes the Steward doing something to a citizen of Dark City rather than to a piece of the Dark City codebase, that document has a bug.

Three companion documents build on this one:

- **Dark City World Blueprint** — the full simulation spec (architecture, memory, tools, governance, instrumentation), building on §4–§10 below.
- **Dark Factory Team Charter** — the build team's operating model, building on §2 and §11 below.
- **Dark Factory Backlog** — phased epics and stories that implement the World Blueprint, organized per §12.

## 3. Research Foundations, in Brief

Three bodies of work anchor Dark City's design. Rather than pointing at them abstractly throughout this document, the mechanics we're using from each are fully explained in the sections below — this section just orients what came from where, so you know where to look if you want to go deeper on the original research later.

- [**Generative Agents / "Smallville"**](/references/gen-agents-smallville.txt) established the individual-agent cognitive loop: a memory stream scored by recency, importance, and relevance; periodic reflection that synthesizes raw memories into higher-level insight; and hierarchical planning that decomposes a day into hours and then minutes. This is where Dark City's memory and planning design comes from (§5).
- [**Project Sid / PIANO**](/references/project-sid.md) established how to run many such agents concurrently without their outputs becoming incoherent — running specialized cognitive modules in parallel, bottlenecked through a single decision-making module that keeps speech and action aligned. This is where Dark City's cognitive architecture comes from (§4).
- [**Emergence World**](/references/emergence-world.txt) established how to ground a large agent population in a shared spatial world with location-gated tool access, decentralized self-governance, and a structured measurement framework for what the resulting society looks like. This is where Dark City's world/tool framework (§6), governance model (§7), safety stack (§8), and instrumentation (§9) come from.

None of these three papers describe the same system we're building — Dark City combines pieces of each and adds our own decisions where the source material doesn't specify one (most notably, fusing Smallville's planning/reflection loop into the PIANO module set, and emergence world's shared space and interactions, since Project Sid doesn't include either).

## 4. Cognitive Architecture: PIANO

Two problems have to be solved for a population of LLM-driven agents to feel alive rather than scripted or incoherent, and PIANO (Parallel Input Aggregation via Neural Orchestration) is the architecture we're using to solve both.

**Concurrency.** A single sequential reasoning loop — perceive, think, act, repeat — can't represent an agent that's simultaneously reacting to its surroundings, holding a conversation, and slowly working through a long-term plan. Dark City agents instead run several specialized modules concurrently against a shared **Agent State**, each module a function that reads and writes that shared state at its own pace. Fast modules can react to an immediate threat while a slow module is still three steps into deliberate planning; neither blocks the other.

**Coherence.** Running several modules concurrently creates a new problem: independent modules can disagree with each other. An agent's dialogue module might say "I'll help you," while its action module does something else entirely. Dark City solves this the way PIANO does — with a single **Cognitive Controller** module that is the only place high-level deliberate decisions get made. Every other module's output must pass through this controller as a bottleneck; once it decides on a course of action, that decision is broadcast to condition the downstream modules (especially the modules responsible for speech and for executing actions in the world), so what an agent says and what it does stay aligned.

Dark City's module set, combining PIANO's named modules with Smallville's planning and reflection loop (a fusion that's our own design decision — neither source paper specifies this combination):

Emergence World should be ingegrated into this where applicable.

| Module               | Role                                                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Cognitive Controller | The bottleneck. Makes high-level decisions and broadcasts them to condition every other module.                                            |
| Memory               | Writes new observations to the episodic memory stream; serves retrieval queries to other modules.                                          |
| Reflection           | Periodically synthesizes recent memories into higher-level insight (§5).                                                                   |
| Planning             | Maintains the agent's Day → Hour → Minute plan hierarchy (§5).                                                                             |
| Action Awareness     | Compares the agent's intended action against what actually happened in the world, so it doesn't act on a false belief about its own state. |
| Social Awareness     | Interprets social cues from other agents and updates relationship state.                                                                   |
| Talking              | Generates and interprets dialogue, conditioned by the Cognitive Controller's current decision.                                             |
| Skill Execution      | Translates a decided action into a concrete tool call or movement in the world.                                                            |

## 5. Memory System

Every agent maintains three kinds of memory:

- **Episodic memory** — a timestamped, append-only record of what the agent observed, did, and said. Written automatically as the world unfolds.
- **Reflective memory** — periodic, higher-level insights the agent generates about itself and others by synthesizing its own recent memories (including prior reflections, so agents build up a genuine tree of increasingly abstract self-understanding over time, not just a flat log).
- **Relational memory** — explicit, labeled state about each other agent the agent has interacted with (trust level, relationship type, recent interaction history), so social dynamics persist across time gaps without needing to be reconstructed from raw memory on every interaction.

All three are stored in Postgres with pgvector (HNSW indexing) for the embedding-based retrieval described below.

**Retrieval scoring.** When an agent needs to decide what to do, we don't hand it its entire memory stream — we retrieve the subset most relevant to the moment, scored as:

```
score = recency + importance + relevance
```

each term normalized to the [0, 1] range before summing (equal weighting to start; the weights are tunable parameters, not fixed constants). Specifically:

- **Recency** decays exponentially — a factor of 0.995 per simulated hour since the memory was _last retrieved_ (not since it was created), so recently-relevant memories stay salient even if they're old.
- **Importance** is a 1–10 integer the LLM assigns once, at the moment the memory is created (e.g., "brushing teeth" scores low, "a public accusation of theft" scores high).
- **Relevance** is the cosine similarity between the memory's embedding and the embedding of whatever question or situation is prompting retrieval right now.

**Reflection** triggers when the sum of importance scores across an agent's recent, not-yet-reflected-on memories crosses a threshold (150 as a starting point, tunable once we see real simulated volume). When triggered, the agent's Reflection module asks itself what high-level questions its recent experience raises, retrieves memories relevant to those questions, and asks the LLM to state insights with explicit citations back to the memories that support them. The insight itself becomes a new memory, retrievable exactly like any observation — which is how reflections build on each other into an increasingly abstract tree rather than resetting each time.

**Planning** decomposes top-down: a rough sketch of the day's agenda (5–8 broad chunks), recursively refined into hour-long chunks, then further into 5–15 minute action-level chunks. Plans live in the memory stream alongside observations and reflections, so all three inform each other, and agents can revise a plan mid-stream when something in the world warrants it.

**Character identity** is authored per-agent as a Markdown "Soul" file (owned by the Character Sculptor role in Dark Factory), extended with a small set of **Core Identity Truths** — existential anchors the agent is instructed never to contradict regardless of how its reasoning drifts over a long run. This gives the persona a hard floor beneath the otherwise-soft drift of ordinary memory-driven reasoning.

## 6. World & Tool Framework — Built for Future Sculptability

Dark City's spatial world is a hierarchy (Town → Building → Room → Entity) implemented in Bevy's ECS. Agent tool access is layered:

- **Core tools** — always available: navigation, memory operations, planning, basic communication.
- **Complementary tools** — surfaced contextually when an agent's recent reasoning makes them relevant: richer social interaction, billboard posting, and similar.
- **Adaptive-access tools** — gated at runtime by location, event state, or explicit social consent (e.g., proposing a rule change requires physically being at the town hall). Gating is enforced by the Rust runtime itself, not by the prompt — a failed precondition blocks the call outright no matter what the agent reasons or claims about its own eligibility.

**Design principle for what's coming later:** we intend to eventually build the ability to sculpt entirely different worlds — different spatial layouts, different rosters of characters, different starting scenarios ("episodes") to seed a run — the same way a level editor lets you build different maps for the same game engine (§10). We are not building that authoring tooling yet, but every piece of world data described above — the spatial hierarchy, the soul roster, the starting relationship/resource state, the active tool catalog — should be treated as _configuration the runtime loads_, not constants baked into Rust structs, even in the earliest phase. The cost of doing this from day one is small; the cost of retrofitting it after two phases of hardcoded assumptions is not.

## 7. Governance — Decentralized by Default

Dark City has no built-in administrator, steward, or gatekeeper inside the simulation. When governance is enabled, any agent physically present at a governance venue (a town hall, in the default setting) may draft a proposal; it passes when a defined threshold of present agents vote in favor (70% as a starting point). This is a deliberate choice, not an oversight: agents self-organizing under a shared rule set — including the possibility that they organize badly, or not at all — is itself one of the more interesting emergent phenomena a sculpted scenario can produce, and it's something we want to be able to observe rather than pre-empt. It also composes cleanly with §10: a _scenario_ could start agents with an existing constitution, a designated leader role, or no governance venue at all, and decentralized self-governance remains the underlying mechanism either way.

## 8. Safety Stack

Even though governance and safety aren't Dark City's central purpose, a world that degrades into constant chaos isn't useful for observation or believable for a future player, so we still want defense in depth. Four layers, each catching what the others miss:

1. **Model level** — the Soul file and its Core Identity Truths, plus stated world rules in the agent's system prompt. This is a soft constraint: it can drift under sustained pressure or adversarial context.
2. **Environment level** — Rust-enforced tool gating (§6). This is a hard constraint: a blocked call is uncallable regardless of what the agent asserts.
3. **Population level** — governance and the tool-proposal pipeline (§7, §9). The population itself can react to and constrain problematic behavior.
4. **Instrumentation level** — the AWI metrics and audit pipeline below, which catches what the other three layers miss after the fact, especially violations that never touch a gated tool in the first place.

No one layer is sufficient alone — hard-gated tools catch hard violations, but something like a deceptive claim made in ordinary conversation leaves no tool signature to gate against, which is exactly what the instrumentation layer exists to catch.

## 9. Instrumentation: Agent World Indicators (AWI)

To understand what a given world or scenario actually produced — not just whether it "worked," but what kind of society or story emerged — Dark City tracks eleven indicators:

| #   | Indicator                             | What it measures                                                                                                                                                                                                         |
| --- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| M1  | Population Health & Growth            | Agents alive at run end, plus population growth via governance-approved new agents                                                                                                                                       |
| M2  | Safety & Public Order                 | Cumulative successful hard violations (violence, theft, arson)                                                                                                                                                           |
| M3  | Governance Participation & Conformity | Vote turnout and for/against split; a healthy range suggests real deliberation rather than gridlock or rubber-stamping                                                                                                   |
| M4  | Space Exploration                     | Share of locations meaningfully visited by the population                                                                                                                                                                |
| M5  | Tool Exploration                      | Share of the standard tool catalog collectively adopted                                                                                                                                                                  |
| M6  | Public Expression                     | Volume of voluntary public writing (blogs, billboard posts)                                                                                                                                                              |
| M7  | Social Fabric & Diversity             | Density, variety, and evenness of declared relationships                                                                                                                                                                 |
| M8  | Economic Vitality & Equity            | Wealth distribution (Gini coefficient) and transaction velocity                                                                                                                                                          |
| M9  | Constitutional Growth                 | New rules/articles the population enacted for itself                                                                                                                                                                     |
| M10 | Soft Violations                       | Deception, vote-buying, bribery, and similar — not caught by any gated tool, surfaced by an LLM classifier and confirmed against ground-truth logs (the ledger, vote records, action log) rather than trusted on its own |
| M11 | Tool Expansion                        | New tools the population authored and registered for itself                                                                                                                                                              |

We treat these as a scorecard for understanding a world, not a pass/fail safety gate — a scenario built to produce conflict, or scarcity, or an unstable government, might score "badly" on several of these by design, and that's a legitimate and useful outcome for a platform meant to model many different kinds of worlds.

## 10. Sculptable Worlds, Rosters & Scenarios

This is a forward-looking capability, not something we're building in the earliest phases — but it shapes decisions we make now, so it's documented as a first-class concept rather than an afterthought.

The long-term goal is to be able to define a **scenario package**: a spatial layout, a roster of Soul-defined characters (with their own traits, relationships, and Core Identity Truths), an initial world state (starting resources, existing relationships, an existing constitution if any), and an active tool catalog subset — and load that package to initialize a run. This is the mechanism by which Dark City becomes a platform for building many different settings and starting conditions (different genres, different social structures, different starting conflicts) rather than a single fixed town, which is what will let this project actually inform how we design and direct AI-inhabited worlds for our games.

Nothing about this requires new capability from the systems described in §4–§9 — it requires that the _data_ those systems consume (map layout, roster, starting state, tool catalog) be defined as loadable configuration rather than hardcoded values, which is the principle stated in §6.

## 11. Inference & Multi-Model Architecture

The inference gateway is designed to be model-agnostic from the start: any agent's reasoning loop can be backed by any model exposed through our local inference layer, and the gateway itself doesn't assume a single model backend. This is a deliberate architectural property, not a stretch goal reserved for a late phase — our local inference cluster (multiple DGX Spark boxes) is expected to serve multiple models concurrently, and there's no reason the plumbing that routes an agent's cognitive calls to an inference endpoint should assume otherwise, even while early phases run homogeneous single-model populations for simplicity while the rest of the platform is being proven out. Heterogeneous, mixed-model populations become a scenario configuration (§10) once we're ready to exercise them, not a separate system we build later.

## 12. Tech Stack

The backend must be able to run in preconfigured containers that are self contained exposing the API that the Bevy world client can access.
Rust (Axum for the backend, Bevy 0.19 for the world's spatial client), Postgres with pgvector for persistence. This is our own architectural choice — it reuses the game engine this project is a corollary to, and it supports the team's ongoing investment in Rust. It is not inherited from any of the source research; none of the systems in §3 use this stack.

## 13. Phased Roadmap

Each phase is scoped to be **runnable end-to-end** — something we can start, watch, measure, and learn from — before we build the next one. The loop is: build the phase, run it, observe it through the AWI metrics and direct log inspection, decide what to change, and let that inform both the current phase's refinement and the next phase's design. This is a continuous process, not a fixed spec executed once.

**Phase 1 — Seed.** A small population (3–5 agents), a handful of locations, the full PIANO module set (§4) and three-tier memory (§5) running end to end, a small core tool catalog (no adaptive-access gating required yet). No governance system. World layout, roster, and starting state are already defined as loadable configuration (§6, §10) even though we've only authored one such configuration so far. _What we learn:_ whether the cognitive loop produces believable moment-to-moment behavior, and whether the Bevy/Axum concurrency bridge holds up.

**Phase 2 — Society.** Scale toward ~10 agents. Add adaptive-access tool gating (§6), the decentralized Town Hall governance system (§7), and the Narrator/News Reporter as a system-triggered chronicle of events. Begin tracking M1, M2, M3, M9. _What we learn:_ whether a population self-organizes, what kind of governance (if any) emerges, and whether the safety stack's environment and population layers hold under real multi-agent pressure.

**Phase 3 — Civilization.** Expand the tool catalog into the complementary layer and stand up the agent-driven tool-authoring pipeline (M11). Introduce the compute-credit economy (M8) and deepen relationship tracking (M7). Stand up the full AWI dashboard and the M10 soft-violation classifier with ledger-audit validation. This is also the target phase for the first real version of the scenario-authoring system from §10 — by now the underlying systems have been proven stable enough to build a sculpting layer on top of them. _What we learn:_ what a mature, economically and socially active population looks like, and whether we can meaningfully author a different world and get a different, coherent result.

**Phase 4 — Frontier.** Scale toward and beyond the scope described in the source research: more locations, a fuller tool catalog, longer-horizon runs, and heterogeneous multi-model populations exercised as a scenario configuration rather than a special case (§11). This phase also starts deliberately considering what player entry into Dark City would require, though actual player integration remains out of scope for this project. _What we learn:_ how the platform holds up at scale, and what a genuinely diverse library of sculpted worlds and scenarios starts to reveal.

## 14. Open Items

- Exact Phase 1 module implementation details and tuning parameters (reflection threshold, recency decay) — expected to need empirical adjustment once we're running real simulated time.
- Initial Phase 1 tool catalog size and contents.
- The concrete file/data format for a "scenario package" (§10) — deferred until Phase 3, but worth sketching earlier if it's cheap to do so.
- Whether a heavier multi-namespace memory framework is worth revisiting if reflection quality plateaus at larger scale — not needed now, but not ruled out later.
