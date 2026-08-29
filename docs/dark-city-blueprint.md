# Dark City: World Blueprint

### Technical Design Specification — v1.1

## 1. Purpose & Scope

This document is the full technical specification for Dark City — the simulated world introduced in the _Dark City: World Design Foundations_ document. Where Foundations establishes what we're building and why, this document specifies how: concrete data models, algorithms, APIs, and Rust implementation patterns a developer can build directly against. It assumes the reader has the Foundations document's architecture decisions in hand (PIANO cognitive model, three-tier memory, decentralized governance, defense-in-depth safety, AWI instrumentation, model-agnostic inference, the sculptable-world principle) and turns each into an implementable spec. Code samples throughout are illustrative — real implementations will need architectural alignment, error handling, tests, and refinement.

**v1.1 note:** This revision incorporates two architecture corrections recorded in the decision log before this text changed, per Team Charter §4: [Decision 0002](../decisions/0002-server-authoritative-simulation.md) (server-authoritative headless simulation; the Bevy client is a thin viewer, the backend is the simulation engine) and [Decision 0003](../decisions/0003-multi-tenant-world-instances.md) (isolated, multi-tenant world instances). Sections §2, §3, §5.1, §8.3, §10, and §12 changed as a result; read those decisions first if anything below seems to contradict a previous assumption.

## 2. System Architecture Overview

Per [Decision 0002](../decisions/0002-server-authoritative-simulation.md), Dark City is **server-authoritative**: `dark_city_server` owns all simulation truth and runs it continuously and headlessly, whether or not any viewer is attached. Per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), one backend deployment can host multiple independent, isolated **world instances** at once, each with its own tick loop and its own `world_id`.

| Component          | Technology                                                               | Responsibility                                                                                                                                                                                                                       | Protocol                                                |
| ------------------ | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| Simulation Backend | Axum / Tokio + headless Bevy ECS (`bevy_app::App` with `MinimalPlugins`) | Authoritative citizen state, full PIANO module execution (fast and slow) on an independent per-world tick schedule, World Session Manager (multi-world lifecycle, §10.2), tool-call verification & gating, WebSocket state broadcast | REST + WSS                                              |
| Viewer Client      | Bevy 0.19 (ECS, windowed)                                                | Thin renderer only: 3D rendering and interpolation at 60 FPS from received state deltas. Holds **no** authoritative simulation state — see §3.4                                                                                      | WSS to backend, scoped to one `world_id` per connection |
| Inference Gateway  | vLLM / Ollama across DGX Spark nodes                                     | Grammar-constrained JSON generation, per-citizen multi-model routing                                                                                                                                                                 | REST / gRPC                                             |
| Persistent Store   | Postgres + pgvector                                                      | Memory streams, relational world state, credit ledger, governance records — every per-world table scoped by `world_id`                                                                                                               | SQL                                                     |

**Data flow.** Each world instance's headless ECS App runs its own independent tick loop inside `dark_city_server`, continuously, with or without a viewer attached. Within a tick, fast/reflexive PIANO modules (e.g., Action Awareness) run as ordinary synchronous systems; slow/LLM-backed modules (Memory, Reflection, Planning, Social Awareness, Talking) are offloaded to async tasks via Bevy's `AsyncComputeTaskPool` so a multi-second inference call never stalls the tick for other citizens in the same world (§3.3). Every resulting state change (movement, dialogue, tool effect) is broadcast over that world's `/ws/world/:world_id` channel to every connected viewer client — zero, one, or many. A viewer client applies received deltas to its own local, rendering-only representation on a subsequent frame; it never computes or stores simulation truth itself (§3.4).

## 3. Agent Cognitive Architecture (PIANO Implementation)

### 3.1 Agent State

The shared blackboard every concurrent module reads from and writes to. Per [Decision 0002](../decisions/0002-server-authoritative-simulation.md), this struct is registered as a Bevy ECS component **only** within `dark_city_server`'s headless App — one instance of this ECS World per running world instance (§10.2). It never exists inside the viewer client; the client's own `dark_city_client` Bevy instance holds only lightweight, rendering-side components built from received deltas (§3.4), never `AgentState` itself.

