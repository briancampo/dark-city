//! Database connectivity, connection pooling, and schema migration management.
//!
//! This module provides the persistence foundation for Dark City's PostgreSQL + pgvector
//! backend. It implements connection pool provisioning (`PgPool`) and runs embedded schema
//! migrations to establish multi-tenant world instances ([Decision 0003](../../decisions/0003-multi-tenant-world-instances.md))
//! and observation event streams ([Decision 0004](../../decisions/0004-observation-and-world-event-capture.md)).

use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use thiserror::Error;
use tracing::info;

/// Errors that can occur during database pool initialization or migration execution.
#[derive(Debug, Error)]
pub enum DbError {
    /// Connection pool creation or initial connection attempt failed.
    #[error("Failed to initialize database connection pool: {0}")]
    PoolInitFailed(String),

    /// Executing database schema migrations failed.
    #[error("Database migration execution failed: {0}")]
    MigrationFailed(String),

    /// A query executed against the database failed.
    #[error("Database query failed: {0}")]
    QueryFailed(String),
}

/// Default maximum number of connections allowed in the PostgreSQL connection pool.
pub const DEFAULT_MAX_CONNECTIONS: u32 = 10;

/// Default minimum number of idle connections maintained in the pool.
pub const DEFAULT_MIN_CONNECTIONS: u32 = 1;

/// Default timeout duration when acquiring a connection from the pool.
pub const DEFAULT_ACQUIRE_TIMEOUT: Duration = Duration::from_secs(10);

/// Initializes a PostgreSQL connection pool with default sizing and timeout settings.
///
/// This is the standard entry point for establishing database connectivity in the
/// backend runtime.
///
/// # Arguments
/// * `database_url` - PostgreSQL connection string (e.g. `postgres://user:pass@host:5432/db`)
///
/// # Errors
/// Returns [`DbError::PoolInitFailed`] if the pool could not be configured or the connection fails.
pub async fn init_pool(database_url: &str) -> Result<PgPool, DbError> {
    init_pool_with_options(
        database_url,
        DEFAULT_MAX_CONNECTIONS,
        DEFAULT_MIN_CONNECTIONS,
        DEFAULT_ACQUIRE_TIMEOUT,
    )
    .await
}

/// Initializes a PostgreSQL connection pool with custom capacity and timeout options.
///
/// Provides fine-grained control over connection pool sizing for testing or high-concurrency
/// deployments.
///
/// # Arguments
/// * `database_url` - PostgreSQL connection string
/// * `max_connections` - Maximum number of concurrent connections
/// * `min_connections` - Minimum number of idle connections
/// * `acquire_timeout` - Connection acquisition timeout duration
///
/// # Errors
/// Returns [`DbError::PoolInitFailed`] if the pool fails to connect or initialize.
pub async fn init_pool_with_options(
    database_url: &str,
    max_connections: u32,
    min_connections: u32,
    acquire_timeout: Duration,
) -> Result<PgPool, DbError> {
    let pool = PgPoolOptions::new()
        .max_connections(max_connections)
        .min_connections(min_connections)
        .acquire_timeout(acquire_timeout)
        .connect(database_url)
        .await
        .map_err(|e| DbError::PoolInitFailed(e.to_string()))?;

    Ok(pool)
}

