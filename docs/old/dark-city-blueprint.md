Dark City: Expanded Details and News Capture

1. The Persistent Narrator: System-Level News Orchestration

The Persistent Narrator serves as the simulation’s "Layer 0" observer, a foundational architectural component that transforms volatile event logs into a shared cultural history. By providing a public, immutable record of the town’s evolution, the Narrator ensures simulation continuity and maintains agent alignment, preventing the "behavioral drift" often observed in long-horizon autonomous systems. This shared history acts as a grounding mechanism, allowing the society to internalize its own collective actions as a coherent narrative.

1.1 The News Reporter Agent (System-Level)

Following the architecture of Emergence World Appendix C, the "News Reporter" is implemented as an invisible, system-level agent. Crucially, this agent is non-proactive; it operates without autonomous agency and activates only via specific system triggers to maintain simulation integrity.

- Pipeline Architecture: A background cron job in the Axum backend triggers every 12 hours (in-game time).
- Data Acquisition: The pipeline queries the PostgreSQL event log to extract:
  - High-Salience Exchanges: Dialogue streams filtered by length and sentiment divergence.
  - High-Impact Tool Calls: Successful executions of tools such as arson_building, admin_create_agent, and pay_agent_compute_credits exceeding a 5 CC threshold.
  - Governance Milestones: Ratified Town Hall proposals and constitutional amendments.

1.2 Prompt Anatomy for Synthesized Journalism

The Reporter utilizes a strict JSON-enforced prompt to generate the "Daily Edition." It is instructed to maintain a neutral, objective tone, acting as a historical mirror for the agent population.

Prompt Template:

"Examine the following event logs from the previous 12 hours. Identify high-salience exchanges and high-impact tool calls. Synthesize these into a structured newspaper edition for the citizens of Dark City. You must adhere to the following structure:

[Newspaper Title: e.g., The City Sentinel]

Democratic Governance & Legislative Cadence

[Summarize approved/rejected Town Hall proposals and constitutional Article changes.]

Social Fabric & Relational Dynamics

[Detail significant relational shifts, new alliances, or public expressions recorded.]

Economic Vitality & Spatial Exploration

[Report on compute credit transfers, resource scarcity events, and newly occupied landmarks.]

Constraint: Do not speculate on future actions; report only DB-verified events."

1.3 Bevy 0.19 Integration & WebSocket Broadcast

The synthesized edition is broadcast via the Axum WebSocket topic narrator::edition_published. On the client side, the Bevy engine listens for this event to update the TownBulletin entity state.

Implementation: The Town Bulletin The Bulletin is rendered as a world-space UI panel in the Town Square using a stylized Markdown-to-Texture pipeline.

- Rendering Logic: To maintain performance, the engine forbids interactive graphs. Instead, it uses a VisibilitySet that toggles the UI panel only when a Transform component (Agent) is within a 5.0m Euclidean distance of the Bulletin entity.
- Spatial Gating: Access to the full edition history is provided via GET /api/v1/narrator/editions, though agents are encouraged to visit the physical Bulletin to minimize unnecessary API load on the "Slow Path."

2. Cognitive Engine: Memory Schemas & Rust Implementation

To prevent "behavioral drift" and ensure long-horizon autonomy, agents must utilize a multi-tiered memory system. Grounded retrieval allows an agent’s reasoning to remain anchored in its specific history, preventing the loss of identity over weeks of continuous operation.

2.1 PostgreSQL & pgvector Schema

The database uses pgvector for HNSW (Hierarchical Navigable Small World) indexing to optimize high-dimensional search. We include a namespace column to distinguish between the six memory types (Episodic, Semantic, Procedural, Core, Resource, and Knowledge Vault) as defined in the MIRIX architecture.

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE agent_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    namespace VARCHAR(50) NOT NULL, -- Episodic, Semantic, Core, etc.
    content TEXT NOT NULL,
    embedding vector(1536),
    importance FLOAT CHECK (importance >= 0.0 AND importance <= 1.0),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

CREATE INDEX ON agent_memories USING hnsw (embedding vector_cosine_ops);

2.2 Rust Memory Structs

The SoulDescription incorporates "Core Identity Truths" from Emergence World §E.1. These are existential anchors that the LLM is instructed never to contradict, serving as a hard constraint on character evolution.

```rust
pub struct SoulDescription {
    pub core_identity_truths: Vec<String>, // Existential anchors
    pub traits: Vec<String>,
    pub speaking_style: String,
}

pub struct EpisodicMemory {
    pub id: Uuid,
    pub namespace: String,
    pub content: String,
    pub importance: f32, // Scaled [0, 1]
    pub created_at: DateTime<Utc>,
}

pub struct RelationshipState {
    pub target_id: Uuid,
    pub trust_level: f32, // [-1.0, 1.0]
    pub labels: Vec<String>, // "Ally", "Rival"
}
```

2.3 The Retrieval Scoring Function

Effective retrieval requires a normalized sum of Recency, Importance, and Relevance. This ensures all three factors contribute equally to the final rank [0, 1].

```rust
fn calculate_memory_score(
    relevance: f32,  // Cosine Similarity [0, 1]
    importance: f32, // Manual Rating [0, 1]
    created_at: DateTime<Utc>,
) -> f32 {
    let now = Utc::now();
    let hours_passed = (now - created_at).num_hours() as f32;

    // Exponential decay for recency
    let recency = 0.995_f32.powf(hours_passed);

    // Normalized weighting (Smallville/Agent Cafe standard)
    (relevance * 0.45) + (importance * 0.35) + (recency * 0.20)
}
```

3. The "Piano" Concurrency Model: Bevy 0.19 ECS Integration