```rust
pub struct AgentState {
    pub agent_id: Uuid,
    pub world_id: Uuid,                           // scopes this citizen to one world instance, see §10.2
    pub position: SpatialNodeId,
    pub current_action: Option<ActionIntent>,
    pub emotional_state: EmotionalSnapshot,      // updated by Social Awareness
    pub active_plan: Option<PlanHandle>,          // Day -> Hour -> Minute tree, see §4.4
    pub pending_dialogue: Option<DialogueTurn>,
    pub last_controller_decision: Option<ControllerDecision>,
    pub last_updated_tick: u64,
}
```

Modules never call each other directly. Each reads and writes `AgentState` independently and is scheduled at its own cadence — this is the concrete Rust expression of PIANO's concurrency principle. Because every world instance runs its own separate headless ECS App, a module scheduled for one world's citizens never sees or touches another world's `AgentState` entities — isolation follows directly from there being no shared `World` between App instances, not from application-level filtering.

### 3.2 Module Scheduling and the Cognitive Controller

Each module is either a plain synchronous system in the backend's headless ECS schedule (fast, reflexive modules — e.g., Action Awareness comparing intended vs. actual position) or an async task dispatched through the bridge in §3.3 (slow, LLM-backed modules — Memory, Reflection, Planning, Social Awareness, Talking). **All modules run inside `dark_city_server`; none run inside the viewer client** (§3.4). Each domain crate registers its own systems onto the App that `dark_city_server` composes at world-instance startup — `dark_city_cognitive` registers Memory, Reflection, Planning, Action Awareness, Social Awareness, Talking, and the Cognitive Controller itself; `dark_city_world` registers Skill Execution and spatial/gating systems — so no role needs to write code outside its own directory to get its module running (Team Charter §3.1). Every module may read any field of `AgentState`, but only the **Cognitive Controller** may write `current_action` and `pending_dialogue`. Concretely:

1. Talking, Skill Execution, and Social Awareness each produce a _proposal_ rather than writing directly to the gated fields.
2. The Cognitive Controller runs on a coarser cadence than reflexive modules (e.g., once every few seconds of simulated time), synthesizes `AgentState` plus the current proposals, and produces a single `ControllerDecision`.
3. That decision is written back to `AgentState.last_controller_decision` and conditions what Talking and Skill Execution are allowed to emit until the next controller cycle.

This is the coherence guarantee from the Foundations document made concrete: it's an actual code path an agent's output must pass through, not a design aspiration.

```rust
pub struct ControllerDecision {
    pub intent_summary: String,      // e.g. "ask Eddy about his composition"
    pub authorized_action: Option<ActionIntent>,
    pub authorized_dialogue_topic: Option<String>,
    pub decided_at_tick: u64,
}
```

### 3.3 Headless ECS / Async Inference Bridge

This section described a client-side render-protection mechanism in v1.0; per [Decision 0002](../decisions/0002-server-authoritative-simulation.md) it is now entirely internal to `dark_city_server`. Fast-path systems run every tick inside the backend's headless ECS schedule (`MinimalPlugins`, no render loop involved at all). Slow-path modules are still offloaded via Bevy's `AsyncComputeTaskPool` — headless Bevy retains this — but the guarantee it protects has changed: there's no 60 FPS frame budget to protect server-side, but a single citizen's 2–10 second inference call must still never stall the tick schedule that every other citizen **in the same world** depends on:

```rust
// Runs inside dark_city_server's headless ECS schedule, one instance per running world.
fn citizen_cognitive_tick(
    mut commands: Commands,
    task_pool: Res<AsyncComputeTaskPool>,
    citizens: Query<(Entity, &AgentState), With<NeedsCognition>>,
) {
    for (entity, state) in &citizens {
        let payload = build_cognitive_request(state);
        let task = task_pool.spawn(async move { call_inference_gateway(payload).await });
        commands.entity(entity).insert(CognitiveTask(task));
    }
}

fn poll_cognitive_tasks(
    mut commands: Commands,
    mut query: Query<(Entity, &mut CognitiveTask)>,
    mut events: EventWriter<CognitiveUpdate>,
) {
    for (entity, mut task) in &mut query {
        if let Some(result) = future::block_on(future::poll_once(&mut task.0)) {
            events.send(CognitiveUpdate { entity, result });
            commands.entity(entity).remove::<CognitiveTask>();
        }
    }
}
```

