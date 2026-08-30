# Working Content

## Current Session

### Session Discussion

#### Feature Discussion:

I'd like to take this session to work on a few project level improvements before we start full scale development:

- The automated brief generator in our `gh-task-ops.sh` script is a great start but it lacks the necessary context and guidance for the implementing agent to be able to use effectively to complete the task. I'd like to make sure that if we are using that to create the brief that we make sure it is clear that is the starting point and that the agent must still add additional details and context to help inform the implementing developer.
- I think we need a specific process (skill or workflow, not sure) for doing a PR review. The review done at the end of the implementation session is great but it will tend to focus on what was done in the session. A major point for a PR review is to bring in a different perspective and check for missed items or other issues that the original developer may have missed.
  - The process developed should provide guidance on the need for an independent review to find what the previous session was not thinking of, provide a critical assessment of the work that was done to find challenges before they get merged to main, and create a checklist of items to go through during the review.
- To support the PR review session integration into our development process; when an implementation session for a work item is completed the implementer should create
  - a log entry -- `/logs/work-log.md`
  - please create a new file to start this with instructions and a log entry template for later sessions to follow capturing high level details that should be retained in the project long term,
  - a review brief `/working/briefs/<issue-id>-review.md`
  - please create a template for this like we have for the mission brief and enrich it but ensure that the reviewer is not going to focus on only what the implementer described and takes a fresh senior reviewer type look at the work.
- I'd like to create a process (workflow or skill, not sure) for when we start a new epic. This could be considered similar to a Sprint Planning session customized around our structure.
  - I'd like it to review the epic and provide an assessment of the work and any gaps or other factors that need to be considered before we start. this should launch a discussion with the user to address those gaps and make any improvements to the epic (and other documentation) to capture and integrate the new information.
  - Then the process should assess the work to create a set of implementation tasks (not necessarily 1:1 with stories) to complete the stories defined in the epic.
    - **Context-Window & Complexity Bounded Slicing:** Ensure stories are decomposed into cohesive units of work (task issues) bounded by single-session cognitive and context capacity rather than arbitrary micro-hour limits. Avoid micro-task thrash while ensuring tasks are completable by a single developer agent session and context. Tasks should avoid multiple unrelated activities or overly broad scope.
    - Then create issues in the GitHub project to match the stories, epics, and tasks that were created.
    - Epic, Story, and Task issues should be related through GitHub Project's relationship structures so they can be navigated for future discovery and understanding.
    - GH issues should have the appropriate tags placed on them to reference the type of issue (epic, story, task), the domain of work the task encompasses, and other information to help with future discovery and understanding.
    - Issues that will be assigned and worked (may be story or task level depending on how they are broken down and sliced) should be put into the Ready status on the board. Epics and stories that have child tasks should remain in the backlog so they don't clutter the work set.
  - Create briefs for each work item that is in the Ready status on the board including the template from the script but the template created must be enriched to effectively guide the implementing agent through the work they will be assigned to do. It must contain a contextually aware and technically comprehensive description of the work to be done aligned withe the current project state and any other relevant information from the other tasks in the epic.
  - The backlog should then be updated with information about the issues created so that the backlog can be used to describe the github project.
- I would like to create a process for an Epic retrospective. This would be similar to a Sprint Retrospective but done within the concept of one or more epics.
  - I'd like the Steward to lead this process and follow the normal Sprint Retrospective set of activities, but utilizing our other `.agent/roles` to participate and contribute to the process. You define the standard activities in addition to the below:
    - This should include the Steward walking the user through a review of the Epic(s), the issues associated with the Epic(s) and the work that was completed to address them. The most important part of this is a User Demo where the Steward guides the user through starting the project and walking through the project running in the user's environment.
    - Among the other standard Epic (Sprint) Retrospective outputs, I'd like an Epic brief created that describes the work that was completed, any new discoveries or improvements to our team, process, and technical approach discovered during the Epic.
