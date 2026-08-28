# Dark Factory Roles — Index

Quick pointer from role name to role file. Directory ownership and Blueprint sections are the source of truth in Team Charter §3.1 and `AGENTS.md`; this table exists so a session can find its own file fast, not to duplicate the Charter table.

| Role                       | File                            | Ownership / Authority                                               |
| -------------------------- | ------------------------------- | ------------------------------------------------------------------- |
| Steward                    | `steward.md`                    | Process, dispatch, decision log, DoD gate                           |
| Tech Lead                  | `tech-lead.md`                  | Technical authority, cross-cutting PR gate, architecture escalation |
| System Architect           | `system-architect.md`           | `/src/server/`, `/migrations/`                                      |
| Local Inference Specialist | `local-inference-specialist.md` | `/src/inference/`, `/grammars/`                                     |
| World Designer             | `world-designer.md`             | `/src/world/`, `/assets/maps/`                                      |
| Character Sculptor         | `character-sculptor.md`         | `/src/cognitive/persona.rs`, `/assets/souls/`                       |
| QA/Instrumentation Agent   | `qa-instrumentation-agent.md`   | `/tests/`, `/src/instrumentation/`                                  |
