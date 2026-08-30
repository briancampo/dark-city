## Ticket

<!-- [Phase.Epic.Story] -->

## Summary

<!-- What this PR does, in a sentence or two. -->

## Definition of Done — Steward Gate (Charter §7, process)

- [ ] `cargo nextest run` clean
- [ ] `cargo clippy --all-targets -- -D warnings` clean
- [ ] `cargo xtask check` clean
- [ ] New logic has tests alongside it
- [ ] No dead code, no commented-out blocks, no unexplained TODOs
- [ ] Public interfaces documented
- [ ] Decision log entry exists for anything not already specified by Foundations or Blueprint (linked below)
- [ ] Ticket ID referenced above

## Definition of Done — Tech Lead Gate (Charter §7, technical soundness)

- [ ] Async / Bevy-thread-safety concerns reviewed for blocking calls, if applicable
- [ ] Tool-schema contract review complete, if `ToolCall` / `ToolDefinition` touched
- [ ] Implementation is consistent with existing patterns elsewhere in the codebase
- [ ] Config-over-constants and no-speculative-generality (Charter §4) genuinely honored, not just technically satisfied

## Decision Log Entries

<!-- Link any /decisions/ entries this PR depends on -->

## Session Handoff

<!-- Paste from the session-handoff-toolkit skill -->
