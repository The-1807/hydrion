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
- [x] HealthKit and Health Connect implementations conform to the same provider contract without forcing platform-specific records into the hydration engine.
- [x] The existing `WearableService`, `BLEService`, `HydrionServices` composition and Provider state-management architecture have been inspected before deciding what to reuse, replace or deprecate.
- [x] The implementation does not turn `WearableService` or another class into a service responsible for permissions, synchronization, storage, analysis and UI simultaneously.
- [x] Unsupported platforms and unavailable providers return explicit capability states rather than empty data or false success.

### Platform capability discovery

- [ ] iOS can determine whether HealthKit is available and display an accurate connection state.
- [x] Android can determine whether Health Connect is available, unavailable, unsupported or requires user action.
- [ ] The application distinguishes provider unavailable, permission not granted, permission revoked, no contributing source, unsupported metric, empty history, synchronization failure and successful synchronization.
- [x] Hydrion continues to support manual hydration tracking when no wearable-data provider is available.
- [x] Web, Windows and macOS behavior is explicitly defined and does not imply wearable support where no provider has been implemented.

### Permissions and consent

- [x] Health access is read-only for this sprint.
- [x] Hydrion requests only the metric permissions required by the implemented features.
- [x] Permissions are requested in context after an understandable user action, not automatically during application startup.
- [x] The consent screen explains what Hydrion reads, why it reads it, how it affects hydration insights, where it is stored and how it can be deleted.
- [x] Permission denial or revocation does not break manual hydration tracking or existing application functionality.
- [x] No account, backend or cloud upload is required for wearable ingestion.

### Initial health-data scope

- [x] The initial provider implementation can import supported workout type, start time, end time and duration records.
- [x] Active-energy records are imported only when supported and their source is preserved.
- [x] Steps and distance may be imported as contextual or fallback data but are not automatically double-counted with workouts or active energy.
- [x] Heart rate, HRV, sleep stages, SpO₂, temperature, stress, recovery, readiness and body-composition data do not modify hydration targets during this sprint.
- [x] Imported wearable data is described as wellness information and is not represented as medical-grade hydration measurement or diagnosis.

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
- [x] Background execution is treated as opportunistic; the application remains correct when synchronization occurs only after launch or resume.

### User controls

- [x] Users can view the connected provider, granted data categories, last successful synchronization and meaningful failure state.
- [x] Users can disconnect a provider without losing their manually entered hydration history.
- [ ] Users can delete imported wearable records and derived wearable context from Hydrion.
- [x] Deleting imported wearable data does not delete records from HealthKit, Health Connect or the vendor application unless a separate, explicit operation is designed and authorized.
- [ ] Hydration recommendations influenced by wearable information identify the contributing factors in understandable language.

### FitPro verification

- [ ] The exact FitPro watch model used for testing is recorded.
- [ ] FitPro is tested independently on the available iPhone and both Android devices.
- [ ] For every device, the test records the operating-system version, destination health platform, contributing source application and metric types actually exported.
- [ ] FitPro data visible only inside FitPro is not reported as accessible to Hydrion.
- [ ] Compatibility is recorded per platform, device model, integration route and metric.
- [ ] Hydrion does not advertise general FitPro support based on one successful device or metric.

### Testing and platform parity

- [x] Unit tests cover canonical conversion, unit normalization, source priority, deduplication, updates, deletion, retention and synchronization recovery.
- [x] Repository integration tests use realistic synthetic histories and failed-write scenarios.
- [x] Permission denial, revocation, unsupported provider, empty history and malformed record scenarios are tested.
- [x] Existing Hydrion unit and integration suites continue to pass.
- [x] Static analysis, formatting, dependency, secret and platform-configuration checks pass.
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

## Sprint 3 Android Evidence Ledger

### Repository and device truth

Sprint 3 work is isolated on the local `wearable_integration` branch created
from `main` at `63fb562`. At preflight, `main` and `origin/main` matched. No
Sprint 3 commit or push has been made.

