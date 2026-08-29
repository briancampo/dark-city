# Working Content

## Current Session

### Session Discussion

Excellent assessment and thank you for the fixes. These documents were very early drafts and more about capturing ideas as they emerged. I had not yet gone back to do any refinement and address gaps or issues with the content. This is very helpful.

Feedback and comments:

1. Great catch and agree that we need to consider the full scope especially the coherence aspects if we want to be able to have a functional world that will be beleivable when real players enter the world.
2. Another very good observation. This is also a case of trying to capture the intent and not going back to improve on the specifics.
3. MIRIX was an early research element that we did to look at a very heavy memory framework but we decided that it was likely a bit too much for what we are trying to do at the moment. We can remove that from the current plan.
4. I think the Steward that you are referring to was intended to exist on the development team and not in the game. There was two elements to the documentation; the in-game world, and the team developing the platform the in-game world runs on. I agree that with your assessment of the Emergence World elements not including a steward.
5. Agree. Part of the intention with doing this project is to continue my Rust Learning Journey with this and doing it in rust will help with that and also provide a very solid foundation for this project if it takes off and we decide to expand it beyond this internal project.

To your questions:
World Administration: I think the world should start fully decentralized and see where the agents decide to take it. A steward or government is not out of the question and we may decide to build a scenario where that is the case but it isn't a prerequisite.
PIANO Depth: I think I would like to incorporate the full PIANO concept as coherence is going to be an integral part of a functional world now and in the future.
Scope: I would like this to follow a phased approach. Starting with a small v1 and building it out over time to reach the full scope and potentially even surpassing the described states in the papers. Again the ultimate goal is to be able to model a variety of worlds and see how AI Agents interact in them to develop worlds for our games.

====

I'd like our documents to start from a fresh surface and not depend on the previous version. I intend to remove those versions from the project once we have completed our rewrite, so the version we work on here should be able to stand alone without those previous versions.
I'd also like to pivot away from the Simulacra Shire as the development project. That was an early name and didn't resonate well with the team. I think we could try using Dark City for the game world, and Dark Factory for the development project. That has an interesting ring to it.
I would also like our documentation to be able to contain the elements of the papers that we are including. I.e. rather than abstractly reference concepts from the papers I would like for our documentation to describe what we are doing and how we will integrate those concepts so that a developer can read our docs and undrstand enough to be able to perform their task without being an expert in those papers. The concepts are deep and complicated but they should be able to be contained in our documents where possible or referenced more directly where it doesn't make sense to bring over the concept.
I think your initial phased approach make sense. I would also like to suggest that we think about the phased approach so that it allows us to have a product in each phase that is executable and can be used to evaluate and improve the platform and how we want to use it. This is a continuous development project and we want to be able to exercise each phase to learn about the world and how the agent inhabit it and interact. Then as we continue to build the phases we can improve and evolve it.
I think your proposed phases makes good sense and is a solid place to start from as we refine this.
I don't think a multi-model approach should be problematic assuming that we have a good way for our rust backend to call the different models. Our local inference engine should be able to handle multiple models. We will have multiple DGX Spark boxes that we can run to provide the models and inference. They can generally support multiple models.
We can certainly look at other memory options as we need to but for now I think we can start with what we have considered.

Additional context:
I'd also like to look at the idea of having a sculptable world and starter scenarios that we use to initialize the world for the agents. This would allow us to build out different settings for them to inhabit, different characters types, and some starting scenarios for the agents to begin with. This equates to the ability to develop game worlds, settings, and game episodes we want to have. This can be something we work in during later phases but I would like to make sure we are considering it as an element and not making decisions that would complicate this when we get to it.
This isn't as much about trying to observe governance as the Emergence paper suggested. That is a core element but this is about being able to define worlds for the agents to be in, constructs and scenarios, and the emergent elements that come from it. Government will be a big part of it, but the governing isn't the goal.

====

Feedback from the document reviews:

