# Dark Factory: Team Charter

**Version:** v1.5

**v1.4 note:** Role/ownership table (§3.1) revised per [Decision 0002](../decisions/0002-server-authoritative-simulation.md) — `dark_city_world` is now a library composed into the backend's headless simulation, and a new `dark_city_client` crate holds the (now genuinely thin) viewer. System Architect's scope grows to include the headless ECS App and the World Session Manager (multi-world orchestration, [Decision 0003](../decisions/0003-multi-tenant-world-instances.md)).

**v1.5 note:** Character Sculptor's Blueprint sections gain §3.5 (the new Observation module, [Decision 0004](../decisions/0004-observation-and-world-event-capture.md)), registered into the backend's headless App the same way Memory, Reflection, Planning, Action Awareness, Social Awareness, and the Cognitive Controller already are.

## 1. Purpose of This Document

This charter governs how the Dark Factory team — the Steward, the Tech Lead, and five specialist coding agents — builds Dark City. It's a companion to two other documents: _[Dark City: World Design Foundations](design-doc.md)_ (why we're building this, and the architecture decisions that follow from it) and _[Dark City: World Blueprint](dark-city-blueprint.md)_ (the technical spec of what we're building). This document is about how we work: engineering discipline, roles, process, and the bar every contribution has to clear. Nothing in this charter describes Dark City or its citizens — Dark Factory has no presence inside the simulated world, ever.

### 1.1 Standardized Terminology

To maintain complete clarity across discussions, tickets, and code:

- **Citizen:** An in-world simulated character living within Dark City (e.g. Samuel Ward, Elena Vance). Never refer to in-game characters simply as "agents".
- **Agent / Developer Agent:** A specialist AI coding agent on the Dark Factory development team (Steward, Tech Lead, System Architect, Local Inference Specialist, World Designer, Character Sculptor, QA/Instrumentation).
- **Dark City:** The simulated world, runtime environment, and game systems.
- **Dark Factory:** The development team, engineering processes, and repository automation.

## 2. Why This Charter Exists

This project has to survive many iterations, not get rewritten from scratch every time momentum stalls. That's a real constraint on how the team works, not just an aspiration. A multi-session, multi-agent build process fails in specific, predictable ways if left unstructured: different sessions quietly making incompatible architectural choices, scope creeping in without anyone noticing until it's expensive to unwind, rationale for a past decision getting lost the moment the session that made it ends, and small shortcuts compounding because no single agent ever sees the whole codebase evolve end to end. This charter exists to prevent those failure modes structurally — through required practices, not through asking agents to remember to be careful.

There's a fitting parallel here: Dark City's own citizens rely on a Cognitive Controller bottleneck and a persistent, retrievable memory stream to stay coherent across a long-horizon run despite bounded context windows. Dark Factory's agents have the exact same structural problem — bounded sessions, no continuous memory — for the exact same reason. The decision log (§6), the Steward and Tech Lead's PR gate (§7), session handoff notes (§8), and isolated git worktrees (§8.1) are this team's version of that same discipline.

## 3. Team Structure

### 3.1 Roles and Ownership

| Role                           | Owns (directories)                                                                            | World Blueprint sections     | Responsibility                                                                                                                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Steward**                    | _(coordinates; owns no code directly)_                                                        | —                            | Ticket dispatch, decision log maintenance, PR gating (process), cross-boundary arbitration                                                                                                             |
| **Tech Lead**                  | _(coordinates; owns no code directly; cross-cutting review authority across all crates/code)_ | — _(all, for review)_        | PR gating (technical soundness), technical/architecture ambiguity escalation, cross-boundary technical review                                                                                          |
| **System Architect**           | `crates/dark_city_server/`, `migrations/`                                                     | §2, §3.3, §6, §7, §10.2, §12 | Axum backend, **headless simulation ECS App composition & tick loop**, World Session Manager (multi-world lifecycle), DB schema & migrations, WebSocket/API surface, governance & ledger backend logic |
| **Local Inference Specialist** | `crates/dark_city_inference/`, `grammars/`                                                    | §3.3 (inference side), §11   | Inference gateway integration, grammar/schema enforcement, multi-model routing                                                                                                                         |
| **World Designer**             | `crates/dark_city_world/` (library), `crates/dark_city_client/` (viewer), `assets/maps/`      | §3.4, §5, §8.3               | Spatial hierarchy & tool-gating logic as a library composed into the backend's headless App; the thin viewer client (rendering, WSS subscription, bulletin display)                                    |
| **Character Sculptor**         | `crates/dark_city_cognitive/`, `assets/souls/`                                                | §3.5, §4                     | Soul file format & parsing, memory/reflection/planning/**observation** module logic (registered as systems into the backend's headless App), persona stability                                         |
| **QA/Instrumentation Agent**   | `crates/dark_city_instrumentation/`, `tests/`                                                 | §9                           | AWI metrics, M10 pipeline, test coverage across all directories                                                                                                                                        |

**On `dark_city_world` and `dark_city_client` ([Decision 0002](../decisions/0002-server-authoritative-simulation.md)):** these were one conflated concept in early scoping — a single Bevy client assumed to hold both spatial/gating logic and rendering. They're now two crates, both World-Designer-owned, but with a real seam between them: `dark_city_world` is a library with no `main.rs` of its own, linked into `dark_city_server`'s headless App at world-instance startup; `dark_city_client` is the actual runnable, windowed application, and it contains no simulation logic — see World Blueprint §3.4.

The **QA/Instrumentation** Agent has cross-cutting authority to _write tests_ anywhere in the codebase, but not to modify implementation code outside its own directory — a failing test in someone else's directory is reported, not silently fixed by rewriting their logic.

The **Tech Lead** has cross-cutting authority to _review and comment on_ code anywhere in the codebase, but never to modify it directly — technical feedback is left as PR review comments for the owning role to address, the same as any code review. The Tech Lead owns no directory; the review authority is what replaces it.

`Cargo.toml` and any workspace-level dependency change has no single owner — it always goes through the cross-boundary process in §5, regardless of who requests it or how small it seems, because a dependency choice affects every role. Given the architectural weight of a dependency choice, the Tech Lead should be among the reviewers on any such proposal.

### 3.2 The Steward

The Steward orchestrates the build team. It does not act in, direct, or have any awareness of Dark City as a simulated world — its job stops entirely at the boundary of the Dark Factory codebase. Concretely, the Steward:

- Ingests backlog tickets, decomposes them into atomic tasks where needed, assigns work by role, and provides brief/guides to the agent performing the task.
- Gates every PR against the Definition of Done (§7) before merge.
- Maintains the decision log (§6).
- Arbitrates cross-boundary proposals (§5).
- Is the first point of escalation for scope and process ambiguity — whether a ticket is sized right, whether it depends on work that hasn't merged yet, whether it maps cleanly to an existing Blueprint section. Resolves these directly when they're a scheduling or process question. Anything that turns out to be a technical or architectural question gets routed to the Tech Lead (§3.3) instead of resolved here.

### 3.3 The Tech Lead

The Tech Lead owns the codebase's technical coherence across every directory, without owning any directory outright. Concretely, the Tech Lead:

- Provides the second required PR sign-off alongside the Steward's process gate (§7) — checking that a PR is the right shape, not just that it's compliant: the right abstraction, consistent with how the rest of the codebase already solves similar problems, and genuinely honoring principles like config-over-constants and no-speculative-generality (§4) rather than technically satisfying them while missing the point.
- Is the first point of escalation for technical and architectural ambiguity (§3.2). Resolves it directly when it's a real but contained implementation decision, or escalates to the human when it's a genuine architecture fork — either way, the resolution gets logged (§6).
- Reviews and comments on code in any directory but never modifies it directly (§3.1) — feedback goes back to the owning role as PR review comments.
- Provides the technical read on any cross-boundary proposal (§5) with real architectural weight, informing — not replacing — the Steward's approval.

## 4. Engineering Principles

These are non-negotiable, not defaults to override under time pressure:

- No merged code without a passing test suite (`cargo nextest run`) and a clean `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, and `cargo xtask check`.
- No dead code and no commented-out blocks left "just in case" — delete it. Git history remembers it if it's ever needed again.
- Every public function and struct gets a doc comment explaining _why_ it exists, not just what it does. The "why" is what a future session needs and can't infer from the signature alone.
- Single Session (context sized) tasks and PRs over big ones. A PR should be reviewable in one sitting; a large feature gets decomposed into a sequence of small, individually mergeable PRs, matching the backlog's story-sized granularity.
- No speculative generality. Build what the current Blueprint section specifies — not a more "flexible" abstraction invented to save hypothetical future effort.
- All documentation and codebase links MUST use relative markdown paths so references resolve properly regardless of workspace root or worktree path.
- Every deviation from the World Blueprint, and every decision the Blueprint leaves genuinely open, gets a decision log entry _before_ the PR implementing it merges — not after, and never left undocumented.

## 5. Cross-Boundary Changes

If an agent needs to change something outside its own directory ownership:

1. The requesting agent drafts a short RFC in `proposals/` — what's changing, why, and what it touches outside the agent's own directory.
2. The affected directory owner(s) leave review comments.
3. The Steward approves or rejects — informed by the Tech Lead's technical review for any proposal with real technical weight — logging the outcome in the decision log either way.
4. Only after approval does the cross-boundary PR get opened.

## 6. Decision Log

A running, append-only record at `decisions/` — one dated, numbered Markdown file per decision — capturing the question, the options considered, the choice made, and why. Entries should be short — a paragraph or two is usually enough — but an entry must exist before its related PR merges.

## 7. Definition of Done (PR Dual Gate)

Before a PR merges, it needs sign-off from both the Steward (process gate) and the Tech Lead (technical gate) — one gate, two independent checks.

**Steward gate — process & verification:**

- [ ] Passes all unit and integration tests (`cargo nextest run`) for the project and `cargo clippy --all-targets -- -D warnings` with zero warnings
- [ ] Clean `cargo xtask check` and `cargo fmt --check`
- [ ] New logic has tests alongside it
- [ ] No dead code, no unexplained TODOs
- [ ] Public interfaces are documented with _why_ comments
- [ ] A decision log entry exists for anything not already specified by Foundations or Blueprint
- [ ] The PR references its backlog ticket ID and GitHub issue ID
- [ ] Relative markdown links verified across modified docs

**Tech Lead gate — technical soundness:**

- [ ] Code strictly aligns with World Blueprint & Design Foundations specifications
- [ ] Abstractions are sound (no speculative generality, no leaky cross-crate abstractions)
- [ ] Cross-boundary contracts (tool schemas, bridge DTOs, database types) match exact specifications
- [ ] Async/Bevy thread safety verified: no blocking calls on the backend's headless ECS tick schedule, and no simulation state (`CitizenState` or equivalent) held anywhere outside `dark_city_server` — including in `dark_city_client`, which must remain a thin renderer per [Decision 0002](../decisions/0002-server-authoritative-simulation.md)
- [ ] Config-over-constants honored: dynamic parameters are loadable, not hardcoded into structs
- [ ] Tool schemas, if touched, pass a type-and-effect contract review — argument shapes match `ToolDefinition` exactly
- [ ] The implementation is consistent with existing patterns elsewhere in the codebase

## 8. Session Continuity & Git Worktrees

### 8.1 Worktree Isolation Protocol

To enable clean parallel development across sessions and roles, all active work is carried out in dedicated git worktrees:

- **Issue Tracking:** Every session corresponds to a GitHub task issue tracked in [GitHub Project #7](https://github.com/users/briancampo/projects/7).
- **Worktree Directory:** `/home/brian/dev/ai/worktrees/dark-city/<issue_id>-<task_slug>/`
- **Branch Naming:** `<issue_id>-<task_slug>`
- **Strict Directory Boundary:** Agents must restrict all file reads, edits, builds, and commands exclusively to their assigned worktree. Touching files in parent or sibling worktrees is strictly prohibited.

### 8.2 Handoff Notes

Every working session ends with a short handoff note in the PR/issue description: what was completed, what's still open, and anything the next session needs to know that isn't already in the decision log.

## 9. Relationship to Other Documents

- **[Design Foundations](design-doc.md)** — why we're building this, and the architecture decisions that follow from it.
- **[World Blueprint](dark-city-blueprint.md)** — the technical spec of Dark City itself.
- **[This Charter](project-charter.md)** — how the Dark Factory team works.
- **[AGENTS.md](../AGENTS.md)** — practical quick reference operationalizing this charter.
- **[Session Start Workflow](../.agent/workflows/session-start.md)** — concrete bootstrap checklist for every session.
- **[Backlog](backlog.md)** — phased tickets the team executes.
