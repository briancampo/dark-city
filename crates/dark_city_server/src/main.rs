//! Main entry point for the Dark City backend server.

use dark_city_server::get_health_status;
use tracing::info;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    info!("Starting Dark City backend server...");
    let health = get_health_status();
    info!("Initial server status: {:?}", health);
}