- In the documents the team composition seems very functionally aligned and not necessarily skill defined. for isntance we have the world designer doing Bevy development work. Is that the intended outcome? I do feel like we need to have some technical alignment. One thing I suggest is a a Tech Lead, to do code/PR reviews and maintain the overall technical direction. I have not run a team with this composition so I will have to defer to your intent.
- In the Design Doc I see quite a bit of description about smallville and Project Sid's PIANO, but I don't see much about how we will integrate the unique functions of Emergence World with the spatial exeection, tools, and organized governance. I don't want to go overboard on the other functions Emergence world did for the governance but there are good additions to consider.
- I don't see much on the newspaper in the design doc. that is an important part of the project.

====

Great feedback and assessment.
One thing I haven't done yet is consider the inclusion of an additional team member (tech-lead). Nobody currently has cross-cutting authority to ask "is this the right abstraction," "does this actually honor config-over-constants or is it just claiming to," or "is this consistent with how the rest of the codebase does this" — across all five specialists' code. That's a real gap, and it's the kind of thing that tends to surface expensively around Phase 2–3, once there's enough surface area for architectural drift to hide in.

My recommendation, split authority the way QA's cross-cutting test power is already split from implementation ownership —

Steward stays process-authority. Dispatch, DoD gate, decision log admin, RFC process admin.
Tech Lead becomes technical-authority. Owns no directory (like the Steward), but has read/comment authority across all of /src, is a required second sign-off on every PR alongside the Steward's DoD gate, and — this is the part I'd flag most — is probably the better fit than the Steward for Charter §3.2's "first point of escalation on a genuine ambiguity." Judging whether something's a small implementation detail or a real architecture fork is a technical call, not a process one. The Steward would keep first-point-of-contact for scope/sequencing ambiguity ("is this ticket sized right," "does this depend on unmerged work"); Tech Lead would own technical/architecture ambiguity.

That's a clean split with no duplicated authority, but it does mean patching Charter §3.1, §3.2, §5, and §7, plus AGENTS.md's role table — all documents currently marked "Done."

I'd like to get your thoughts on this and if you agree let's put that in place before we begin Epic 1.0.

A few additional points:

- I updated the agent directory path to be roles instead of agents and fixed the links in the design-doc.md file.
- I'd like to better understand the plan for the different crates proposed.

===

Currently:
complete on the review of AG updates and need to integrate the claude updates.
reviewing backlog with mission brief update to include Docker as a starting story on deck.

#### CL:

I don't see anything about a user interface to follow the world visually and see the world play out similar to what Smallville and A16Z's AI Town do. Is this considered in the current project scope?

- It is not clear to me how the world client (bevy) is retrieving all of the necessary information it needs. I want to make sure that the backend and the world client are separable so that we can run the backend in our containerized infrastructure with the client being able to be run on a different machine (likely a workstation). At some point in the future I would ideally like to be able to run multiple world clients against our backend so that we can have many simulations supported by the backend.
  - I am not sure if our current design supports either the separable world client and backend, and then further if our backend is designed to be able to support multiple world clients.

===

This is great feedback and highlights a bit of a misunderstanding on my part. I misunderstood that Bevy was being used for handling of the core agent functions and not just being used as the world client (viewer). I may have miscommunicated during the initial phases of the project what my intent was. That could have led us to where we are now.

The second part about multiple clients was more trying to see if there was the ability to have a sort of tenant approach to things and how we might abstract multiple concurrent worlds. This isn't trying to replicate the same world in multiple clients but trying to replicate multiple worlds each with their own client. Hope this makes sense and happy to discuss further.

Given your knock on issues point I agree it may be that we need to think through a series of documentation changes to resolve the group of things. This is much better done now while we are very early in the project rather than later when it will be much harder.

Your suggestion for underlying fix of moving things to the backend seems to align with the conceptual idea was thinking of. If ECS is still the right idea that is fine. We can still run ECS and Bevy headlessly (there is also bevy_ecs for headless running as well) if that is the right approach on the backend and have a world client for the front end that is a different Bevy instance.

