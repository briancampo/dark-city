# Research Brief: Citizen Emotional & Affective State Dynamics

**Date:** 2026-08-30
**Status:** Research Brief (Pre-Proposal)
**Prepared for:** Steward / Tech Lead / User Review
**Assigned Specialist Owner:** Character Sculptor (Blueprint §3.5, §4)

---

## 1. Core Question

How should Dark City capture, evolve, and leverage a citizen's **emotional and affective state** — encompassing designer-seeded baseline dispositions (temperament, core values), transient in-world emotional states (mood, valence, arousal), interpersonal sentiments (trust, affection, grievance), and ideological stances — to deepen simulation fidelity, modulate memory salience, and drive emergent behaviors?

---

## 2. Context & Background Precedents

### Generative Agents (Park et al., 2023) & Social Simulation

- **Affect as Behavior Driver:** In rich social simulations, citizen interactions and priorities cannot be sterile utilitarian calculations. Believable social dynamics require emotional grounding — frustration over resource scarcity, grief over tragic world events, joy in social gatherings, or resentment from broken promises.
- **Interpersonal Memory:** Relationships persist and evolve through sentiment accrual. A citizen needs to remember not just that a conversation happened, but _how they felt about the other person afterward_.

### Cognitive Emotion Models (Russell's Circumplex & OCC Appraisal)

- **Valence-Arousal Dimensionality:** A simple two-dimensional vector (`valence`: pleasantness from -1.0 to +1.0, `arousal`: activation/intensity from 0.0 to 1.0) provides a computationally lightweight way to represent transient mood and emotional shock.
- **Appraisal Theory:** Events are evaluated relative to a citizen's baseline goals and values, producing specific emotional reactions that guide immediate reflexes.

### Synergy with Dark City Architecture

- **Memory Salience Modulation (M1):** High emotional arousal naturally demands higher write-time importance scoring in Episodic Memory, ensuring traumatic or joyful events are retained and retrieved during planning.
- **Reflection Synthesis (M2):** The Reflection module can periodically synthesize recent emotional memories to update durable interpersonal sentiments (e.g., transitioning from "mild annoyance" to "deep distrust").
- **Goal & Action Motivation:** Emotional states provide the impetus for Goal Generation (e.g., fear motivating defensive goals; social affinity motivating collaborative proposals).

---

## 3. Analysis of Approaches & Candidate Shapes

### Option A: Pure Prompt-Based Ephemeral Affect

- **Concept:** Rely entirely on free-text descriptions in Soul files (`traits`, `background`) and instruct LLM prompts to deduce emotional tone on the fly without dedicated database tracking.
- **Pros:** Zero database schema additions, zero extra state management logic.
- **Cons:** Complete loss of emotional persistence across sessions; emotional state resets or hallucinates wildly between turns; inability to aggregate community emotional climate in AWI.

### Option B: Hybrid Structured Affective State & Sentiment Graph (Recommended)

- **Concept:**
  1. **Designer-Seeded Baseline:** Extend `SoulDescription` with an `AffectiveDisposition` (baseline temperament, emotional volatility, core values).
  2. **Dynamic In-World State:** Track transient mood and valence/arousal in a lightweight `citizen_affect_states` table.
  3. **Interpersonal Sentiment Graph:** Maintain directed edges between citizens (`citizen_sentiments`) capturing trust, affinity, and grievance.
- **Pros:** Durable emotional continuity; direct feed into M1 memory salience scoring; enables aggregate AWI metrics (e.g., City Social Tension / Harmony Index); grounds Goal Generation in emotional reality.
- **Cons:** Requires schema migrations and lightweight sentiment update logic during reflection ticks.

**Recommendation:** Option B. It provides durable depth and directly enriches the player/observer experience without placing heavy overhead on the tick loop.

---

## 4. Architectural Sketch (For Eventual Proposal/Decision)

### Data Model & Schemas