One authorized device was selected explicitly for every ADB command. Its serial
and unique fingerprint portion are intentionally omitted. It reports INFINIX,
model Infinix X6835B, Android 13/API 33 and arm64-v8a. Google Mobile Services and
the Play Store are installed, it is not a work profile, and approximately 3.46
GiB remained on `/data` during the final sample. Health Connect is not built in
on this Android version. The first discovery run correctly reported the
standalone package absent and `installationRequired`.

Production `com.the1807.hydrion` and debug `com.the1807.hydrion.debug` were
already installed and were not replaced, cleared or inspected for user health
content. Physical testing used only the separately named
`com.the1807.hydrion.hwi_test` debug package and synthetic data.

### Foundation revalidation

The provider-independent domain, repository, synchronization, feature
extraction, encrypted repository and key-store focused suites passed 46 tests.
With the Android discovery tests included, the focused total passed 50 tests.
The production hydration-target integration remains disabled.

### Physical encrypted-storage evidence

On the isolated package, SQLCipher loaded for arm64-v8a and returned a non-empty
runtime cipher version. A 256-bit random key was stored through the production
Android secure-storage path. The encrypted database closed and reopened after
force-stop/relaunch. Unkeyed SQLite and a wrong key could not read it. The
wrong-key attempt did not change the ciphertext. A deliberately failed atomic
record/checkpoint operation rolled back and retained the prior checkpoint.

The synthetic canary was absent from the database and all database sidecar files.
Searches found no raw base64url or hexadecimal key encoding in the writable test
sandbox and no canary or key diagnostic in the isolated process Logcat. The
database directory contained only `synthetic-health.db`; no WAL, SHM, journal or
temporary plaintext file remained after close. Injected missing-key, inaccessible
key, corruption and unsupported-future-schema behavior remains covered by
automated tests. Hardware-backed or StrongBox storage is not claimed.

Three bounded physical iterations produced these median/worst measurements:
encrypted first open 568/595 ms; idempotent 1,000-record batch 2,694/3,072 ms;
indexed 250-row page 192/302 ms. The encrypted database was 753,664 bytes. The
final ARM64 split test APK and installed base APK were 121,889,826 bytes, and
the isolated writable sandbox was approximately 85,030 KiB, dominated by debug
Flutter assets. One post-test
sample reported total PSS 301,081 KiB, RSS 413,195 KiB, 6.2 percent sampled CPU
and 7 visible file descriptors. These are bounded observations, not a leak or
battery certification. The full 10,000-record and battery gates remain open.
Compared with the pre-router isolated ARM64 artifact of 120,870,256 bytes, the
final artifact was 1,019,570 bytes larger. That is an observed same-target delta,
not a guaranteed Play download cost. Play distribution can deliver one ABI;
universal multi-ABI APK sizes are not representative of an arm64 device install.

### Android provider discovery

Production discovery now calls the official Health Connect SDK status API and
separately reports phone manufacturer/model, Android SDK, GMS, Play Store, work
profile, built-in versus standalone Health Connect, permission/connection state,
and installed known companion applications. Structured states fail closed and
manual hydration remains available. Provider names are not hard-coded into UI.

After the user installed standalone Health Connect version
`2026.08.06.00.release`, the same isolated package and official SDK probe returned
`available`. Permission remained `notRequested`, connection remained
`disconnected`, and no health records were requested or read. This certifies the
capability-state transition. The read-only Health Connect record adapter is now
implemented but is not physically record-certified. FitPro and Infinix
HealthLife were installed and enabled, but neither
application had a verified export route, readable metric or physical watch
identity. Their status remains `requiresVerification`; every FitPro acceptance
criterion remains unchecked.

The Android capability-discovery criterion changed from unchecked to checked.
Its evidence is `AndroidHealthProviderDiscovery.kt`,
`android_health_provider_discovery.dart`, the focused discovery tests, and the
official SDK result on the physical Infinix. This does not check the broader
provider-ingestion, Android wearable, combined encryption, iOS or FitPro gates.

