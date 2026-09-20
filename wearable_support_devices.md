# Hydrion Wearable Integration Matrix and Product Scope

Last revised: 2026-09-14

## Purpose

This document defines:

- Hydrion’s supported wearable integration architecture.
- The provider routes prioritized for production.
- The limited compatibility candidates selected for research.
- Hydrion’s user-facing wearable-data interface.
- The evidence required before any device, application or route is advertised as supported.

This is not a universal wearable-support claim.

A wearable is supported only when its exact provider route, permissions, metrics,
provenance, synchronization behaviour and physical-device operation have been
implemented and verified independently on every applicable platform.

## Critical Testing Boundary

Hydrion separates two activities:

### Production qualification

Testing a documented standard, platform SDK or authorized vendor interface to
demonstrate that it operates correctly under production conditions.

### Compatibility research

Investigating whether a closed companion application or white-label wearable
offers a legitimate interface that Hydrion could support.

Compatibility research does not establish production support and must not block
or define Hydrion’s standard wearable architecture.

## Status Vocabulary

- `verified-supported`: Exact production route and metrics passed physical-device acceptance.
- `implemented-unverified`: Production code exists but physical acceptance is incomplete.
- `planned`: A documented route exists but Hydrion has not implemented it.
- `research-candidate`: Compatibility investigation only.
- `partner-restricted`: Vendor approval, licensing or commercial agreement required.
- `region-dependent`: Availability changes by country, account, firmware or store.
- `unsupported`: Hydrion does not support the route.
- `closed-no-legitimate-route`: No documented or authorized interface is known.

## Tier 1 — Core Production Routes

These routes define Hydrion’s wearable architecture.

| Priority | Provider route | Intended capability | Current status |
|---:|---|---|---|
| 1 | Android Health Connect | Imported workouts, active energy, steps, distance and supported records | Implemented-unverified |
| 2 | Apple HealthKit | Imported workouts, active energy, steps and distance on iPhone | Implemented-unverified |
| 3 | Wear OS Health Services | Live and passive measurements from compatible Wear OS devices | Planned |
| 4 | watchOS workout sessions | Live Apple Watch workout measurements | Planned |
| 5 | Standard Bluetooth GATT | Direct live data from devices implementing documented standard profiles | Planned |

The [2026-09-17 Mac/Simulator validation](docs/validation/healthkit-macos-simulator-2026-09-17.md)
records native build, XCTest and synthetic simulator results separately. No
physical iPhone or contributing wearable is certified by simulator evidence.

Health Connect and HealthKit are record repositories. They are not assumed to
provide continuous live sensor streaming.

Live wearable sessions require Wear OS Health Services, watchOS workout sessions
or an explicitly supported Bluetooth/device interface.

### Standard BLE boundary

Initial BLE eligibility is limited to documented Bluetooth SIG services, such as
the Heart Rate Service.

A smartwatch exposing arbitrary proprietary Bluetooth characteristics is not a
standard BLE device merely because it uses Bluetooth.

## Smart-Bottle Decision

Smart-bottle support is deferred from the current scope.

Android Studio provides phone and Wear OS virtual-device testing, but no verified
built-in Android Studio facility has been established that emulates a programmable
smart bottle as an external BLE GATT peripheral.

A mocked Dart provider can validate Hydrion’s state management and UI, but cannot
certify Bluetooth scanning, pairing, GATT discovery, reconnection, background
behaviour or radio failure handling.

Smart-bottle work may begin in a later sprint when at least one of these exists:

- A physical documented smart bottle.
- A Nordic or equivalent BLE development board acting as the bottle.
- A second physical device capable of running a controlled GATT peripheral.
- A vendor-provided simulator reproducing the production protocol.

## Tier 2 — Prioritized Official Vendor Candidates

These candidates were selected for ecosystem reach, user adoption and availability
of an official or potentially legitimate integration route. They are not all part
of the immediate MVP.

| Priority | Ecosystem | Preferred route | Alternative route | Classification |
|---:|---|---|---|---|
| 1 | Samsung Galaxy Watch/Ring | Health Connect | Samsung Health Data SDK | Planned |
| 2 | Fitbit and Pixel Watch | Health Connect/Wear OS | Google Health API | Planned |
| 3 | Garmin | HealthKit or Health Connect where available | Garmin Health API | Partner-restricted |
| 4 | Huawei Watch/Band | Huawei Health Kit | Verified hub export where available | Region-dependent |
| 5 | Oura Ring | HealthKit or Health Connect where available | Oura API | Planned |
| 6 | WHOOP | Verified hub export | WHOOP API | Planned |

### Tier 2 implementation rules

- HealthKit or Health Connect must be attempted first when the required metrics
  and provenance are available.
- Vendor APIs must be separate providers behind `HealthDataProvider`.
- Vendor APIs must not place client secrets inside the APK or iOS application.
- Any backend requirement must receive a separate privacy, security and operating-cost review.
- OAuth tokens must be revocable and securely stored.
- Vendor-cloud data must be clearly distinguished from device-local data.
- Hydrion must not advertise an entire brand based on one tested model or metric.