- I'd also like to look at the `/proposals` area. I place a couple of research briefs into the folder. In my mind a research brief is the start of the process.
  - That creates a proposal that would be reviewed, discussed, and revised through a working session between the Steward and I (along with any other assigned roles).
  - I'd like to update the proposal README.md and template to be much more comprehensive and useful to a user to complete the following process to go from idea -> research -> proposal -> decision -> implementation.
  - Proposal drafting would be assigned to a team member to create a first draft of the proposal and present that to the Steward and I.
  - If a proposal is accepted it would create a decision brief along with an integration plan that becomes a work item to integrate the decision into the project
    - Documentation, Epic/Stories/Tasks, and other updates will need to be included in the work item to integrate the decision.
    - Part of a research brief's preparation should be to consider sequencing the research activity, the integration, and the potential work against the current project backlog schedule so we can decide where in the backlog to insert each effort. For instance if the proposed element does not impact the project until Phase 3 we may decide to defer adding the research/proposal development work until phase 2 and place the decision task as the last work element of phase 2. That would allow for the work to be sequenced into Phase 3 effectively. Conversely if there is an immediate impact we may decide to defer current work to complete all phases now and resume regularly scheduled work items once the decision has been made and any downstream work has been sequenced.
  - The two existing research briefs have some proposed sequencing included in them for reference that should be integrated into the project. This illustrates the structure and process I am proposing.  

Fixes for gh-task-ops.sh:

- please check to make sure that the pr create command moves the applicable work item to the review column so it is clear that the next assignment will be a pr review.
- finish command should early exit with a message to the user and not make any changes if there is not a PR for the current ticket. We don't want to do partial finish if a pr has not been created.
- once finish has completed I'd like the terminal to provide a cd command to go back to the main repo (/home/brian/dev/ai/dc-root) like it does for the assign command.

====

- It seems like currently we have tool calls defined statically. I thought I remembered some discussion around having tool calls being able to be expanded in the future. Is this the case and have we thought through how that would be implemented in the project?
- I think we should capture a bit more info about the citizen's emotional state and views on things. This is extremely interesting for our ability to have these citizens inhabiting a world that feels alive for players. It could also allow for us to seed conditions for a citizen and enhance the depth of their role in the world to improve the player's experience.

---

3.  **Context-Window & Complexity Bounded Slicing:** Ensure issues are decomposed into cohesive units of work bounded by single-session cognitive and context capacity rather than arbitrary micro-hour limits. Avoid micro-task thrash while ensuring tasks do not span multiple unrelated modules.
4.  **Refinement & Validation Pipeline:** You are the gatekeeper of the backlog's readiness. No story proceeds to technical specification without your validation.
    - **Validate:** Review existing epics and stories referenced in `docs/product/gdd/11_epic_list.md` and `docs/product/epics/*.md` for INVEST compliance and `Given/When/Then` Acceptance Criteria.
    - **Reconcile:** Consult `docs/agile/prioritization_table.md` as the authoritative source for story sequencing and iteration planning. Update the applicable columns in the table with technical details, dependency links, or Tracker associations as refinement occurs.
    - **Propose:** The Scrum Master should take the initiative to propose draft edits or changes to the `prioritization_table.md` (Seq, Priority, Dependencies) during the Planning/Grooming ceremony to discuss technical realities with the Product Owner.
    - **Elaborate:** If a story is incomplete, lead the elaboration process. Elaboration can be performed out-of-sequence if it is more context-efficient (e.g., batching related technical modules).
    - **Sync:** Create/Sync validated Stories/Epics to the GitHub Project as issues (labeled as `story` or `epic`).
    - **Tracker Aggregation:** If multiple stories share a high degree of technical overlap (e.g., adding several methods to the same service), the Scrum Master should aggregate them under a **`Tracker`** issue. This Tracker acts as the parent for implementation tasks and the single source of truth for technical refinement. Tracker issues should document the related stories they aggregate.
    - **Mark:** Update the source epic documentation (e.g., `docs/product/epics/*.md`) by adding `✅ VALIDATED` next to the story title when a story has been created as an issue or aggregated into a Tracker.
    - **Handoff:** Generate a formal handoff document in `working/handoffs/` for the System Architect once validation is complete. Notify the Tech Lead/PO to trigger the specification development phase.
