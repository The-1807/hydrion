/// core\crates\hydrion-crypto\src\envelope.rs

use crate::error::CryptoError;
use crate::rng::{random_u64, Nonce12};
use aes_gcm::{
    aead::{Aead, AeadInPlace},
    Aes256Gcm, KeyInit, Nonce,
};
use core::fmt;

pub type KeyId = u64;
const AES_256_GCM: u8 = 1;

#[derive(Clone)]
pub struct EncryptionEnvelope {
    pub cipher_id: u8,
    pub key_id: KeyId,
    pub nonce: [u8; 12],
    pub tag: [u8; 16],
    pub ciphertext: Vec<u8>,
}

impl fmt::Debug for EncryptionEnvelope {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("EncryptionEnvelope")
            .field("cipher_id", &self.cipher_id)
            .field("key_id", &self.key_id)
            .field("nonce_hex", &hex::encode(self.nonce))
            .field("tag_hex", &hex::encode(self.tag))
            .field("ciphertext_len", &self.ciphertext.len())
            .finish()
    }
}

#[derive(Clone)]
pub struct EncryptedData(EncryptionEnvelope);
impl EncryptedData {
    #[inline] pub fn into_inner(self) -> EncryptionEnvelope { self.0 }
    #[inline] pub fn as_inner(&self) -> &EncryptionEnvelope { &self.0 }
}

pub trait KeyRing {
    fn get_key(&self, id: &KeyId) -> Result<&[u8; 32], CryptoError>;
    fn insert_key(&mut self, id: KeyId, key: [u8; 32]) -> Result<(), CryptoError>;
    fn remove_key(&mut self, id: &KeyId) -> Result<(), CryptoError>;
}

#[inline]
pub fn encrypt_data_with_aad(
    keyring: &impl KeyRing,
    key_id: KeyId,
    plaintext: &[u8],
    aad: &[u8],
) -> Result<EncryptedData, CryptoError> {
    let key = keyring.get_key(&key_id)?;
    if key.len() != 32 { return Err(CryptoError::InvalidKey); }

    let cipher = Aes256Gcm::new(key.into());
    let nonce = Nonce12::generate().0;
    let nonce_ref = Nonce::<Aes256Gcm>::from_slice(&nonce);

    let mut buf = plaintext.to_vec();
    let tag = cipher
        .encrypt_in_place_detached(nonce_ref, aad, &mut buf)
        .map_err(|_| CryptoError::EncryptionFailed)?;

    Ok(EncryptedData(EncryptionEnvelope {
        cipher_id: AES_256_GCM,
        key_id,
        nonce,
        tag: tag.into(),
        ciphertext: buf,
    }))
}

#[inline]
pub fn encrypt_data(
    keyring: &impl KeyRing,
    key_id: KeyId,
    plaintext: &[u8],
) -> Result<EncryptedData, CryptoError> {
    encrypt_data_with_aad(keyring, key_id, plaintext, &[])
}

#[inline]
pub fn decrypt_data_with_aad(
    keyring: &impl KeyRing,
    envelope: &EncryptionEnvelope,
    aad: &[u8],
) -> Result<Vec<u8>, CryptoError> {
    if envelope.cipher_id != AES_256_GCM {
        return Err(CryptoError::UnsupportedCipher);
    }
    let key = keyring.get_key(&envelope.key_id)?;
    if key.len() != 32 { return Err(CryptoError::InvalidKey); }

    let cipher = Aes256Gcm::new(key.into());
    let nonce_ref = Nonce::<Aes256Gcm>::from_slice(&envelope.nonce);

    let mut plaintext = envelope.ciphertext.clone();
    cipher
        .decrypt_in_place_detached(nonce_ref, aad, &mut plaintext, &envelope.tag.into())
        .map_err(|_| CryptoError::AuthenticationFailed)?;
    Ok(plaintext)
}

#[inline]
pub fn decrypt_data(
    keyring: &impl KeyRing,
    envelope: &EncryptionEnvelope,
) -> Result<Vec<u8>, CryptoError> {
    decrypt_data_with_aad(keyring, envelope, &[])
}

pub fn seal_auto(
    keyring: &mut impl KeyRing,
    plaintext: &[u8],
) -> Result<(KeyId, EncryptedData), CryptoError> {
    let key_id = generate_key_id();
    let mut key = [0u8; 32];
    crate::rng::fill_bytes(&mut key);
    keyring.insert_key(key_id, key)?;
    let encrypted = encrypt_data(keyring, key_id, plaintext)?;
    Ok((key_id, encrypted))
}

#[inline]
pub fn open_sealed(
    keyring: &impl KeyRing,
    _key_id: KeyId,
    data: EncryptedData,
) -> Result<Vec<u8>, CryptoError> {
    decrypt_data(keyring, data.as_inner())
}

pub fn rekey_envelope(
    keyring: &mut impl KeyRing,
    old_env: &EncryptionEnvelope,
    new_key_id: KeyId,
    aad: &[u8],
) -> Result<EncryptedData, CryptoError> {
    let pt = decrypt_data_with_aad(keyring, old_env, aad)?;
    encrypt_data_with_aad(keyring, new_key_id, &pt, aad)
}

#[inline(always)]
fn generate_key_id() -> KeyId {
    random_u64()
}
