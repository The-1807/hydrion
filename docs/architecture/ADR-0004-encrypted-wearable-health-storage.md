# ADR-0004: Encrypted Wearable Health Storage

Status: Accepted for the provider-independent foundation

## Context

Wearable source records, derived activity features, provider identifiers, device
identifiers and synchronization checkpoints are sensitive local data. They need
indexed, bounded queries and atomic record/checkpoint commits. SharedPreferences
is neither a suitable database nor an acceptable location for this history.
Hydrion must retain its iOS 14 deployment target and must not open an unencrypted
fallback when encryption or key access fails.

## Decision

Use `sqlite_async` 0.14.x over `sqlite3` 3.5.x configured with the bundled
SQLCipher community build. Use `flutter_secure_storage` 10.3.x for a randomly
generated 256-bit database key protected by Android Keystore or iOS Keychain.

`sqlite_async` supplies asynchronous pooled access, one serialized writer,
transactions, bounded SQL queries and reliable close ownership. A custom native
connection factory applies the SQLCipher key before every other pragma and
verifies that `cipher_version` exists and the schema can be read. Schema changes
run inside a write transaction and are tracked by `user_version`.

The database is production-enabled only on Android and iOS. Web, Windows, Linux
and macOS return an explicit unsupported state in Hydrion composition. Tests may
inject a 32-byte key and use temporary encrypted database files.

Android backup remains disabled at the application level. The iOS key uses
`first_unlock_this_device`, is non-synchronizable and does not migrate through
iCloud Keychain. Missing key plus existing database is a recoverable error state;
the application does not delete the file or generate a replacement.

## Evaluation

| Option | Transactions/indexes/migrations | Encryption and key protection | Compatibility and maintenance | Decision |
| --- | --- | --- | --- | --- |
| `sqlite_async` + `sqlite3` SQLCipher | Native SQLite transactions, indexes, bounded SQL and versioned migrations | SQLCipher database; app key from Keystore/Keychain | Android/iOS including iOS 14; active PowerSync and sqlite3.dart releases; MIT library licenses, SQLCipher community BSD license | Selected |
| Drift + sqlite3 SQLCipher | Strong generated schema and migrations | Same SQLCipher/key work still required | Maintained, but adds code generation and a wider dependency/build surface than this repository contract needs | Rejected for this sprint |
| Direct synchronous `sqlite3` | Capable but configuration, pooling and isolate safety become application responsibilities | SQLCipher available | Maintained, but risks blocking UI or hand-rolled concurrency | Rejected |
| `sqflite_sqlcipher` | Transactions and indexes | Password API around SQLCipher | Smaller maintenance community, platform-specific migration caveats and no advantage over the selected native-assets route | Rejected |
| `sqlcipher_flutter_libs` wrappers | Depends on consumer | Historically supplied binaries | Obsolete with sqlite3 v3 native assets | Rejected |
| SharedPreferences/NSUserDefaults JSON | No bounded indexed history or atomic checkpoint contract | Not full database encryption | Existing dependency, wrong data model | Prohibited |

`flutter_secure_storage` 11.x was evaluated but conflicts with Hydrion's existing
`share_plus` 10.x through incompatible `win32` constraints. Version 10.3.x retains
Android Keystore and iOS Keychain behavior without an unrelated dependency
upgrade. `resetOnError` is disabled so a key error cannot silently erase and
replace the database key.

## Consequences

- Native SQLCipher and OpenSSL increase mobile build size; measured deltas belong
  in `HWI_progress.md` after reproducible builds.
- SQLCipher protects extracted files, not data on an unlocked fully compromised
  device.
- Key rotation is deferred. A future design must rekey inside a transaction,
  verify the new key, then atomically update protected key material with recovery
  metadata. Rotation must never overwrite the only working key first.
- No existing production wearable database exists, so schema version 1 creates a
  new isolated database and does not migrate hydration/profile preferences.