## Tier 3 — Prioritized White-Label Research Candidates

These are experimental compatibility candidates only.

| Priority | Companion application | Selection reason | Classification |
|---:|---|---|---|
| 1 | FitPro | Very large white-label wearable user base | Research candidate |
| 2 | Da Fit | Large user and review footprint across generic watches | Research candidate |
| 3 | GloryFit | Widely used companion application for multiple watch families | Research candidate |
| 4 | FitCloudPro | Large installed base and numerous supported watch models | Research candidate |
| 5 | WearFit Pro | Common companion for inexpensive white-label wearables | Research candidate |
| 6 | HryFine | Common companion application for generic watches | Research candidate |

FitPro remains one candidate within this tier. It is not Hydrion’s wearable
connection procedure or the definition of wearable-integration success.

### Tier 3 research questions

Every candidate must be evaluated independently for:

- Health Connect export on Android.
- HealthKit export on iOS.
- Metrics actually exported—not merely displayed inside the companion application.
- Standard documented BLE services.
- Official API or SDK availability.
- Model-specific proprietary characteristics.
- Pairing and authentication behaviour.
- Encryption and replay protection.
- Source and device provenance.
- Background synchronization delay.
- Firmware, account and region dependencies.
- Legal authorization for any protocol implementation.

Reverse engineering must be isolated from production qualification.

No proprietary protocol may enter production merely because packet inspection
made communication technically possible. Legal authority, stability, security,
consent and maintainability must also be established.

## Hydrion Wearable Interface

Hydrion shall provide a dedicated `Wearable Health` area rather than hiding
wearable operation inside general settings.

### Wearable overview

The screen shall show:

- Available provider routes.
- Connected providers.
- Connected wearable or contributing application when known.
- Provider type: hub, live watch, BLE or vendor API.
- Granted data categories.
- Last synchronization attempt.
- Last successful synchronization.
- Latest data timestamp.
- Imported record count.
- Whether live monitoring is active.
- Whether wearable information currently influences hydration insights.
- Clear privacy and local/cloud-storage status.

### Required provider states

The interface must visually distinguish:

1. Provider unavailable.
2. Installation or system update required.
3. Permission not requested.
4. Permission partially granted.
5. Permission granted but not connected.
6. Connecting.
7. Connected but no contributing source found.
8. Connected but no records found.
9. Synchronizing.
10. Data successfully imported.
11. Live session active.
12. Data stale.
13. Permission revoked.
14. Synchronization failed.
15. Provider disconnected.
16. Provider unsupported.

These states must not reuse an identical screen with only hidden internal changes.

### Successful imported-data state

When data is available, the interface shall show:

- `Health data connected`
- Provider name.
- Contributing application.
- Wearable/device name when reliably supplied.
- Latest synchronization time.
- Records read, imported, updated, rejected and deleted.
- Latest workout or activity summary.
- Latest supported metrics and timestamps.
- A `Synchronize again` control.
- A `View imported data` control.
- A `Manage permissions` control.
- A `Disconnect` control.
- A `Delete imported wearable data` control.

### Live-session state

When live measurements are supported, Hydrion shall show:

- `Live wearable session active`
- Connected device and provider.
- Current supported measurements.
- Time of the most recent event.
- Signal/data freshness.
- Connection-loss state.
- Pause and stop controls.
- A visible explanation of how the live information affects hydration guidance.

A stale measurement must never continue appearing as live.

### Connected-with-no-data state

The interface shall identify the missing section of the route:

- Hydrion lacks permission.
- The health hub contains no requested records.
- The companion application has not exported records.
- The wearable has not synchronized with its companion.
- The available records are outside the requested period.
- The record types are unsupported.
- The source cannot be identified.
- Synchronization failed.

The screen must provide the appropriate recovery action rather than only
displaying a generic `Try again`.

## Data Presentation

Hydrion shall provide a wearable-data dashboard containing:

- Activity and workout timeline.
- Steps and distance trends.
- Active-energy trend.
- Live-session summaries where supported.
- Provider and device provenance.
- Data freshness.
- Synchronization history.
- Records excluded because of duplication or source priority.
- Explanations of any hydration insight influenced by wearable information.

Every value must display its source and timestamp.

Hydrion must not represent consumer wearable measurements as medical diagnosis
or direct measurement of hydration status.

## Verified Android Environment

| Item | Verified result |
|---|---|
| Phone | Infinix X6835B |
| OS | Android 13 / API 33 |
| Architecture | ARM64 |
| Google services | Present |
| Health Connect | Installed and SDK status `available` |
| Hydrion permission | Read permission granted for selected categories |
| Hydrion adapter | Able to read Health Connect records |
| Toolbox records | Read successfully when deliberately inserted |
| Repeat synchronization | 0 new records; imported total remained 3 |
| Missing optional device metadata | Synthetic workout imported successfully |
| Force-stop/relaunch | Imported records, connection state and manual hydration persisted |
| Cold provider launch | Blocked by Infinix/XOS `AutoStart Limit` after Health Connect is killed |
| FitPro export | Not established |
| HealthLife export | Not established |
| Production wearable route | Not yet physically certified |

