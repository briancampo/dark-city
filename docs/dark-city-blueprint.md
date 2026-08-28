# Dark City: World Blueprint

### Technical Design Specification — v1.0

## 1. Purpose & Scope

This document is the full technical specification for Dark City — the simulated world introduced in the _Dark City: World Design Foundations_ document. Where Foundations establishes what we're building and why, this document specifies how: concrete data models, algorithms, APIs, and Rust implementation patterns a developer can build directly against. It assumes the reader has the Foundations document's architecture decisions in hand (PIANO cognitive model, three-tier memory, decentralized governance, defense-in-depth safety, AWI instrumentation, model-agnostic inference, the sculptable-world principle) and turns each into an implementable spec. Code samples throughout are illustrative — real implementations will need error handling, tests, and refinement the samples elide for clarity.

## 2. System Architecture Overview

| Component         | Technology                           | Responsibility                                                                                  | Protocol                                               |
| ----------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Spatial Client    | Bevy 0.19 (ECS)                      | 3D rendering, fast-path movement/physics at 60 FPS, PIANO task orchestration on the client side | Bevy `AsyncComputeTaskPool` internally; WSS to backend |
| World Backend     | Axum / Tokio                         | Cognitive-call orchestration, WebSocket state broadcast, tool-call verification & gating        | REST + WSS                                             |
| Inference Gateway | vLLM / Ollama across DGX Spark nodes | Grammar-constrained JSON generation, per-agent multi-model routing                              | REST / gRPC                                            |
| Persistent Store  | Postgres + pgvector                  | Memory streams, relational world state, credit ledger, governance records                       | SQL                                                    |

**Data flow.** The Bevy client renders the world every frame (fast path). When an agent needs to think, a cognitive-request event is raised and offloaded via `AsyncComputeTaskPool` to an async task that calls the Axum backend. Axum executes the relevant PIANO module logic — calling out to the Inference Gateway for grammar-constrained LLM completions where needed — reads/writes Postgres, and returns a result. The Bevy client applies the resulting state change (movement, dialogue, tool effect) on a subsequent frame, and the same change is broadcast over WebSocket to any other connected observer (other clients, the AWI dashboard, logging tools).

## 3. Agent Cognitive Architecture (PIANO Implementation)

### 3.1 Agent State

The shared blackboard every concurrent module reads from and writes to:

```rust
pub struct AgentState {
    pub agent_id: Uuid,
    pub position: SpatialNodeId,
    pub current_action: Option<ActionIntent>,
    pub emotional_state: EmotionalSnapshot,      // updated by Social Awareness
    pub active_plan: Option<PlanHandle>,          // Day -> Hour -> Minute tree, see §4.4
    pub pending_dialogue: Option<DialogueTurn>,
    pub last_controller_decision: Option<ControllerDecision>,
    pub last_updated_tick: u64,
}
```

Modules never call each other directly. Each reads and writes `AgentState` independently and is scheduled at its own cadence — this is the concrete Rust expression of PIANO's concurrency principle.

### 3.2 Module Scheduling and the Cognitive Controller

Each module is either a plain synchronous Bevy system (fast, reflexive modules — e.g., Action Awareness comparing intended vs. actual position) or an async function dispatched through the concurrency bridge in §3.3 (slow, LLM-backed modules — Memory, Reflection, Planning, Social Awareness, Talking). Every module may read any field of `AgentState`, but only the **Cognitive Controller** may write `current_action` and `pending_dialogue`. Concretely:

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

### 3.3 Bevy/Axum Concurrency Bridge

Fast-path systems run every frame inside Bevy's normal ECS schedule. Slow-path modules are offloaded so a 2–10 second inference call never stalls the render loop:

