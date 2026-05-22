//! Strongly-typed, monotonic ULID-based identifiers.
//! Zero-collision, globally sortable, and ORM-compatible.

use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;
use ulid::Ulid;

#[macro_export]
macro_rules! define_id {
    ($name:ident, $doc:expr) => {
        #[doc = $doc]
        #[derive(
            Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize
        )]
        #[serde(transparent)]
        pub struct $name(Ulid);

        impl $name {
            /// Generates a new unique identifier.
            #[inline]
            pub fn generate() -> Self {
                Self(Ulid::new())
            }

            /// Creates from an existing ULID.
            #[inline]
            pub fn from_ulid(u: Ulid) -> Self {
                Self(u)
            }

            /// Parses from string representation.
            pub fn from_str(s: &str) -> Result<Self, ulid::DecodeError> {
                Ok(Self(Ulid::from_string(s)?))
            }

            /// Returns the underlying ULID.
            #[inline]
            pub fn inner(&self) -> &Ulid {
                &self.0
            }

            /// Returns canonical string form.
            #[inline]
            pub fn to_string(&self) -> String {
                self.0.to_string()
            }

            /// Returns as 128-bit integer.
            #[inline]
            pub fn to_u128(&self) -> u128 {
                self.0.into()
            }

            /// Rebuilds from a 128-bit integer.
            #[inline]
            pub fn from_u128(v: u128) -> Self {
                Self(Ulid::from_u128(v))
            }
        }

        impl fmt::Display for $name {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                write!(f, "{}", self.0)
            }
        }

        impl Default for $name {
            fn default() -> Self {
                Self::generate()
            }
        }

        impl From<Ulid> for $name {
            fn from(u: Ulid) -> Self {
                Self(u)
            }
        }

        impl From<$name> for Ulid {
            fn from(id: $name) -> Self {
                id.0
            }
        }

        impl FromStr for $name {
            type Err = ulid::DecodeError;
            fn from_str(s: &str) -> Result<Self, Self::Err> {
                Ok(Self(Ulid::from_string(s)?))
            }
        }

        // ======================
        // SQLx Integration
        // ======================
        #[cfg(feature = "sqlx")]
        mod sqlx_impls {
            use super::*;
            use sqlx::{database::HasArguments, encode::IsNull, postgres::PgArgumentBuffer, Postgres};
            use sqlx::{Database, Decode, Encode, Type};

            impl Type<Postgres> for $name {
                fn type_info() -> <Postgres as Database>::TypeInfo {
                    <String as Type<Postgres>>::type_info()
                }
            }

            impl<'q> Encode<'q, Postgres> for $name {
                fn encode_by_ref(&self, buf: &mut PgArgumentBuffer<'q>) -> IsNull {
                    <String as Encode<'q, Postgres>>::encode(self.to_string(), buf)
                }
            }

            impl<'r> Decode<'r, Postgres> for $name {
                fn decode(value: <Postgres as Database>::ValueRef<'r>) -> Result<Self, sqlx::error::BoxDynError> {
                    let s = <String as Decode<'r, Postgres>>::decode(value)?;
                    Ok(Self::from_str(&s)?)
                }
            }
        }

        // ======================
        // SeaORM Integration
        // ======================
        #[cfg(feature = "sea-orm")]
        mod seaorm_impls {
            use super::*;
            use sea_orm::{sea_query::Value, TryGetError, TryGetable, ValueType};

            impl ValueType for $name {
                fn try_from(v: Value) -> Result<Self, TryGetError> {
                    if let Value::String(Some(s)) = v {
                        Ok(Self::from_str(&s)?)
                    } else {
                        Err(TryGetError::DbErr(format!("invalid ULID for {}", stringify!($name)).into()))
                    }
                }
                fn type_name() -> String {
                    stringify!($name).to_string()
                }
                fn into_value(self) -> Value {
                    Value::String(Some(self.to_string()))
                }
            }

            impl TryGetable for $name {
                fn try_get(
                    res: &sea_orm::QueryResult,
                    pre: &str,
                    col: &str,
                ) -> Result<Self, TryGetError> {
                    let s: String = res.try_get(pre, col)?;
                    Ok(Self::from_str(&s)?)
                }
            }
        }
    };
}

// === Define all ULID-backed identifiers ===

define_id!(UserId, "Unique identifier for a user profile.");
define_id!(EventId, "Unique identifier for a fluid intake event.");
define_id!(TargetId, "Unique identifier for a daily hydration target.");
define_id!(DeviceId, "Unique identifier for a connected device.");
define_id!(SessionId, "Unique identifier for an LLM coaching session.");
define_id!(NotificationId, "Unique identifier for a notification rule.");
