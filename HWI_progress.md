**Story ID:** HYD-US-TBD
**Title:** Integrate Cross-Platform Wearable Health Data
**Epic:** Wearable Health Integration
**Story Type:** User Story
**Priority:** P1
**Release Scope:** MVP
**T-shirt Size:** XL
**Project Column:** Sprint Backlog
**Business Rank:** 1
**Labels:** `user-story`, `type:user-story`, `epic:wearable-health-integration`, `priority:p1`, `scope:mvp`, `size:xl`, `status:sprint-backlog`

## User Story

**As a** Hydrion user with a supported wearable or health application  
**I need** Hydrion to securely import permitted wellness and activity data through the health-data providers available on my iOS or Android device  
**So that** Hydrion can produce more relevant, explainable hydration insights without requiring my private health data to leave my device

## Business Value

This story establishes Hydrion’s provider-independent wearable foundation.

It allows Hydrion to integrate with HealthKit, Health Connect, and future vendor-specific or documented BLE providers without coupling the hydration engine to a particular device brand.

The implementation improves personalization while preserving local-first storage, informed consent, data minimization, source provenance, Android/iOS parity and future extensibility.

This story does not promise universal wearable compatibility. A wearable is supported only when its exact platform route and required metrics have been implemented and verified.

## Acceptance Criteria

### Architecture

- [x] A platform-independent `HealthDataProvider` contract exists and is separated from hydration calculations, UI state, persistence and platform-specific code.
- [ ] HealthKit and Health Connect implementations conform to the same provider contract without forcing platform-specific records into the hydration engine.
- [x] The existing `WearableService`, `BLEService`, `HydrionServices` composition and Provider state-management architecture have been inspected before deciding what to reuse, replace or deprecate.
- [x] The implementation does not turn `WearableService` or another class into a service responsible for permissions, synchronization, storage, analysis and UI simultaneously.
- [x] Unsupported platforms and unavailable providers return explicit capability states rather than empty data or false success.

### Platform capability discovery

- [ ] iOS can determine whether HealthKit is available and display an accurate connection state.
- [ ] Android can determine whether Health Connect is available, unavailable, unsupported or requires user action.
- [ ] The application distinguishes provider unavailable, permission not granted, permission revoked, no contributing source, unsupported metric, empty history, synchronization failure and successful synchronization.
- [x] Hydrion continues to support manual hydration tracking when no wearable-data provider is available.
- [x] Web, Windows and macOS behavior is explicitly defined and does not imply wearable support where no provider has been implemented.

### Permissions and consent

- [x] Health access is read-only for this sprint.
- [ ] Hydrion requests only the metric permissions required by the implemented features.
- [x] Permissions are requested in context after an understandable user action, not automatically during application startup.
- [ ] The consent screen explains what Hydrion reads, why it reads it, how it affects hydration insights, where it is stored and how it can be deleted.
- [ ] Permission denial or revocation does not break manual hydration tracking or existing application functionality.
- [x] No account, backend or cloud upload is required for wearable ingestion.

### Initial health-data scope

- [ ] The initial provider implementation can import supported workout type, start time, end time and duration records.
- [ ] Active-energy records are imported only when supported and their source is preserved.
- [ ] Steps and distance may be imported as contextual or fallback data but are not automatically double-counted with workouts or active energy.
- [x] Heart rate, HRV, sleep stages, SpO₂, temperature, stress, recovery, readiness and body-composition data do not modify hydration targets during this sprint.
- [ ] Imported wearable data is described as wellness information and is not represented as medical-grade hydration measurement or diagnosis.

### Canonical data model

- [x] Imported records use a versioned canonical Hydrion model that preserves the original provider record identifier, metric type, value, original unit, canonical unit, start/end timestamps, timezone information and temporal precision.
- [x] Every record preserves its platform, health hub, contributing application, available device information and acquisition route.
- [x] Imported source records are separated from derived hydration features and recommendations.
- [x] Derived features retain the algorithm version and source-record references used to produce them.
- [x] The model supports updated, superseded and deleted provider records.
- [x] Provider-specific extensions are versioned and allowlisted rather than stored as unrestricted opaque data.

### Secure local persistence

- [x] Wearable health records are not stored as an unbounded JSON collection in SharedPreferences or NSUserDefaults.
- [x] Records are stored in a transactional, indexed and migration-capable local database.
- [ ] Sensitive health data is encrypted at rest using a key protected through Android Keystore and iOS Keychain.
- [x] Record updates and synchronization checkpoints are committed atomically.
- [x] The implementation defines retention, deletion, corruption recovery and migration behavior.
- [x] Logs, diagnostics, analytics and crash reports do not expose health values, identifiers, encryption keys or permission tokens.

