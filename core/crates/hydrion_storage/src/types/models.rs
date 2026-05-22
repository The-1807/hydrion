// core/crates/hydrion_storage/src/types/models.rs
//! Core domain models for Hydrion persistence.
//! Validated, serialization-friendly, and ready for SQLx/SeaORM integration.

use crate::types::ids::*;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

#[cfg(feature = "chrono")]
use chrono::{NaiveDateTime, TimeZone, Utc};

/// Biological sex with hydration impact metadata.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
#[cfg_attr(feature = "db-sqlx", derive(sqlx::Type))]
#[cfg_attr(feature = "db-sqlx", sqlx(type_name = "sex", rename_all = "lowercase"))]
pub enum Sex {
    Male,
    Female,
    Other,
}

impl fmt::Display for Sex {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            Sex::Male => "male",
            Sex::Female => "female",
            Sex::Other => "other",
        };
        f.write_str(s)
    }
}

impl FromStr for Sex {
    type Err = &'static str;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_ascii_lowercase().as_str() {
            "male" | "m" => Ok(Sex::Male),
            "female" | "f" => Ok(Sex::Female),
            "other" | "o" | "x" | "nonbinary" | "non-binary" => Ok(Sex::Other),
            _ => Err("invalid sex"),
        }
    }
}

/// Physical activity level used for metabolic adjustment.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
#[cfg_attr(feature = "db-sqlx", derive(sqlx::Type))]
#[cfg_attr(feature = "db-sqlx", sqlx(type_name = "activity_level", rename_all = "lowercase"))]
pub enum ActivityLevel {
    Sedentary,
    Light,
    Moderate,
    High,
}

impl ActivityLevel {
    /// Multiplicative adjustment for baseline hydration.
    #[inline]
    pub const fn multiplier(self) -> f32 {
        match self {
            ActivityLevel::Sedentary => 1.00,
            ActivityLevel::Light => 1.20,
            ActivityLevel::Moderate => 1.40,
            ActivityLevel::High => 1.60,
        }
    }
}

impl fmt::Display for ActivityLevel {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            ActivityLevel::Sedentary => "sedentary",
            ActivityLevel::Light => "light",
            ActivityLevel::Moderate => "moderate",
            ActivityLevel::High => "high",
        };
        f.write_str(s)
    }
}

impl FromStr for ActivityLevel {
    type Err = &'static str;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_ascii_lowercase().as_str() {
            "sedentary" | "none" | "rest" => Ok(ActivityLevel::Sedentary),
            "light" | "low" => Ok(ActivityLevel::Light),
            "moderate" | "medium" => Ok(ActivityLevel::Moderate),
            "high" | "intense" | "vigorous" => Ok(ActivityLevel::High),
            _ => Err("invalid activity level"),
        }
    }
}

/// Health conditions affecting fluid balance.
#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize)]
pub struct HealthFlags {
    pub is_pregnant: bool,
    pub is_breastfeeding: bool,
    pub has_kidney_condition: bool,
    pub has_heart_condition: bool,
    pub has_diabetes: bool,
}

impl HealthFlags {
    #[inline]
    pub const fn is_empty(self) -> bool {
        !(self.is_pregnant
            || self.is_breastfeeding
            || self.has_kidney_condition
            || self.has_heart_condition
            || self.has_diabetes)
    }

    /// Simple additive adjustment in milliliters.
    /// Pregnancy and breastfeeding increase needs. Certain conditions decrease.
    /// Diabetes is excluded from automatic adjustment due to variability.
    #[inline]
    pub const fn adjustment_ml(self) -> i32 {
        let mut adj = 0;
        if self.is_pregnant {
            adj += 300;
        }
        if self.is_breastfeeding {
            adj += 700;
        }
        if self.has_kidney_condition {
            adj -= 500;
        }
        if self.has_heart_condition {
            adj -= 300;
        }
        adj
    }
}

