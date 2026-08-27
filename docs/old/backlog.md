Dark City Development Backlog & Story Catalog v2.0

1. Strategic Context & Architecture Blueprint Integration

The "Dark City" architecture is engineered to resolve the fundamental "slow-path" bottleneck inherent in multi-agent simulations driven by Large Language Models (LLMs). By implementing the PIANO (Parallel Input/Information Aggregation via Neural Orchestration) model, we decouple the high-latency reasoning loops of the "mind engine" from the 60 FPS "fast-path" spatial simulation in Bevy. The backend, built on Axum and Tokio, serves as a high-concurrency stateless inference orchestration layer, ensuring that every cognitive task is offloaded from the main render thread. This separation allows for high-performance local inference—enforced by structured grammar-sampling—without sacrificing the real-time responsiveness required for a 3D environment with 40+ grounded locations.

System Hierarchy Map

Component Technology Primary Role Inter-service Protocol
Inference Gateway VLLM / Ollama Stateless inference with grammar-enforced JSON sampling. REST / gRPC
Mind Registry Axum / Tokio Async task orchestration, WebSocket state management, and tool verification. WSS / REST
Persistent Storage Postgres / pgvector Vectorized episodic memory (HNSW), relational states, and the credit ledger. SQL (TCP)
Spatial Engine Bevy 0.19 (ECS) 3D rendering, PIANO task pool management, and spatial grounding. Bevy AsyncComputeTaskPool

Internal Development Agent Roles

- System Architect: Substrate engineering, including database schema, Axum middleware, and the Tokio channel orchestration.
- Local Inference Specialist: LLM gateway integration, JSON-schema grammar enforcement, and prompt-to-struct mapping.
- World Designer: Bevy ECS systems, spatial hierarchy using bevy_spatial, and A* navigation for the 40+ distinct landmarks.
- Character Sculptor: Authorship of Markdown "Soul Files," hierarchical planning loops (Day->Hour->Minute), and personality stability.
- QA/Instrumentation Agent: Development of the AWI (Agent World Indicators) pipeline and the M10 soft-violation ground-truth audit.

This substrate provides the foundational reliability required for long-horizon agent processing and economic state enforcement.

2. Epic 1: Axum Backend & High-Performance Local Inference Gateway

The gateway acts as the simulation's central nervous system. Its primary strategic objective is ensuring that LLM latency never compromises world-state integrity. We utilize structured JSON sampling to eliminate "hallucinations of capability" at the boundary layer. By forcing LLM outputs into strictly typed Rust structs, we ensure that the Mind Engine can only attempt actions that exist within the simulation's tool manifest.

ID Title Role/Goal Gherkin AC Est. Responsible
1.1 Database & pgvector Provisioning As a System Architect, I want to provision Postgres with pgvector so that high-dimensional agent memories are indexed for salient retrieval. Given a Postgres 16 instance, When pgvector is enabled and memories table is indexed with HNSW, Then cosine similarity queries must execute in < 50ms for 1k+ vectors. 3 System Architect
1.2 Structured JSON Sampling Gateway As a Local Inference Specialist, I want to implement a VLLM wrapper that enforces JSON schemas so that agent tool calls are type-safe. When a prompt is sent to /inference, Then the response must satisfy the ToolCall schema and pass serde deserialization with zero field-drift. 5 Local Inference Specialist
1.3 Connection State & Async Pipeline As a System Architect, I want to manage WebSocket connections and Tokio channels so the world state updates in real-time. Given multiple active Bevy clients, When an agent completes a cognitive loop, Then the state change is broadcasted via WSS to all relevant observers. 8 System Architect

Technical Notes (Story 1.1 - 1.2):

```sql
-- STORY-1.1: Optimized Vector Storage
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536),
    importance INT DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON memories USING hnsw (embedding vector_cosine_ops);
```

```rust
// STORY-1.2: Grammar-Enforced Tool Schema
#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "tool_name", content = "arguments")]
pub enum ToolCall {
    #[serde(rename = "go_to_place")]
    GoToPlace { place_id: String },
    #[serde(rename = "pay_agent")]
    PayAgent { target_id: Uuid, amount: i32 },
    #[serde(rename = "punch_agent")]
    PunchAgent { target_id: Uuid, message: String },
}
```

3. Epic 2: The Cognitive Mind Engine

The mind engine leverages the "Smallville" three-tier memory architecture (Episodic, Reflective, Relational) to prevent cognitive drift. Stability is achieved by synthesizing raw experiences into reflective diaries, ensuring agents maintain long-term purposeful trajectories rather than merely reacting to immediate environmental stimuli.

