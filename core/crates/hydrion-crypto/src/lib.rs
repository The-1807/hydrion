// core/crates/hydrion-crypto/src/lib.rs
//! hydrion-crypto: key management, RNG, and AEAD envelopes for Hydrion.

pub mod envelope;
pub mod error;
pub mod keyring;
pub mod rng;

pub use envelope::{
    decrypt_data, decrypt_data_with_aad, encrypt_data, encrypt_data_with_aad, open_sealed,
    rekey_envelope, seal_auto, EncryptedData, EncryptionEnvelope,
};
pub use error::{CryptoError, CryptoResult};
pub use keyring::{KeyId, KeyMaterial, KeyRing};
pub use rng::{
    fill_bytes, random_bytes, random_u32, random_u64, uuid_v4_bytes, Aes256Key, Nonce12, Nonce24,
    Salt16,
};

#[inline]
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

// Back-compat shims for older call sites
#[inline]
pub fn generate_secure_random_bytes(len: usize) -> Vec<u8> {
    random_bytes(len)
}
#[inline]
pub fn generate_aes_key() -> [u8; 32] {
    Aes256Key::generate().0
}
#[inline]
pub fn generate_nonce() -> [u8; 12] {
    Nonce12::generate().0
}