Final validation passed `flutter analyze` with no issues and the complete
`flutter test` suite with 684 tests. The isolated package, synthetic encrypted
database and its package-scoped secure-storage entry were removed together by
uninstalling only `com.the1807.hydrion.hwi_test`. Production and ordinary debug
Hydrion remained installed.

### Sprint 3 production-adapter continuation

The official AndroidX Health Connect 1.1.0 client is now used behind the narrow
Kotlin channel in `AndroidHealthConnectHost.kt`. `AndroidHealthConnectProvider`
maps only exercise sessions, active calories, steps and distance into the
canonical domain. The production manifest contains the matching four read
permissions and no Health Connect write, background-read or extended-history
permission. API 24 installation is preserved; the native client is lazy and
runtime-gated at API 28. ADR-0005 records this choice, the 30-day initial window,
250-record paging and rejected alternatives.

The connection screen is available from Settings and is localized in English,
French and Spanish. It explains category purpose, read-only access, encrypted
local storage, no account/cloud requirement, declining and revocation, local
copy deletion, wellness-only status and the deliberate absence of hydration
target changes. Permission requests occur only through Connect or Request
missing access. Current grants are reread from Health Connect on refresh and
resume. Protected-storage initialization failure blocks provider access instead
of falling back to an unencrypted or temporary repository.

The adapter captures a per-metric changes token before the bounded initial read,
then uses incremental pages for upserts and deletions. The coordinator commits
records and checkpoints atomically, retries an expired token with one bounded
reread, deduplicates stable identities and semantic overlaps, and reconstructs
identifier-only deletion events from stored provenance before tombstoning. No
background synchronization is scheduled; synchronization is user-initiated and
the app remains correct with foreground-only refresh.

The following acceptance criteria changed from unchecked to checked, based on
production implementation and automated tests: minimum metric permissions;
complete consent explanation; denial/revocation regression safety; workout
import mapping; active-energy mapping with source; steps/distance fallback and
overlap protection; wellness/non-medical wording; opportunistic foreground-only
synchronization; provider/category/success/failure visibility; disconnect
without manual-data loss; local-only deletion that cannot call source deletion;
and comprehensive domain/sync/repository unit coverage. Physical Android record
import is not used as evidence for these code-level criteria.

Focused provider, controller, UI, synchronization and Settings regression tests
passed 36 tests before the final controller deletion case was added. Static
analysis then passed with no issues. The prior full run had 697 passes and one
stale Settings inventory failure; that test was corrected to require the new
working Health Data control and the focused regression passed. Final full-suite,
format, audit and build results are recorded after the current validation run.

At continuation time the device no longer contained either Hydrion package; this
was a changed external device state, not a repository or ADB cleanup action in
this run. Health Connect remained installed. The final isolated ARM64 artifact
is `com.the1807.hydrion.hwi_test`, version `1.2.0-hwi-test`, version code 2005,
128,397,886 bytes, SHA-256
`D71669391D1AC69B52911AABDC3C6BD577828D70BBD245821F20BE01D1DDCB12`.
Its manifest requests only exercise, active-calorie, steps and distance read
permissions, and its only native ABI is `arm64-v8a`. Equal-version replacement
installation succeeded and preserved the isolated package data. Production
Hydrion was not installed, uninstalled, replaced or cleared by this
continuation.

With explicit user/device authorization complete, Health Connect Toolbox
synthetic data produced three visible imported Hydrion records. The import
preserved the Toolbox source, accepted a workout whose optional device
manufacturer/model were absent, and deduplicated two identical workout records.
A repeat synchronization reported 0 read, 0 new, 0 updated, 0 deleted and 0
rejected while the imported total remained three. A synthetic 150 ml manual
hydration entry remained present after force-stop and relaunch, as did the three
imported records and connected state. Raw health values, provider identifiers
and permission tokens are intentionally omitted from this ledger.

