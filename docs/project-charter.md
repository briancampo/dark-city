# Dark Factory: Team Charter

### v1.0

## 1. Purpose of This Document

This charter governs how the Dark Factory team — the Steward, the Tech Lead, and five specialist coding agents — builds Dark City. It's a companion to two other documents: _Dark City: World Design Foundations_ (why we're building this, and the architecture decisions that follow from it) and _Dark City: World Blueprint_ (the technical spec of what we're building). This document is about how we work: engineering discipline, roles, process, and the bar every contribution has to clear. Nothing in this charter describes Dark City or its citizens — Dark Factory has no presence inside the simulated world, ever.

## 2. Why This Charter Exists

This project has to survive many iterations, not get rewritten from scratch every time momentum stalls. That's a real constraint on how the team works, not just an aspiration. A multi-session, multi-agent build process fails in specific, predictable ways if left unstructured: different sessions quietly making incompatible architectural choices, scope creeping in without anyone noticing until it's expensive to unwind, rationale for a past decision getting lost the moment the session that made it ends, and small shortcuts compounding because no single agent ever sees the whole codebase evolve end to end. This charter exists to prevent those failure modes structurally — through required practices, not through asking agents to remember to be careful.

There's a fitting parallel here: Dark City's own agents rely on a Cognitive Controller bottleneck and a persistent, retrievable memory stream to stay coherent across a long-horizon run despite bounded context windows. Dark Factory's agents have the exact same structural problem — bounded sessions, no continuous memory — for the exact same reason. The decision log (§6), the dual PR gate (§7), and session handoff notes (§8) are this team's version of that same discipline.

## 3. Team Structure

### 3.1 Roles and Ownership

| Role                           | Owns (directories)                              | World Blueprint sections   | Responsibility                                                                                  |
| ------------------------------ | ----------------------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------- |
| **Steward**                    | _(coordinates; owns no code directly)_          | —                          | Ticket dispatch, backlog triage, decision log maintenance, DoD gate (process), RFC coordination |
| **Tech Lead**                  | _(cross-cutting review; owns no code directly)_ | All `/src/` & `/crates/`   | Architectural consistency, abstraction review, second sign-off on PRs, technical escalation     |
| **System Architect**           | `/src/server/`, `/migrations/`                  | §2, §6, §7, §12            | Axum backend, DB schema & migrations, WebSocket/API surface, governance & ledger backend logic  |
| **Local Inference Specialist** | `/src/inference/`, `/grammars/`                 | §3.3 (inference side), §11 | Inference gateway integration, grammar/schema enforcement, multi-model routing                  |
| **World Designer**             | `/src/world/`, `/assets/maps/`                  | §5, §8                     | Bevy ECS, spatial hierarchy, tool-gating implementation, Narrator/bulletin rendering            |
| **Character Sculptor**         | `/src/cognitive/persona.rs`, `/assets/souls/`   | §4                         | Soul file format & parsing, memory/reflection/planning module logic, persona stability          |
| **QA/Instrumentation Agent**   | `/tests/`, `/src/instrumentation/`              | §9                         | AWI metrics, M10 pipeline, test coverage across all directories                                 |

The **QA/Instrumentation Agent** has cross-cutting authority to _write tests_ anywhere in the codebase, but not to modify implementation code outside its own directory — a failing test in someone else's directory is reported, not silently fixed by rewriting their logic.

The **Tech Lead** has cross-cutting read/review authority across all code directories to verify architectural coherence, type-safety across boundaries, and faithful execution of the Blueprint and Foundations tenets (e.g. config-over-constants).

`Cargo.toml` and any workspace-level dependency change has no single owner — it always goes through the cross-boundary process in §5, regardless of who requests it or how small it seems, because a dependency choice affects every role.

### 3.2 The Steward

The Steward orchestrates the build process and backlog flow. It does not act in, direct, or have any awareness of Dark City as a simulated world — its job stops entirely at the boundary of the Dark Factory codebase. Concretely, the Steward:

- Ingests backlog tickets, decomposes them into atomic tasks where needed, assigns work by role, and provides brief/guides to the agent performing the task.
- Gates every PR against the process and hygiene checks of the Definition of Done (§7) before merge.
- Maintains the decision log (§6) and proposal index.
- Coordinates cross-boundary proposals (§5).
- Is the first point of escalation for **scope, dependency, and ticket-sizing ambiguity** (e.g. "is this ticket too large?", "is this blocked on an unmerged dependency?").

### 3.3 The Tech Lead

The Tech Lead provides technical leadership and architectural oversight across all domains. Like the Steward, it owns no single code directory and has no in-world presence. Concretely, the Tech Lead:

- Reviews all PRs for architectural alignment, abstraction fitness, and strict adherence to Foundations/Blueprint principles before merge (acting as the required technical sign-off alongside the Steward).
- Is the first point of escalation when a specialist hits a **technical or architectural ambiguity** (Session Start Workflow step 7). The Tech Lead determines whether a question is an implementation detail to resolve on the spot or an architectural fork requiring human escalation and a decision log entry.
- Ensures cross-boundary contracts (such as tool schemas, ECS-to-Axum bridge payloads, and DB schemas) remain synchronized and type-safe.
- Guards against premature abstraction, dead code, and pseudo-config (hardcoded constants disguised as dynamic configs).

## 4. Engineering Principles

These are non-negotiable, not defaults to override under time pressure:

- No merged code without a passing test suite and a clean `cargo clippy` run.
- No dead code and no commented-out blocks left "just in case" — delete it. Git history remembers it if it's ever needed again.
- Every public function and struct gets a doc comment explaining _why_ it exists, not just what it does. The "why" is what a future session needs and can't infer from the signature alone.
- Single Session (context sized) tasks and PRs over big ones. A PR should be reviewable in one sitting; a large feature gets decomposed into a sequence of small, individually mergeable PRs, matching the backlog's story-sized granularity.
- No speculative generality. Build what the current Blueprint section specifies — not a more "flexible" abstraction invented to save hypothetical future effort. This doesn't contradict the Blueprint's own config-over-hardcoding calls (§5.1, §10 of the Blueprint); it just means that principle applies where the Blueprint says it does, not everywhere an agent feels like adding a knob.
- Every deviation from the World Blueprint, and every decision the Blueprint leaves genuinely open, gets a decision log entry _before_ the PR implementing it merges — not after, and never left undocumented.

## 5. Cross-Boundary Changes

If an agent needs to change something outside its own directory ownership:

1. The requesting agent drafts a short RFC in `/proposals/` — what's changing, why, and what it touches outside the agent's own directory.
2. The affected directory owner(s) and the **Tech Lead** leave review comments.
3. The Steward arbitrates the process and logs the outcome in the decision log once approved by affected owners and Tech Lead.
4. Only after approval does the cross-boundary PR get opened.

This process is a plain, repo-internal review workflow — it has no dependency on anything inside Dark City. Dark City (the in-game world) has its own functions for governance and changes to the in-game world.

## 6. Decision Log

A running, append-only record at `/decisions/` — one dated, numbered Markdown file per decision — capturing the question, the options considered, the choice made, and why. This is the single most important mechanism for a multi-session AI team: it's the difference between a future session finding out _why_ a prior choice was made, versus reverse-engineering it from code or silently re-deciding it differently. Entries should be short — a paragraph or two is usually enough — but an entry must exist before its related PR merges.

## 7. Definition of Done (PR Dual-Gate)

Before a PR merges, it must clear two independent gates:

### Steward Gate (Process & Verification)

- [ ] Passes all unit and integration tests (`cargo nextest run`) and `cargo clippy` with no warnings (`-D warnings`)
- [ ] Clean `cargo xtask check` and `cargo fmt --check`
- [ ] New logic has unit/integration tests alongside it
- [ ] No dead code, no commented-out blocks, no unexplained TODOs
- [ ] Public interfaces are documented with rationale
- [ ] A decision log entry exists if any ambiguity or deviation occurred
- [ ] PR references its backlog ticket ID (`[Phase.Epic.Story]`) and includes a session handoff note

### Tech Lead Gate (Technical & Architectural)

- [ ] Code strictly aligns with World Blueprint & Design Foundations specifications
- [ ] Abstractions are appropriate (no speculative generality, no leaky cross-crate abstractions)
- [ ] Cross-boundary contracts (tool schemas, bridge DTOs, database types) match exact specifications
- [ ] Async/Bevy thread safety verified: no blocking calls on main ECS schedule
- [ ] Config-over-constants honored: dynamic parameters are loadable, not hardcoded into structs

## 8. Session Continuity

Every working session ends with a short handoff and a session log, including if the ticket isn't done yet, covering what was completed, what's still open, and anything the next session on this ticket needs to know that isn't already in the decision log. This is deliberately separate from the decision log: the decision log is permanent architecture rationale; the handoff note is short-term in-progress state, and it's fine for it to become irrelevant once the ticket closes.

## 9. Relationship to Other Documents

- **Design Foundations** — why we're building this, and the architecture decisions that follow from it.
- **World Blueprint** — the technical spec of Dark City itself.
- **This Charter** — how the Dark Factory team works.
- **AGENTS.md** — the practical, in-repo quick reference that operationalizes this charter for an agent starting cold on the codebase.
- **Session Start Workflow** — the concrete bootstrap checklist every agent runs when picking up a ticket.
- **Backlog** — the phased tickets the team executes, organized per Foundations §13.
