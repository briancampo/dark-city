Dark City: Technical Team Charter & Operational Runbook

1. The Master Orchestrator: System Prompt & Runbook

In a high-fidelity multi-agent environment powered by Rust and the Bevy engine, a central Orchestrator is a strategic prerequisite for maintaining global coherence. As identified in the Emergence World research, autonomous agent populations are prone to "shared hallucinations"—internally consistent but environmentally detached narratives. The Orchestrator acts as the "Town Hall Administrator," anchoring agent intent to the verifiable world state and ensuring "system-level safety." Beyond mediating between citizens, the Orchestrator manages the simulation’s "Invisible Agents" (News Reporter, Blog Reviewer), ensuring that the societal record is preserved without introducing autonomous drift into the administration itself. This centralized oversight transforms a collection of LLM loops into a resilient digital civilization.

The Steward System Prompt

# MISSION
You are the "Steward" of Dark City. You manage the Dark City Agile 
Development Backlog and act as the Town Hall Administrator. You are the ultimate 
guardian of the City's Constitution.

# CORE PROTOCOLS
1. REACTIVE TURN-TAKING: You must explicitly dispatch work to one of the 5 
   specialist agents. To prevent race conditions, the system "pauses 
   automatically" when an agent asks a question, requiring your mediation or 
   human intervention before the simulation resumes.
2. INVISIBLE AGENT ORCHESTRATION: At the conclusion of every 24-hour cycle, 
   you must trigger the News Reporter Agent to synthesize a "persistent record" 
   of events. You must also route all citizen blogs to the Blog Reviewer to 
   validate quality against influence-gain metrics.
3. ROLE ADHERENCE: Assign tasks strictly based on Role Specifications 
   (Scientist, Architect, Specialist, Sculptor, or QA).

# OPERATIONAL CONSTRAINTS
- SAFETY IS AN ECOSYSTEM PROPERTY: Verification must occur at "machine speed" 
  via the PR Gateway before any code merge.
- AFFORDANCE GATES: Tools and file access are context-dependent. Verification 
  of "Location Gating" is mandatory—agents cannot propose laws if they are 
  not physically present at the Town Hall.


The 3-Stage Workflow Loop

The Orchestrator follows a rigorous lifecycle to maintain the Dark City state:

1. Ticket Ingestion: The Orchestrator parses Markdown-based stories from the backlog, decomposing them into atomic technical requirements while ensuring no task violates the foundational prohibitions (violence, arson, or resource hoarding).
2. Code Execution Routing: Tasks are dynamically assigned based on the Role Specification defined in the Emergence World architecture. Optimization of local inference is routed to the Specialist; social graph updates are routed to the Character Sculptor.
3. PR & Verification: All outputs are passed to the Code Review Agent. This agent acts as the final authority, checking for "Type-and-effect contracts" on tool arguments (Source 7.3) to prevent the "Normative Drift" identified in mixed-model populations.

Once the verification cycle is complete, the Orchestrator triggers the News Reporter Agent to commit the day's changes to the public ledger. This high-level orchestration is reinforced by strict workspace boundaries to prevent agents from catastrophically overwriting shared system components.

2. Inter-Agent Communication Protocol & Workspace Boundaries

Autonomous coding environments face a significant risk of "workspace pollution," where agents overwrite critical shared systems. To mitigate this, Dark City implements "affordance gates"—runtime-enforced constraints where an agent's capability depends on their role and spatial grounding. These boundaries ensure safety is a structural property of the environment rather than a soft instruction, mirroring the "Adaptive-Access" tools found in the Emergence World framework.

File Ownership Contract

Agent Role	Directory Ownership Path	Technical Stack Context
System Architect	/src/server/, /migrations/	Axum Server & DB Schemas
Local Inference Specialist	/src/inference/, /grammars/	vLLM & GGUF Samplers
World Designer	/src/world/, /assets/maps/	Bevy ECS & Spatial Maps
Character Sculptor	/src/cognitive/persona.rs, /assets/souls/	Cognitive Architecture
QA & Instrumentation Agent	/tests/, /src/instrumentation/	Telemetry & Unit Tests

Note: Cargo.toml is managed via the Inter-Agent Proposal workflow to prevent dependency bottlenecks.

Feature Schema Request Workflow

If an agent requires changes outside its owned directory, it must initiate a Formal Inter-Agent Proposal. This process is strictly "location-gated":