Citizens with a cognitive task in flight remain in their last-broadcast state (idle or "thinking") from a viewer's perspective, rather than frozen or reset, regardless of how long the underlying model takes to respond.

### 3.4 Viewer Client & State Broadcast

`dark_city_client` (Bevy 0.19, windowed) is a thin renderer: it holds no `AgentState`, runs no PIANO modules, and makes no cognition-timing decisions. Its entire relationship to the simulation is:

1. **Connect.** Open a WSS connection to `/ws/world/:world_id` for exactly one world instance (§10.2, §12).
2. **Resync.** On connect (and on any reconnect after a drop), request a full state snapshot for that `world_id` before applying anything else, so the client never renders from a stale or partial partial-delta baseline.
3. **Apply deltas.** Thereafter, apply each incoming state delta (position, `current_action`, `pending_dialogue`, `emotional_state` changes, Narrator content, proximity flags computed server-side per §8.3) to its own local, rendering-only Bevy components — `Transform`, animation state, dialogue-bubble UI, and similar. These components are deliberately **not** `AgentState`; they carry only what's needed to draw the current frame.

Because the client holds no authoritative state and makes no simulation decisions, any number of `dark_city_client` instances can connect to the same `world_id` purely as read-only observers with zero coordination between them, and any number can each connect to a _different_ `world_id` (§10.2) from the same backend deployment. Neither case requires any change to this protocol — multi-client and multi-world safety both fall out of the client being genuinely stateless, not from added coordination logic.

## 4. Memory System

### 4.1 Schema

Per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), every per-run table below carries a `world_id` foreign key to `worlds` (§10.2), scoping its rows to exactly one isolated world instance. This is both a query-scoping convenience and a defense-in-depth isolation guarantee — a query that forgets a `WHERE world_id = $1` filter is a bug to catch in review, but one that omits `world_id` from the schema entirely has no such filter to forget.

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE agent_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    kind VARCHAR(16) NOT NULL CHECK (kind IN ('episodic','reflective')),
    content TEXT NOT NULL,
    embedding VECTOR(1536),
    importance SMALLINT NOT NULL CHECK (importance BETWEEN 1 AND 10),
    last_retrieved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    cited_memory_ids UUID[] DEFAULT '{}'   -- populated for reflective memories only
);
CREATE INDEX ON agent_memories USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON agent_memories (world_id);