### Synchronization and correctness

- [x] Repeating a synchronization operation does not create duplicate records.
- [x] Corrections and deletions from the source platform are reconciled where the provider supports them.
- [x] Synchronization checkpoints are advanced only after imported records are committed successfully.
- [x] An interrupted or failed synchronization can safely resume without losing or duplicating records.
- [x] Source-priority and overlap rules prevent the same activity from being counted repeatedly through multiple contributing applications.
- [ ] Background execution is treated as opportunistic; the application remains correct when synchronization occurs only after launch or resume.

### User controls

- [ ] Users can view the connected provider, granted data categories, last successful synchronization and meaningful failure state.
- [ ] Users can disconnect a provider without losing their manually entered hydration history.
- [ ] Users can delete imported wearable records and derived wearable context from Hydrion.
- [ ] Deleting imported wearable data does not delete records from HealthKit, Health Connect or the vendor application unless a separate, explicit operation is designed and authorized.
- [ ] Hydration recommendations influenced by wearable information identify the contributing factors in understandable language.

### FitPro verification

- [ ] The exact FitPro watch model used for testing is recorded.
- [ ] FitPro is tested independently on the available iPhone and both Android devices.
- [ ] For every device, the test records the operating-system version, destination health platform, contributing source application and metric types actually exported.
- [ ] FitPro data visible only inside FitPro is not reported as accessible to Hydrion.
- [ ] Compatibility is recorded per platform, device model, integration route and metric.
- [ ] Hydrion does not advertise general FitPro support based on one successful device or metric.

### Testing and platform parity

- [ ] Unit tests cover canonical conversion, unit normalization, source priority, deduplication, updates, deletion, retention and synchronization recovery.
- [x] Repository integration tests use realistic synthetic histories and failed-write scenarios.
- [x] Permission denial, revocation, unsupported provider, empty history and malformed record scenarios are tested.
- [x] Existing Hydrion unit and integration suites continue to pass.
- [ ] Static analysis, formatting, dependency, secret and platform-configuration checks pass.
- [ ] Android behavior is validated on an authorized physical Android device.
- [ ] iOS behavior is independently validated on an authorized physical iPhone.
- [x] Android success does not satisfy iOS acceptance criteria, and iOS success does not satisfy Android acceptance criteria.
- [x] Simulator or emulator results are identified separately and are not presented as physical-device verification.
- [ ] Storage growth, synchronization time, memory behavior and battery impact are measured using bounded representative datasets.
- [x] Every acceptance criterion is marked complete only when supported by reproducible evidence; blocked criteria remain unchecked and name the blocker.

## Sprint 2 Evidence Ledger

### Repository truth

The authoritative checkout is `C:\Users\User\StudioProjects\hydrion` on `main`.
This repository contains one `HWI_progress.md`. At Sprint 2 preflight the
acceptance checklist contained 61 criteria: 17 checked and 44 unchecked. No
separate planning checkbox list was present. The criteria were not duplicated or
weakened. Some punctuation appears mojibaked in the current editor/console
encoding; this does not alter checkbox identity or count.

### Sprint 1 certification

| Behavior | Production evidence | Test evidence | Result |
| --- | --- | --- | --- |
| Provider-independent contract and explicit states | `lib/domain/health_data.dart` | `test/health_data_domain_test.dart`, `test/health_data_sync_coordinator_test.dart` | Foundation certified; no platform provider claimed |
| Repository transaction contract | `lib/repositories/health_data_repository.dart` | `test/health_data_repository_test.dart` | Memory contract certified and revalidated against encrypted persistence |
| Checkpoints, retries, corrections, tombstones and duplicate classification | `lib/services/health_data_sync_coordinator.dart` | `test/health_data_sync_coordinator_test.dart`, `test/encrypted_health_data_repository_test.dart` | Certified; failed writes no longer increment uncommitted import counts |
| Bounded feature extraction and deterministic source priority | `lib/services/hydration_feature_extractor.dart` | `test/hydration_feature_extractor_test.dart` | Certified; production hydration-target integration remains disabled |
| Composition boundaries and manual hydration fallback | `lib/main.dart`, `lib/services/wearable_service.dart`, `lib/services/ble_service.dart` | full `flutter test` suite | Certified as architecture/fallback behavior only |

The canonical model was corrected before certification: it now preserves
original and canonical units, timezone identifier and UTC offset, temporal
precision, provider created/modified/recorded/imported timestamps, and versioned
allowlisted provider extensions. The synchronization coordinator now pages
bounded repository reads, supports cancellation and counts imports only after the
atomic commit succeeds.

