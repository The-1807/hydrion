// core/crates/hydrion-crypto/src/keyring.rs
use crate::error::CryptoError;
use crate::rng::generate_aes_key;
use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum KeyId {
    LocalDb,
    ExportData(String),
    LlmProvider(String),
}

impl KeyId {
    pub fn local_db() -> Self { KeyId::LocalDb }
    pub fn export_data(tag: impl Into<String>) -> Self { KeyId::ExportData(tag.into()) }
    pub fn llm_provider(name: impl Into<String>) -> Self { KeyId::LlmProvider(name.into()) }
    fn alias(&self) -> String {
        match self {
            KeyId::LocalDb => "hydrion_local_db_key".to_string(),
            KeyId::ExportData(tag) => format!("hydrion_export_{}", tag),
            KeyId::LlmProvider(name) => format!("hydrion_llm_{}", name),
        }
    }
}

#[derive(Zeroize, ZeroizeOnDrop, Clone)]
pub struct KeyMaterial(pub [u8; 32]);

impl core::fmt::Debug for KeyMaterial {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.write_str("KeyMaterial(REDACTED)")
    }
}
impl AsRef<[u8]> for KeyMaterial { fn as_ref(&self) -> &[u8] { &self.0 } }

#[derive(Debug, Clone)]
pub struct KeyRing {
    inner: Arc<Mutex<KeyRingInner>>,
}

#[derive(Debug)]
struct KeyRingInner {
    keys: HashMap<KeyId, KeyMaterial>,
}

impl KeyRing {
    pub fn initialize_or_create() -> Result<Self, CryptoError> {
        static INIT: OnceLock<Result<KeyRing, CryptoError>> = OnceLock::new();
        INIT.get_or_init(|| {
            let mut map = HashMap::new();
            let db_id = KeyId::LocalDb;
            let db_key = Self::load_or_generate_key(&db_id, &db_id.alias())?;
            map.insert(db_id, KeyMaterial(db_key));
            Ok(KeyRing {
                inner: Arc::new(Mutex::new(KeyRingInner { keys: map })),
            })
        }).clone()
    }

    pub fn get_key_clone(&self, id: &KeyId) -> Result<[u8; 32], CryptoError> {
        let guard = self.inner.lock().map_err(|_| CryptoError::InternalError("KeyRing poisoned".into()))?;
        guard.keys.get(id)
            .map(|km| km.0)
            .ok_or_else(|| CryptoError::KeyNotFound(format!("{id:?}")))
    }

    pub fn insert_key(&self, id: KeyId, key: [u8; 32]) -> Result<(), CryptoError> {
        let mut guard = self.inner.lock().map_err(|_| CryptoError::InternalError("KeyRing poisoned".into()))?;
        guard.keys.insert(id.clone(), KeyMaterial(key));
        let alias = id.alias();
        drop(guard);
        Self::persist_key(&id, &key, &alias)
    }

    pub fn remove_key(&self, id: &KeyId) -> Result<(), CryptoError> {
        let mut guard = self.inner.lock().map_err(|_| CryptoError::InternalError("KeyRing poisoned".into()))?;
        guard.keys.remove(id).ok_or_else(|| CryptoError::KeyNotFound(format!("{id:?}")))?;
        Ok(())
    }

    pub fn rotate_key(&self, id: &KeyId) -> Result<[u8; 32], CryptoError> {
        let new_key = generate_aes_key();
        let alias = id.alias();
        {
            let mut guard = self.inner.lock().map_err(|_| CryptoError::InternalError("KeyRing poisoned".into()))?;
            guard.keys.insert(id.clone(), KeyMaterial(new_key));
        }
        Self::persist_key(id, &new_key, &alias)?;
        Ok(new_key)
    }

    pub fn contains(&self, id: &KeyId) -> bool {
        self.inner.lock().ok().map_or(false, |g| g.keys.contains_key(id))
    }

    pub fn list_ids(&self) -> Vec<KeyId> {
        self.inner.lock().ok().map_or_else(Vec::new, |g| g.keys.keys().cloned().collect())
    }

    fn load_or_generate_key(id: &KeyId, alias: &str) -> Result<[u8; 32], CryptoError> {
        match Self::load_key_from_secure_storage(alias)? {
            Some(bytes) if bytes.len() == 32 => {
                let mut arr = [0u8; 32];
                arr.copy_from_slice(&bytes);
                Ok(arr)
            }
            _ => {
                let key = generate_aes_key();
                Self::persist_key(id, &key, alias)?;
                Ok(key)
            }
        }
    }

    fn persist_key(id: &KeyId, key: &[u8; 32], alias: &str) -> Result<(), CryptoError> {
        #[cfg(target_os = "android")]
        {
            use android_key_store::AndroidKeyStore;
            AndroidKeyStore::store_key(alias, key).map_err(|e| CryptoError::InternalError(e.to_string()))
        }
        #[cfg(target_os = "ios")]
        {
            use ios_keychain::Keychain;
            Keychain::set(alias, key).map_err(|e| CryptoError::InternalError(e.to_string()))
        }
        #[cfg(not(any(target_os = "android", target_os = "ios")))]
        {
            let _ = (id, key, alias);
            Ok(())
        }
    }

    fn load_key_from_secure_storage(alias: &str) -> Result<Option<Vec<u8>>, CryptoError> {
        #[cfg(target_os = "android")]
        {
            use android_key_store::AndroidKeyStore;
            AndroidKeyStore::get_key(alias).map_err(|e| CryptoError::InternalError(e.to_string()))
        }
        #[cfg(target_os = "ios")]
        {
            use ios_keychain::Keychain;
            Keychain::get(alias).map_err(|e| CryptoError::InternalError(e.to_string()))
        }
        #[cfg(not(any(target_os = "android", target_os = "ios")))]
        {
            let _ = alias;
            Ok(None)
        }
    }
}