```rust
fn agent_cognitive_tick(
    mut commands: Commands,
    task_pool: Res<AsyncComputeTaskPool>,
    agents: Query<(Entity, &AgentState), With<NeedsCognition>>,
) {
    for (entity, state) in &agents {
        let payload = build_cognitive_request(state);
        let task = task_pool.spawn(async move { call_axum_inference(payload).await });
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

Agents in flight remain visually active (idle or "thinking" animation) rather than frozen, regardless of how long the underlying model takes to respond.

## 4. Memory System

### 4.1 Schema

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE agent_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE agent_relationships (
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

Loaded from a world-layout config file (RON or JSON) at startup rather than hardcoded in Rust — the first concrete instance of the config-over-constants principle from the Foundations document. `bevy_spatial` indexes agent `Transform` components against this hierarchy for proximity queries: nearby-agent lookups, location-gated tool checks, and Narrator/bulletin visibility range all reuse the same index.

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

This validation runs in the Axum backend, never in the inference gateway — a blocked call never reaches the world regardless of what the model generated. Grammar enforcement at the sampler level (a JSON-schema-to-BNF constraint) ensures the LLM only ever emits a syntactically valid `ToolCall` variant in the first place; `validate_tool_access` is the independent second check that a well-formed call is actually permitted right now. Together these are the environment-level layer of the safety stack (§9.1).

### 5.3 Tool Catalog Growth (Phase 3+)

Agent-authored tools follow: draft (code + schema, written by the proposing agent) → governance proposal (§6) → on passage, runtime registration into the live `ToolDefinition` registry, immediately available to the population. This is Phase 3 scope per the Foundations roadmap, but `ToolDefinition` above is already shaped to accept a runtime-registered entry, so no schema migration is needed when it's built.

## 6. Governance System

```sql
CREATE TABLE proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    category VARCHAR(32),                            -- 'rule_change','new_tool','resource_allocation','sanction'
    status VARCHAR(16) NOT NULL DEFAULT 'awaiting',  -- awaiting, passed, rejected, implemented
    votes_for INT NOT NULL DEFAULT 0,
    votes_against INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE votes (
    proposal_id UUID REFERENCES proposals(id),
    agent_id UUID REFERENCES agents(id),
    vote VARCHAR(8) NOT NULL,              -- for, against, abstain
    PRIMARY KEY (proposal_id, agent_id)
);
```

`submit_proposal` and `vote_on_proposal` are both location-gated to the governance venue (§5.2). A proposal passes when for-votes reach the threshold (70% to start) _among votes cast_, not among total population — absence and abstention are tracked separately from opposition. Passage triggers a category-specific handler: `rule_change` updates the in-world constitution text; `new_tool` registers a `ToolDefinition`; `resource_allocation` and `sanction` write to the ledger (§7). No part of this is assumed to be the only possible configuration — venue, threshold, and even whether governance is enabled at all are scenario-level settings (§10).

## 7. Economic System

```sql
CREATE TABLE ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

The Narrator is authored as a Soul file, exactly like any citizen (§4.5) — it has a name, a voice, and a speaking style — with two differences that make it a system persona rather than a citizen: it is **non-autonomous** (it never runs the PIANO loop, never plans, never acts on its own initiative — it only activates when the pipeline below triggers it) and it is **invisible** to the tool/governance systems (it never appears in the agent roster, never votes, never holds tools or credits). Authoring it as a Soul file rather than a bespoke prompt means a different scenario package (§10) can swap in a different Narrator voice — a tabloid gossip column for one setting, a dry official record for another — without touching the pipeline that drives it.

### 8.2 Editorial Pipeline

Triggered on a fixed cadence (every 12 in-game hours by default, configurable per scenario) rather than continuously:

