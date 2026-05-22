//! hydrion-time
//!
//! Core time and scheduling utilities for Hydrion.
//! Provides:
//! - timezone and daily-cycle helpers (`tz`)
//! - quiet-hours computation and policy logic (`quiet_hours`)
//!
//! All functions are timezone-aware and safe for embedded or cloud builds.
//! Designed for deterministic use in AI policy evaluation and user scheduling.

pub mod quiet_hours;
pub mod tz;

pub use quiet_hours::*;
pub use tz::*;

/// Returns crate semantic version at compile time for diagnostics.
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}
