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

### [2026-08-30] Story/Task [N/A]: Developer Process & Quality System Modernization

- **Role:** Steward / Tech Lead
- **Phase / Epic:** Phase 1 — Repository Bootstrap & Tooling
- **GH Issue/PR:** #7 / TBD
- **Key Deliverables & Changes:**
  - Standardized the Workflow vs. Skill architecture: Workflows (`.agent/workflows/<action>-<target>.md`) for procedural session runbooks, and Skills (`.agent/skills/<name>-toolkit/`) for reusable capabilities, checklists, and templates.
  - Implemented the Lead Developer PR Review system: `/review-pr` workflow, `pr-review-toolkit` skill with 5-dimension quality checklist (plus static analysis and documentation consistency), and structured P0-P3 review template.
  - Implemented the Epic Inception & Planning system: `/plan-epic` workflow and `epic-planning-toolkit` skill with Context-Window & Complexity Bounded Slicing and GitHub project hierarchy management.
  - Implemented the Epic Retrospective system: `/conduct-retrospective` workflow and `retrospective-toolkit` skill with User Live Demo walkthroughs and durable retro briefs.
  - Established durable session completion artifacts: `logs/work-log.md` with phase-based archiving guidelines and automated review brief scaffolding (`scripts/gh-task-ops.sh scaffold-review`).
  - Formalized the 5-stage proposal and research lifecycle in `proposals/` and integrated Epics 2.7 (Environmental Events) and 2.8 (Citizen Goal Generation) into `docs/backlog.md`.
  - Upgraded CLI automation in `scripts/gh-issue-ops.sh` and `scripts/gh-task-ops.sh` to scaffold briefs and ensure worktree path isolation.
- **Key Architectural Decisions & Learnings:**
  - Clearly separated permanent architectural identity (`[Backlog_ID]` e.g. `[1.1.1]`) from ephemeral GitHub project tracking (`#Issue_ID` e.g. `#87`).
  - Ratified 100% test integrity mandate (eliminating vacuous `is_ok()` assertions) and zero-tolerance for leaky public visibility.
  - Ratified Decision 0002 (server-authoritative headless simulation, thin viewer client).
  - Ratified Decision 0003 (multi-tenant isolated world instances).
  - Ratified Decision 0004 (Observation module and `world_events` schema).
  - Ratified Decision 0006 (Tool Review Agent for citizen-authored code audit).
- **Downstream Impact & Follow-up Notes:**
  - All developer agents and workflows are fully equipped for rigorous, isolated task execution starting with Phase 1 Story 1.1.1 (Postgres + pgvector provisioning).
