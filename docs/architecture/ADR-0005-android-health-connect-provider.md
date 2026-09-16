# ADR-0005: Android Health Connect Provider

- Status: implemented; synthetic physical record flow verified, production source certification pending
- Date: 2026-09-12

## Context

Hydrion needs a provider-independent way to import bounded activity context on
Android without coupling its domain model to Android SDK record classes. The
application still supports Android API 24, while Health Connect is available
only from API 28. Android 9-13 use the standalone Health Connect application;
Android 14 and later provide the system implementation.

## Decision

Use the official AndroidX Health Connect client behind the existing narrow
Kotlin/Flutter platform-channel boundary. Keep `HealthDataProvider`, canonical
mapping, synchronization, encrypted persistence and UI state in their existing
separate layers.

The selected dependency is `androidx.health.connect:connect-client:1.1.0`. Its
published AndroidX POM identifies the Android Open Source Project as its source
and declares the Apache License 2.0. The Gradle debug runtime dependency report
resolved that exact version without adding a competing health-data wrapper.

The production manifest requests read access only for exercise sessions, active
calories burned, steps and distance. It requests no write, background-read or
extended-history permission. The native host is runtime-gated at API 28, is
created lazily, validates method-channel inputs and returns only bounded maps.
Android SDK records never cross into Dart.

Permission requests occur only after the user selects Connect. Every operation
rereads current grants. The first import is bounded to 30 days and pages at 250
records. A changes token is captured before the initial read, then persisted
atomically with imported records. Expired tokens trigger one bounded reread.
Corrections use stable provider record identity; deletions become local
tombstones. Imported values never change hydration targets in this sprint.

The Android adapter preserves Health Connect's contributing application and
device metadata only when supplied. It does not infer a wearable brand or model
from an application package.

If SQLCipher or its platform-protected key is unavailable, the production
connection controller fails closed. It does not import into an unencrypted or
temporary fallback repository.

## Rejected Alternatives

- A broad Flutter health plugin was rejected because Hydrion already has a
  provider contract and native discovery boundary, and the plugin would expose
  a wider permission and platform surface than this four-record sprint needs.
- Raising the application minimum SDK was rejected because API 24-27 can keep
  using Hydrion with an explicit unsupported health-provider state.
- SharedPreferences JSON was rejected because imported health history requires
  bounded queries, transactions, schema migration and encrypted storage.
- Background and extended-history access were rejected because user-initiated,
  foreground 30-day synchronization satisfies the initial product behavior.
- Direct vendor SDKs, proprietary BLE and companion-app storage access were
  rejected for this provider. They require separate provider routes and cannot
  be inferred from Health Connect availability.

## Consequences

The Android build gains the AndroidX Health Connect client and its native/code
footprint. On the authorized Android 13 Infinix test device, the isolated package
imported three synthetic Toolbox records, deduplicated a duplicate workout,
accepted missing optional device metadata and produced zero new records on
repeat sync. Imported records and connection state persisted through
force-stop/relaunch. This verifies the Android adapter with synthetic provider
data, not a production wearable export route. HealthKit and vendor routes remain
unimplemented.

The same device's XOS AutoStart policy can prevent the standalone Health Connect
service from launching after its process is killed. Android reports `AutoStart
Limit`, and the official Health Connect Toolbox fails with the same binding
`RemoteException`. The native host makes one bounded fresh-client rebind and then
fails explicitly. Source mutation, permission revocation/restoration and reliable
cold provider launch remain physical acceptance blockers.
