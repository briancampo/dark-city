//! `dark_city_core` defines the foundational domain models, strongly-typed
//! identifiers, error types, and core contracts shared across all Dark City systems.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

/// Strongly-typed unique identifier for an in-world simulated citizen.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CitizenId(pub Uuid);

impl CitizenId {
    /// Generates a new random identifier for a citizen.
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for CitizenId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for CitizenId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Strongly-typed identifier for a spatial hierarchy node (Town -> Building -> Room -> Entity).
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct SpatialNodeId(pub String);

impl SpatialNodeId {
    /// Creates a new `SpatialNodeId` from a string-like slice.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }
}

impl std::fmt::Display for SpatialNodeId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Errors arising when attempting an in-world tool or spatial action.
#[derive(Debug, Error, PartialEq, Eq, Clone, Serialize, Deserialize)]
pub enum AccessError {
    /// Citizen does not possess sufficient energy to execute the action.
    #[error("insufficient energy to perform tool action")]
    InsufficientEnergy,
    /// Citizen is not present at the required spatial location.
    #[error("location denied: required presence at {0}")]
    LocationDenied(SpatialNodeId),
    /// Citizen lacks necessary social consent from target citizen.
    #[error("social consent required from target citizen")]
    ConsentRequired,
    /// The specified tool is not recognized in the active tool catalog.
    #[error("unknown tool: {0}")]
    UnknownTool(String),
}

/// Classification of tools within the Dark City runtime hierarchy.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ToolLayer {
    /// Always available (movement, basic communication, memory retrieval).
    Core,
    /// Contextually surfaced based on recent cognitive state.
    Complementary,
    /// Gated at runtime by location, energy, or explicit social consent.
    AdaptiveAccess,
}

/// Soul description loaded from Markdown character files defining a citizen.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SoulDescription {
    /// Citizen's visible character name.
    pub name: String,
    /// Citizen's functional or social role in the world.
    pub role: String,
    /// High-level personality traits.
    pub traits: Vec<String>,
    /// Core existential anchors that cannot be contradicted by reasoning drift.
    pub core_identity_truths: Vec<String>,
    /// Dialogue styling instructions.
    pub speaking_style: String,
    /// Seed memories loaded into the episodic stream at bootstrap.
    pub seed_memories: Vec<String>,
}

/// Spatial node representation in the world layout hierarchy.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SpatialNode {
    /// Unique identifier for this spatial node.
    pub id: SpatialNodeId,
    /// Human-readable name of the location.
    pub name: String,
    /// Parent spatial node identifier in the spatial hierarchy, if any.
    pub parent: Option<SpatialNodeId>,
    /// Tools that can be executed when physically present at this node.
    pub gated_tools: Vec<String>,
}

/// Concrete tool calls executable in the simulated world by citizens.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "tool_name", content = "arguments")]
pub enum ToolCall {
    /// Move citizen to a specific spatial node.
    GoToPlace { place_id: SpatialNodeId },
    /// Speak directly to another citizen.
    SayToCitizen {
        target_id: CitizenId,
        message: String,
    },
    /// Post a public governance proposal at the governance venue.
    SubmitProposal { title: String, body: String },
    /// Transfer credits to another citizen.
    PayCitizen { target_id: CitizenId, amount: i64 },
}

/// Common timestamped simulation event payload for event logging and AWI queries.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SimulationEvent {
    /// Unique event identifier.
    pub id: Uuid,
    /// Citizen associated with this event, if applicable.
    pub citizen_id: Option<CitizenId>,
    /// Event category or name.
    pub event_type: String,
    /// Detailed JSON payload of the event.
    pub payload: serde_json::Value,
    /// Timestamp when the event occurred in the simulation.
    pub occurred_at: DateTime<Utc>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_citizen_id_generation() {
        let id1 = CitizenId::new();
        let id2 = CitizenId::new();
        assert_ne!(id1, id2);
    }

    #[test]
    fn test_tool_call_serialization() {
        let call = ToolCall::GoToPlace {
            place_id: SpatialNodeId::new("town_square"),
        };
        let json = serde_json::to_string(&call).expect("serialization failed");
        assert!(json.contains("GoToPlace"));
        assert!(json.contains("town_square"));
    }
}
