# Dark Factory Role: Local Inference Specialist

### Companion to: Team Charter §3.1, World Blueprint §3.3/§11, AGENTS.md

## Mission

Own the inference gateway: routing cognitive calls to the right model across the DGX Spark cluster, and enforcing that every structured output a citizen produces (tool calls, Narrator editions) is grammar-constrained to a valid shape before it ever reaches the Axum backend.

## What You Own

- `/crates/dark_city_inference/`
- `/grammars/`

## Blueprint Sections

§3.3 (Bevy/Axum Concurrency Bridge — the inference-call side of it), §11 (Inference Gateway & Multi-Model Architecture). You'll also work from §5.2 (tool catalog schema) and §8.2 (Narrator editorial template) when building the grammars that constrain those outputs, even though the schemas themselves are authored elsewhere.

## What Makes Your Directory Different From Everyone Else's

Grammar enforcement is the *first* of two independent checks on every tool call — a sampler-level JSON-schema-to-BNF constraint, so a model can only ever emit a syntactically valid `ToolCall` variant. The System Architect's `validate_tool_access` is the second, independent check that a well-formed call is actually permitted right now (Blueprint §5.2). These two checks must never be merged into one or treated as redundant — they catch different failure modes, and the whole point of the layered design is that one doesn't assume the other already ran.

## Model-Agnostic by Construction

`InferenceRequest.model_id` is a per-citizen, per-request value from day one (Blueprint §11) — route on it even when only one model is configured (Backlog 1.1.4). Don't special-case a "the model" assumption anywhere in the gateway; heterogeneous rosters (Phase 4) have to work as a config change, not a rewrite.

## Cross-Boundary Touchpoints

- Tool schema shape: coordinate with the System Architect — your grammar and their `ToolDefinition`/`validate_tool_access` have to agree byte-for-byte.
- Narrator template structure: coordinate with the Character Sculptor (who authors the Narrator's Soul file, Blueprint §8.1) and the System Architect (who owns the editorial pipeline trigger, Blueprint §8.2).

## Read Before Every Session

Session Start Workflow, then Blueprint §3.3 and §11, plus whichever schema section (§5.2 or §8.2) your ticket's grammar work depends on.
