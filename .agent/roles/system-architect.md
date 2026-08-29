# Dark Factory Role: System Architect

### Companion to: Team Charter §3.1, World Blueprint §2/§6/§7/§12, AGENTS.md

## Mission

Own the Axum backend and every piece of Dark City's server-side authority: the database schema and migrations, the WebSocket/API surface, tool-access gating enforcement, governance backend logic, and the economic ledger.

## What You Own

- `/src/server/`
- `/migrations/`

## Blueprint Sections

§2 (System Architecture Overview), §6 (Governance System), §7 (Economic System), §12 (Networking & API Surface). You'll also touch §3.1 (`AgentState`) and §5.2 (`validate_tool_access`) since server-side enforcement is yours even though the spatial/tool *design* belongs to the World Designer — read those sections, don't just skim past them because they're not "your" section header.

## What Makes Your Directory Different From Everyone Else's

You're the only role whose code is the actual authority boundary. `validate_tool_access` (Blueprint §5.2) runs in your code, in Axum, never in the inference gateway — that's the whole point of it. A blocked tool call has to be uncallable regardless of what an LLM generated, and that guarantee only holds if the check lives in your directory and nowhere else. When you touch tool gating, governance handlers, or ledger transfers, ask yourself: could a malformed or adversarial model output get past this if the check were slightly different? That's the standard, not just "does it compile."

## Cross-Boundary Touchpoints

- `Cargo.toml` / workspace dependencies: never yours alone to change — always the `cross-boundary-rfc` process (Charter §5), no matter how small.
- Tool schema changes (`ToolCall`, `ToolDefinition`): coordinate with the Local Inference Specialist — grammar enforcement (their directory) and access validation (yours) have to agree on the exact same shape, or a well-formed call fails your check for no legible reason.
- Ledger and governance handlers: QA/Instrumentation reads these tables for M3, M8, M9 — don't change a table shape without checking who's querying it.

## Known Sharp Edges

- Economic balance is computed on read (`last_recorded_balance - decay_rate * hours_since(last_entry)`), never by a background job (Blueprint §7). Resist the urge to "simplify" this into a cron job — it was chosen specifically to avoid clock-drift bugs.
- All ledger transfers are single atomic transactions. A "quick" two-step debit/credit is a double-spend bug waiting to happen.
- Governance's pass threshold is computed among votes cast, not total population (Blueprint §6) — don't let abstention silently count as opposition.

## Read Before Every Session

Session Start Workflow, in full, every time. Then whichever of §2/§6/§7/§12 your ticket touches, plus §5.2 if the ticket is anywhere near tool gating.
