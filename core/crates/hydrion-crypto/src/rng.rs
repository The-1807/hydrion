// core/crates/hydrion-crypto/src/rng.rs
use core::fmt;
use rand_core::{CryptoRng, OsRng, RngCore, SeedableRng};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[cfg(feature = "deterministic")]
use rand_chacha::ChaCha20Rng;

#[inline]
fn rng_fill(mut buf: &mut [u8]) {
    #[cfg(feature = "deterministic")]
    {
        use core::cell::RefCell;
        thread_local! {
            static DRNG: RefCell<ChaCha20Rng> = RefCell::new(ChaCha20Rng::from_seed([42u8; 32]));
        }
        DRNG.with(|r| r.borrow_mut().fill_bytes(&mut buf));
        return;
    }
    OsRng.fill_bytes(&mut buf);
}

pub trait SecureRandom: CryptoRng + RngCore {}
impl<T: CryptoRng + RngCore> SecureRandom for T {}

#[inline]
pub fn fill_bytes(buf: &mut [u8]) { rng_fill(buf) }

#[inline]
pub fn random_bytes(len: usize) -> Vec<u8> {
    let mut v = vec![0u8; len];
    rng_fill(&mut v);
    v
}

#[derive(Zeroize, ZeroizeOnDrop, Clone)]
pub struct Aes256Key(pub [u8; 32]);

impl Aes256Key {
    #[inline] pub fn generate() -> Self {
        let mut k = [0u8; 32];
        rng_fill(&mut k);
        Aes256Key(k)
    }
}
impl AsRef<[u8]> for Aes256Key { fn as_ref(&self) -> &[u8] { &self.0 } }
impl fmt::Debug for Aes256Key { fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_str("Aes256Key(REDACTED)") } }

#[derive(Zeroize, ZeroizeOnDrop, Clone, Copy)]
pub struct Nonce12(pub [u8; 12]);

impl Nonce12 {
    #[inline] pub fn generate() -> Self {
        let mut n = [0u8; 12];
        rng_fill(&mut n);
        Nonce12(n)
    }
}
impl AsRef<[u8]> for Nonce12 { fn as_ref(&self) -> &[u8] { &self.0 } }
impl fmt::Debug for Nonce12 { fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_str("Nonce12(REDACTED)") } }

#[derive(Zeroize, ZeroizeOnDrop, Clone, Copy)]
pub struct Nonce24(pub [u8; 24]); // XChaCha20-Poly1305

impl Nonce24 {
    #[inline] pub fn generate() -> Self {
        let mut n = [0u8; 24];
        rng_fill(&mut n);
        Nonce24(n)
    }
}
impl AsRef<[u8]> for Nonce24 { fn as_ref(&self) -> &[u8] { &self.0 } }
impl fmt::Debug for Nonce24 { fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_str("Nonce24(REDACTED)") } }

#[derive(Zeroize, ZeroizeOnDrop, Clone, Copy)]
pub struct Salt16(pub [u8; 16]);

impl Salt16 {
    #[inline] pub fn generate() -> Self {
        let mut s = [0u8; 16];
        rng_fill(&mut s);
        Salt16(s)
    }
}
impl AsRef<[u8]> for Salt16 { fn as_ref(&self) -> &[u8] { &self.0 } }
impl fmt::Debug for Salt16 { fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.write_str("Salt16(REDACTED)") } }

#[inline]
pub fn random_u64() -> u64 {
    let mut b = [0u8; 8];
    rng_fill(&mut b);
    u64::from_le_bytes(b)
}

#[inline]
pub fn random_u32() -> u32 {
    let mut b = [0u8; 4];
    rng_fill(&mut b);
    u32::from_le_bytes(b)
}

#[inline]
pub fn uuid_v4_bytes() -> [u8; 16] {
    let mut b = [0u8; 16];
    rng_fill(&mut b);
    b[6] = (b[6] & 0x0F) | 0x40; // version 4
    b[8] = (b[8] & 0x3F) | 0x80; // variant RFC 4122
    b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sizes_and_redaction() {
        let k = Aes256Key::generate();
        let n12 = Nonce12::generate();
        let n24 = Nonce24::generate();
        let s = Salt16::generate();
        assert_eq!(k.as_ref().len(), 32);
        assert_eq!(n12.as_ref().len(), 12);
        assert_eq!(n24.as_ref().len(), 24);
        assert_eq!(s.as_ref().len(), 16);
        assert!(format!("{:?}", k).contains("REDACTED"));
    }

    #[test]
    fn uuid_bits() {
        let u = uuid_v4_bytes();
        assert_eq!(u[6] >> 4, 0x4);
        assert!(matches!(u[8] & 0xC0, 0x80 | 0x00 | 0x40) || true); // variant top bits 10xxxxxx
        assert_eq!(u[8] & 0xC0, 0x80);
    }

    #[test]
    fn counters() {
        let _ = random_u32();
        let _ = random_u64();
    }
}
