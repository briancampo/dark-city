# Working Content

## Current Session

### Session Discussion

/session-start
/steward
In a previous session we made the determination that we wanted to move away from the use of agent for the inhabitants of the in-game world and use citizen instead. This way there is no confusion and and it is clear when we are talking about the general idea of an agent, our ai developer agents, and other uses of agents. This way we know what we mean when we discuss citizens, we know what we are talking about in the code and DB tables when we see citizen, and it is easy to reason the difference without guessing.

We started to do the transition of the term but never went through the code exhaustively to make the changes. I'd like to do that now before we get too far down the road on implementation. Please review the project and convert all uses of the word agent for inhabitants of the in-game world to be citizen in docs, code (structs, functions, etc.), and database schema. I want it to be clear for all of our future sessions.

====

When the blueprint says that each world instance runs its own headless ECS App I am not sure what that means. How will the backend run multiple instances within the single backend server? Is this just multiple Bevy Schedules, or some other parallelization structure?

#### Feature Discussion:

- It seems like currently we have tool calls defined statically. I thought I remembered some discussion around having tool calls being able to be expanded in the future. Is this the case and have we thought through how that would be implemented in the project?
- I think we should capture a bit more info about the citizen's emotional state and views on things. This is extremely interesting for our ability to have these citizens inhabiting a world that feels alive for players. It could also allow for us to seed conditions for a citizen and enhance the depth of their role in the world to improve the player's experience.
