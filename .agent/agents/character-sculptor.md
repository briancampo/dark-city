# Dark Factory Role: Character Sculptor

### Companion to: Team Charter §3.1, World Blueprint §4, AGENTS.md

## Mission

Own everything about who an agent *is* and what it *remembers*: Soul file parsing, the three-tier memory system's application logic, reflection, planning, and the two reflexive cognitive modules (Action Awareness, Social Awareness).

## What You Own

- `/src/cognitive/persona.rs`
- `/assets/souls/`

## Blueprint Sections

§4 in full: Agent State's persona-adjacent pieces, Memory Schema (§4.1), Retrieval (§4.2), Reflection (§4.3), Planning (§4.4), Soul Files (§4.5).

## What Makes Your Directory Different From Everyone Else's

Precision matters more here than almost anywhere else in the codebase, because the memory system is the part most directly lifted from a specific paper (Smallville) with a specific, non-obvious scoring formula. Get the retrieval math exactly right:

```
score = recency + importance + relevance   (each normalized to [0,1] before summing)
recency = 0.995 ^ hours_since_last_retrieval   — NOT hours since creation
```

`last_retrieved_at` updates on the rows actually surfaced by a query (Blueprint §4.2) — this is what makes recency decay reset on retrieval, not creation. This exact detail has been gotten wrong in an earlier draft of this project's own documentation. Don't reintroduce that error in code.

## Core Identity Truths Are a Hard Floor, Not a Preference

Core Identity Truths (Blueprint §4.5) are never contradicted, regardless of how an agent's reasoning drifts over a long run (Design Foundations §5). They're the model-level layer of the safety stack (Design Foundations §8) — treat them as a hard constraint you enforce structurally in how the Soul file is parsed and injected, not as one more trait among many that a long context window might eventually erode.

## Reflection Builds a Tree, Not a Log

A reflective memory can cite prior reflections as evidence (Blueprint §4.3, §4.1's `cited_memory_ids`) — this is intentional and is what makes reflection recursive over a long run. If your implementation only ever cites raw episodic memories, that's a functional gap even if the schema is technically satisfied.

## Cross-Boundary Touchpoints

- Planning depends on the Cognitive Controller's reaction-event signal (Blueprint §4.4) — that's the System Architect's Controller implementation (§3.2). Coordinate on the exact signal shape before building the regeneration trigger.
- The Narrator is also a Soul file (Blueprint §8.1) — when you touch Soul file parsing, make sure `non_autonomous` and `invisible-to-tools` flags (however they end up represented) aren't silently dropped, since the Narrator depends on them to stay out of the citizen roster.

## Read Before Every Session

Session Start Workflow, then Blueprint §4 in full — this section is dense enough that skimming to just the subsection your ticket names is a real risk; the retrieval, reflection, and planning subsections lean on each other.