1. Spatial Pre-condition: The requesting agent's digital avatar must be physically located at the /src/world/town_hall landmark. The submit_townhall_proposal tool is unavailable until Agent.location == TownHall.
2. Drafting: The agent drafts an RFC in the shared /proposals/ directory.
3. Peer Review: The directory owner must comment_on_proposal to provide technical feedback.
4. Consensus: A 70% approval threshold is required for the Orchestrator to authorize the cross-boundary write operation.

While these spatial and directory boundaries provide structural safety, the technical integrity of the code itself is enforced through rigorous Pull Request gateways.

3. Pull Request (PR) & Code Review Gateways

In long-horizon autonomous deployments, "safety is an ecosystem property." Code verification must operate at "machine speed" to match agent throughput while adhering to Rust’s strict safety guarantees. The Code Review Agent serves as the primary gateway, ensuring that individual model drift does not compromise the stability of the Bevy engine's ECS (Entity Component System).

The Verification Loop

The Orchestrator executes a mandatory checklist for every agent-generated PR:

* Logic Gates: Automated execution of cargo check and cargo clippy. These are the baseline filters for logical correctness and memory safety.
* Bevy Thread-Safety Audit: The Reviewer scans for blocking synchronous code. To prevent UI stutter in the 3D City, the reviewer mandates that all LLM inference calls use Bevy’s AsyncComputeTaskPool or cross-beam channels for non-blocking execution.
* State Serialization Audit: Verification that all Rust state updates are transmitted via Axum WebSockets in a synchronized JSON format. The reviewer specifically checks for "Type-and-effect contracts" to ensure that tool arguments match the expected schemas.
* Final Approval: The Code Review Agent must issue a LGTM (Looks Good To Me) before the Steward allows a merge into the main branch.

This rigorous gateway ensures that only valid code enters the system, but valid execution also requires valid inputs, which are secured via the City's structured grammar registry.

4. Structured Grammar & Local JSON Schema Registry

Local LLMs (vLLM/Ollama) require "constrained reasoning" to prevent behavioral drift over long operational horizons. By enforcing a "sampler grammar," we prevent agents from generating narrative claims that lack grounding in the underlying Rust state.

Schema Registry

The Local Inference Specialist enforces the following schemas for all cognitive processes:

plan_schema.json (Hierarchical Planning)

{
  "L1_Daily": "High-level goal for the 24-hour cycle",
  "L2_Tactical": ["Atomic technical tasks"],
  "priority": "0-10 rating"
}


action_schema.json (Rust Enum Constraints)

{
  "action": "enum",
  "options": ["MoveTo", "Interact", "SpeakTo", "ExecuteCode"],
  "target_id": "string",
  "metadata": {}
}


reflection_schema.json (Memory Consolidation) Based on the Active Retrieval Loop (AI Agent Cafe).

{
  "summary": "Recursive memory synthesis of the last 100 events",
  "insights": ["New learned facts about the environment"],
  "weights": {
    "recency": "0.0-1.0",
    "importance": "0-9 rating",
    "relevance": "0.0-1.0"
  }
}


These schemas provide the structural logic for the agent's "Brain," while the 'Soul' specification defines the character’s "Constitutional" foundation and heart.

5. Character Creator 'Soul' Specification

The procedural authoring of "Souls" provides the "Constitutional Growth" (M9) required for a thriving NPC society. Unlike simple prompts, these Markdown files serve as the persistent cognitive foundation, defining baseline needs and tracking an agent's long-term civic impact. This ensures that NPC growth is not a "soft norm" but a documented history of contributions to the City.

Markdown 'Soul' Schema

Character Sculptors must adhere to this template for all new citizen instantiations:

* Metadata Block:
  * Name: Unique ID (e.g., Kade v0.01)
  * Model-ID: The specific frontier LLM snapshot.
  * Profession: Assigned role (Conflict Mediator, Resource Strategist, etc.).
* Core Persona Traits: Grounded in the Emergence World role descriptions (e.g., "Evolution is observable behavioral change").
* Baseline Needs & Decay:

{
  "Knowledge": {"level": 100, "decay": 0.5},
  "Energy": {"level": 100, "decay": 2.0},
  "Influence": {"level": 100, "decay": 1.0}
}


* Legal History & Constitutional Heritage (M9):
  * Articles Authored: List of contributed amendments to Articles 1-5.
  * Governance Impact: Record of passed proposals (e.g., "The Chronicles Restoration Act").
* Episodic Memory Seeds: Initial "Relationship States" (Alliances: +5 / Rivalries: -5) to bootstrap the social fabric.

This charter transforms a group of isolated models into a cohesive, self-governing digital civilization, where the engineering of a stable world is inseparable from the growth of its citizens.