- **Soul Integration (`assets/souls/*.md`):**
  ```yaml
  disposition:
    temperament: 'Guarded, Analytical, High Empathy'
    baseline_valence: 0.1
    volatility: 0.3
    core_values: ['Knowledge', 'Loyalty', 'Security']
  ```
- **Postgres Tables (`crates/dark_city_server/migrations/`):**

  ```sql
  CREATE TABLE citizen_affect_states (
      citizen_id UUID NOT NULL,
      world_id UUID NOT NULL,
      current_mood VARCHAR(64) NOT NULL, -- e.g. "anxious", "content", "outraged"
      valence FLOAT NOT NULL DEFAULT 0.0, -- -1.0 to 1.0
      arousal FLOAT NOT NULL DEFAULT 0.0, -- 0.0 to 1.0
      last_event_impact TEXT,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (world_id, citizen_id)
  );

  CREATE TABLE citizen_sentiments (
      world_id UUID NOT NULL,
      source_citizen_id UUID NOT NULL,
      target_citizen_id UUID NOT NULL,
      trust_level FLOAT NOT NULL DEFAULT 0.5,   -- 0.0 (distrust) to 1.0 (deep trust)
      affinity_level FLOAT NOT NULL DEFAULT 0.5, -- 0.0 (hostile) to 1.0 (fond)
      relationship_label VARCHAR(64),           -- e.g. "rival", "confidant", "stranger"
      grievance_summary TEXT,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (world_id, source_citizen_id, target_citizen_id)
  );
  ```

### Cognitive Integration Points (`crates/dark_city_cognitive/`)

1. **Observation & Memory Write (M1):** If an observed event involves a citizen with high sentiment weight or causes high emotional arousal, write-time salience score is boosted by `arousal * weight`.
2. **Talking & Dialogue:** The Talking module includes the speaker's current mood and their sentiment toward the interlocutor in the generation context.
3. **Reflection (M2):** When a Reflection batch runs, it evaluates emotional trajectories and updates `citizen_sentiments` and `citizen_affect_states`.
4. **Goal Generation:** Unresolved grievances or intense emotional states feed directly into goal formation prompts.

---

## 5. Open Questions for Decision Working Session

1. **Dimensional vs. Categorical Representation:** Should the LLM prompt interface work primarily with natural language emotion descriptors (e.g. "Resentful", "Optimistic") backed by numeric vectors, or purely structured categorical enums?
2. **Emotional Decay:** Should high arousal and negative/positive mood spikes naturally decay toward baseline over simulated time (e.g. daily decay ticks), or only change in response to new events?
3. **Observer / AWI Metrics:** Should Dark City include an aggregate AWI indicator (e.g., Indicator 13: Community Emotional Harmony & Social Tension Index)?

---

## 6. Proposed Backlog Sequencing

### Research & Spike Phase (Phase 2)

- Coordinate with Phase 2 social dynamics runs (Epic 2.5) and Goal Generation spike (Epic 2.8).

### Decision Milestone

- Ratify ADR covering Soul schema expansion, affective state tables, and memory weighting before Phase 3.

### Implementation Insertion

- **Epic 2.9 — Citizen Affective & Sentiment Dynamics** (Phase 2 / Phase 3 Bridge):

| ID        | Title                                                              | Goal                                                                                                                                                                                                                           | Acceptance Criteria                                                                                                                                                                                                                                                                 | Owner              | Depends On                 |
| :-------- | :----------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------- | :------------------------- |
| **2.9.1** | **Affective State & Sentiment Dynamics research spike & decision** | As a Character Sculptor, I want to evaluate sentiment graphs, emotional memory salience weighting, and mood decay models against Phase 2 run data, so that citizen behavior displays realistic emotional depth and continuity. | Given Phase 2 run data and this research brief, when the spike concludes, then a decision log entry and Blueprint amendment draft exist covering: Soul `disposition`, `citizen_affect_states`, `citizen_sentiments`, emotional memory weighting, and AWI emotional climate metrics. | Character Sculptor | 1.2.4, 1.3.3, 1.3.4, 2.5.2 |
