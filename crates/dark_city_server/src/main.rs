//! Main entry point for the Dark City backend server.
//! This is only a stub to allow for the docker container to assess health
//! This stub should be replaced during actual development cycle. 


use dark_city_server::{get_health_status, ServerConfig};
use tracing::info;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let config = ServerConfig::from_env();
    info!("Starting Dark City backend server...");
    info!("Binding configuration: {}", config.socket_addr());

    if let Some(ref db_url) = config.database_url {
        // Redact credentials in logs if present
        let sanitized = db_url.split('@').next_back().unwrap_or(db_url);
        info!("Database endpoint configured: ...@{}", sanitized);
    } else {
        info!("No DATABASE_URL configured (running in unpersisted mode)");
    }

    if let Some(ref inference_url) = config.inference_gateway_url {
        info!("Inference gateway endpoint configured: {}", inference_url);
    } else {
        info!("No INFERENCE_GATEWAY_URL configured (running in standalone mode)");
    }

    let health = get_health_status();
    info!("Initial server health status: {:?}", health);

    info!("Dark City backend server initialized. Waiting for termination signals...");

    wait_for_shutdown_signal().await;

    info!("Dark City backend server shut down cleanly.");
}

/// Waits for an OS termination signal (SIGINT/SIGTERM on Unix or Ctrl+C).
async fn wait_for_shutdown_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};

        let mut sigterm =
            signal(SignalKind::terminate()).expect("Failed to register SIGTERM signal handler");
        let mut sigint =
            signal(SignalKind::interrupt()).expect("Failed to register SIGINT signal handler");

        tokio::select! {
            _ = tokio::signal::ctrl_c() => {
                info!("Received Ctrl+C interrupt signal");
            }
            _ = sigterm.recv() => {
                info!("Received SIGTERM termination signal");
            }
            _ = sigint.recv() => {
                info!("Received SIGINT termination signal");
            }
        }
    }

    #[cfg(not(unix))]
    {
        if let Err(err) = tokio::signal::ctrl_c().await {
            tracing::error!("Failed to listen for Ctrl+C shutdown signal: {:?}", err);
        } else {
            info!("Received Ctrl+C shutdown signal");
        }
    }
}
