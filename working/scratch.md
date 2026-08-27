# Working Content

## Current Session

### Session Discussion

Excellent assessment and thank you for the fixes. These documents were very early drafts and more about capturing ideas as they emerged. I had not yet gone back to do any refinement and address gaps or issues with the content.  This is very helpful. 

Feedback and comments: 
1. Great catch and agree that we need to consider the full scope especially the coherence aspects if we want to be able to have a functional world that will be beleivable when real players enter the world. 
2. Another very good observation. This is also a case of trying to capture the intent and not going back to improve on the specifics. 
3. MIRIX was an early research element that we did to look at a very heavy memory framework but we decided that it was likely a bit too much for what we are trying to do at the moment.  We can remove that from the current plan. 
4. I think the Steward that you are referring to was intended to exist on the development team and not in the game.  There was two elements to the documentation; the in-game world, and the team developing the platform the in-game world runs on. I agree that with your assessment of the Emergence World elements not including a steward.  
5. Agree.  Part of the intention with doing this project is to continue my Rust Learning Journey with this and doing it in rust will help with that and also provide a very solid foundation for this project if it takes off and we decide to expand it beyond this internal project. 

To your questions: 
World Administration: I think the world should start fully decentralized and see where the agents decide to take it.  A steward or government is not out of the question and we may decide to build a scenario where that is the case but it isn't a prerequisite. 
PIANO Depth: I think I would like to incorporate the full PIANO concept as coherence is going to be an integral part of a functional world now and in the future. 
Scope:  I would like this to follow a phased approach. Starting with a small v1 and building it out over time to reach the full scope and potentially even surpassing the described states in the papers.  Again the ultimate goal is to be able to model a variety of worlds and see how AI Agents interact in them to develop worlds for our games.  

====

I'd like our documents to start from a fresh surface and not depend on the previous version. I intend to remove those versions from the project once we have completed our rewrite, so the version we work on here should be able to stand alone without those previous versions. 
I'd also like to pivot away from the Simulacra Shire as the development project. That was an early name and didn't resonate well with the team.  I think we could try using Dark City for the game world, and Dark Factory for the development project. That has an interesting ring to it. 
I would also like our documentation to be able to contain the elements of the papers that we are including.  I.e. rather than abstractly reference concepts from the papers I would like for our documentation to describe what we are doing and how we will integrate those concepts so that a developer can read our docs and undrstand enough to be able to perform their task without being an expert in those papers.  The concepts are deep and complicated but they should be able to be contained in our documents where possible or referenced more directly where it doesn't make sense to bring over the concept. 
I think your initial phased approach make sense. I would also like to suggest that we think about the phased approach so that it allows us to have a product in each phase that is executable and can be used to evaluate and improve the platform and how we want to use it. This is a continuous development project and we want to be able to exercise each phase to learn about the world and how the agent inhabit it and interact. Then as we continue to build the phases we can improve and evolve it. 
I think your proposed phases makes good sense and is a solid place to start from as we refine this. 
I don't think a multi-model approach should be problematic assuming that we have a good way for our rust backend to call the different models. Our local inference engine should be able to handle multiple models. We will have multiple DGX Spark boxes that we can run to provide the models and inference. They can generally support multiple models. 
We can certainly look at other memory options as we need to but for now I think we can start with what we have considered. 

Additional context: 
I'd also like to look at the idea of having a sculptable world and starter scenarios that we use to initialize the world for the agents.  This would allow us to build out different settings for them to inhabit, different characters types, and some starting scenarios for the agents to begin with.  This equates to the ability to develop game worlds, settings, and game episodes we want to have. This can be something we work in during later phases but I would like to make sure we are considering it as an element and not making decisions that would complicate this when we get to it. 
This isn't as much about trying to observe governance as the Emergence paper suggested. That is a core element but this is about being able to define worlds for the agents to be in, constructs and scenarios, and the emergent elements that come from it. Government will be a big part of it, but the governing isn't the goal.

====

Feedback from the document reviews: 
- One thing we are missing in the Dark Factory Team is the developers.  We will need at least a backend rust developer, a bevy Developer, and a Tech Lead (to do code/PR reviews).  At a later time we may also need a devops engineer but we may be able to hold off on that. 