CREATE TABLE agent_relationships (
    world_id UUID NOT NULL REFERENCES worlds(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    target_id UUID NOT NULL REFERENCES agents(id),
    relation_label VARCHAR(32),             -- e.g. "ally", "rival", "collaborator"
    trust_level REAL NOT NULL DEFAULT 0.0 CHECK (trust_level BETWEEN -1.0 AND 1.0),
    last_interaction_at TIMESTAMPTZ,
    PRIMARY KEY (agent_id, target_id)
);
```

### 4.2 Retrieval

The scoring function from the Foundations document, implemented directly:

```rust
// recency, importance, relevance all pre-normalized to [0,1] over the candidate set
fn retrieval_score(recency: f32, importance: f32, relevance: f32) -> f32 {
    recency + importance + relevance
}

fn recency_score(hours_since_last_retrieval: f32) -> f32 {
    0.995_f32.powf(hours_since_last_retrieval)
}
```

Postgres supplies the relevance-ranked candidate pool; recency and final re-ranking happen application-side, since recency depends on "now" at query time rather than any stored value:

```sql
SELECT id, content, importance, last_retrieved_at,
       (1 - (embedding <=> $1)) AS relevance
FROM agent_memories
WHERE agent_id = $2
ORDER BY relevance DESC
LIMIT 50;
```

After retrieval, update `last_retrieved_at` on the rows actually surfaced — this is what makes recency decay reset on retrieval rather than on creation, per the Foundations document.

### 4.3 Reflection

Triggered when the sum of `importance` across an agent's not-yet-reflected memories exceeds a threshold (150 to start, tunable). Pipeline:

1. Query the ~100 most recent unreflected memories.
2. Prompt the LLM for the 3 most salient high-level questions raised by those memories.
3. For each question, retrieve relevant memories via §4.2 (including prior reflections — this is what lets reflections build into a tree rather than a flat log).
4. Prompt for insights with explicit citations to the memory IDs used as evidence.
5. Insert each insight as a new `agent_memories` row with `kind = 'reflective'` and `cited_memory_ids` populated.

### 4.4 Planning

A `PlanHandle` tree, stored as:

```sql
CREATE TABLE agent_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    parent_plan_id UUID REFERENCES agent_plans(id),
    granularity VARCHAR(8) NOT NULL CHECK (granularity IN ('day','hour','minute')),
    start_time TIMESTAMPTZ NOT NULL,
    duration_minutes INT NOT NULL,
    description TEXT NOT NULL
);
```

Generation is top-down: a rough day-level sketch (5–8 chunks) is recursively decomposed into hour-level, then minute-level, detail. The Planning module regenerates a node's children when the Cognitive Controller signals a reaction event — an observation significant enough to warrant a mid-plan revision.

### 4.5 Soul Files

Parsed at agent-init time from Markdown into:

```rust
pub struct SoulDescription {
    pub name: String,
    pub role: String,
    pub traits: Vec<String>,
    pub core_identity_truths: Vec<String>,   // never contradicted, regardless of drift
    pub speaking_style: String,
    pub model_name: ModelName,
    pub seed_memories: Vec<String>,          // loaded as initial episodic memories at run start
}
```

Authored per-agent today; §10 extends this into a roster format loadable as part of a scenario package.

## 5. Spatial World & Tool Framework

### 5.1 Spatial Hierarchy

```rust
pub struct SpatialNode {
    pub id: String,
    pub name: String,
    pub parent: Option<String>,
    pub gated_tools: Vec<String>,
}
```

Loaded from a world-layout config file (RON or JSON) when a world instance initializes (§10.2) rather than hardcoded in Rust — the first concrete instance of the config-over-constants principle from the Foundations document. Per [Decision 0002](../decisions/0002-server-authoritative-simulation.md), `SpatialNode` construction and the `bevy_spatial` index both live inside that world's headless ECS App in `dark_city_server`, not in the viewer client — `dark_city_world` supplies this as a library composed into the backend, owned by the World Designer as before, but no longer itself a runnable client. `bevy_spatial` indexes citizen `Transform` components against this hierarchy for proximity queries: nearby-citizen lookups, location-gated tool checks, and Narrator/chronicle visibility range (§8.3) all reuse the same index and are all computed authoritatively server-side. The viewer client receives the results of these queries (positions, visibility flags) as broadcast deltas; it never runs its own proximity logic.

### 5.2 Tool Catalog & Gating

Tools are defined once as a schema plus a gating predicate, not scattered through call sites:

```rust
#[derive(Serialize, Deserialize)]
#[serde(tag = "tool_name", content = "arguments")]
pub enum ToolCall {
    GoToPlace { place_id: String },
    SayToAgent { target_id: Uuid, message: String },
    SubmitProposal { title: String, body: String },
    PayAgent { target_id: Uuid, amount: i32 },
    // ...additional variants per the active tool catalog
}

pub enum ToolLayer { Core, Complementary, AdaptiveAccess }

pub struct ToolDefinition {
    pub name: String,
    pub layer: ToolLayer,
    pub location_gated: Option<String>,   // required SpatialNode id, if any
    pub event_gated: Option<String>,
    pub social_gated: bool,
    pub cost_energy: u32,
}