====

Plan looks good with a few comments at the end. As we are working through this I also decided to change a few things. Please review the below and make sure that the changes are reflected in both scripts so that they will operate correctly.

I moved this out of my personal github (briancampo) and into the organization's github (Mindstar Studion) account now that we are ready to start.
Repo: https://github.com/Mindstar-Studio/dark-city
project: https://github.com/orgs/Mindstar-Studio/projects/2

I also created an issue for the epic as I want to be able to track epic to story to task. Not all stories will need multiple tasks but I want to have the ability to break down large stories into multiple tasks and continue the parent child relationship.  
I like the structure you have for the story issues. The epic I created only has the backlog table as the description so if you have a better structure/template for our epics you can modify that to improve it.

Feedback items:

- Create Story or create epic: I am not sure that the backlog document captures all of the detail we need for a story and especially if the story is further broken down into multiple tasks that we will have enough information in the backlog document to automatically create a well defined and comprehensive issue description. I could be off on this but would like you to review. The idea of using an issue body file that the agent constructs seemed to make sense since there was additional info needed but will defer to your insight.

====

When the blueprint says that each world instance runs its own headless ECS App I am not sure what that means. How will the backend run multiple instances within the single backend server? Is this just multiple Bevy Schedules, or some other parallelization structure?

I see how we are capturing citizen interactions and activities, but I don't see how we are capturing world events. Is it intended that the only way to capture that something has happened in the world is that citizens would talk about it?

====

General insights:
I wonder if this is better considered as observations so an not to conflict with or overlap with the concept of Perception in the other mechanisms.  
The project has not progressed past what is already documented in the project artifacts beyond the simple completion of Epic 1.0 and Story 1.1.0 Containerization. So we have a very clean slate to work from as we decide the best path forward.

Producer: I would like to consider both of the described options but also consider citizen generated events as well where a citizens actions might queue a new world event.

Responses to your questions:

- For severe world events, I would say that is not where we will start but may be something we consider further in the future.
- M10 scanning raw perceived memories: I think that is something i would like to better understand how the impact of. If i understand correctly the raw sourced event is just an observation and when it surfaces is when it would become citizen interpreted or related. If that is correct i think it would be that we scan the citizen's later speech since that is when it becomes "theirs". I don't think M10 should scan raw event info, only the citizen's conception, interpretation, or discussion of it.

A couple of additional questions:

- I just want to make sure that a perceived event that is put directly into memory can immediately trigger an action, correct? I want to make sure that is a citizen perceives (or observes) a fire in their kitchen the mechanism would allow them to react to it as they observe it, not at some later point indicating they didn't take an action.
- Since we are updating the scenario package we should have a starting time for the scenario which would allow the world to have an time anchor but also allow the setting of scripted events to a world clock time instead of just a trigger time that is based on elapsed time.

====

Great work. I have reviewed this latest version and think it is ready to be integrated into the project documents. Please proceed with updating the rest of the documentation to integrate this new concept.  Once you have made the updates I will take your updated documents and move them over to the project repository so the team can get started on this. 

A couple of thoughts while you are doing the integrations: 
- To your question of population scale events. I don't think that is something we need to worry about now. 
- I agree with your approach to keep urgency path in the fast loop allowing it to leverage a flag or category (salience) to determine if it needs to go straight to the Cognitive Controller.  I think all three producers will have the ability to predefine the urgency at event creation time so we don't need to tie up the Controller to make that determination. 



#### Feature Discussion:

- It seems like currently we have tool calls defined statically. I thought I remembered some discussion around having tool calls being able to be expanded in the future. Is this the case and have we thought through how that would be implemented in the project?
- I think we should capture a bit more info about the citizen's emotional state and views on things. This is extremely interesting for our ability to have these citizens inhabiting a world that feels alive for players. It could also allow for us to seed conditions for a citizen and enhance the depth of their role in the world to improve the player's experience.

