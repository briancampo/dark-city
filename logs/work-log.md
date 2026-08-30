# Dark Factory Work Log

This log is the durable project history for the Dark Factory engineering team. It captures high-level context, key technical discoveries, architectural milestones, and downstream impacts across development sessions.

---

## Work Log Guidelines & Archiving Policy

### When to Log

Every developer agent session completing an assigned work item or ticket MUST append a standardized entry to this log before closing the session.

### Archiving & Discovery Rules

1. **Active Log Window:** `logs/work-log.md` maintains the active log entries for the current development phase (up to ~100 entries or ~50KB).
2. **Phase Archiving:** Upon completion of a Phase (or when the active file reaches capacity), the Steward moves completed phase entries to `logs/archive/work-log-phase-<N>.md` (e.g. `logs/archive/work-log-phase-1.md`).
3. **Searchability:** Every archive file is indexed in the table below with its ticket range, date span, and phase theme for rapid cross-session discovery.

### Archive Index

| Archive File               | Short Description | Phase / Theme | Ticket Range | Date Range |
| :------------------------- | :---------------- | :------------ | :----------- | :--------- |
| [logs/[yyyy]/[mm]-xxxx.md] | —                 | -             | —            | —          |

---

## Log Entry Template

```markdown
### [YYYY-MM-DD] Story/Task [ID]: [Title]

- **Role:** [Dispatched Role]
- **Phase / Epic:** [Phase_ID-Epic_Id] — [Epic Title]
- **GH Issue/PR:** #[Issue Number] / #[PR Number]
- **Key Deliverables & Changes:**
  - ...
- **Key Architectural Decisions & Learnings:**
  - ...
- **Downstream Impact & Follow-up Notes:**
  - ...
```

---

## Active Log Entries (Newest on Top)

### [2026-08-30] [N/A] Repository Bootstrap & Tooling Modernization

- **Role:** Steward / Tech Lead
- **Phase / Epic:** Phase 1 — Repository Bootstrap
- **GH Issue/PR:** 07 / TBD
- **Key Deliverables & Changes:**
  - Initialized Cargo workspace with crates (`dark_city_core`, `dark_city_server`, `dark_city_world`, `dark_city_cognitive`, `dark_city_inference`, `dark_city_client`, `dark_city_instrumentation`, `xtask`).
  - Built GitHub CLI task and issue automation scripts (`scripts/gh-task-ops.sh`, `scripts/gh-issue-ops.sh`).
  - Established Dual-Gate PR review workflows (`/review-pr`), mission brief scaffolding, review briefs, and comprehensive developer process frameworks.
- **Key Architectural Decisions & Learnings:**
  - Ratified Decision 0002 (server-authoritative headless simulation, thin viewer client).
  - Ratified Decision 0003 (multi-tenant isolated world instances).
  - Ratified Decision 0004 (Observation module and `world_events` schema).
  - Ratified Decision 0006 (Tool Review Agent for citizen-authored code audit).
- **Downstream Impact & Follow-up Notes:**
  - Ready for Phase 1 foundational infrastructure implementation (Story 1.1.1 Postgres + pgvector provisioning).