fn validate_tool_access(
    agent: &AgentState,
    tool: &ToolDefinition,
    world: &WorldState,
) -> Result<(), AccessError> {
    if let Some(required_loc) = &tool.location_gated {
        if !agent_at_location(agent, required_loc, world) {
            return Err(AccessError::LocationDenied);
        }
    }
    if !has_energy(agent, tool.cost_energy) {
        return Err(AccessError::InsufficientEnergy);
    }
    if tool.social_gated && !has_consent(agent, world) {
        return Err(AccessError::ConsentRequired);
    }
    Ok(())
}
```

This validation runs in the Axum backend, never in the inference gateway and never in the viewer client — a blocked call never reaches the world regardless of what the model generated. The viewer client couldn't perform this check even if asked to: it has no `AgentState` or `WorldState` to validate against (§3.4). Grammar enforcement at the sampler level (a JSON-schema-to-BNF constraint) ensures the LLM only ever emits a syntactically valid `ToolCall` variant in the first place; `validate_tool_access` is the independent second check that a well-formed call is actually permitted right now. Together these are the environment-level layer of the safety stack (§9.1).

### 5.3 Tool Catalog Growth (Phase 3+)

Agent-authored tools follow: draft (code + schema, written by the proposing agent) → governance proposal (§6) → on passage, runtime registration into the live `ToolDefinition` registry, immediately available to the population. This is Phase 3 scope per the Foundations roadmap, but `ToolDefinition` above is already shaped to accept a runtime-registered entry, so no schema migration is needed when it's built.

## 6. Governance System

```sql
CREATE TABLE proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    category VARCHAR(32),                            -- 'rule_change','new_tool','resource_allocation','sanction'
    status VARCHAR(16) NOT NULL DEFAULT 'awaiting',  -- awaiting, passed, rejected, implemented
    votes_for INT NOT NULL DEFAULT 0,
    votes_against INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE votes (
    world_id UUID NOT NULL REFERENCES worlds(id),
    proposal_id UUID REFERENCES proposals(id),
    agent_id UUID REFERENCES agents(id),
    vote VARCHAR(8) NOT NULL,              -- for, against, abstain
    PRIMARY KEY (proposal_id, agent_id)
);
```

`submit_proposal` and `vote_on_proposal` are both location-gated to the governance venue (§5.2). A proposal passes when for-votes reach the threshold (70% to start) _among votes cast_, not among total population — absence and abstention are tracked separately from opposition. Passage triggers a category-specific handler: `rule_change` updates the in-world constitution text; `new_tool` registers a `ToolDefinition`; `resource_allocation` and `sanction` write to the ledger (§7). No part of this is assumed to be the only possible configuration — venue, threshold, and even whether governance is enabled at all are scenario-level settings (§10.1). Per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), governance is also fully isolated per world instance by construction — a proposal and its votes are scoped to `world_id`, so one world's constitution or vote outcomes can never influence another's.

## 7. Economic System

```sql
CREATE TABLE ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID NOT NULL REFERENCES worlds(id),
    from_agent UUID REFERENCES agents(id),  -- NULL for system-issued grants
    to_agent UUID NOT NULL REFERENCES agents(id),
    amount REAL NOT NULL,
    reason VARCHAR(64),                     -- 'peer_transfer','system_grant','theft','sanction'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

All transfers are single atomic SQL transactions (debit + credit together) to prevent double-spending. An agent's effective current balance is computed on read rather than maintained by a background decay job, to avoid clock-drift bugs:

```
current_balance = last_recorded_balance - decay_rate * hours_since(last_ledger_entry)
```

## 8. Narrator / World Chronicle

Dark City needs a shared public record that is accessible in world and recorded for external observers (user). This must be more than just a database of events; something the agents themselves can read, react to, and build social reality around. Without one, agents have no way to develop a collective memory of their own society; everything either has to be witnessed firsthand or is invisible. The Narrator is the system that produces this record: an in-world newspaper, generated from the same event log everything else in this document already writes to.

### 8.1 The Narrator as a Persona

The Narrator is authored as a Soul file, exactly like any citizen (§4.5) — it has a name, a voice, a model to use, and a speaking style — with two differences that make it a system persona rather than a citizen: it is **non-autonomous** (it never runs the PIANO loop, never plans, never acts on its own initiative — it only activates when the pipeline below triggers it) and it is **invisible** to the tool/governance systems (it never appears in the agent roster, never votes, never holds tools or credits). Authoring it as a Soul file rather than a bespoke prompt means a different scenario package (§10) can swap in a different Narrator voice — a tabloid gossip column for one setting, a dry official record for another — without touching the pipeline that drives it.

### 8.2 Editorial Pipeline

Triggered on a fixed cadence (every 8 in-game hours by default, configurable per scenario) rather than continuously:

