---
name: pr-definition-of-done
description: Use as a self-review checklist before opening any Dark Factory PR, and by the Steward when gating a PR for merge — Charter §7's Definition of Done. Trigger on "is this PR ready," "self-review before I open a PR," "check this against the Definition of Done," or "gate this PR."
---

# PR Definition of Done

Run every item before opening a PR (self-review) or before approving one (Steward gate). All of them, every time — this list is the Charter §7 merge gate, not a suggestion.

- [ ] **Tests pass.** `cargo nextest run` clean for the whole project, not just your directory.
- [ ] **Clippy clean.** `cargo clippy --all-targets -- -D warnings` — zero warnings, not just zero errors.
- [ ] **`cargo xtask check` clean.** The project-specific lint/rule suite (AGENTS.md, Commands).
- [ ] **New logic has tests alongside it.** Not retrofitted after the fact — Charter §4 treats this as continuous, not a pre-PR scramble.
- [ ] **Async / Bevy-thread-safety reviewed**, if the PR touches anything crossing the concurrency bridge (Blueprint §3.3) — specifically, no blocking call on the main Bevy schedule.
- [ ] **Tool-schema contract review**, if `ToolCall`/`ToolDefinition` was touched — argument shapes match exactly; check with whichever of System Architect / Local Inference Specialist you don't already own that boundary with.
- [ ] **No dead code, no commented-out blocks, no unexplained TODOs.** Delete it — git history remembers it if it's needed again (Charter §4).
- [ ] **Public interfaces documented** — every public fn/struct has a doc comment explaining *why* it exists, not just what it does.
- [ ] **Decision log entry exists** for anything not already specified by Foundations or Blueprint. Use the `decision-log-entry` skill if you haven't written one yet.
- [ ] **PR references its backlog ticket ID** in the title or description (Backlog §1 convention: `[Phase.Epic.Story]`).
- [ ] **Handoff note included**, even if the ticket is fully done — Session Start Workflow step 10. Use the `session-handoff-note` skill.

If any box can't be checked and you don't know why, that's a Session Start Workflow step 7 situation — stop and raise it rather than opening the PR anyway.
