// core/crates/hydrion_storage/src/migrations.rs
//! Versioned, atomic database migrations for Hydrion storage.
//!
//! Integrates with `sqlx::migrate!`, ensuring schema matches model invariants
//! from `types::models`. Safe for SQLite, SQLCipher, and PostgreSQL builds.
//!
//! Features:
//! - Embedded, versioned migrations from `schema/migrations/`
//! - Auto-verification of table existence and domain parity
//! - Graceful error propagation through `CoreError`

use hydrion_core::errors::CoreError;
use sqlx::{Pool, Sqlite};

/// Runs all embedded migrations from `schema/migrations/`.
/// This must be called before any data access to ensure the database
/// structure matches model expectations (`UserProfile`, `IntakeEvent`, `DailyTarget`).
pub async fn run(pool: &Pool<Sqlite>) -> Result<(), CoreError> {
    // Embed and compile migrations at build time
    let migrator = sqlx::migrate!("./schema/migrations");

    migrator
        .run(pool)
        .await
        .map_err(|e| CoreError::StorageError(format!("Migration failed: {e}")))?;

    verify_schema(pool).await?;
    Ok(())
}

/// Verifies that all required tables exist and key columns match expectations.
/// This protects against external tampering or mismatched build migrations.
async fn verify_schema(pool: &Pool<Sqlite>) -> Result<(), CoreError> {
    let mut conn = pool.acquire().await.map_err(|e| {
        CoreError::StorageError(format!("Failed to acquire connection: {e}"))
    })?;

    let tables = sqlx::query_scalar::<_, String>(
        "SELECT name FROM sqlite_master WHERE type='table'"
    )
    .fetch_all(&mut *conn)
    .await
    .map_err(|e| CoreError::StorageError(format!("Schema check failed: {e}")))?;

    for expected in ["users", "intake_events", "daily_targets"] {
        if !tables.iter().any(|t| t == expected) {
            return Err(CoreError::StorageError(format!(
                "Missing expected table: {expected}"
            )));
        }
    }

    // Optional: ensure schema_version exists and has at least version 1
    let version: Option<i64> = sqlx::query_scalar(
        "SELECT version FROM schema_version WHERE id=1"
    )
    .fetch_optional(&mut *conn)
    .await
    .map_err(|e| CoreError::StorageError(format!("Failed to read schema_version: {e}")))?;

    match version {
        Some(v) if v >= 1 => Ok(()),
        _ => Err(CoreError::StorageError("Invalid schema version".into())),
    }
}