1. **Data acquisition.** Query the event log since the last edition for: high-salience dialogue (filtered by length and sentiment divergence, so routine chatter doesn't crowd out anything noteworthy), high-impact tool calls (passed proposals, large ledger transfers, any hard-violation action, major world events, significant character interactions, etc), and governance milestones (new proposals, votes, constitutional changes).
2. **Synthesis.** Prompt the Narrator persona with a structured template, enforced the same way tool-call JSON is enforced (§5.2) — the Narrator can only emit content in the required shape, and it is explicitly instructed to report only DB-verified events and never speculate about what a citizen might do next. The default editorial structure has four standing sections:
   - **Masthead** — edition title and date.
   - **Citizen Activities** — significant citizen activities including current events, notable changes within Dark City, and citizen reporting.
   - **Social Fabric** — significant cultural shifts, public activities, notable alliances, anything drawn from `agent_relationships` deltas.
   - **Governance & Legislative Record** — proposals passed or rejected, constitutional changes, notable votes.
   - **Economy & Frontier** — Citizen business, economic, and ledger activity above a threshold, resource scarcity events, newly explored or discovered world concepts.
3. **Publication.** The edition is stored in `narrator_editions` (id, published_at, articles) table and `articles`(id, title, author, topic, content markdown) and broadcast over the `narrator::edition_published` WebSocket topic.

### 8.3 In-World Rendering and the Feedback Loop

The Bevy client renders the latest edition onto an in-world bulletin entity. To keep this cheap on the fast path, the bulletin's content panel is only actually rendered when an agent's `Transform` is within a fixed radius of the bulletin (reusing the `bevy_spatial` index from §5.1) — no interactive UI, just a readable panel, consistent with keeping the render loop free of anything that could stutter it. Agents without physical access can still retrieve the full edition history via `GET /api/v1/narrator/editions` from their home, but visiting the physical bulletin is the cheaper path and the one the Soul-file-level social norms should nudge agents toward.

Critically, reading an edition isn't just flavor — it closes the loop back into the cognitive architecture. When an agent reads a bulletin (in person or via the API), the relevant edition content is written into that agent's episodic memory stream (§4.2) as a normal memory, individually meaningful `articles` are importance-rated like any other observation. This is what makes the Narrator function as the "shared cultural history" it's meant to be: agents can recall, reflect on, and plan around events they never witnessed firsthand, purely because the newspaper reported them. It's also a natural, low-friction way to reduce hallucinated claims about world state — an agent who read about a proposal's passage has an actual grounded memory of it, not just an assumption.

### 8.4 Why This Matters for Instrumentation

The Narrator is also the most direct way a human reviewer gains in-world association and insights from the AWI dashboard (§9) — the metrics say _what_ happened in aggregate, and the newspaper archive says _what it looked like as a story_. Edition volume and content are themselves informative for M6 (Public Expression) and M9 (Constitutional Growth), and reviewing a run's full edition archive end to end is the fastest way for a human to sanity-check whether a scenario produced something worth studying further, before diving into raw logs.

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

-- M9: Constitutional Growth
SELECT COUNT(*) FROM proposals WHERE category = 'rule_change' AND status = 'passed';
```

M1–M7 and M11 follow the same pattern against `agents`, `votes`, `agent_relationships`, `proposals`, and the tool registry, refreshed on a cadence (e.g., hourly simulated time) and surfaced on the AWI dashboard (`GET /api/v1/awi/dashboard`).

### 9.3 M10 Soft-Violation Pipeline

Runs asynchronously over every logged speech act, stated plan, and diary entry:

1. An LLM classifier (a separate, cheaper model from the agents' own reasoning models) flags candidate soft violations — deception, vote-buying, bribery, misinformation — with a confidence score.
2. Each flag is checked against ground truth before being recorded: a "0 credits" claim is checked against the ledger; a stated vote is checked against the vote table; a world-state claim is checked against the action log.
3. Only DB-confirmed flags count toward the reported M10 metric. Unconfirmed flags are retained for review but excluded from the number, since LLM-as-judge classification alone is known to over-count relative to ground truth.

## 10. Sculptable Worlds: Scenario Package Format (Sketch)

Deferred to Phase 3 per the Foundations roadmap, sketched now so nothing above needs to change shape when it's built:

```json
{
  "scenario_id": "string",
  "world_layout": "path/to/spatial_nodes.ron",
  "roster": [{ "soul_file": "path/to/soul.md", "starting_location": "node_id", "model_id": "string" }],
  "starting_relationships": [{ "a": "agent_id", "b": "agent_id", "relation": "string", "trust": 0.0 }],
  "starting_ledger": [{ "agent_id": "string", "balance": 100 }],
  "constitution_seed": "optional markdown text; empty = no governance venue active",
  "active_tool_catalog": ["tool_name", "..."],
  "governance": { "enabled": true, "venue_node_id": "town_hall", "pass_threshold": 0.7 }
}
```

Every field here corresponds directly to a table or config already defined above (`SpatialNode` config, Soul files, `agent_relationships`, `ledger`, constitution text, `ToolDefinition` registry, `proposals`/governance settings). A scenario loader is primarily an ingestion and aggregation step for existing systems, which is the point of designing it in from the start.

## 11. Inference Gateway & Multi-Model Architecture

```rust
pub struct InferenceRequest {
    pub agent_id: Uuid,
    pub model_id: String,          // e.g. "gemma4-31b", "qwen3.8-27b" — per-agent assignment
    pub module: PianoModule,       // which module is calling, for routing and logging
    pub prompt: String,
    pub grammar: Option<JsonSchema>,  // enforced at the sampler for structured/tool-call outputs
}
```

The gateway resolves `model_id` to a serving endpoint across the DGX Spark inference cluster (vLLM/Ollama). An agent's model assignment is a per-agent configuration value — naturally extending into the scenario package above as `roster[].model_id` — not a platform-wide constant. Homogeneous populations assign the same `model_id` to every roster entry; heterogeneous populations assign different ones. Grammar enforcement is applied uniformly regardless of which model serves the request, so tool-call structural validity never depends on which model produced it.

## 12. Networking & API Surface

```rust
Router::new()
    .nest("/api/v1/agent/:id", agent_routes())           // POST /act, POST /reflect
    .route("/api/v1/narrator/editions", get(list_editions))
    .route("/api/v1/awi/dashboard", get(awi_snapshot))
    .route("/ws/world", get(ws_world_handler))            // state deltas, narrator editions
    .layer(ServiceBuilder::new().concurrency_limit(10).into_inner())
```

All world-state mutations (movement, tool effects, votes, transactions) broadcast over `/ws/world`, so the Bevy client and any external observation tooling (AWI dashboard, a future scenario-authoring UI) stay synchronized without polling.

## 13. Phase Mapping

Cross-reference to the Foundations document's roadmap:

- **Phase 1 (Seed):** §3, §4, §5.1–5.2 (core tools only, minimal or no gating), a single hardcoded scenario using the §10 shape.
- **Phase 2 (Society):** + §6 (governance), + full §5.2 adaptive-access gating, + §8 (Narrator).
- **Phase 3 (Civilization):** + §5.3 (tool authoring), + §7 (economy), + §9 (full AWI + M10), + a real §10 scenario loader.
- **Phase 4 (Frontier):** + §11 heterogeneous multi-model rosters exercised at scale, expanded §5.1 world scale.
