# Wearable Health Local-Storage Threat Model

## Assets and classification

| Data | Classification | Storage rule |
| --- | --- | --- |
| Imported wearable records and tombstones | Sensitive health/wellness | SQLCipher database only |
| Derived activity features and source references | Sensitive inferred wellness | SQLCipher database only, logically marked derived |
| Sync checkpoints and provider/source identifiers | Sensitive metadata | SQLCipher database only |
| Device identifiers and provider extensions | Sensitive metadata | SQLCipher database only; extensions versioned and allowlisted |
| Consent and permission state | Sensitive preference | Encrypted database when implemented; not implemented in Sprint 2 |
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
- **Screenshots/app switcher:** Sprint 2 adds no health UI, so no sensitive health
  content is rendered. Future UI work must review screen capture and task-preview
  behavior before exposing records.
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
- **Rollback and replay:** a checkpoint advances only in the successful record
  transaction. A retry replays the provider identity as an upsert.
- **Deletion:** provider deletion removes imported records and its checkpoints but
  not external provider data or manual hydration. Derived context is independently
  retained until an explicit derived-data deletion policy is implemented. Purge is
  bounded by a caller-supplied time cutoff.
- **Reinstall/application-data deletion:** normal uninstall removes sandbox data
  and Keystore/Keychain association according to platform behavior. Restore or
  anomalous survival of only one component is handled as missing-key/unreadable,
  never silent data destruction.

## Residual risks and deferred work

Physical-device verification is required for Android Keystore and iOS Keychain
behavior. iOS cannot be certified from Windows. Key rotation, consent persistence,
screen-capture controls, explicit user-facing recovery/deletion UI and encryption
of unrelated profile/preferences remain separate reviewed work.