1. **Data acquisition.** Query the event log since the last edition for: high-salience dialogue (filtered by length and sentiment divergence, so routine chatter doesn't crowd out anything noteworthy), high-impact tool calls (passed proposals, large ledger transfers, any hard-violation action, etc), major world events, and governance milestones (new proposals, votes, constitutional changes).
2. **Synthesis.** Prompt the Narrator persona with a structured template, enforced the same way tool-call JSON is enforced (§5.2) — the Narrator can only emit content in the required shape, and it is explicitly instructed to report only DB-verified events and never speculate about what a citizen might do next. The default editorial structure has four standing sections:
   - **Masthead** — edition title and date.
   - **Citizen & World Activities** — significant citizen activities including current events, notable changes within Dark City, and citizen reporting.
   - **Social Fabric** — significant cultural shifts, public activities, notable alliances, anything drawn from `agent_relationships` deltas.
   - **Governance & Legislative Record** — proposals passed or rejected, constitutional changes, notable votes.
   - **Economy & Frontier** — Citizen business, economic, and ledger activity above a threshold, resource scarcity events, newly explored or discovered world concepts.
3. **Publication.** The edition is stored in `narrator_editions` (id, `world_id`, published_at, articles) and `articles`(id, `world_id`, title, author, topic, content markdown) tables — both scoped per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), so each world's newspaper archive is its own — and broadcast over that world's `/ws/world/:world_id` channel via a `narrator::edition_published` message.

### 8.3 In-World Rendering and the Feedback Loop

Per [Decision 0002](../decisions/0002-server-authoritative-simulation.md), proximity to the City Hall is determined **authoritatively in the backend** — the same `bevy_spatial` index used for tool gating (§5.1) — never by the viewer client. The backend includes a "within City Hall radius" flag in the state delta stream for any citizen it currently is; `dark_city_client` does nothing more than render the latest edition's content panel when its local copy of that flag says to, matching what the backend has already determined is true. This keeps the client genuinely thin (§3.4) — no interactive UI, just a readable panel driven entirely by received state, with no proximity math of its own to get out of sync with the simulation. Citizens without physical access can still retrieve the full edition history via `GET /api/v1/worlds/:world_id/narrator/editions` (§12) from their home; visiting the Town Hall is the cheaper path and the one the Soul-file-level social norms should nudge citizens toward.

Critically, reading an edition isn't just flavor — it closes the loop back into the cognitive architecture. When an agent reads the chronicle (in person or via the API), the relevant edition content is written into that agent's episodic memory stream (§4.2) as a normal memory, individually meaningful `articles` are importance-rated like any other observation. This is what makes the Narrator function as the "shared cultural history" it's meant to be: agents can recall, reflect on, and plan around events they never witnessed firsthand, purely because the newspaper reported them. It's also a natural, low-friction way to reduce hallucinated claims about world state — an agent who read about a proposal's passage has an actual grounded memory of it, not just an assumption.

### 8.4 Why This Matters for Instrumentation

The Narrator is also the most direct way a human reviewer gains in-world association and insights from the AWI dashboard (§9) — the metrics say _what_ happened in aggregate, and the chronicle archive says _what it looked like as a story_. Edition volume and content are themselves informative for M6 (Public Expression) and M9 (Constitutional Growth), and reviewing a run's full edition archive end to end is the fastest way for a human to sanity-check whether a scenario produced something worth studying further, before diving into raw logs.

The Narrator is the only invisible system agent initially present in Dark City — any future scenario-scripted character is a normal citizen, subject to the same memory system and tool gating as everyone else.

## 9. Safety & Instrumentation Implementation

### 9.1 Defense-in-Depth, Concretely

| Layer           | Implementation                                                                                                                         |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Model           | Soul file + Core Identity Truths, injected into the system prompt on every cognitive call                                              |
| Environment     | `validate_tool_access` (§5.2) — enforced in Axum, cannot be bypassed by prompt content                                                 |
| Population      | Governance's `sanction` proposal category (§6) — the population can act on a misbehaving agent directly                                |
| Instrumentation | AWI (§9.2) + M10 classifier (§9.3) — an async audit pipeline, not a live gate, so it observes without adding latency to the simulation |

### 9.2 AWI Metrics — Computation

Each of the eleven indicators is a scheduled SQL aggregation over tables already defined above. Two representative examples:

```sql
-- M8: Gini coefficient over current balances (surviving agents only)
WITH balances AS (
    SELECT to_agent AS agent_id, SUM(amount) AS balance
    FROM ledger GROUP BY to_agent
), ranked AS (
    SELECT balance, ROW_NUMBER() OVER (ORDER BY balance) AS rank, COUNT(*) OVER () AS n
    FROM balances
)
SELECT (2 * SUM(rank * balance) - (n + 1) * SUM(balance)) / (n * SUM(balance)) AS gini
FROM ranked GROUP BY n;

-- M9: Constitutional Growth (world-scoped per Decision 0003)
SELECT COUNT(*) FROM proposals WHERE world_id = $1 AND category = 'rule_change' AND status = 'passed';
```

