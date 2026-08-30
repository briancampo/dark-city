# Common Prompts

## Session Start Prompts

### Developer Start Format

#### Backend Dev Start

```prompt
/project-session-start \
  --role /rust-developer \
  --domain "developer-backend" \
  --github-issue 87 \
  --brief @[working/briefings/87-refresh-lifecycle-brief.md] \
  --handoff @[working/handoffs/87-refresh-lifecycle-handoff.md] \
  --spec @[docs/architecture/specifications/83-backend-auth-middleware.md] \
  --task "Please review the Mission Brief to understand your strategic goal and use the Handoff for your immediate technical state. Implement the Token Refresh Lifecycle (POST /auth/refresh) with single-use rotation and Redis revocation. Begin by planning the work and presenting an Implementation Plan for the user to review and approve before starting implementation. Adhere to TDD requirements, the Backend Testing Guide, and acceptance criteria validation."
```

#### Client Dev Start (example)

```prompt
/project-session-start \
  --role /bevy-developer \
  --domain "developer-client" \
  --github-issue 89 \
  --brief @[working/briefs/89-authenticated-requests-brief.md] \
  --handoff @[working/handoffs/89-authenticated-requests-handoff.md] \
  --spec @[docs/architecture/specifications/84-apiclient-http-methods.md] \
  --task "Please review the Mission Brief to understand your strategic goal and use the Handoff for your immediate technical state. Implement JWT Header Injection for Authenticated Requests. Utilize the existing `ApiClientService` async base. Begin by planning the work and presenting an Implementation Plan for the user to review and approve before starting implementation. Follow ATDD and latest Bevy 0.19 development practices and ensure clean lifecycle management, and acceptance criteria validation. "
```

### Code Review Prompts

```prompt
/project-session-start \
  --role /tech-lead \
  --domain "reviewer" \
  --github-issue 178 \
  --github-pr 196 \
  --brief @178-brief.md \
  --handoff @178-handoff.md \
  --walkthrough @178-walkthrough.md \
  --spec @49-global-event-bus.md \
  --task "Perform the Lead Developer PR Review (/review-pr) of PR #XXX. Review should focus on the 5 dimensions of quality and verify that the implementation effectively implements all aspects of the requirements. Ensure 100% test value and integrity and project quality standards before approval. Document review findings via your skill's template ( `review-template.md` ) and ensure full compliance with the review checklist (`review-checklist.md`). "
```

## In-Session Prompts

### Begin Development Prompt

```prompt
Please review the provided comments and, if you have no follow-up questions, proceed with implementation noting the updates requested.
```

### Review Artifact Prompt

```prompt
Please review the provided comments. Follow up with any discussions, or additional questions for the user to refine the plan. Make any relevant updates to the plan and provide feedback on any discussion items.

I would like to review any updates and the plan before you proceed into implementation. Please make sure the updates to the plan are noted and easy to identify for the user's review.
```

## Closeout Prompts

### Dev Session Closeout

```prompt
Please run `cargo xtask check` and address any issues before we close out this session.

I'd like to make sure that we capture any insights and learnings that you had during this session in the appropriate places (project memory) so that future developers can reference and use your insight to make their development work more effective and efficient and benefit from any unique discoveries you made or issues you encountered.  This doesn't need to capture existing knowledge you had or basic execution.

Once all the work has been completed prepare for the next session where /tech-lead will do the final /review-pr using their `review-checklist.md`. Instruct the Tech Lead to focus on their own viewpoints and evaluation of the code and not simply review what is proposed in their mission brief. Their review must find things you haven't thought of or addressed. Make sure you provide an enriched review brief with enough context for the next agent that they will be able to seamlessly continue this task using the brief you create without skewing the impartiality of their review. Your brief must encourage the reviewer to take a fresh look at the work and not guide them to things you have already verified. Then ensure all files are committed and pushed to the remote and create a PR using `gh-task-ops.sh`

Finally close out this session using the /project-session-end workflow.
```

### Code Reviewer Closeout

#### Final Closeout

```prompt
Your review is very well done and your recommendations are sound. Please proceed with implementing all defined remediations.
run `cargo xtask check` and address any issues before we close out this session.

I'd like to make sure that we capture any implementation insights and learnings that you had during this session so that future developers can reference and use your insight to make their development work more effective and efficient.

Begin preparing the next agent's session where they will work on [issue-id] from [backlog-id]. Review the work on [issue-id] so that you can prepare the next agent by creating a mission brief to cover the tasks.

Once that is complete, prepare a mission brief for the appropriate persona to begin work on proposed starting task. Ensure you enrich the brief and populate the template with enough context for the next agent that they will be able to effectively complete work on the task using the mission brief you create.

Finally close out this session using the /project-session-end workflow and record agent learnings as appropriate.
```

## Prompt Fragment Storage

### Epic Closeout Review

Run a full service capability review and acceptance criteria validation. Consider architectural alignment and implementation, opportunities to refactor for optimal implementation, and Code Quality. Perform a thorough review of the generated code focusing on the following aspects:

- **Architectural Alignment**: Verify the code adheres to the projects design and architecture guidelines.
- **Implementation Quality**: Check for code quality, following idiomatic Rust patterns, and absence of "leaky abstractions". Ensure unnecessary `pub` visibility is minimized.
- **Refactoring Opportunities**: Identify any potential improvements or refactorings that could make the code cleaner, more efficient, or easier to maintain, without changing the external API.
- **Test Quality**: Review the test coverage and ensure tests are meaningful, correctly implemented, and follow the established patterns in the project.
- **Documentation Completeness**: Verify that all necessary documentation, including `README.md`, design doc, and tech spec, are up-to-date and accurately reflect the implementation.
- **Build & Tooling**: Ensure the code compiles successfully (`cargo xtask check`, `cargo clippy`, WASM compatibility checks).