ID Title Role/Goal Gherkin AC Est. Responsible
2.1 Markdown 'Soul File' Parser As a Character Sculptor, I want to parse Markdown soul files into system prompts to ensure persistent agent identity. Given a .md soul file, When the agent initializes, Then the persona metadata (role, traits) is injected into the LLM system prompt. 2 Character Sculptor
2.2 Salient Memory Retrieval As a System Architect, I want to implement a weighted scoring algorithm (R/I/Relevance) to simulate human-like recall. When an agent queries memory, Then the results must be sorted by the product of Recency, Importance, and Cosine Similarity calculated in-database. 5 System Architect
2.3 Hierarchical Planning Loop As a Character Sculptor, I want a nested planning loop (Day/Hour/Min) to drive purposeful long-horizon behavior. When the simulation day starts, Then the agent must generate a Plan object that is progressively refined into atomic Action units. 8 Character Sculptor

Technical Notes (Story 2.2): The retrieval score must be computed on the database side to handle high-dimensional vectors efficiently.

```sql
-- Weighted Retrieval Formula
SELECT content,
  (importance *
  (1.0 / (EXTRACT(EPOCH FROM (NOW() - created_at))/3600 + 1)) *
  (1 - (embedding <=> $1))) AS salient_score
FROM memories
WHERE agent_id = $2
ORDER BY salient_score DESC LIMIT 10;
```

4. Epic 3: Bevy 0.19 Spatial Environment & PIANO Concurrency

Strategic separation of the "fast-path" (60 FPS rendering/movement) from the "slow-path" (LLM reasoning) is handled within Bevy. PIANO allows the simulation to remain visually fluid while agents wait for 10-second inference windows.

ID Title Role/Goal Gherkin AC Est. Responsible
3.1 ECS Spatial Hierarchy As a World Designer, I want to map 40+ locations using bevy_spatial to calculate agent proximity efficiently. Given the town map, When an agent moves, Then its Transform component updates in the spatial index with zero frame-latency. 5 World Designer
3.2 PIANO AsyncCompute Implementation As a System Architect, I want to offload cognitive calls to the async task pool to prevent main-thread hangs. When an agent decides to "Think," Then a task is spawned in AsyncComputeTaskPool and the main loop continues at 60 FPS. 13 System Architect
3.3 A Navigation & Map Sync* As a World Designer, I want to implement A* pathfinding so agents can autonomously navigate the 40 locations. When an agent receives a place_id, Then it must calculate a valid path and translate it into a sequence of MoveTo commands. 5 World Designer

Technical Notes (Story 3.2):

```rust
// Offloading LLM reasoning using Bevy's AsyncComputeTaskPool
fn agent_thinking_system(mut commands: Commands, thread_pool: Res<AsyncComputeTaskPool>) {
    let task = thread_pool.spawn(async move {
        let response = perform_inference(prompt).await?;
        Ok(response)
    });
    commands.spawn(ThinkingTask(task));
}
```

5. Epic 4: Adaptive-Access Tool Gates & Economic State

Affordance gates are the simulation's primary defense against "magical actions." By resource-gating tool access (energy, credits, location), we enforce the physical constraints necessary for the tool-use economy to emerge.

ID Title Role/Goal Gherkin AC Est. Responsible
4.1 Adaptive-Access Enforcement As a System Architect, I want the API to verify coordinates/energy before tool execution to prevent hallucinations. Given an agent at 'Library', When they call submit_proposal (Town Hall gated), Then the API must return a 403 Forbidden error. 5 System Architect
4.2 Atomic Credit Ledger As a World Designer, I want to implement atomic transaction logs to provide a ground-truth economic substrate. When a credit transfer occurs, Then the Postgres ledger must update atomically via a SQL transaction to prevent double-spending. 3 World Designer
4.3 Proximity-Based WSS Broadcast As a QA Agent, I want to restrict speech to co-located agents to simulate natural information propagation. When Agent A calls say_to_agent, Then only agents within a 10-unit spatial radius receive the WSS event. 3 QA Agent

6. Epic 5: Democratic Governance & Town Hall Institutions

Governance moves the simulation from a static sandbox to an evolving civilization. Irreversible state changes through supermajority voting create a high-stakes environment where agent decisions have historical consequences.

