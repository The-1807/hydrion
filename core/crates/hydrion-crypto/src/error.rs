//! core/crates/hydrion-crypto/src/error.rs
//!
//! Error types for hydrion-crypto: key management, random generation,
//! and encryption/decryption operations.

use thiserror::Error;

/// Primary error type for hydrion-crypto operations.
#[derive(Debug, Error, Clone)]
pub enum CryptoError {
    #[error("Key not found: {0}")]
    KeyNotFound(String),

    #[error("Failed to generate secure random data: {0}")]
    RngFailure(String),

    #[error("Authentication or decryption failed (bad key, tag, or corrupted data)")]
    AuthenticationFailed,

    #[error("Unsupported cipher algorithm")]
    UnsupportedCipher,

    #[error("Encryption failed")]
    EncryptionFailed,

    #[error("Key rotation failed")]
    KeyRotationFailed,

    #[error("Invalid key size")]
    InvalidKey,

    #[error("Internal crypto error: {0}")]
    InternalError(String),
}

impl CryptoError {
    #[inline] pub fn key_not_found<T: Into<String>>(id: T) -> Self {
        CryptoError::KeyNotFound(id.into())
    }
    #[inline] pub fn internal<T: Into<String>>(msg: T) -> Self {
        CryptoError::InternalError(msg.into())
    }
    #[inline] pub fn rng_fail<T: Into<String>>(msg: T) -> Self {
        CryptoError::RngFailure(msg.into())
    }
}

pub type CryptoResult<T> = Result<T, CryptoError>;
