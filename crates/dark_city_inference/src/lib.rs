//! `dark_city_inference` provides model routing, schema/grammar enforcement,
//! and inference gateway client abstractions for Dark City.

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Errors arising during inference requests or response parsing.
#[derive(Debug, Error)]
pub enum InferenceError {
    /// Failure during network transport to inference backend.
    #[error("inference transport error: {0}")]
    Transport(String),
    /// Response from model failed schema or grammar constraint validation.
    #[error("grammar or schema validation failed: {0}")]
    ValidationError(String),
    /// Deserialization error from model JSON output.
    #[error("failed to deserialize response: {0}")]
    Deserialization(#[from] serde_json::Error),
}

/// Request sent to the local inference gateway.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceRequest {
    /// Model identifier to route this request to (supports multi-model setup).
    pub model_id: String,
    /// System prompt conditioning the citizen or module.
    pub system_prompt: String,
    /// User/Blackboard context payload.
    pub context_prompt: String,
    /// Optional JSON schema constraining the generated output.
    pub response_schema: Option<serde_json::Value>,
    /// Sampling temperature.
    pub temperature: f32,
}

/// Response returned from the inference gateway.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InferenceResponse {
    /// Raw text output or structured JSON text.
    pub content: String,
    /// Number of tokens evaluated in the prompt.
    pub prompt_tokens: usize,
    /// Number of tokens generated in the completion.
    pub completion_tokens: usize,
}

/// Trait defining the client interface for dispatching inference calls.
#[async_trait]
pub trait InferenceGatewayClient: Send + Sync {
    /// Executes an inference request with guaranteed response schema validation.
    async fn generate(
        &self,
        request: InferenceRequest,
    ) -> Result<InferenceResponse, InferenceError>;
}

/// Mock inference client for unit testing and offline development.
#[derive(Default)]
pub struct MockInferenceClient;

#[async_trait]
impl InferenceGatewayClient for MockInferenceClient {
    async fn generate(
        &self,
        _request: InferenceRequest,
    ) -> Result<InferenceResponse, InferenceError> {
        Ok(InferenceResponse {
            content: "{}".to_string(),
            prompt_tokens: 10,
            completion_tokens: 10,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_mock_inference_client() {
        let client = MockInferenceClient;
        let req = InferenceRequest {
            model_id: "test-model".to_string(),
            system_prompt: "sys".to_string(),
            context_prompt: "ctx".to_string(),
            response_schema: None,
            temperature: 0.7,
        };
        let res = client.generate(req).await.expect("generate failed");
        assert_eq!(res.content, "{}");
    }
}