ID Title Role/Goal Gherkin AC Est. Responsible
5.1 Town Hall Entity Lifecycle As a System Architect, I want a Proposal entity to manage world-rule changes. When an agent calls submit_proposal, Then a record is created with Awaiting status and explicit vote counters. 5 System Architect
5.2 Supermajority Logic (70%) As a QA Agent, I want to enforce consensus-based rule changes. Given a proposal, When 70% of active agents vote 'For', Then the status automatically transitions to 'Passed'. 5 QA Agent
5.3 Irreversible State Handlers As a System Architect, I want hooks to register new tools upon proposal passage. When a "New Tool" proposal passes, Then the tool is dynamically added to the Adaptive-Access registry. 8 System Architect

Technical Notes (Story 5.1):

```rust
struct Proposal {
    id: Uuid,
    title: String,
    category: String,
    status: ProposalStatus, // Awaiting, Passed, Rejected, Implemented
    votes_for: i32,
    votes_against: i32,
    created_at: DateTime<Utc>,
}
```

7. Epic 6: The Persistent Narrator & World Chronicles

The Narrator compiles the raw "field" actions of agents into a public record. This collective memory enhances social cohesion by providing a shared narrative that agents can reference in future discussions.

ID Title Role/Goal Gherkin AC Est. Responsible
6.1 Daily Event Compiler As a System Architect, I want a background service to aggregate logs into daily event summaries. When the daily cron runs, Then it produces a structured JSON of all significant deaths, votes, and economic shifts. 3 System Architect
6.2 World Chronicles Generation As a QA Agent, I want to use a "News Reporter" persona to write engaging world history. Given the daily summary, When the News Agent is prompted, Then it returns a thematic Markdown newspaper. 2 QA Agent
6.3 3D Bulletin Board Renderer As a World Designer, I want to render the Chronicles in-world for agent observation. When a new edition is published, Then the text2d component on the Town Hall board is updated. 5 World Designer

8. Epic 7: Instrumentation & Agent World Indicators (AWI)

The AWI dashboard transforms the simulation into a research instrument. By applying post-hoc LLM classification with a ground-truth audit, we can measure the "soft" health of the civilization, such as deception or normative drift.

ID Title Role/Goal Gherkin AC Est. Responsible
7.1 Post-Hoc AWI Classification As a QA Agent, I want to classify actions (M10: Soft Violations) with a ground-truth audit against the ledger. Given a log entry flagged as 'Deception', When audited, Then it must be verified against the credit_grants table before scoring. 8 QA Agent
7.2 Real-time Gini/Velocity Metrics As a QA Agent, I want to track transaction velocity and wealth inequality (Gini). When the dashboard loads, Then it must display a live Gini coefficient calculated via SQL aggregation. 5 QA Agent
7.3 Shock Simulation Framework As a QA Agent, I want to trigger "Black Swan" events via API to test population resilience. When a /admin/shock event is triggered, Then agents must perceive the state change and respond via the Mind Engine. 5 QA Agent

Technical Notes (Story 7.1): LLM-as-judge is notoriously noisy (over-counting by ~2x). The pipeline must perform a "Ledger Audit" where a claim like "I have zero credits" is verified against the database balance before being recorded as a violation.

9. Backlog Summary & Deployment Roadmap

All development must adhere to standard Rust clippy guidelines and maintain strict Markdown consistency for ingestion.

Epic Story Effort (Points) Responsibility Pre-requisite
Epic 1 1.1 DB Provisioning 3 System Architect -
1.2 JSON Gateway 5 Inference Specialist -
1.3 Async Pipeline 8 System Architect 1.2
Epic 2 2.1 Soul Parser 2 Character Sculptor -
2.2 Memory Scoring 5 System Architect 1.1
2.3 Planning Loop 8 Character Sculptor 2.1
Epic 3 3.1 Spatial ECS 5 World Designer -
3.2 PIANO Pool 13 System Architect 1.3
3.3 A* Pathfinding 5 World Designer 3.1
Epic 4 4.1 Adaptive Gates 5 System Architect 1.3, 3.1
4.2 Credit Ledger 3 World Designer 1.1
4.3 Proximity Chat 3 QA Agent 3.1
Epic 5 5.1 Town Hall 5 System Architect 1.1
5.2 Voting Logic 5 QA Agent 5.1
5.3 State Handlers 8 System Architect 4.1, 5.2
Epic 6 6.1 Event Compiler 3 System Architect 1.1
6.2 News Agent 2 QA Agent 6.1
6.3 3D Bulletin 5 World Designer 6.2
Epic 7 7.1 AWI Classifier 8 QA Agent 4.2, 6.1
7.2 Metric Dashboard 5 QA Agent 7.1
7.3 Shock Simulation 5 QA Agent 4.1

The implementation of the AWI dashboard serves as the final validation of the simulation's long-horizon autonomy and emergent social stability.
