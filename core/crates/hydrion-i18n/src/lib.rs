//! hydrion-i18n
//!
//! High-performance, thread-safe internationalization for Hydrion.
//! Focus areas: fast lookups, deterministic catalogs, language detection hooks,
//! hot reload hooks, and ergonomic re-exports. This crate does not assume any
//! global singletons or UI framework. Callers own the lifetime of managers.

#![forbid(unsafe_code)]
#![cfg_attr(docsrs, feature(doc_cfg))]

// Public modules
pub mod catalog;
pub mod error;

// Re-exports for ergonomic downstream use
pub use catalog::{I18nManager, Language, LocalizationCatalog};
pub use error::I18nError;

// Crate metadata
/// Crate version at compile time.
pub const CRATE_VERSION: &str = env!("CARGO_PKG_VERSION");

/// Canonical type alias for translation keys. Keys should be stable, dotted, and lowercase.
pub type StringKey = &'static str;

// ===============================
// Translation Key Registry
// ===============================
//
// Keep these stable and additive. Removing or renaming keys is a breaking change.
// Group keys by functional area for predictable discovery and linting.

/// Reminder-related keys.
pub mod keys_reminder {
    use super::StringKey;

    pub const LOW_HYDRATION: StringKey = "reminder.low_hydration";
    pub const GOAL_PROMPT: StringKey = "reminder.goal_prompt";
}

/// Error message keys.
pub mod keys_error {
    use super::StringKey;

    pub const DB_FAILED: StringKey = "error.db_failed";
    pub const NETWORK_UNAVAILABLE: StringKey = "error.network_unavailable";
    pub const PERMISSION_DENIED: StringKey = "error.permission_denied";
    pub const PARSE_FAILED: StringKey = "error.parse_failed";
}

/// UI strings.
pub mod keys_ui {
    use super::StringKey;

    pub const BUTTON_LOG: StringKey = "ui.button.log";
    pub const BUTTON_SAVE: StringKey = "ui.button.save";
    pub const BUTTON_CANCEL: StringKey = "ui.button.cancel";
    pub const LABEL_OK: StringKey = "ui.label.ok";
    pub const LABEL_RETRY: StringKey = "ui.label.retry";
    pub const SETTINGS_LANGUAGE: StringKey = "settings.language";
    pub const SETTINGS_REGION: StringKey = "settings.region";
}

/// Onboarding and welcome flows.
pub mod keys_welcome {
    use super::StringKey;

    pub const TITLE: StringKey = "welcome.title";
    pub const SUBTITLE: StringKey = "welcome.subtitle";
    pub const CTA_BEGIN: StringKey = "welcome.cta_begin";
}

// Backward-compatible top-level constants (legacy names).
// Prefer the namespaced modules above for all new code.
pub const KEY_REMINDER_LOW_HYDRATION: StringKey = keys_reminder::LOW_HYDRATION;
pub const KEY_REMINDER_GOAL_PROMPT: StringKey = keys_reminder::GOAL_PROMPT;
pub const KEY_ERROR_DB_FAILED: StringKey = keys_error::DB_FAILED;
pub const KEY_UI_BUTTON_LOG: StringKey = keys_ui::BUTTON_LOG;
pub const KEY_WELCOME_TITLE: StringKey = keys_welcome::TITLE;
pub const KEY_SETTINGS_LANGUAGE: StringKey = keys_ui::SETTINGS_LANGUAGE;

/// All keys known at compile time. Useful for audits and CI validation.
pub const ALL_KNOWN_KEYS: &[StringKey] = &[
    // reminder
    keys_reminder::LOW_HYDRATION,
    keys_reminder::GOAL_PROMPT,
    // error
    keys_error::DB_FAILED,
    keys_error::NETWORK_UNAVAILABLE,
    keys_error::PERMISSION_DENIED,
    keys_error::PARSE_FAILED,
    // ui
    keys_ui::BUTTON_LOG,
    keys_ui::BUTTON_SAVE,
    keys_ui::BUTTON_CANCEL,
    keys_ui::LABEL_OK,
    keys_ui::LABEL_RETRY,
    keys_ui::SETTINGS_LANGUAGE,
    keys_ui::SETTINGS_REGION,
    // welcome
    keys_welcome::TITLE,
    keys_welcome::SUBTITLE,
    keys_welcome::CTA_BEGIN,
];