This proves Hydrion can consume supported Health Connect records. It does not
prove that FitPro, HealthLife or the attached watch contributes records.

The cold-start limitation is external to Hydrion's record mapper: the official
Google Health Connect Toolbox also receives `RemoteException: Binding to service
failed` when XOS refuses to start the standalone provider service. Hydrion makes
one bounded fresh-client rebind attempt and then exposes the failure. Manually
opening Health Connect restores access temporarily; that is a diagnostic fact,
not an acceptable production workaround or a certification result.

## Production Acceptance Gates

- [ ] Health Connect imports real records written by a non-Toolbox production source.
- [ ] HealthKit imports real records on a physical iPhone.
- [ ] Wear OS live measurements are received from an authorized physical watch.
- [ ] Apple Watch live measurements are independently verified.
- [ ] Standard BLE is verified using a documented physical sensor.
- [ ] The wearable interface displays every required provider state accurately.
- [ ] Successful synchronization produces visible source, record and timestamp evidence.
- [ ] Connected-with-no-data identifies the missing route without claiming success.
- [ ] Stale data is never displayed as live.
- [ ] Disconnecting preserves manual hydration history.
- [ ] Deleting imported data does not delete the source platform’s records.
- [ ] Imported data remains encrypted locally.
- [ ] Logs and diagnostics contain no health values, tokens or encryption keys.
- [ ] Android success does not satisfy iOS acceptance.
- [ ] Simulator success is not reported as physical-device certification.
- [ ] Health Connect can cold-bind after the provider process is killed under the phone's production battery/AutoStart policy.
- [ ] Source updates and deletions are reconciled on the physical Android device.
- [ ] Permission revocation and restoration are verified through user-controlled system settings.

## Tier 3 Research Gates

These gates are separate from production acceptance:

- [ ] Exact watch model and firmware recorded.
- [ ] Exact companion application package and version recorded.
- [ ] Health Connect export tested.
- [ ] HealthKit export tested.
- [ ] Exported metrics and units recorded.
- [ ] Standard BLE services enumerated.
- [ ] Proprietary characteristics kept out of production code during discovery.
- [ ] Authentication, encryption and replay behaviour assessed.
- [ ] Legal and licensing position recorded.
- [ ] Candidate classified as supported, partner-restricted, unsupported or closed.

Failure of a Tier 3 candidate does not block Tier 1 or Tier 2 delivery.

## Current Product Truth

Hydrion currently has a secure provider-independent storage and synchronization
foundation, an Android Health Connect record reader, and an implemented but
physically unverified iOS Apple Health reader.

Hydrion does not yet have physically certified production wearable support.
The iOS implementation must not be advertised as Apple Health or Apple Watch
support until its macOS and physical-iPhone acceptance gates pass.

Toolbox-generated records validate the Health Connect reader but do not constitute
wearable certification.

The next production milestone is a complete real-source route with visible UI:

`Supported wearable/source → documented provider → Hydrion → encrypted records → visible wearable dashboard`

No integration is complete until that complete route passes.

## Apple simulator repair and separate Wear OS track — 2026-09-19

See [the reproducible Apple sprint evidence](docs/validation/apple-wearable-sprint-2026-09-19.md).
The watchOS companion mirrors manual hydration snapshots. It is separate from
read-only Apple Health imports and from the WidgetKit extension. An Apple Health
record retains its contributing application and optional device provenance;
its presence does not prove Apple Watch, Garmin, Fitbit, Oura or FitPro support.

**Wear OS is not implemented.** Repository inspection found only Android's
`:app` phone module, no Wear OS module/manifest/Gradle configuration, watch UI,
Data Layer or Health Services integration, wear permissions, tests or emulator
workflow. A commit subject mentioning a scaffold is not implementation evidence.

The bounded follow-on plan requires separate authorization before coding:

1. Agree the first product slice: a passive hydration mirror, or a separately
   scoped Health Services workout feature. Define permissions and ownership.
2. Add an isolated Wear OS module, manifest and Gradle configuration compatible
   with the existing Android toolchain; keep the phone app working alone.
3. Define a versioned, validated snapshot protocol, explicit connection/error
   states, latest-value delivery and duplicate/delayed-update rules. Use the
   Data Layer for phone communication; select Health Services only for an
   authorized sensor/workout slice, never for the passive mirror by default.
4. Add parser/state tests, then build/install/launch an Android phone and Wear OS
   emulator pair. Exercise permissions, no data, invalid payloads, disconnect,
   reconnect, process termination and state restoration independently of Apple.
5. Record emulator evidence separately. Physical Wear OS support, device model,
   metrics, battery, memory and background delivery remain physical test gates.

No Wear OS acceptance criterion is checked by this Apple sprint. There are
zero physical iPhones available and zero completed physical-iPhone tests;
physical Apple Watch certification is also unavailable.
