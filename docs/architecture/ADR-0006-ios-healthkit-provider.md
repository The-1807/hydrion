# ADR-0006: iOS Apple Health Provider

- Status: implemented on feature branch; macOS and physical-iPhone acceptance pending
- Date: 2026-09-15

## Context

Hydrion needs a read-only iOS route for bounded activity records without adding
a second storage or synchronization system. Apple describes HealthKit as the
developer framework and requires user-facing interfaces to refer to the Apple
Health app as Apple Health. Apple also deliberately prevents an application
from learning whether read access was denied; a denied query can look identical
to an empty health store.

## Decision

Use a narrow native Swift `HealthKitHost` behind the existing
`HealthDataProvider` boundary. The production Runner requests read access only
for workouts, active energy, steps and walking/running distance. It requests no
write types, has no `NSHealthUpdateUsageDescription`, does not enable background
delivery and retains the existing iOS 14 deployment target.

Capability discovery uses `HKHealthStore.isHealthDataAvailable()`. Permission is
requested only from Hydrion's existing connection screen after the user selects
Connect. `getRequestStatusForAuthorization` is represented as either request
required or authorization flow completed; it is never presented as proof that a
specific read category was granted. Empty-query copy names both legitimate
possibilities: no matching readable records, or read access not allowed.

Each metric uses a separate `HKAnchoredObjectQuery`, a 30-day initial history
window supplied by the shared coordinator, a fixed end time across a paged read,
250-object pages and the coordinator's 100-page ceiling. Channel responses and
persisted cursors are schema-versioned. Invalid anchors request one bounded
checkpoint restart through the existing coordinator. Metric failures remain
isolated; records and the corresponding metric checkpoint commit atomically.

Native records map into `CanonicalHealthRecord`. Mapping preserves the HealthKit
UUID, metric and canonical unit, interval, source bundle/name/revision, available
time-zone offset and available device identifier/manufacturer/model/hardware and
software versions. Optional provenance remains optional. Provider extensions use
the existing versioned allowlist. HealthKit samples are not logged.

Imported records use the existing SQLCipher repository and platform-protected
database-key lifecycle. Connection summaries remain small preference values;
health records, anchors and provider identifiers remain in the encrypted
database. Disconnect is local to Hydrion. Deleting imported data deletes
Hydrion's provider-scoped records and checkpoints, never Apple Health records or
manual hydration history.

## Rejected Alternatives

- A broad Flutter health plugin was rejected because Hydrion already owns the
  provider, canonical-domain, synchronization and encrypted-storage boundaries.
- HealthKit write access was rejected because this sprint imports data only.
- `authorizationStatus(for:)` was rejected as evidence of read permission; it
  describes sharing authorization and would create a false read-grant claim.
- Background delivery and direct Apple Watch connectivity were rejected from
  this sprint. Foreground synchronization is explicit and bounded.
- SharedPreferences or NSUserDefaults record storage was rejected because it is
  not an encrypted, indexed, transactional health-record ledger.

## Consequences

Windows can validate Dart mapping, UI state, localization, configuration files,
encrypted-repository behavior and cross-provider contracts. Windows cannot
compile the Swift host, validate Xcode signing, run an iOS Simulator build or
prove physical Apple Health behavior. Therefore the provider remains
`implemented-unverified`; Hydrion must not advertise Apple Health, Apple Watch or
iOS wearable support until the macOS and physical-iPhone acceptance matrix is
complete.

## Mac and Simulator follow-up

The user selected Xcode Simulator for the 2026-09-17 Mac validation because no
physical iPhone is available. See the [validation record](../validation/healthkit-macos-simulator-2026-09-17.md)
for actual results and remaining gates. Simulator evidence does not change the
physical compatibility classification.

The native boundary now rejects malformed or oversized anchors before secure
decoding, bounds date input strings, and validates sample types before converting
units. Sample mapping and anchor archiving run on the HealthKit completion queue;
only completed method-channel results move to the main thread. Native XCTest
coverage exercises these production helpers with synthetic HealthKit objects.