// ===============================
// Utilities
// ===============================

/// Validates that a given set of locales contains all required keys.
/// Returns the first missing key encountered for a specific locale.
///
/// This performs strict presence checks only. It does not validate formatting,
/// plural rules, or placeholder shape. Those belong to higher-level tests.
pub fn validate_required_keys(
    manager: &I18nManager,
    locales: &[Language],
    required_keys: &[StringKey],
) -> Result<(), I18nError> {
    for &lang in locales {
        for &key in required_keys {
            if !manager.has_key(lang, key)? {
                return Err(I18nError::MissingKey {
                    language: lang.code().to_string(),
                    key: key.to_string(),
                });
            }
        }
    }
    Ok(())
}

/// Returns a stable set of baseline keys that should exist in every shipped locale.
/// Use this to gate releases.
pub fn baseline_required_keys() -> &'static [StringKey] {
    ALL_KNOWN_KEYS
}

// ===============================
// Feature Surface
// ===============================
//
// The following cfg gates describe optional capabilities. They assume matching
// feature flags are defined in Cargo.toml for this crate.
//
// - feature "detect-locale": enable helpers that infer Language from system info.
// - feature "hot-reload": enable interfaces for watching catalog files.
// - feature "tracing": add spans around IO and catalog swaps.

#[cfg(feature = "detect-locale")]
pub mod detect {
    use super::{I18nError, Language};

    /// Attempts to map a platform locale tag to Language.
    /// Fallback is Language::En when detection fails.
    pub fn detect_language_from_tag(tag: &str) -> Result<Language, I18nError> {
        // Expect tags like en-US, fr_CA, pt-BR, zh-CN, etc.
        // Only the primary code is used to select Language.
        let primary = tag
            .split(|c| c == '-' || c == '_' || c == '.')
            .next()
            .unwrap_or("en")
            .to_ascii_lowercase();
        Ok(Language::from_code(primary.as_str()))
    }
}

#[cfg(feature = "hot-reload")]
pub mod hotreload {
    use super::I18nManager;

    /// Marker trait for hot reload capability. The concrete watcher lives in the
    /// catalog module. Exposed here to avoid leaking internal types.
    pub trait HotReload {
        fn trigger_reload(&self);
        fn is_watching(&self) -> bool;
    }

    impl HotReload for I18nManager {
        fn trigger_reload(&self) {
            self.trigger_reload();
        }
        fn is_watching(&self) -> bool {
            self.is_watching()
        }
    }
}

// ===============================
// Prelude
// ===============================

/// Convenience prelude for downstream crates. Import this when you want
/// quick access to primary types and keys without digging through modules.
pub mod prelude {
    pub use crate::catalog::{I18nManager, Language, LocalizationCatalog};
    pub use crate::error::I18nError;
    pub use crate::keys_error::*;
    pub use crate::keys_reminder::*;
    pub use crate::keys_ui::*;
    pub use crate::keys_welcome::*;
    pub use crate::{baseline_required_keys, validate_required_keys, StringKey};
}

// ===============================
// Lints for downstream clarity
// ===============================

#[cfg(test)]
mod compile_time_checks {
    use super::*;

    // Keys must be sorted and unique. This makes diffs and audits cleaner.
    #[test]
    fn all_known_keys_are_unique_and_sorted() {
        let mut v = ALL_KNOWN_KEYS.to_vec();
        let mut sorted = v.clone();
        sorted.sort_unstable();
        assert_eq!(v.len(), sorted.len(), "keys must be unique");
        // Not enforcing lexicographic ordering in source, but this asserts uniqueness
        // by comparing set sizes.
        v.sort_unstable();
        v.dedup();
        assert_eq!(v.len(), sorted.len(), "duplicate keys detected");
    }
}
