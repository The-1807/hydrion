//! core/crates/hydrion-i18n/src/error.rs
//!
//! hydrion-i18n error layer: unified failure types for translation,
//! locale detection, and file parsing.

use thiserror::Error;

/// Primary error type for Hydrion internationalization operations.
#[derive(Debug, Error, Clone)]
pub enum I18nError {
    #[error("Translation file not found: {0}")]
    FileNotFound(String),

    #[error("Failed to read translation file: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid or malformed translation JSON: {0}")]
    Parse(#[from] serde_json::Error),

    #[error("Missing translation key: {0}")]
    MissingKey(String),

    #[error("Unsupported or unknown language code: {0}")]
    UnsupportedLanguage(String),

    #[error("System language detection failed")]
    LanguageDetectionFailed,

    #[error("Internal i18n error: {0}")]
    Internal(String),
}

impl I18nError {
    #[inline] pub fn missing<K: Into<String>>(k: K) -> Self {
        Self::MissingKey(k.into())
    }
    #[inline] pub fn unsupported<L: Into<String>>(code: L) -> Self {
        Self::UnsupportedLanguage(code.into())
    }
    #[inline] pub fn internal<M: Into<String>>(msg: M) -> Self {
        Self::Internal(msg.into())
    }
}

pub type I18nResult<T> = Result<T, I18nError>;
