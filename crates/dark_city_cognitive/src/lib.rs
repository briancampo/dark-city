//! `dark_city_cognitive` implements the PIANO cognitive architecture:
//! - Shared blackboard (`CitizenState`)
//! - Cognitive Controller bottleneck (`ControllerDecision`)
//! - Memory retrieval scoring (Recency, Importance, Relevance)
//! - Reflection triggers and hierarchical planning models.

use dark_city_core::{CitizenId, SpatialNodeId, ToolCall};
use serde::{Deserialize, Serialize};

/// High-level intended action produced by deliberate reasoning modules.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ActionIntent {
    /// Action description for auditing and reflection.
    pub description: String,
    /// Concrete tool call execution details.
    pub tool_call: ToolCall,
}

/// Dialogue turn emitted by the Talking module.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DialogueTurn {
    /// Recipient of the dialogue.
    pub target_id: CitizenId,
    /// Content of the message.
    pub content: String,
    /// Topic authorizing this dialogue turn.
    pub authorized_topic: String,
}

/// Sole authoritative decision issued by the Cognitive Controller bottleneck.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ControllerDecision {
    /// Summary of the citizen's current high-level intent.
    pub intent_summary: String,
    /// Authorized action allowed to mutate world state.
    pub authorized_action: Option<ActionIntent>,
    /// Authorized dialogue topic for the Talking module.
    pub authorized_dialogue_topic: Option<String>,
    /// Simulation tick at which this decision was reached.
    pub decided_at_tick: u64,
}

/// Snapshot of a citizen's emotional state.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct EmotionalSnapshot {
    /// Valence (-1.0 to 1.0) representing pleasantness.
    pub valence: f32,
    /// Arousal (0.0 to 1.0) representing intensity.
    pub arousal: f32,
    /// Current emotional label.
    pub label: String,
}

/// The shared blackboard state for an individual citizen in the PIANO model.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CitizenState {
    /// Unique citizen identifier.
    pub citizen_id: CitizenId,
    /// Current spatial location node.
    pub position: SpatialNodeId,
    /// Current action authorized by the Cognitive Controller.
    pub current_action: Option<ActionIntent>,
    /// Emotional snapshot maintained by Social Awareness.
    pub emotional_state: EmotionalSnapshot,
    /// Pending dialogue turn awaiting dispatch.
    pub pending_dialogue: Option<DialogueTurn>,
    /// Last decision committed by the Cognitive Controller bottleneck.
    pub last_controller_decision: Option<ControllerDecision>,
    /// Most recent simulation tick when this state was updated.
    pub last_updated_tick: u64,
}

impl CitizenState {
    /// Creates a fresh `CitizenState` initialized at a starting position.
    pub fn new(citizen_id: CitizenId, position: SpatialNodeId) -> Self {
        Self {
            citizen_id,
            position,
            current_action: None,
            emotional_state: EmotionalSnapshot::default(),
            pending_dialogue: None,
            last_controller_decision: None,
            last_updated_tick: 0,
        }
    }
}

/// Calculates the combined memory retrieval score per Blueprint §4.2:
/// `score = recency + importance + relevance`
///
/// All input arguments must be pre-normalized to the `[0.0, 1.0]` range.
pub fn calculate_retrieval_score(recency: f32, importance: f32, relevance: f32) -> f32 {
    recency + importance + relevance
}

/// Computes the exponential recency decay score for a memory:
/// `0.995 ^ hours_since_last_retrieval`
pub fn calculate_recency_score(hours_since_last_retrieval: f32) -> f32 {
    0.995_f32.powf(hours_since_last_retrieval)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_retrieval_scoring() {
        let score = calculate_retrieval_score(0.8, 0.9, 0.95);
        assert!((score - 2.65).abs() < 1e-5);
    }

    #[test]
    fn test_recency_decay() {
        let immediate = calculate_recency_score(0.0);
        assert!((immediate - 1.0).abs() < 1e-5);

        let later = calculate_recency_score(10.0);
        assert!(later < 1.0 && later > 0.0);
    }
}
