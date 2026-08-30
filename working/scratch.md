# Working Content

## Current Session

### Session Discussion

/session-start
/steward
In a previous session we made the determination that we wanted to move away from the use of agent for the inhabitants of the in-game world and use citizen instead. This way there is no confusion and and it is clear when we are talking about the general idea of an agent, our ai developer agents, and other uses of agents. This way we know what we mean when we discuss citizens, we know what we are talking about in the code and DB tables when we see citizen, and it is easy to reason the difference without guessing.

We started to do the transition of the term but never went through the code exhaustively to make the changes. I'd like to do that now before we get too far down the road on implementation. Please review the project and convert all uses of the word agent for inhabitants of the in-game world to be citizen in docs, code (structs, functions, etc.), and database schema. I want it to be clear for all of our future sessions.

====

When the blueprint says that each world instance runs its own headless ECS App I am not sure what that means. How will the backend run multiple instances within the single backend server? Is this just multiple Bevy Schedules, or some other parallelization structure?

====

Excellent review and findings.  
1. I'm not sure what that was referring to. Do you know what that might mean? 
2. Please provide an updated version of 1.1.2-brief.md that incorporates those and any other emergent changes. 
3. great finds. i'll make those updates in the project version of the docs. 
4. I'll make these changes as well. 
5. I will make this change. 

Open Design Questions: 
1. Code Review Safety Audit: This is a great suggestion.  Please integrate this into the appropriate places so we ensure this is considered before we deploy the development team. 
2. Goal Generation is an excellent suggestion. I'd like to have the ability to provide a goal to the citizen at design time, but also for Citizens to develop their own goals at certain times.  This shouldn't happen every simulation step, but is something a Citizen may develop and work on over time as they observe the world and other citizens.  Let's create a research brief and set a backlog item sequenced appropriately to think through and plan the implementation of this. 
3. Another excellent finding and a true oversight. This is a fantastic way to make our world even more dynamic and interesting. If we combine this with the idea of the world events, and the concept of the narrator, perhaps we have another non-citizen actor (or even have the narrator handle this from a different POV) that runs on a daily basis to introduce new events into like weather, external events from outside the city, and other similar factors into the city as world events and into the newspaper that the narrator creates. 
   - This is definitely something we should add. Please create a research brief and add this to the backlog to sequence an activity for us to get after this. 
4. this sounds like an excellent addition.  Please include this as appropriate. 

Please proceed with the ones I have designed for action by you.  



#### Feature Discussion:

- It seems like currently we have tool calls defined statically. I thought I remembered some discussion around having tool calls being able to be expanded in the future. Is this the case and have we thought through how that would be implemented in the project?
- I think we should capture a bit more info about the citizen's emotional state and views on things. This is extremely interesting for our ability to have these citizens inhabiting a world that feels alive for players. It could also allow for us to seed conditions for a citizen and enhance the depth of their role in the world to improve the player's experience.