Cold provider startup remains blocked by an Infinix/XOS AutoStart policy. When
Health Connect has been killed, Android logs `AutoStart Limit` while attempting
to bind `androidx.health.ACTION_BIND_HEALTH_DATA_SERVICE`; the official Google
Health Connect Toolbox then fails its own permission query with the same
`RemoteException: Binding to service failed`. Opening Health Connect manually
allows Hydrion to synchronize until XOS kills the provider again. Hydrion now
performs exactly one fresh-client rebind after that remote failure and otherwise
reports failure truthfully; it does not loop, auto-launch another application or
claim synchronization. Source correction/deletion, permission revoke/restore,
and reliable cold provider launch remain unperformed physical gates.

The following criteria remain deliberately unchecked: combined HealthKit and
Health Connect parity; all iOS/HealthKit gates; complete provider-state
distinction; combined Android/iOS key protection; imported-plus-derived context
deletion; wearable-influenced recommendation explanation; every FitPro and
vendor-specific claim; static/audit completion until the final commands finish;
physical Android record behavior; physical iPhone behavior; and bounded battery
and complete resource certification. No acceptance checkbox was newly marked by
this continuation: the physical Android criterion remains intentionally broad
and therefore remains unchecked while the named device gates above are open.

### HealthKit provider sprint evidence

The local `feature/healthkit-provider` branch adds a narrow Swift HealthKit host
and an `AppleHealthKitProvider` behind the same `HealthDataProvider`, canonical
record, synchronization coordinator, encrypted repository and connection-screen
boundaries used by Health Connect. The shared-contract criterion changed from
unchecked to checked. Evidence is `HealthKitHost.swift`,
`health_kit_provider.dart`, the expanded provider/coordinator tests and
ADR-0006. No HealthKit record enters the hydration engine or modifies a target.

Production iOS access is read-only and limited to workouts, active energy, steps
and walking/running distance. Permission is requested only after Connect. The
provider records authorization-flow completion without claiming that Apple
revealed individual read grants. Empty-query text explicitly preserves Apple's
denied-versus-empty ambiguity. English, French and Spanish permission-purpose
strings are included in the Runner target; the widget target has no HealthKit
entitlement or purpose string.

Anchored responses and cursors are schema-versioned. Each metric retains an
independent checkpoint; page size is 250, the initial history is 30 days and the
shared coordinator caps a run at 100 pages. Tests cover all four metric mappings,
optional provenance, time-zone offset, update/deletion reconciliation, invalid
anchor recovery, unsupported schemas, partial metric failure, scoped retry and
permission-request failure. Provider records and checkpoints still commit through
the existing SQLCipher transaction.

The iOS capability criterion remains unchecked because Windows cannot compile or
execute `HKHealthStore.isHealthDataAvailable()`. The complete provider-state
criterion also remains unchecked: HealthKit intentionally prevents Hydrion from
distinguishing denied read access from an empty readable store. Combined
Keystore/Keychain encryption, physical iPhone, source application, corrections,
deletions, revocation, restart, performance, memory, resource release and battery
criteria remain unchecked pending authorized macOS and physical-iPhone evidence.

Windows validation completed with `flutter gen-l10n`, 33 focused iOS/provider/UI
configuration tests, and the full 745-test Flutter suite passing. Repository-wide
formatting reported 238 files with 0 changes, `flutter analyze` reported no
issues, dependency resolution completed without changing `pubspec.yaml` or
`pubspec.lock`, and the secret scan found no committed credentials or private-key
blocks. Localization coverage remained 943/943 for EN, FR and ES plus 24/24 for
each Android locale; the mixed-language audit reported no identical untranslated
messages or placeholder drift. The production-literal audit reviewed all 936
findings with 0 unresolved, both GitHub Actions workflows validated, and
`git diff --check` passed. These Windows/static results do not satisfy any macOS,
iOS simulator, physical-iPhone, HealthKit runtime or Keychain criterion.