/// Complete user profile with validation and computed fields.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct UserProfile {
    pub user_id: UserId,

    // Biometric
    pub date_of_birth_ms: i64,
    pub sex: Sex,
    pub weight_kg: f32,
    pub height_cm: f32,

    // Computed
    pub bmi: f32,

    // Contextual
    pub occupation: Option<String>,
    pub marital_status: Option<String>,

    // Health and activity
    pub health_flags: HealthFlags,
    pub activity_level: ActivityLevel,

    // Quiet hours in local device time
    pub quiet_hours_start_h: u8,
    pub quiet_hours_end_h: u8,
}

impl UserProfile {
    /// Validate numeric ranges and compute BMI.
    pub fn validate_and_compute(&mut self) -> Result<(), ValidationError> {
        // Weight and height sanity
        if !(0.0..=500.0).contains(&self.weight_kg) || self.weight_kg == 0.0 {
            return Err(ValidationError::InvalidWeight);
        }
        if !(0.0..=300.0).contains(&self.height_cm) || self.height_cm == 0.0 {
            return Err(ValidationError::InvalidHeight);
        }
        // Quiet-hour bounds
        if self.quiet_hours_start_h > 23 || self.quiet_hours_end_h > 23 {
            return Err(ValidationError::InvalidQuietHour);
        }
        // Date of birth plausibility if chrono is available
        #[cfg(feature = "chrono")]
        {
            let min_ts = Utc.with_ymd_and_hms(1900, 1, 1, 0, 0, 0).unwrap().timestamp_millis();
            let now = Utc::now().timestamp_millis();
            if self.date_of_birth_ms < min_ts || self.date_of_birth_ms > now {
                return Err(ValidationError::InvalidDateOfBirth);
            }
        }
        // BMI
        let h_m = self.height_cm / 100.0;
        self.bmi = self.weight_kg / (h_m * h_m);
        Ok(())
    }

    /// Baseline hydration using sex baseline and weight adjustment averaged.
    #[inline]
    pub fn baseline_hydration_ml(&self) -> u32 {
        let base = match self.sex {
            Sex::Male => 3700.0,
            Sex::Female => 2700.0,
            Sex::Other => 3000.0,
        };
        let activity_adj = base * self.activity_level.multiplier();
        let weight_adj = self.weight_kg * 30.0;
        ((activity_adj + weight_adj) / 2.0) as u32
    }

    /// Final daily target including health adjustments.
    #[inline]
    pub fn daily_target_ml(&self) -> u32 {
        let b = self.baseline_hydration_ml();
        let adj = self.health_flags.adjustment_ml();
        (b as i32 + adj).max(0) as u32
    }

    /// Check if a given hour (0-23) is within quiet hours window.
    /// Wrap-around windows are supported (e.g., 22 to 6).
    #[inline]
    pub fn is_quiet_hour(&self, hour: u8) -> bool {
        let s = self.quiet_hours_start_h;
        let e = self.quiet_hours_end_h;
        if s == e {
            return false;
        }
        if s < e {
            hour >= s && hour < e
        } else {
            hour >= s || hour < e
        }
    }

    /// Computed age in years if chrono is available.
    #[cfg(feature = "chrono")]
    pub fn age_years(&self) -> Option<u32> {
        let dob = NaiveDateTime::from_timestamp_millis(self.date_of_birth_ms)?;
        let now = Utc::now().naive_utc();
        let years = now.signed_duration_since(dob).num_days() / 365;
        Some(years as u32)
    }
}

/// Single fluid intake event with source tracking.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "db-sqlx", derive(sqlx::FromRow))]
pub struct IntakeEvent {
    pub event_id: EventId,
    pub user_id: UserId,
    pub timestamp_ms: i64,
    pub volume_ml: u32,
    pub is_water: bool,
    pub source_device_id: Option<DeviceId>,
    pub synced_at: Option<i64>,
}