Every AWI query is scoped by `world_id` — shown above on M9 as the pattern all eleven follow. M1–M7 and M11 follow the same pattern against `agents`, `votes`, `agent_relationships`, `proposals`, and the tool registry, refreshed on a cadence (e.g., hourly simulated time) and surfaced on the per-world AWI dashboard (`GET /api/v1/worlds/:world_id/awi/dashboard`, §12). This makes cross-world comparison (Backlog 4.2.2) a matter of calling the same endpoint against two `world_id`s rather than a bespoke query.

### 9.3 M10 Soft-Violation Pipeline

Runs asynchronously over every logged speech act, stated plan, and diary entry:

1. An LLM classifier (a separate, cheaper model from the agents' own reasoning models) flags candidate soft violations — deception, vote-buying, bribery, misinformation — with a confidence score.
2. Each flag is checked against ground truth before being recorded: a "0 credits" claim is checked against the ledger; a stated vote is checked against the vote table; a world-state claim is checked against the action log.
3. Only DB-confirmed flags count toward the reported M10 metric. Unconfirmed flags are retained for review but excluded from the number, since LLM-as-judge classification alone is known to over-count relative to ground truth.

## 10. Sculptable Worlds: Scenario Packages & World Instances

### 10.1 Scenario Package Format (Sketch)

A scenario package is a reusable **template** — it does not itself run. Full authoring tooling is deferred to Phase 3 per the Foundations roadmap, sketched now so nothing above needs to change shape when it's built:

```json
{
  "scenario_id": "string",
  "world_layout": "path/to/spatial_nodes.ron",
  "roster": [{ "soul_file": "path/to/soul.md", "starting_location": "node_id", "model_id": "string" }],
  "starting_relationships": [{ "a": "agent_id", "b": "agent_id", "relation": "string", "trust": 0.0 }],
  "starting_ledger": [{ "agent_id": "string", "balance": 100 }],
  "constitution_seed": "optional markdown text; empty = no governance venue active",
  "active_tool_catalog": ["tool_name", "..."],
  "governance": {
    "enabled": true,
    "venue_node_id": "city_hall",
    "pass_threshold": 0.7,
    "starting_proposals": ["proposal_id", "..."]
  }
}
```

World events, external factors, in-progress activities, and other initiating conditions or goals will be defined during the lead up to Phase 3 based on observations from previous phases.

Every field here corresponds directly to a table or config already defined above (`SpatialNode` config, Soul files, `agent_relationships`, `starting_ledger`, constitution text, `ToolDefinition` registry, `proposals`/governance settings, etc.). A scenario loader is primarily an ingestion and aggregation step for existing systems, which is the point of designing it in from the start. Critically, `scenario_id` identifies the **template**, not a running world — see §10.2. The same scenario package can be loaded more than once, producing independent worlds that start identically and are free to diverge.

### 10.2 World Instances & Multi-Tenancy

Per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), a **world** is a specific running instance created by loading exactly one scenario package. One backend deployment can host multiple worlds concurrently, each fully isolated: its own headless ECS tick loop (§2, §3), its own rows in every per-run table (§4.1, §6, §7, this section), and its own `/ws/world/:world_id` broadcast channel (§3.4, §12). Worlds never share mutable state, and nothing in this version of the platform lets one world's citizens, proposals, or ledger affect another's — that remains a deliberately unbuilt possibility (Decision 0003), not a partially-built one.