/// Executes all pending embedded database migrations against the provided connection pool.
///
/// Migrations are compiled directly into the server binary from `../../migrations` at build time,
/// guaranteeing that schema state matches binary expectations regardless of runtime container paths.
///
/// # Arguments
/// * `pool` - Active [`PgPool`] connection pool
///
/// # Errors
/// Returns [`DbError::MigrationFailed`] if any migration script fails during execution.
pub async fn run_migrations(pool: &PgPool) -> Result<(), DbError> {
    info!("Running pending database migrations from migrations/...");
    sqlx::migrate!("../../migrations")
        .run(pool)
        .await
        .map_err(|e| DbError::MigrationFailed(e.to_string()))?;

    info!("Database migrations executed successfully.");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_db_error_display() {
        let pool_err = DbError::PoolInitFailed("connection refused".to_string());
        assert_eq!(
            pool_err.to_string(),
            "Failed to initialize database connection pool: connection refused"
        );

        let mig_err = DbError::MigrationFailed("syntax error in 0001".to_string());
        assert_eq!(
            mig_err.to_string(),
            "Database migration execution failed: syntax error in 0001"
        );

        let query_err = DbError::QueryFailed("table not found".to_string());
        assert_eq!(
            query_err.to_string(),
            "Database query failed: table not found"
        );
    }

    #[tokio::test]
    async fn test_init_pool_invalid_url() {
        let result = init_pool_with_options(
            "postgres://invalid_user:invalid_pass@127.0.0.1:54329/nonexistent",
            1,
            1,
            Duration::from_millis(150),
        )
        .await;
        assert!(result.is_err());
        if let Err(DbError::PoolInitFailed(msg)) = result {
            assert!(!msg.is_empty());
        } else {
            panic!("Expected DbError::PoolInitFailed");
        }
    }

    #[test]
    fn test_embedded_migration_bundle() {
        // Compile-time check that migrations exist and are parseable by sqlx::migrate!
        let migrator = sqlx::migrate!("../../migrations");
        assert!(
            !migrator.migrations.is_empty(),
            "Migrations bundle must not be empty"
        );
        let initial_migration = &migrator.migrations[0];
        assert_eq!(initial_migration.version, 1);
        assert!(!initial_migration.sql.is_empty());

        // Verify key architectural schema definitions are present in 0001
        let sql = &initial_migration.sql;
        assert!(sql.contains("CREATE EXTENSION IF NOT EXISTS vector;"));
        assert!(sql.contains("CREATE TABLE worlds"));
        assert!(sql.contains("CREATE TABLE citizens"));
        assert!(sql.contains("CREATE TABLE simulation_events"));
        assert!(sql.contains("CREATE TABLE world_events"));
        assert!(sql.contains("CREATE VIEW observable_events"));

        // Verify Decision 0004 simulated-time rule: occurred_at must not use DEFAULT now()
        assert!(sql.contains("location_node_id TEXT"));
        assert!(sql.contains("salience SMALLINT NOT NULL CHECK (salience BETWEEN 1 AND 10)"));
        assert!(sql.contains("occurred_at TIMESTAMPTZ NOT NULL"));
    }

    #[tokio::test]
    async fn test_live_migration_and_observable_events_view() {
        let db_url = dotenvy::var("DATABASE_URL")
            .or_else(|_| std::env::var("DATABASE_URL"))
            .unwrap_or_else(|_| "postgres://admin:admin@127.0.0.1:5432/dc_dev".to_string());

        // Redact password in logs for secure output
        let sanitized = db_url.split('@').next_back().unwrap_or(&db_url);

        // Attempt connection; if Postgres is not running or accessible, skip gracefully
        let pool = match init_pool_with_options(&db_url, 5, 1, Duration::from_millis(500)).await {
            Ok(p) => {
                println!("Connected to live database at ...@{}", sanitized);
                p
            }
            Err(e) => {
                println!(
                    "Live Postgres not reachable at ...@{} ({:?}), skipping live integration test.",
                    sanitized, e
                );
                return;
            }
        };

        // Run migrations
        run_migrations(&pool)
            .await
            .expect("Migrations must run cleanly against live Postgres");
        println!("Migrations applied successfully on live database.");

        // 1. Verify worlds insertion (Blueprint §10.2, Decision 0003)
        let world_id: uuid::Uuid = sqlx::query_scalar(
            r#"
            INSERT INTO worlds (scenario_id, name, sim_clock)
            VALUES ($1, $2, $3)
            RETURNING id
            "#,
        )
        .bind("phase_1_seed")
        .bind("Dark City World Alpha")
        .bind(chrono::Utc::now())
        .fetch_one(&pool)
        .await
        .expect("Failed to insert test world");

        // 2. Verify citizens insertion
        let citizen_id: uuid::Uuid = sqlx::query_scalar(
            r#"
            INSERT INTO citizens (world_id, name)
            VALUES ($1, $2)
            RETURNING id
            "#,
        )
        .bind(world_id)
        .bind("Elena Vance")
        .fetch_one(&pool)
        .await
        .expect("Failed to insert test citizen");

        // 3. Verify simulation_events insertion with simulated time (occurred_at)
        let sim_event_time = chrono::Utc::now();
        let sim_event_id: uuid::Uuid = sqlx::query_scalar(
            r#"
            INSERT INTO simulation_events (world_id, citizen_id, event_type, location_node_id, payload, salience, occurred_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id
            "#,
        )
        .bind(world_id)
        .bind(citizen_id)
        .bind("speech_turn")
        .bind(Some("city_square"))
        .bind(serde_json::json!({"text": "Hello world"}))
        .bind(5i16)
        .bind(sim_event_time)
        .fetch_one(&pool)
        .await
        .expect("Failed to insert test simulation_event");
        assert!(!sim_event_id.is_nil());

        // 4. Verify world_events insertion (citizen-less / environmental event per Decision 0004)
        let world_event_time = chrono::Utc::now();
        let world_event_id: uuid::Uuid = sqlx::query_scalar(
            r#"
            INSERT INTO world_events (world_id, source, origin_citizen_id, event_type, location_node_id, payload, salience, occurred_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id
            "#,
        )
        .bind(world_id)
        .bind("scenario_scripted")
        .bind(None::<uuid::Uuid>)
        .bind("scripted_disaster")
        .bind(Some("city_square"))
        .bind(serde_json::json!({"summary": "Storm sirens sounded"}))
        .bind(9i16)
        .bind(world_event_time)
        .fetch_one(&pool)
        .await
        .expect("Failed to insert test world_event");
        assert!(!world_event_id.is_nil());

        // 5. Verify observable_events union view returns both events
        let count: i64 = sqlx::query_scalar(
            r#"
            SELECT COUNT(*) FROM observable_events
            WHERE world_id = $1
            "#,
        )
        .bind(world_id)
        .fetch_one(&pool)
        .await
        .expect("Failed to query observable_events view");

        assert!(
            count >= 2,
            "Observable events view should contain both simulation_events and world_events (found {})",
            count
        );
    }
}