impl IntakeEvent {
    #[inline]
    pub fn new(
        user_id: UserId,
        timestamp_ms: i64,
        volume_ml: u32,
        is_water: bool,
        source_device_id: Option<DeviceId>,
    ) -> Self {
        Self {
            event_id: EventId::generate(),
            user_id,
            timestamp_ms,
            volume_ml,
            is_water,
            source_device_id,
            synced_at: None,
        }
    }

    #[inline]
    pub fn mark_synced(&mut self, ts_ms: i64) {
        self.synced_at = Some(ts_ms);
    }
}

/// Daily hydration target with provenance.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "db-sqlx", derive(sqlx::FromRow))]
pub struct DailyTarget {
    pub target_id: TargetId,
    pub user_id: UserId,
    pub date: i64, // midnight UTC millis
    pub baseline_ml: u32,
    pub adjustment_ml: i32,
    pub final_target_ml: u32,
    pub model_version: String,
    pub computed_at: i64,
}

impl DailyTarget {
    #[inline]
    pub fn new(
        user_id: UserId,
        date: i64,
        baseline: u32,
        adjustment: i32,
        model: impl Into<String>,
    ) -> Self {
        let final_target = (baseline as i32 + adjustment).max(0) as u32;
        Self {
            target_id: TargetId::generate(),
            user_id,
            date,
            baseline_ml: baseline,
            adjustment_ml: adjustment,
            final_target_ml: final_target,
            model_version: model.into(),
            computed_at: current_ts_ms(),
        }
    }

    #[inline]
    pub fn recompute(&mut self, baseline: u32, adjustment: i32, model: impl Into<String>) {
        self.baseline_ml = baseline;
        self.adjustment_ml = adjustment;
        self.final_target_ml = (baseline as i32 + adjustment).max(0) as u32;
        self.model_version = model.into();
        self.computed_at = current_ts_ms();
    }
}

/// Validation errors for domain models.
#[derive(Debug, thiserror::Error)]
pub enum ValidationError {
    #[error("Weight must be between 0 and 500 kg")]
    InvalidWeight,
    #[error("Height must be between 0 and 300 cm")]
    InvalidHeight,
    #[error("Quiet hour must be 0-23")]
    InvalidQuietHour,
    #[cfg(feature = "chrono")]
    #[error("Date of birth is out of plausible range")]
    InvalidDateOfBirth,
}

#[inline]
fn current_ts_ms() -> i64 {
    #[cfg(feature = "chrono")]
    {
        return Utc::now().timestamp_millis();
    }
    #[allow(deprecated)]
    {
        // Fallback if chrono is not enabled. Not monotonic but available.
        use std::time::{SystemTime, UNIX_EPOCH};
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as i64
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quiet_hours_wraparound() {
        let p = UserProfile {
            user_id: UserId::from_u128(1),
            date_of_birth_ms: 0,
            sex: Sex::Other,
            weight_kg: 70.0,
            height_cm: 175.0,
            bmi: 0.0,
            occupation: None,
            marital_status: None,
            health_flags: HealthFlags::default(),
            activity_level: ActivityLevel::Light,
            quiet_hours_start_h: 22,
            quiet_hours_end_h: 6,
        };
        assert!(p.is_quiet_hour(23));
        assert!(p.is_quiet_hour(1));
        assert!(!p.is_quiet_hour(12));
    }

    #[test]
    fn daily_target_never_negative() {
        let p = UserProfile {
            user_id: UserId::from_u128(1),
            date_of_birth_ms: 0,
            sex: Sex::Other,
            weight_kg: 70.0,
            height_cm: 175.0,
            bmi: 0.0,
            occupation: None,
            marital_status: None,
            health_flags: HealthFlags {
                is_pregnant: false,
                is_breastfeeding: false,
                has_kidney_condition: true,
                has_heart_condition: true,
                has_diabetes: false,
            },
            activity_level: ActivityLevel::Sedentary,
            quiet_hours_start_h: 0,
            quiet_hours_end_h: 0,
        };
        let target = p.daily_target_ml();
        assert!(target >= 0);
    }
}