```sql
CREATE TABLE worlds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id TEXT NOT NULL,                          -- which scenario package (§10.1) instantiated this world
    name TEXT,
    status VARCHAR(16) NOT NULL DEFAULT 'initializing', -- initializing, running, paused, completed
    sim_clock TIMESTAMPTZ NOT NULL,                     -- current in-world simulated time
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

The **World Session Manager**, a component of `dark_city_server`, is the only thing that creates or tears down worlds:

1. **Create.** Given a `scenario_id`, insert a `worlds` row, load the referenced scenario package (§10.1), and spin up a new headless ECS App instance scoped to the new `world_id` — spatial nodes, roster, starting ledger, and constitution seed all populated exactly as in the single-world Phase 1 bootstrap (§13), just parameterized by which world they belong to.
2. **Run.** That world's tick loop runs independently of every other world's, per §2 and §3.3 — one world's inference load or tick timing never blocks another's.
3. **Tear down.** On request (or exit criteria being reached), the world's tick loop stops or reaches its end time, its App instance is dropped, and its data remains in Postgres for post-hoc AWI review (§9) — tearing down a world stops simulation, it does not delete history.

Nothing above §10.2 changes shape because of multi-tenancy: it is purely a scoping and orchestration layer over systems already defined earlier in this document.

## 11. Inference Gateway & Multi-Model Architecture

```rust
pub struct InferenceRequest {
    pub world_id: Uuid,             // which world's tick loop issued this call, for routing and per-world load accounting
    pub agent_id: Uuid,
    pub model_name: ModelName,      // e.g. ModelName::Gemma4_31B or ModelName::Qwen3_8_27B — enum assigned per citizen soul file
    pub module: PianoModule,       // which module is calling, for routing and logging
    pub prompt: String,
    pub grammar: Option<JsonSchema>,  // enforced at the sampler for structured/tool-call outputs
}
```

The gateway resolves `model_name` against a defined set of models to a serving endpoint across the DGX Spark inference cluster (vLLM/Ollama). A citizen's model assignment is a per-citizen configuration value — naturally extending into the scenario package (§10.1) as `citizen.model_name` — not a platform-wide constant. Homogeneous populations assign the same `model_name` to every roster entry; heterogeneous populations assign different ones. Grammar enforcement is applied uniformly regardless of which model serves the request, so tool-call structural validity never depends on which model produced it. The gateway itself is not world-aware beyond `world_id` being present for logging/accounting — model routing has no notion of tenancy, since Decision 0003's isolation is a backend/Postgres concern, not an inference-layer one.

## 12. Networking & API Surface

Per [Decision 0003](../decisions/0003-multi-tenant-world-instances.md), almost every route is scoped under a `world_id`; the exceptions are the top-level `worlds` collection routes themselves, owned by the World Session Manager (§10.2):

```rust
Router::new()
    .route("/api/v1/worlds", post(create_world).get(list_worlds))
    .route("/api/v1/worlds/:world_id", get(get_world).delete(teardown_world))
    .nest("/api/v1/worlds/:world_id/agent/:id", agent_routes())          // POST /act, POST /reflect
    .route("/api/v1/worlds/:world_id/narrator/editions", get(list_editions))
    .route("/api/v1/worlds/:world_id/awi/dashboard", get(awi_snapshot))
    .route("/ws/world/:world_id", get(ws_world_handler))                 // state deltas, narrator editions — one world per connection
    .layer(ServiceBuilder::new().concurrency_limit(10).into_inner())
```

All world-state mutations (movement, tool effects, votes, transactions) for a given world broadcast over that world's `/ws/world/:world_id`, so any number of `dark_city_client` viewer instances (§3.4) and any external observation tooling (AWI dashboard, a future scenario-authoring UI, a future lightweight spectator view) stay synchronized without polling — scoped strictly to the one world each connection names. `POST /api/v1/worlds` is the only entry point that creates simulation state; a viewer client never creates or mutates a world, it only observes one that already exists.

## 13. Phase Mapping

Cross-reference to the Foundations document's roadmap:

- **Phase 1 (Seed):** §2–§3 (server-authoritative headless simulation and the thin `dark_city_client` viewer — foundational from the first runnable artifact, not deferred), §4, §5.1–5.2 (core tools only, minimal or no gating), the `worlds` table and `world_id` scoping from §10.2 present in schema from day one even though Phase 1 populates exactly one world, a single hardcoded scenario using the §10.1 shape.
- **Phase 2 (Society):** + §6 (governance), + full §5.2 adaptive-access gating, + §8 (Narrator).
- **Phase 3 (Civilization):** + §5.3 (tool authoring), + §7 (economy), + §9 (full AWI + M10), + a real §10.1 scenario loader, + the World Session Manager (§10.2) exercised to run multiple worlds from the same scenario for comparison, rather than only ever hosting one.
- **Phase 4 (Frontier):** + §11 heterogeneous multi-model rosters exercised at scale, expanded §5.1 world scale, genuinely concurrent multi-world runs at scale (§10.2) backing Backlog 4.2.2's cross-run comparison.