### Persistence architecture and security

ADR: `docs/architecture/ADR-0004-encrypted-wearable-health-storage.md`.
Threat model: `docs/architecture/WEARABLE_HEALTH_THREAT_MODEL.md`.

Production Android/iOS composition uses `sqlite_async` 0.14.5 with `sqlite3`
3.5.2 configured for SQLCipher. A custom connection factory applies a 256-bit
key before every other pragma and rejects connections without SQLCipher or a
readable schema. `flutter_secure_storage` 10.3.3 protects the key through Android
Keystore or iOS Keychain. Version 11 was rejected because its Windows transitive
constraint conflicts with Hydrion's existing `share_plus` version; no unrelated
dependency was upgraded.

The schema has strict `health_records` and `health_sync_checkpoints` tables.
Records have unique Hydrion and provider/source identities, an imported/derived
kind, tombstone/correction/duplicate fields, complete provenance and encrypted
JSON only for bounded allowlisted metadata and source references. Indexes cover
provider+metric+time, metric+time and kind+retention time. Record upserts and
checkpoint advancement share one serialized transaction. `PRAGMA user_version`
advances inside the migration transaction. Unsupported future schemas,
corruption, wrong keys, missing keys and inaccessible keys fail closed without
file deletion or plaintext fallback.

Android backup remains disabled. The iOS target remains 14.0 and Runner now has
its application Keychain access-group entitlement. Key rotation is explicitly
deferred to a reviewed rekey protocol. Existing hydration, profile, reminder,
challenge, report and settings storage was not migrated or modified.

### Reproducible validation

| Validation | Result |
| --- | --- |
| Sprint 1 focused tests | 26 passed |
| Expanded domain/key/encrypted repository/sync/feature tests | 41 passed across the final focused files |
| Persistent sync, restart, wrong-key, corruption, future-schema, rollback, retention, deletion, paging, concurrency and close tests | Passed |
| `flutter analyze` | Passed, no issues |
| Full `flutter test` | Passed, 679 tests |
| Secret scan | Passed; no committed credentials/private-key blocks detected |
| Locale message audit | EN/FR/ES each 869/869; Android EN/FR/ES each 24/24 |
| Mixed-language audit | No placeholder drift; two reviewed identical French report terms |
| Production literal audit | Existing baseline remains 15 unresolved findings; no Sprint 2 UI strings were added |
| Web release build | Passed; wearable persistence is explicitly unsupported and no database is opened |
| Android debug build | Passed |
| Android release build | Passed; universal APK 115,158,366 bytes |
| iOS build/runtime | Not run: Windows host cannot build or certify iOS/Keychain behavior |
| Physical Android/iPhone security behavior | Not run; platform protection criterion remains unchecked |

The first formatting verification found and then formatted `lib/main.dart`; the
final verification result is recorded after this ledger is written. No emulator,
simulator or physical-device result is claimed by Sprint 2.

### Host resource measurements

The repeatable command is
`dart run tool/health_storage_benchmark.dart`. On this Windows host with 1,000
typical plus 10,000 heavy synthetic workout records: first encrypted open 212 ms;
1,000-record append 313 ms; 10,000-record append 1,399 ms; indexed 250-row query
34 ms; 100-record update 18 ms; encrypted database/WAL/SHM footprint 5,812,224
bytes; observed RSS delta 4,415,488 bytes; ten reopen/close cycles 183 ms; bounded
purge of 2,410 records 66 ms; temporary files were deletable after close. These
are host measurements, not mobile performance or battery evidence.

The prior local artifacts were 221,232,666 bytes for debug and 98,334,246 bytes
for universal release. The rebuilt artifacts are 260,651,848 and 115,158,366
bytes: approximate deltas of +39,419,182 and +16,824,120 bytes. The comparison is
not a controlled identical-source baseline, so it must not be treated as the
isolated package cost. SQLCipher/OpenSSL native libraries are the expected main
contributor.

### Open blockers and Sprint 3 boundary

The encryption-at-rest criterion remains unchecked until Android Keystore and
iOS Keychain behavior is exercised on their real platforms. HealthKit, Health
Connect, consent/connection UI, real import, FitPro, user-facing deletion,
wearable-informed hydration recommendations and all physical-device criteria are
outside Sprint 2 and remain unchecked. Unit conversion logic, full migration
fault injection, mobile battery/startup profiling and a controlled clean build
size baseline also remain open. Sprint 3 should begin with physical key-lifecycle
verification and one narrow provider adapter behind explicit consent, without
enabling hydration-target changes.