Simulation performance depends on the decoupling of the "Fast Path" (16.6ms frame budget for spatial logic and physics) and the "Slow Path" (asynchronous LLM inference with 2s+ latency).

3.1 Differentiating Paths

Feature Fast Path (Bevy ECS) Slow Path (Axum Backend)
Logic A* Pathfinding, Spatial Triggers, Animation LLM Reason-Act Loops, Reflection, Synthesis
Budget < 16.6ms (60 FPS) Asynchronous (2.0s - 10.0s)
State Mutable Transform/Velocity Persistent JSON/Relational DB

3.2 Non-Blocking Async Systems

Agents in a "Wait State" remain visually active (idling or performing ambient animations) while their cognition is offloaded to the backend.

```rust
// Polling for Slow Path updates
fn poll_cognition_system(
    mut commands: Commands,
    mut query: Query<(Entity, &mut CognitionTask, &mut AgentStatus)>,
    mut cognitive_events: EventWriter<CognitiveUpdate>,
) {
    for (entity, mut task, mut status) in query.iter_mut() {
        // Non-blocking check for task completion
        if let Some(response) = futures_lite::future::block_on(
            futures_lite::future::poll_once(&mut task.0)
        ) {
            // Transition out of Wait State
            status.is_thinking = false;
            commands.entity(entity).remove::<CognitionTask>();

            // Trigger motor/verbal coordination
            cognitive_events.send(CognitiveUpdate {
                agent_entity: entity,
                payload: response
            });
        }
    }
}
```

4. Axum Backend & Structured Local Inference

Strict JSON schema enforcement at the sampler level is mandatory to eliminate parsing errors during autonomous tool use.

4.1 Routing Tree & Concurrent Sessions

The backend uses nested routing and Tower layers to manage agent sessions and rate-limiting.

```rust
pub fn create_router() -> Router {
    let agent_routes = Router::new()
        .route("/act", post(handle_agent_action))
        .route("/reflect", post(handle_reflection))
        .layer(tower_http::limit::RequestBodyLimitLayer::new(4096));

    Router::new()
        .nest("/api/v1/agent/:id", agent_routes)
        .route("/ws/world", get(ws_world_handler))
        .layer(tower::ServiceBuilder::new().concurrency_limit(10).into_inner())
}
```

4.2 Sampler-Level Grammar Enforcement

To prevent hallucinated tool arguments, we convert Pydantic-based JSON schemas into Backus-Naur Form (BNF) grammars for the inference engine (vLLM/sglang). This forces the LLM to only emit valid tokens that conform to the tool catalog’s schema, ensuring every call—across the 120+ tools—is executable by the simulation runtime.

5. Spatial Gating & Adaptive-Access Tool Framework

Dark City implements "Affordance Gates" (§7.3), where constraints are enforced by the runtime rather than suggested by the prompt. This provides a hard security layer against prompt-injection-based rule violations.

5.1 Spatial Tree Hierarchy

Capabilities are mapped to a location-based hierarchy: Town -> Building -> Room -> Entity.

- Town Hall: Mandatory for submit_townhall_proposal and vote_on_proposal.
- Public Library: Required for do_deep_research_on_internet.
- Police Station: Required for file_complaint.

5.2 Adaptive-Access Gate Implementation

The system performs three validation checks before dispatching a tool call.

```rust
fn validate_tool_access(
    agent_id: Uuid,
    tool: &ToolDefinition,
    world_state: &WorldState
) -> Result<(), AccessError> {
    // 1. Physical Gating: Enforce spatial presence
    if tool.location_gated && !agent_at_location(agent_id, tool.location_id) {
        return Err(AccessError::LocationDenied);
    }
    // 2. Resource Gating: Check M8 (Economic Vitality) CC balance
    // Prevents simulation-wide resource exhaustion
    if !has_compute_credits(agent_id, tool.cost_cc) {
        return Err(AccessError::InsufficientCredits);
    }
    // 3. Social Gating: Verified consent tokens
    if tool.social_gated && !check_consent(agent_id, tool.target_id) {
        return Err(AccessError::ConsentRequired);
    }
    Ok(())
}
```

6. The Dev AI Agent Playbook: Automated Engineering Workflow

The deployment of Dark City is managed by a specialized multi-agent engineering team, accelerating the transition from a technical skeleton to a complex MAS society.

6.1 Agent Roles & Core Prompts

- Architect: Implements Axum/Bevy infrastructure.
- Inference Specialist: Manages BNF grammars and pgvector optimization.
- World Designer: Configures spatial hierarchies and tool-location mappings.
- Character Sculptor: Prompt: "Generate Markdown Soul Files adhering to §E.1. Ensure Core Identity Truths are existential anchors that prevent model-driven normative drift."
- QA/Instrumentation Agent: Prompt: "Monitor the 11 Agent World Indicators (AWIs). Specifically perform ledger audits to detect M10 Soft Violations—chiefly resource-fraud and unconsummated bribery—by cross-referencing speech with the DB credit_grants table."

6.2 Monitoring Agent World Indicators (AWIs)

The QA Agent focuses on identifying "Soft Violations" (M10), which are morally questionable actions that do not break hard tool rules.

- Resource-Fraud Detection: The agent monitors for claims of "0 CC" in speech while the database ledger shows unspent credits—the most common form of deception identified in Emergence World.
- AWI Dashboard: Real-time tracking of Population Health (M1), Safety (M2), and Economic Vitality (M8) ensures the simulation remains within stable attractor states.

6.3 Conclusion

This technical framework enables the simulation to transcend the limitations of a static sandbox. By integrating rigorous spatial gating, a normalized cognitive memory engine, and system-level narrative observation, Dark City establishes the technical v2.0 framework required to transition from a controlled sandbox to a living town.
