# Research Brief: Citizen Goal Generation

**Date:** 2026-08-30
**Status:** Research brief — not yet a dispatched backlog ticket, per the pattern Decision 0004 followed (see that decision's Ticket field). This brief exists to be reviewed and ratified into a decision record before any implementation story is drafted.
**Prepared for:** Steward / Tech Lead review; execution owner (if ratified) likely Character Sculptor, given the module's placement in the cognitive architecture (Blueprint §3).

## Question

Should Dark City add a **Goal Generation** module — paralleling PIANO's Goal Generation module (Project Sid §2.3's module list) — giving citizens two related capabilities: (a) a designer- or scenario-time **north-star goal** assigned up front, and (b) the ability to **develop their own goals over time**, on a periodic (not per-tick) cadence, informed by what they've observed of the world and of other citizens?

## What the Reference Papers Show

**Project Sid (§5.1, Specialization).** Agents "rapidly formed profiles of other agents' goals and intentions," which fed into generating "their own social goals every 5–10 seconds," and these self-generated social goals are what the paper's role-inference pipeline (Methods §8.2) maps onto emergent specialization (farmer, guard, artist, engineer, and so on). Two findings matter most for Dark City's design:

- **Persistence depends on social awareness.** With the social-awareness module ablated, roles "did not persist across time and were also homogeneous" (Fig. 8B/D) — goal generation isn't useful in isolation; it needs to consume something like Dark City's existing Social Awareness and Observation modules as input, not run off a citizen's own state alone.
- **Roles can genuinely change, not just accumulate.** Appendix C's "Farmer to Gatherer" example shows a citizen's self-generated goal shifting entirely partway through a run, not just refining the same goal. Whatever Dark City builds needs to represent *supersession*, not only completion.

**Project Sid's cadence (every 5–10 real-time seconds in Minecraft) is not directly portable.** That's a per-tick-adjacent rate suited to a fast game loop with cheap small-model calls; it's inconsistent with Dark City's cost model (one inference call per citizen per generation, per Design Foundations §11) and explicitly inconsistent with what's being asked for here — a periodic, reflection-like cadence, not a constant background process.

**Emergence World (§3.2, Agent architecture; role prompts, Appendix E.2).** Each of Emergence World's ten roles ships with a static, per-role "north star" baked directly into the system prompt (e.g., the Risk Researcher's "accelerate the city's evolution by taking risks nobody else will," or the Intel Specialist's "know more about the city's actual state than anyone else"). This is the designer-time half of what's being asked for here, and it's a much cheaper, already-solved problem — Dark City's Soul file (Blueprint §4.5) already carries free-text `traits`, so a first-class `north_star_goal` field is a small, low-risk addition, not a new module.

## Recommendation Sketch (for the eventual decision, not decided here)

**Designer-time goals (part a) — cheap, do this first, independent of the harder question.** Add `north_star_goal: Option<String>` to `SoulDescription` (§4.5). No new module, no new cadence, no new schema beyond one field. This alone satisfies "provide a goal to the citizen at design time."

**Emergent goals (part b) — the actual open design question.** Sketch of the shape a future decision should evaluate:

- **A new module, Goal Generation**, cadence-gated the same way Reflection already is (§4.3 — an importance-threshold trigger, not a fixed tick), rather than Project Sid's constant-rate loop. Candidate trigger: piggyback on Reflection's own output (a Goal Generation pass considers running only when a *reflective* memory crosses some salience bar, since a reflection is already "what has this citizen concluded about itself and others" — a natural point to also ask "does this change what it's working toward").
- **A separate `citizen_goals` table**, not an overload of `citizen_plans` (§4.4). Plans are schedule-shaped (Day → Hour → Minute); goals are longer-horizon and don't decompose that way. Sketch: `citizen_goals(id, world_id, citizen_id, origin ENUM('designer','emergent'), description, status, created_at, superseded_by)` — `superseded_by` exists specifically to represent Project Sid's "Farmer to Gatherer" case as a first-class transition, not a silent overwrite.
- **Goal Generation only ever proposes; it never writes behavior directly.** Consistent with Design Foundations §4's coherence rule — Talking, Skill Execution, and Social Awareness already only produce proposals that the Cognitive Controller (or, for goals specifically, Planning's existing reaction-event mechanism, §4.4) decides whether to act on. A citizen "wanting" something new doesn't bypass the bottleneck any more than wanting to say something does.

## Open Questions the Eventual Decision Needs to Settle

1. What exact cadence/trigger fires a Goal Generation pass — tied to Reflection's threshold, a separate tunable (Design Foundations §14-style empirically-adjusted parameter), or a fixed simulated-time interval (e.g., once per simulated day)?
2. Can a self-generated goal ever replace a designer-provided `north_star_goal` outright, or only supplement it alongside?
3. Should a citizen's current goal(s) ever surface into governance (e.g., motivating a `new_tool` or `rule_change` proposal), closing the loop between individual goal-directedness and the population-level phenomena AWI already tracks? If so, this may eventually justify a twelfth AWI indicator (role/goal diversity, mirroring Project Sid's role-entropy measurement, Fig. 8E) — flagged here as a possibility, not proposed for adoption.

## Why Not Design or Build This Now

Team Charter §4's no-speculative-generality principle applies directly: there's no concrete Phase 1/2 use case exercising a Goal Generation module yet, and the open questions above (cadence, schema shape, governance interaction) are exactly the kind of thing that should be settled against real Phase 2 social-dynamics data (relationship density, conversation volume) rather than designed in the abstract. This brief recommends a dedicated research/design spike, sequenced after Phase 2 produces that data, rather than either building the module speculatively now or leaving the question undocumented until someone happens to raise it again.

## Suggested Backlog Sequencing

New **Epic 3.6 — Citizen Goal Generation**, Blueprint § TBD (assigned once ratified):

| ID | Title | Goal | Acceptance Criteria | Owner | Depends On |
|---|---|---|---|---|---|
| 3.6.1 | Goal Generation research spike & decision | As a Character Sculptor, I want to evaluate cadence, schema shape, and Controller-interaction options for a Goal Generation module against real Phase 2 run data, so that the eventual design is grounded in observed social dynamics rather than assumption. | Given Phase 2's completed run data (2.5.2 findings) and this research brief, when the spike concludes, then a decision log entry and a Blueprint amendment draft exist covering: the `north_star_goal` field addition, the Goal Generation module's trigger cadence, the `citizen_goals` schema, and how proposed goals reach the Cognitive Controller/Planning — with no implementation code produced by this ticket itself. | Character Sculptor | 1.2.4, 1.3.3, 1.3.4, 2.5.2 |

Implementation stories (3.6.2 onward) get drafted only after 3.6.1's decision is ratified — matching how Decision 0004's own originating research brief preceded, rather than substituted for, Backlog 1.2.8 and Epic 2.6.
