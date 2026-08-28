//! `dark_city_server` provides the backend runtime, API handlers,
//! and coordination logic for the Dark City simulation.

use dark_city_core::AgentId;
use serde::{Deserialize, Serialize};

/// Health check status response.
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct HealthResponse {
    /// Service status message.
    pub status: String,
    /// Simulation status.
    pub simulation_running: bool,
}

/// Ledger account balance information.
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct AccountBalance {
    /// Agent owning the account.
    pub agent_id: AgentId,
    /// Current settled balance in simulation credits.
    pub balance: i64,
}

/// Returns a default healthy status.
pub fn get_health_status() -> HealthResponse {
    HealthResponse {
        status: "ok".to_string(),
        simulation_running: false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_health_response() {
        let health = get_health_status();
        assert_eq!(health.status, "ok");
    }
}
