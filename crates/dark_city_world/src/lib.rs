//! `dark_city_world` provides spatial hierarchy management, tool gating validation,
//! and world state tracking for Dark City.

use dark_city_core::{AccessError, AgentId, SpatialNode, SpatialNodeId, ToolLayer};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Definition of an in-world tool with its runtime gating rules.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ToolDefinition {
    /// Unique name of the tool (e.g., "SubmitProposal").
    pub name: String,
    /// Classification of the tool layer (Core, Complementary, AdaptiveAccess).
    pub layer: ToolLayer,
    /// Required spatial node location, if location-gated.
    pub location_gated: Option<SpatialNodeId>,
    /// Energy cost deducted upon invocation.
    pub cost_energy: u32,
    /// Whether explicit social consent from target agent is required.
    pub social_gated: bool,
}

/// In-memory representation of the active world state for spatial and tool verification.
#[derive(Default, Debug)]
pub struct WorldState {
    /// Spatial nodes mapped by identifier.
    pub spatial_nodes: HashMap<SpatialNodeId, SpatialNode>,
    /// Current agent locations mapped by agent identifier.
    pub agent_positions: HashMap<AgentId, SpatialNodeId>,
    /// Active agent energy levels mapped by agent identifier.
    pub agent_energy: HashMap<AgentId, u32>,
}

impl WorldState {
    /// Creates a new empty `WorldState`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Registers a spatial node in the world hierarchy.
    pub fn add_node(&mut self, node: SpatialNode) {
        self.spatial_nodes.insert(node.id.clone(), node);
    }

    /// Sets an agent's current position.
    pub fn set_agent_position(&mut self, agent_id: AgentId, position: SpatialNodeId) {
        self.agent_positions.insert(agent_id, position);
    }

    /// Sets an agent's current energy balance.
    pub fn set_agent_energy(&mut self, agent_id: AgentId, energy: u32) {
        self.agent_energy.insert(agent_id, energy);
    }

    /// Validates whether an agent has runtime access to execute a tool.
    pub fn validate_tool_access(
        &self,
        agent_id: AgentId,
        tool: &ToolDefinition,
    ) -> Result<(), AccessError> {
        if let Some(required_loc) = &tool.location_gated {
            let current_pos = self.agent_positions.get(&agent_id);
            if current_pos != Some(required_loc) {
                return Err(AccessError::LocationDenied(required_loc.clone()));
            }
        }

        let energy = self.agent_energy.get(&agent_id).copied().unwrap_or(0);
        if energy < tool.cost_energy {
            return Err(AccessError::InsufficientEnergy);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_location_and_energy_gating() {
        let mut world = WorldState::new();
        let agent = AgentId::new();
        let town_hall = SpatialNodeId::new("town_hall");
        let tavern = SpatialNodeId::new("tavern");

        world.set_agent_position(agent, tavern.clone());
        world.set_agent_energy(agent, 100);

        let proposal_tool = ToolDefinition {
            name: "SubmitProposal".to_string(),
            layer: ToolLayer::AdaptiveAccess,
            location_gated: Some(town_hall.clone()),
            cost_energy: 10,
            social_gated: false,
        };

        // Should fail due to location
        assert_eq!(
            world.validate_tool_access(agent, &proposal_tool),
            Err(AccessError::LocationDenied(town_hall.clone()))
        );

        // Move to town hall
        world.set_agent_position(agent, town_hall);
        assert_eq!(world.validate_tool_access(agent, &proposal_tool), Ok(()));

        // Drain energy
        world.set_agent_energy(agent, 5);
        assert_eq!(
            world.validate_tool_access(agent, &proposal_tool),
            Err(AccessError::InsufficientEnergy)
        );
    }
}
