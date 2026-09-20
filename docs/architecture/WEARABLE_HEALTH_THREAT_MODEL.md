# Wearable Health Local-Storage Threat Model

## Assets and classification

| Data | Classification | Storage rule |
| --- | --- | --- |
| Imported wearable records and tombstones | Sensitive health/wellness | SQLCipher database only |
| Derived activity features and source references | Sensitive inferred wellness | SQLCipher database only, logically marked derived |
| Sync checkpoints and provider/source identifiers | Sensitive metadata | SQLCipher database only |
| Device identifiers and provider extensions | Sensitive metadata | SQLCipher database only; extensions versioned and allowlisted |
| Connection UX state and synchronization timestamps | Sensitive preference | Local application preferences; never treated as authoritative permission grants |
| Database encryption key | Secret | Android Keystore/iOS Keychain wrapper only; never database, preferences, source or logs |
| Database path, schema version and unsupported status | Non-sensitive configuration | May exist outside the database; no health values or identifiers |

Existing hydration logs, profile data, reminders, challenges, reports and app
settings retain their current storage. Their broader encryption review is
separate work and is not silently folded into this migration.

## Threats and controls

- **Device theft and database extraction:** SQLCipher encrypts pages, indexes,
  metadata and WAL content. The key is separately protected. This does not protect
  an unlocked device whose application process or OS is fully compromised.
- **Root, jailbreak or sandbox escape:** platform protection raises extraction
  cost but cannot promise confidentiality after full privilege compromise.
  Hydrion does not claim otherwise.
- **Android backup:** `android:allowBackup="false"` excludes application backup.
  Restore of a copied database without its non-exportable key fails closed.
- **Apple backup:** the Keychain item is non-synchronizable and
  `first_unlock_this_device`; a restored database without its device-bound key is
  preserved but reported unreadable until an explicit user recovery decision.
- **Key extraction/loss:** a secure random 256-bit key is generated once. Key read,
  decode or write-verification failure produces an inaccessible state. Missing key
  plus existing database never generates a replacement.
- **Logs/crash diagnostics:** code must report categorical states only. It must not
  log keys, values, provider records, source/device identifiers, SQL parameters or
  permission tokens. SQL query profiling is disabled.
- **Screenshots/app switcher:** the connection screen exposes categories, counts,
  contributing application names and synchronization status, but not record
  values. Screen-capture hardening remains required before any detailed health
  record UI is introduced.
- **Temporary files:** tests use synthetic temporary files and delete them. Mobile
  production stores only in application support. SQLCipher temp storage uses
  encrypted/native in-memory configuration; no plaintext export is implemented.
- **Debug builds:** debug/test keys are injected only by tests. Production
  composition always requests the platform-protected key.
- **Corruption and wrong keys:** open verifies SQLCipher availability and schema
  readability. Corrupt, invalid-key and unsupported-future-schema states do not
  recreate or downgrade files automatically.
- **Low disk and partial writes:** SQLite errors propagate. Record upserts and the
  checkpoint share one transaction, so failure rolls both back.
- **Incomplete migration:** schema migration uses the same serialized write
  transaction. `user_version` advances only after schema statements succeed.
- **Concurrent synchronization:** one writer serializes commits; unique provider
  identity makes replay idempotent. Reads are bounded and use stable ordering.
- **Provider service availability:** an OEM may prevent a standalone health hub
  from starting in the background. Hydrion performs one bounded fresh-client
  rebind after a remote binding failure and then reports failure. It does not
  auto-launch the provider, retry indefinitely or treat an unavailable service
  as an empty successful synchronization.
- **Opaque Apple read authorization:** HealthKit intentionally does not reveal
  whether read access was denied. Hydrion records that the authorization flow
  completed and then reports readable records, empty readable history or query
  failure. It never uses write-authorization status to claim a read grant.
- **Native HealthKit channel payloads:** the channel accepts only four allowlisted
  metrics, ISO-8601 date strings capped at 64 UTF-8 bytes with ordered endpoints,
  and secure-coded anchors capped at 16,384 UTF-8 bytes. The coordinator supplies
  the initial 30-day lower bound; the native boundary does not enforce a separate
  maximum history span. Wrong-typed anchors fail rather than becoming initial
  queries. Persisted Dart cursor envelopes are versioned. Responses are
  capped at 250 objects, schema-versioned and mapped into allowlisted canonical
  fields. Native errors return categorical codes without record values or
  identifiers.
- **Rollback and replay:** a checkpoint advances only in the successful record
  transaction. A retry replays the provider identity as an upsert.
- **Deletion:** provider deletion removes imported records and its checkpoints but
  not external provider data or manual hydration. No derived wearable context is
  persisted or used by production hydration targets in this sprint. A future
  persisted derived-context feature must join this deletion transaction. Purge is
  bounded by a caller-supplied time cutoff.
- **Reinstall/application-data deletion:** normal uninstall removes sandbox data
  and Keystore/Keychain association according to platform behavior. Restore or
  anomalous survival of only one component is handled as missing-key/unreadable,
  never silent data destruction.

## Residual risks and deferred work

Android Keystore behavior has bounded physical evidence on the isolated Infinix
package; iOS Keychain behavior still cannot be certified from Windows. Key
rotation, detailed screen-capture controls, explicit user-facing storage-recovery
UI and encryption of unrelated profile/preferences remain separate reviewed work.
The tested Infinix/XOS configuration can block cold binding to standalone Health
Connect through its AutoStart policy; the official Health Connect Toolbox is
affected as well. This remains a device-policy acceptance blocker.

The iOS Runner now has a read-only HealthKit implementation and localized purpose
strings, but Swift compilation, signing, Keychain lifecycle, device logging,
resource release and Apple Health record behavior remain unverified until the
authorized macOS and physical-iPhone gates run.

The [2026-09-17 Mac/Simulator validation record](../validation/healthkit-macos-simulator-2026-09-17.md)
separates macOS tests, native compilation, simulator runtime evidence and pending
physical-device gates. The isolated simulator contains synthetic test data only.
Simulator Keychain or SQLCipher results do not certify device hardware security,
backup, lock-state protection or physical-device leakage behavior.

## Passive watch companion boundary — 2026-09-19

The WatchConnectivity channel carries manual hydration snapshots, not imported
HealthKit records, authorization tokens, encryption keys, or source identifiers.
Snapshots are still private wellness information: neither side logs payloads or
raw platform exceptions. Runner retains only the newest pending context in
memory, and WatchConnectivity manages the latest application context. This is
not evidence of SQLCipher encryption for watch-local application contexts.

The watch rejects unsupported schemas, wrong types, out-of-range numbers,
missing timestamps and oversized text. Duplicate/older snapshots cannot replace
a newer accepted snapshot. Reachability and update errors remain visible while
last-known data is retained. A queued update is never labeled delivered.
No HealthKit, App Group, background mode or new authorization capability is
assigned to HydrionWatch. Runner's read-only HealthKit boundary and the widget's
separate App Group remain unchanged. Transport, restart and physical background
behavior require their own tests; parser tests alone do not establish them.
