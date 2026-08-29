//! `dark_city_server` provides the backend runtime, API handlers,
//! and coordination logic for the Dark City simulation.

use dark_city_core::AgentId;
use serde::{Deserialize, Serialize};
use std::env;

/// Configuration options for the Dark City backend server runtime.
///
/// Encapsulates all environment-driven parameters necessary for running
/// the server container and connecting to external services such as
/// PostgreSQL + pgvector and inference clusters.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ServerConfig {
    /// Host interface to bind to (e.g. `0.0.0.0` or `127.0.0.1`).
    /// Configured via `SERVER_HOST` env var, defaults to `0.0.0.0`.
    pub host: String,
    /// TCP port to bind the server listener to.
    /// Configured via `SERVER_PORT` env var, defaults to `8080`.
    pub port: u16,
    /// Database connection URL for PostgreSQL + pgvector.
    /// Configured via `DATABASE_URL` env var.
    pub database_url: Option<String>,
    /// Inference gateway endpoint URL (e.g. DGX Spark vLLM/Ollama).
    /// Configured via `INFERENCE_GATEWAY_URL` env var.
    pub inference_gateway_url: Option<String>,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: "0.0.0.0".to_string(),
            port: 8080,
            database_url: None,
            inference_gateway_url: None,
        }
    }
}

impl ServerConfig {
    /// Constructs a [`ServerConfig`] by reading known environment variables,
    /// falling back to defaults if not set.
    ///
    /// - `SERVER_HOST`: Host address (default: `0.0.0.0`)
    /// - `SERVER_PORT`: Port number (default: `8080`)
    /// - `DATABASE_URL`: PostgreSQL connection string
    /// - `INFERENCE_GATEWAY_URL`: Inference gateway URL
    pub fn from_env() -> Self {
        let host = env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
        let port = env::var("SERVER_PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(8080);
        let database_url = env::var("DATABASE_URL").ok();
        let inference_gateway_url = env::var("INFERENCE_GATEWAY_URL").ok();

        Self {
            host,
            port,
            database_url,
            inference_gateway_url,
        }
    }

    /// Returns the socket address formatted as `host:port`.
    pub fn socket_addr(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}

/// Health check status response.
///
/// Used for container orchestration readiness/liveness probes and monitoring.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct HealthResponse {
    /// Service status message (e.g. "ok").
    pub status: String,
    /// Indicates whether the headless ECS simulation loop is currently active.
    pub simulation_running: bool,
}

/// Ledger account balance information.
///
/// Reflects settled currency state for an agent in simulation credits.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct AccountBalance {
    /// Agent owning the account.
    pub agent_id: AgentId,
    /// Current settled balance in simulation credits.
    pub balance: i64,
}

/// Returns a default healthy status for readiness and healthcheck endpoints.
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
        assert!(!health.simulation_running);
    }

    #[test]
    fn test_server_config_defaults() {
        let config = ServerConfig::default();
        assert_eq!(config.host, "0.0.0.0");
        assert_eq!(config.port, 8080);
        assert_eq!(config.socket_addr(), "0.0.0.0:8080");
        assert!(config.database_url.is_none());
        assert!(config.inference_gateway_url.is_none());
    }

    #[test]
    fn test_server_config_from_env() {
        // Test parsing with explicitly set environment variables
        unsafe {
            std::env::set_var("SERVER_HOST", "127.0.0.1");
            std::env::set_var("SERVER_PORT", "9090");
            std::env::set_var("DATABASE_URL", "postgres://user:pass@localhost:5432/testdb");
            std::env::set_var("INFERENCE_GATEWAY_URL", "http://inference.local:8000");
        }

        let config = ServerConfig::from_env();
        assert_eq!(config.host, "127.0.0.1");
        assert_eq!(config.port, 9090);
        assert_eq!(config.socket_addr(), "127.0.0.1:9090");
        assert_eq!(
            config.database_url.as_deref(),
            Some("postgres://user:pass@localhost:5432/testdb")
        );
        assert_eq!(
            config.inference_gateway_url.as_deref(),
            Some("http://inference.local:8000")
        );

        unsafe {
            std::env::remove_var("SERVER_HOST");
            std::env::remove_var("SERVER_PORT");
            std::env::remove_var("DATABASE_URL");
            std::env::remove_var("INFERENCE_GATEWAY_URL");
        }
    }
}
