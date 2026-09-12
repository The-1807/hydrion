# Hydrion Wearable and Health Data Integration Architecture

## 1. Document Status

- **Status:** Architecture decision and feasibility audit; no wearable integration is implemented by this document.
- **Repository inspected:** Hydrion Flutter application, version `1.2.0+4`.
- **External facts checked:** 2026-09-11, against the authoritative sources in section 39.
- **Decision:** Adopt a **local-first hybrid architecture**, beginning with read-only Apple HealthKit and Android Health Connect ingestion. Defer vendor clouds, a Hydrion backend, accounts, aggregators, and direct BLE until a demonstrated product requirement cannot be met by the OS health hubs.
- **Accuracy target:** Highest practical fidelity with preserved provenance and explicit uncertainty. Consumer wearable data is not assumed to be complete, immediate, clinically accurate, or semantically interchangeable.

Terms such as **current** or **verified** describe repository state observed during this audit. Terms such as **proposed**, **future**, or **should** describe architecture that does not yet exist.

## 2. Executive Summary

Hydrion should not connect directly to every watch. Apple HealthKit and Android Health Connect already form the supported user-consent, data-sharing, and source-attribution boundary for most consumer wearables. The first implementation should read a deliberately small set of activity records from those hubs, normalize them on-device, preserve their origin, derive conservative hydration-relevant activity features, and pass only those features to the existing personalization boundary.

The initial useful data set is workout/exercise type, start/end/duration, and active energy where available. Steps and distance may support activity context but should not be independently added to a workout adjustment, because they commonly overlap. Heart rate may later help classify an explicitly detected workout, but it is not required for the first release. HRV, sleep stages, SpO2, temperature, stress, recovery/readiness scores, and body composition must not change a hydration target without separate scientific, semantic, and product validation. Imported weight can materially alter the current body-weight baseline and therefore requires an explicit review/confirmation workflow rather than silent synchronization.

Hydrion currently has no account service, remote database, health-data store, HealthKit/Health Connect configuration, or production wearable integration. Its `WearableService` and `BLEService` are local, unavailable placeholders; they are not evidence of health-platform or device support. The application uses manually composed Provider/ChangeNotifier services and JSON stored through SharedPreferences. That storage is suitable for small preferences and checkpoints, not a growing, indexed health-sample ledger.

The target design is:

```text
Wearable -> vendor companion app -> HealthKit / Health Connect
                                      |
                                      v
                         proposed platform provider adapter
                                      |
                                      v
                    proposed local normalized health repository
                         | provenance, quality, deduplication
                                      v
                    proposed hydration feature extraction
                                      |
                                      v
                       existing personalization boundary
```

Optional, separately consented paths may later add a vendor cloud provider through a Hydrion backend, or an open BLE sensor provider for an owned/licensed smart bottle or a standardized GATT sensor. Those paths must emit the same canonical records and retain their different ingestion routes. They are not phase-one requirements.

## 3. Repository Truth

The following is verified repository state, not a proposed design:

| Area | Current state |
| --- | --- |
| Language/framework | Dart and Flutter; small Kotlin/Swift platform hosts |
| Product version | `1.2.0+4` in `pubspec.yaml` |
| Declared platforms | Android, iOS, web, macOS, and Windows |
| State management | `provider` with ChangeNotifier repositories/services |
| Composition | Manual construction in `HydrionServices` in `lib/main.dart`; no dependency-injection framework |
| Navigation | Flutter `MaterialApp` routing and explicit service passing |
| Persistence | `HydrionLocalStore`; production implementation uses SharedPreferences strings/JSON, with an in-memory test implementation |
| Serialization | Hand-authored Dart map/JSON conversion and versioned preference keys |
| Networking | Focused HTTP adapters for weather/Open-Meteo and optional Gemini behavior; no general backend client |
| Accounts/backend | None found: no authentication, remote database, user account, token vault, or health cloud |
| Health integration | No HealthKit, Health Connect, wearable vendor SDK/API, or health Flutter package |
| BLE integration | `BLEService` returns unavailable/empty/null and has no Bluetooth dependency |
| Wearable integration | `WearableService` reads/writes local Hydrion hydration logs and reports health/BLE sync unsupported |
| Testing | Flutter unit/widget tests with in-memory services and repository fakes |
| Background tasks | Local notification scheduling and Android boot/exact-alarm declarations; no health background delivery or WorkManager health sync |

Current health-adjacent domain state includes body metrics, age/sex settings, reproductive state and pregnancy duration, daily activity intensity/minutes, hydration logs, weather context, and `PersonalizedHydrationEngine`. Current hydration logs record ID, volume, timestamp, a string source/action identifier, and hydration metadata. That model is not a sufficient health-sample provenance model.

The current local-first privacy posture is material to this decision: Hydrion has no health-data processor or remote health-data store today. Introducing a cloud aggregator or vendor OAuth backend would be a new product, security, privacy, and operational boundary rather than a small adapter change.

## 4. Current Hydrion Architecture

Hydrion's existing boundaries should guide the future design:

- Repositories own persisted state and expose ChangeNotifier updates.
- Domain services/engines calculate recommendations from explicit inputs.
- `HydrionServices` acts as the composition root and creates platform adapters.
- Platform-specific behavior is narrow and currently uses plugins plus a small number of method channels.
- Tests substitute in-memory repositories rather than requiring global singletons.

`PersonalizedHydrationEngine` already consumes a summarized activity context. Wearable records should therefore not be injected directly into that engine. A proposed feature-extraction layer should convert qualified, deduplicated records into a reviewable daily activity context. This keeps provider semantics, sync state, and raw sample density outside the hydration calculation.

The existing `WearableService` name should not be expanded into an all-purpose integration object. Its present local hydration-log behavior is conceptually different from external health ingestion. During implementation, migrate ownership deliberately: retain compatibility where needed, but introduce focused provider, sync, repository, and feature responsibilities rather than turning the placeholder into a large service.

### Platform configuration currently present

**iOS:** deployment target 14.0; `AppDelegate` performs normal Flutter plugin registration; the Runner entitlement contains the Hydrion app group used by widgets. `Info.plist` has location/photo descriptions but no HealthKit read/write purpose strings. There is no HealthKit entitlement, HealthKit background-delivery entitlement, or health background mode.

**Android:** the app ID is `com.the1807.hydrion`; the manifest currently declares internet, coarse location, notification, boot, and exact-alarm permissions. It contains no Health Connect data permissions, activity-recognition/body-sensor/Bluetooth health permissions, or health permission-rationale activity configuration. The Gradle file delegates minimum/target SDK values to Flutter. Native Kotlin method channels cover locale, permission-revocation handling, and timed-session notifications, not health ingestion.

Desktop and web have no equivalent first-party hub path in scope. The proposed feature must remain unavailable there unless a future cloud/account product is explicitly approved.

## 5. Product Requirements

### Near-real-time

Hydrion's current product does not require second-by-second heart rate. Its existing daily recommendation model can use completed or recently updated activity. HealthKit/Health Connect delivery within minutes or at next foreground sync is sufficient for the first version.

True live workout coaching would be a different capability. It may require a watch app, a vendor-specific live SDK, or standardized direct BLE, with substantial battery, lifecycle, and safety work. Do not select that architecture until a concrete UI and latency requirement exists.

If that requirement is approved later, use platform-native watch applications rather than trying to turn the phone health hubs into live sensor buses:

- **Apple Watch:** a Hydrion watchOS app owns an `HKWorkoutSession` and `HKLiveWorkoutBuilder`. Use HealthKit workout-session mirroring and `sendToRemoteWorkoutSession` for the paired iPhone experience. Do not assume `WatchConnectivity` or mirroring provides an uninterrupted instant stream: HealthKit can cache data while the iPhone app is suspended and may deliver it minutes later.
- **Wear OS:** a Hydrion Wear OS app owns the workout through Health Services `ExerciseClient`, after checking device/exercise capabilities. The Wear OS Data Layer then carries selected derived updates to the Android phone. `MessageClient` is connected, best-effort, and has no built-in retry; use `DataClient` for durable synchronized state or `ChannelClient` for a connection-oriented stream when their trade-offs fit.
- **Garmin:** the Garmin Health API is a post-device-sync cloud path, not a guaranteed live stream. A true live Garmin feature requires separate evaluation of Garmin Health SDK access or a Connect IQ watch app plus its companion mobile SDK, commercial terms, supported devices, and delivery behavior.

Even in a future live mode, Hydrion should transmit the minimum useful workout features and retain raw dense heart-rate samples on the watch/phone unless an approved feature needs them. Live BPM must not be converted directly into an unvalidated fluid dose.

### Periodic wellness

Workouts, active energy, steps, and distance can tolerate delayed/eventual synchronization. A useful target is refresh on onboarding import, app launch/resume, manual refresh, and opportunistic background delivery where the platform permits. Daily resting metrics, sleep, and recovery scores are not required for hydration calculation.

### History

Default initial import should be bounded, proposed at 30 days, with a clear user choice for a smaller or larger range only when it serves an explained feature. Ongoing sync should be incremental. Long multi-year imports add processing, deduplication, storage, and consent costs with little value for the current daily hydration product.

### User-facing product behavior

- Connecting health data is optional and revocable.
- Manual Hydrion activity and body data continue to work when health access is absent or partial.
- Imported activity must be visible as imported and show its source.
- A user can exclude a source, correct the effective daily activity, disconnect it, and delete imported data without deleting manual Hydrion data.
- No clinical diagnosis, dehydration detection, or medical-device claim is created by connecting a wearable.

## 6. Health Data Relevant to Hydrion

| Signal | Classification | Initial use |
| --- | --- | --- |
| Workout/exercise session and duration | Directly useful | Candidate input to daily activity minutes after deduplication |
| Workout type/intensity | Directly useful when provider semantics are clear | Map conservatively to the existing activity bands; allow review |
| Active energy | Potentially useful/corroborative | Validate activity context; do not double-count with workout duration |
| Steps | Potentially useful | Context/fallback when no workout exists; not a separate additive dose |
| Walking/running distance | Potentially useful | Context/fallback and user insight |
| Exercise heart rate | Potentially useful | Future workout-intensity evidence, not a direct water-dose formula |
| Weight | Potentially useful but high impact | Offer an explicit imported update for confirmation; never silently replace baseline |
| Body composition | Clinically questionable for current purpose | Do not collect initially |
| Resting heart rate | Experimental/contextual | Display only after validation; no hydration adjustment |
| HRV | Experimental and semantically variable | Keep vendor/method-specific; no hydration adjustment |
| Sleep duration/stages | Experimental/contextual | No hydration adjustment in initial architecture |
| Respiratory rate | Unnecessary for current product | Do not request |
| Skin/body temperature | Clinically questionable/metric-dependent | Do not request; not a substitute for ambient heat exposure |
| SpO2 | Unnecessary for current product | Do not request |
| Stress/recovery/readiness scores | Vendor-specific experimental | Do not normalize across vendors or change hydration targets |
| Hydration/water records from a health hub | Potentially useful future import | Requires loop prevention and conflict rules; not initial scope |

The defensible relationship is limited: physical activity and heat can increase water loss, but consumer measurements do not reveal an individual's actual sweat loss reliably. National Academies guidance also distinguishes total water from drinking water and notes wide individual/contextual variation. Hydrion should use activity as a bounded wellness heuristic and keep its existing weather input independent. It must avoid converting heart rate, sleep, HRV, or proprietary recovery scores into precise fluid prescriptions. See the [National Academies water reference](https://www.nationalacademies.org/read/10925), [CDC activity/heat guidance](https://www.cdc.gov/heat-health/risk-factors/heat-and-athletes.html), and [NIOSH hydration limits](https://www.cdc.gov/niosh/docs/mining/userfiles/works/pdfs/2017-126.pdf).

## 7. Wearable Integration Models

### A. OS health hubs

HealthKit on iOS and Health Connect on Android offer the best first boundary: user-controlled permissions, broad companion-app participation, local data access, standard data types, and source metadata. Coverage remains device/app/metric dependent, and vendor-derived scores may not be exported.

### B. Direct BLE

BLE is appropriate only for a documented, licensed protocol or a standardized service whose live latency is genuinely needed. It is not a universal watch integration strategy.

### C. Vendor API/SDK

Vendor clouds can provide richer proprietary metrics and history but add OAuth, accounts, tokens, network dependence, rate limits, vendor review, a backend/webhook surface, and new processors. Add one only for a proven fidelity/coverage gap.

### D. Aggregator

An aggregator reduces per-vendor integration effort but sends sensitive data through another processor, adds subscription/lock-in and outage risk, and normally requires Hydrion accounts/backend infrastructure. It is unjustified for the initial hub-based feature.

### E. Staged hybrid

Use OS hubs by default; retain provider interfaces capable of later vendor-cloud or open-BLE adapters. This gives a coherent destination without paying the cloud and integration costs before demand is established.

## 8. Direct BLE Analysis

The Bluetooth SIG defines standardized services such as Heart Rate (`0x180D`), Battery, and Device Information. A compliant sensor can expose documented characteristics, but Hydrion would still need scanning, pairing/bonding, reconnect behavior, permission handling, background/lifecycle behavior, device identity, measurement parsing, firmware interoperability, and a device test matrix.

Closed watches generally do not expose their complete wellness history as standard GATT services. Their companion apps, OS hubs, or approved cloud APIs perform proprietary authentication, encryption, interpretation, and synchronization. Reverse-engineering those protocols would create fragile firmware coupling, possible terms/certification issues, support burden, and unpredictable battery behavior. It is not an acceptable production plan.

Avoid the broader claim that every Apple, Samsung, or Garmin device deliberately blocks the standard Heart Rate Service. Behavior differs by model, mode, installed app, and vendor feature; some devices can broadcast heart rate in particular modes. That does not create a stable cross-vendor smartwatch integration contract. Hydrion may advertise support only for models and modes it has documented and physically tested.

Use direct BLE only for:

1. A future Hydrion-owned/licensed smart bottle with an authenticated, documented protocol, where live drink events cannot flow through a health hub.
2. A standardized open sensor, such as a heart-rate strap, if an approved live-workout experience needs seconds-level data.
3. A documented vendor SDK explicitly intended for third-party live connections, after licensing and lifecycle review.

Direct BLE is not required for periodic watch-derived wellness data and must not be used to bypass platform consent controls.

## 9. Apple HealthKit Analysis

HealthKit is the recommended iOS source. It supports fine-grained read authorization by type, time-bounded historical access, queries for samples/aggregates, and provenance including source revision, device, UUID, and metadata. Hydrion must preserve those fields rather than flattening every sample to "Apple Watch."

Important limitations:

- Read authorization is intentionally opaque. If read access is denied, queries appear as if only data written by Hydrion is available; the app cannot reliably distinguish denial from no external data. UX must say "no readable data" rather than asserting permission status.
- Background observer queries notify that data changed; Hydrion must then perform a sample/anchored query. Delivery is opportunistic and frequency-limited, not a real-time stream.
- HealthKit capability, `NSHealthShareUsageDescription`, and per-type authorization are required. `NSHealthUpdateUsageDescription` and write authorization are not needed for the initial read-only design.
- Background delivery requires its entitlement/configuration and physical-device testing.
- The current repository lacks all of that configuration.

Use a separate anchored-query cursor per metric/query contract. Persist the cursor only after the imported batch commits. A changed authorization window may require conservative re-query/reconciliation. See Apple's [authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data), [reading](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit), [observer query](https://developer.apple.com/documentation/healthkit/executing-observer-queries), and [source revision](https://developer.apple.com/documentation/healthkit/hkobject/sourcerevision) documentation.

## 10. Android Health Connect Analysis

Health Connect is the recommended Android source. It supplies typed records, data origins, historical reads, and a changes API for inserts/updates/deletes. On Android 14+ it is part of the system; on supported Android 9-13 devices it is delivered through the Health Connect app/Google Play services path. It is not available in work profiles and availability must be checked at runtime.

Important limitations:

- Ordinary reads have a history boundary; broader history requires the dedicated history permission.
- Background reads require a separate background-read capability/permission and availability check.
- Changes tokens should be maintained per data type. Google documents that inactive tokens can expire after 30 days; expiration requires a bounded re-read and deduplication.
- Data origin identifies the contributing app, but it may represent data relayed from a device/vendor app. Preserve origin metadata and never assume the phone is the physical source.
- Runtime permissions may be partial or revoked. Manifest data permissions, a privacy/rationale flow, Play Console declarations, and Google Play health-data policy compliance are required.
- The current repository has no Health Connect configuration.

Google Fit APIs are deprecated and are not the primary design. See Android's [data types](https://developer.android.com/health-and-fitness/guides/health-connect/data-types), [availability](https://developer.android.com/health-and-fitness/health-connect/availability), [read behavior](https://developer.android.com/health-and-fitness/health-connect/read-data), [changes synchronization](https://developer.android.com/health-and-fitness/health-connect/sync-data), and the [Google Fit deprecation notice](https://developers.google.com/android/reference/com/google/android/gms/fitness/Fitness).

## 11. Vendor API / SDK Analysis

Availability below means an official route was found; it does not mean Hydrion is approved or every metric is accessible.

| Vendor | Official route | Constraints and Hydrion decision |
| --- | --- | --- |
| Apple Watch | HealthKit | Native iOS hub is primary. No direct BLE/watch protocol plan. |
| Samsung | Samsung Health -> Health Connect; Samsung Health Data SDK | Hub first. Rich SDK access/public distribution requires Samsung partnership/signature registration and adds Samsung-only native maintenance. |
| Google Pixel Watch / Fitbit | Health Connect; Fitbit Web API | Hub first. Web API is OAuth/cloud; intraday HR for third parties requires approval and resolution is conditional. Fitbit services are being presented under Google Health in 2026. |
| Garmin | Garmin Connect -> Health Connect where enabled; Garmin Health API | Hub first. Health API is cloud JSON after Garmin Connect sync, requires business evaluation/approval, and some metrics may carry licensing costs. |
| Oura | HealthKit/Health Connect where exported; Oura API v2 | Hub first. API uses OAuth2 and scopes; proprietary readiness/recovery semantics remain vendor-specific. Personal access tokens were deprecated in December 2025. |
| WHOOP | WHOOP API | Official OAuth cloud API exposes recovery, cycle, workout, sleep, and body measurement scopes. Use only if hub coverage cannot satisfy an approved feature. |
| Polar | Polar AccessLink | OAuth2 cloud API with exercise/activity/sleep/continuous HR and signed webhooks. Hub first where exported. |
| Withings | Public Health Data API | OAuth cloud, history and notifications/webhooks. Code exchange has tight timing requirements. Hub first. |
| Huawei | Huawei Health Kit / enterprise cloud subscription | User authorization and ecosystem/account dependency; local/background restrictions and region/device availability require a market-specific spike. |
| Amazfit/Zepp | Zepp OS on-device health-writing API verified | This does not prove a general consumer cloud read API for Hydrion. Prefer verified hub export; otherwise mark unsupported pending vendor confirmation. |
| Xiaomi | No suitable authoritative public health-read API verified in this audit | Prefer verified hub export. Do not promise direct support until official documentation/partnership is confirmed. |

Cloud data usually arrives after the wearable synchronizes to its companion app and vendor cloud. It is not equivalent to live telemetry. Vendor scores must retain vendor name, algorithm/semantic version where available, and route; they must not be coerced into a universal recovery or stress metric.

## 12. Aggregator Platform Analysis

| Platform | Verified capability | Principal trade-off | Decision |
| --- | --- | --- | --- |
| Terra | Claims 500+ sources; cloud vendor connections, backend/webhooks, and mobile HealthKit/Health Connect SDKs; usage-credit pricing | Broad coverage and normalized payloads, but health data transits another processor/backend; price and schema dependency | Defer |
| ROOK | Claims 400+ sources; mobile hub SDKs plus cloud connectors and backend/webhooks | Similar coverage benefit with vendor-account prerequisites and processor/lock-in risk | Defer |
| Vital | A current authoritative wearable-integration documentation set was not located during this audit | Name recognition is not evidence of current product capability, terms, or support | Requires vendor verification; do not select |

An aggregator is justified only when measured user demand spans enough cloud-only vendors that building and operating individual adapters costs more than the privacy, commercial, and dependency burden. Before procurement, require a data-processing agreement, residency/subprocessor inventory, deletion SLA, incident terms, field-level provenance proof, raw-vs-derived documentation, export/exit plan, rate/latency SLOs, sandbox evidence, and a current price quote. Marketing device counts are not a compatibility test.

## 13. Wearable Compatibility Matrix

`Indirect` means the vendor companion app must export the metric, which can vary by region, OS, app version, user setting, and metric.

| Ecosystem | iOS HealthKit | Android Health Connect | Vendor API | Direct BLE | Aggregator | Recommended Hydrion route |
| --- | --- | --- | --- | --- | --- | --- |
| Apple Watch | Native, metric/permission-dependent | Unsupported | HealthKit is the official app route | Not recommended | Usually via HealthKit | HealthKit |
| Samsung Galaxy Watch | Not primary; export route requires verification | Indirect via Samsung Health; metric-dependent | Data SDK, partner-restricted for distribution | Not recommended | Conditional | Health Connect first; SDK only for proven gaps |
| Pixel Watch / Fitbit | Indirect via Google Health/Fitbit sync; metric-dependent | Native/indirect Google Health path | Fitbit OAuth cloud; intraday restricted | Not recommended | Commonly available | Health Connect/HealthKit first |
| Garmin | Indirect via Garmin Connect; partial | Indirect via Garmin Connect; partial | Garmin Health, approval/cloud | Not recommended | Commonly available | Hub first; Health API only for justified metrics |
| Oura | Indirect, metric-dependent | Indirect, metric-dependent | Oura API v2 OAuth cloud | Not recommended | Commonly available | Hub first; API for approved proprietary use |
| WHOOP | Hub export coverage requires verification | Hub export coverage requires verification | Official OAuth cloud API | Not recommended | Commonly available | Vendor API only after product justification |
| Amazfit / Zepp | Indirect export requires verification | Indirect export requires verification | General read API not verified | Not recommended | Conditional | Hub where verified; otherwise unsupported |
| Huawei | Indirect/region-dependent | Indirect/region-dependent | Health Kit/cloud, market-dependent | Not recommended | Conditional | Market spike, then hub or approved API |
| Xiaomi | Indirect export requires verification | Indirect export requires verification | Suitable official read API not verified | Not recommended | Conditional | Hub where verified; otherwise unsupported |
| Generic BLE HR sensor | Usually not automatically | Usually not automatically | None generally | Native only when standard Heart Rate Service is implemented correctly | Rare | Future BLE adapter only for approved live workout use |
| Hydrion/open smart bottle | No generic standard assumed | No generic standard assumed | Product-dependent | Preferred if Hydrion owns/licenses protocol | Unnecessary | Future authenticated BLE adapter |

## 14. Architecture Decision Matrix

Scores are 1 (poor) to 5 (strong) for Hydrion's current requirements. Effort and cost are scored so 5 means lower burden. High-weight criteria govern the decision; totals are directional, not mathematically precise procurement scores.

| Criterion (weight) | BLE-first | HealthKit + Health Connect | Individual vendors | Aggregator | Staged hybrid |
| --- | ---: | ---: | ---: | ---: | ---: |
| Data fidelity (High) | 2 | 4 | 5 | 3 | 5 |
| Device coverage (High) | 1 | 4 | 2 | 5 | 5 |
| Privacy (High) | 4 | 5 | 2 | 2 | 4 |
| Security (High) | 3 | 4 | 2 | 3 | 4 |
| Maintainability (High) | 1 | 4 | 2 | 4 | 3 |
| Platform-policy compliance (High) | 2 | 5 | 3 | 3 | 4 |
| Offline capability (Medium/High) | 5 | 5 | 1 | 1 | 4 |
| Data freshness (Medium/High) | 5 | 3 | 3 | 4 | 4 |
| Engineering effort (Medium) | 1 | 4 | 1 | 5 | 2 |
| Infrastructure cost (Medium) | 3 | 5 | 2 | 2 | 3 |
| Low vendor lock-in (Medium) | 3 | 4 | 1 | 1 | 3 |
| Scalability (Medium) | 1 | 5 | 2 | 4 | 4 |
| Long-term support risk (High) | 1 | 5 | 3 | 3 | 4 |

**Outcome:** build the OS-hub portion first inside a provider abstraction designed for a staged hybrid. This scores strongest on the current high-weight needs without prematurely creating cloud infrastructure. The hybrid column is the long-term shape, not permission to implement every route now.

## 15. Recommended Hydrion Architecture

```text
Apple Watch/vendor app                 Android wearable/vendor app
           |                                      |
        HealthKit                           Health Connect
           |                                      |
 AppleHealthDataProvider (proposed)  HealthConnectDataProvider (proposed)
           +------------------+-------------------+
                              v
               HealthDataSyncCoordinator (proposed)
                  cursor ledger + idempotent import
                              v
                  HealthDataRepository (proposed)
           canonical record + provenance + source policy
                              v
              HydrationFeatureExtractor (proposed)
            bounded daily activity evidence/uncertainty
                              v
         existing daily context / personalization boundary
```

Future optional routes terminate at the same coordinator/repository:

```text
Vendor OAuth cloud -> proposed Hydrion backend -> VendorCloudDataProvider
Open/authenticated BLE device -------------> BleHealthDataProvider
```

Platform adapters return provider records and capabilities; they do not calculate hydration. The repository performs transactional normalization/deduplication. The feature extractor owns metric eligibility, source selection, overlap rules, quality thresholds, and a versioned explanation of how records affected activity context. The existing engine receives only bounded, inspectable features.

## 16. Local-First vs Cloud Decision

| Model | Benefit | Cost/risk | Decision |
| --- | --- | --- | --- |
| Fully local hub ingestion | Strong privacy/offline operation; no account; simplest compliance boundary | No cross-device recovery; misses cloud-only proprietary metrics | Build first |
| Local-first plus optional account sync | Recovery/cross-device use | Authentication, encrypted sync, conflicts, deletion and breach response | Defer until demanded |
| Cloud-backed by default | Vendor OAuth/webhooks and broad cross-device access | Largest privacy/security/operations burden; offline dependence | Reject for current product |
| Hybrid cloud only for opted-in vendors | Preserves local default while enabling a justified cloud-only integration | Two operating models and explicit processor consent | Target extension point, not initial implementation |

Hydrion does not need accounts or a backend for direct on-device HealthKit/Health Connect reads. A backend becomes necessary for confidential OAuth client secrets, reliable webhooks, server-side vendor tokens, cross-device synchronization, or account recovery. None is an established current requirement.

## 17. Proposed Provider Abstraction

Conceptual Dart only; names and APIs must be validated in an implementation design review:

```dart
abstract interface class HealthDataProvider {
  String get providerId;
  Future<HealthProviderAvailability> availability();
  Future<HealthAuthorizationResult> requestReadAccess(Set<HealthMetric> metrics);
  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint);
}
```

Proposed implementations are `AppleHealthDataProvider` and `HealthConnectDataProvider`; future implementations may be `VendorCloudDataProvider` and `BleHealthDataProvider`. The interface should express capabilities, partial authorization, deletions, external IDs, source metadata, and cursor invalidation. It must not reduce every platform to a false common denominator.

Align with Hydrion by composing adapters in `HydrionServices`, keeping repository state observable through ChangeNotifier, and injecting memory/fake adapters in tests. Keep provider-native DTOs at adapter boundaries; translate into canonical records through explicit versioned mappers.

## 18. Canonical Health Data Model

A proposed normalized record needs at least:

| Field group | Required content |
| --- | --- |
| Identity | Hydrion local ID; provider ID; external record ID; external version; tombstone/deletion state |
| Metric | Canonical metric kind; semantic definition ID/version; numeric/categorical value; canonical unit and original unit |
| Time | Start/end instant; source zone/offset when provided; recorded/created/updated time; ingestion time |
| Shape | Instant sample vs interval vs aggregate; aggregation method; sampling/count metadata |
| Origin | Source platform/hub; source application/data origin; ingestion route; provider account pseudonymous reference if needed |
| Device | Physical source device ID where available, manufacturer, model, hardware/software version |
| Authorship | Manual vs sensor-entered vs unknown; raw measurement vs platform-derived vs vendor-derived score |
| Quality | Provider quality flags, Hydrion validation status, confidence class, completeness/gap flags |
| Provenance | Parent record IDs, relay chain, transformation/mapping version, bounded allowlisted provider metadata |

Provider-specific metadata stays in a namespaced, versioned extension object and is allowlisted to avoid accidental collection. Fields that participate in queries, deduplication, retention, source selection, or user explanation belong in the canonical schema, not an opaque JSON blob.

SharedPreferences is not appropriate for this ledger. Before sample ingestion, select a transactional, indexed, migration-capable local database and define encryption, backup, deletion, corruption recovery, and key-loss behavior. Small consent/display preferences and cursors may remain in the existing store only if cursor/data commits cannot become inconsistent.

## 19. Metric Semantics

Canonicalize only when unit conversion and meaning are defensible:

- Heart-rate BPM samples with time/source can share a transport shape, but acquisition context and device quality remain attached.
- Steps, distance, and active energy can share canonical units, but aggregation windows and origin must remain distinct; totals from multiple origins are not additive.
- Workout intervals can share a time/type representation, while vendor activity labels map through an explicit, versioned table with an `unknown` fallback.
- Weight can normalize to kilograms while preserving manual/sensor origin and measurement time.

Do not canonicalize away methodology:

- HRV may use SDNN, RMSSD, sampling windows, or vendor-specific processing. The method is part of the metric identity.
- Sleep stages and session boundaries differ by vendor algorithm and version.
- Resting heart rate, calories, stress, recovery, readiness, and body-battery-style scores are derived by proprietary algorithms.
- Skin temperature deviation is not core body temperature; neither is ambient temperature.

Vendor scores remain namespaced, for example `oura.readiness` rather than `recovery`. Cross-vendor comparisons require an independently validated transformation; absent that, Hydrion may show separate source-labeled trends but may not merge them or drive hydration dosing.

## 20. Provenance

Every record must answer: what measured or calculated it, which app/hub relayed it, when, under which semantic mapping, and how Hydrion ingested it. Preserve the difference between physical device, source app/data origin, OS hub, vendor cloud, aggregator, and Hydrion import.

Example route:

```text
Oura Ring -> Oura app -> Apple Health -> Hydrion HealthKit adapter
```

That is not equivalent to a Hydrion Oura API record even if the values overlap. Display a concise user source while retaining full technical lineage locally. Provider metadata that can identify a user/account should be minimized or pseudonymized.

## 21. Deduplication and Conflict Resolution

1. **Exact upsert:** use `(provider, data origin, external record ID, external version)` when available. A repeated page must be idempotent; provider deletions create/reconcile tombstones.
2. **Cross-route candidate matching:** after unit normalization, compare metric semantic ID, time interval/tolerance, value/aggregate, physical source, and source app. Store a duplicate-group link rather than destroying provenance.
3. **Do not merge distinct samples:** close heart-rate readings are expected. Similar values/times alone are insufficient proof of duplication.
4. **Intervals:** overlapping workout or sleep intervals from the same physical event require a deterministic source policy. Prefer the direct physical-device origin over a relay when quality is equivalent, but preserve alternatives.
5. **Totals:** select one configured source per metric/day/window. Never sum Apple Watch steps plus Oura/phone steps or workout calories plus daily active-energy totals blindly.
6. **Manual data:** manual Hydrion entries never get overwritten silently. User corrections outrank imported values for the effective hydration context while both records retain provenance.
7. **User control:** expose per-metric source priority and an automatic recommended default. Changing priority recomputes derived features without mutating raw imported records.
8. **Versioning:** dedupe, mapping, and selection algorithm versions are persisted so results can be reproduced and safely reprocessed.

## 22. Synchronization Architecture

Maintain a local sync ledger keyed by provider, metric/query contract, account/device scope, and schema version. It stores cursor/token, authorized history boundary, last attempt/success, status/error category, fetched/upserted/deleted counts, and backoff state, but no measurement values in logs.

For HealthKit, use anchored queries per type and an observer only as a change signal. For Health Connect, use a changes token per data type, process upserts and deletes, and handle token expiry by bounded overlap re-read plus dedupe. Vendor clouds later use provider cursor/page token and signed webhook checkpoints.

Import transaction:

```text
read page using old checkpoint
  -> validate and normalize each provider record
  -> atomically upsert records/tombstones and new checkpoint
  -> recompute only affected daily features
  -> publish repository change
```

Retries use bounded exponential backoff with jitter for transient failures. Permanent permission/auth failures pause that provider. Partial pages never advance past uncommitted data. Clock changes do not change stored instants; local-day aggregation is recomputed with the applicable zone policy. DST days are treated as calendar days, not assumed 24-hour intervals.

On reinstall, local checkpoints and data may be lost; with no account, Hydrion performs a new consent-aware bounded import. Device replacement behaves similarly. Disconnect stops new imports and offers separate choices to retain or delete imported records. Permission reduction invalidates only affected metric jobs and preserves allowed/manual data.

## 23. Background Processing

| State/route | Realistic behavior | Freshness promise |
| --- | --- | --- |
| Foreground/resume/manual | Query hub immediately subject to permission/availability | Seconds to minutes after data has reached hub |
| iOS background HealthKit | Observer may wake app; app then executes anchored read; system controls scheduling | Opportunistic/eventual, not continuous |
| Android background Health Connect | Requires supported background read and scheduled platform work; OEM/battery rules apply | Periodic/eventual |
| Suspended/terminated/low power | Work may be delayed or not run until relaunch | No deadline guarantee |
| Reboot | Reschedule Android work/restore state where permitted; iOS remains system-controlled | Eventual after OS/app opportunity |
| Vendor cloud/webhook | Depends on device -> vendor app -> cloud and provider delivery | Minutes to hours, provider-dependent |
| Direct BLE | Foreground active session can be near-real-time; background is platform/device constrained | Seconds only during an explicitly supported session |

Phase one should ship foreground/on-resume/manual incremental sync. Add background modes only after value, battery, permission, and physical-device reliability are demonstrated. Never present "last synced" as "last measured."

## 24. Permissions and Consent

### Initial least-privilege map

| Hydrion capability | Data requested | Platform permission | User-facing purpose |
| --- | --- | --- | --- |
| Import completed activity | Workouts/exercise sessions | HealthKit workout read / Health Connect exercise-session read | Use completed activity duration/type to improve today's activity context |
| Corroborate activity | Active energy, only if feature approved | Per-type read | Reduce reliance on self-reported intensity without double-counting |
| Optional fallback context | Steps/distance, only if separately enabled | Per-type read | Estimate general movement when workout records are absent |

Do not request write permissions initially. Do not request HR, HRV, sleep, SpO2, temperature, respiratory rate, body composition, or broad history until an approved feature specifically needs it.

On Apple, add the HealthKit capability and a specific `NSHealthShareUsageDescription`; add background delivery only in its later phase. On Android, declare only used Health Connect record permissions, implement the required permission-rationale/privacy route and Play declaration, and request at runtime after an educational screen. Check SDK/provider availability before showing connect UI.

Consent is granular by capability/metric and separate from legal-policy acceptance. Record local consent purpose/version/time, not a claim that every platform read was granted. Partial authorization produces partial features. Denial, no data, unsupported data, and revoked access all preserve manual workflows. Provide settings to reconnect, adjust metrics/source priority, delete imports, and disconnect. Re-prompt only after user action or a meaningful new capability, never in a loop.

## 25. Security Architecture

- Store granular health records in a proposed encrypted, transactional local database. Protect the database key with iOS Keychain/Android Keystore and apply iOS file protection. Define behavior when the key is lost; do not weaken protection to recover silently.
- Exclude sensitive health stores from inappropriate backups. Document any encrypted user export separately. Current Android `allowBackup=false` is helpful but is not a complete cross-platform control.
- Keep raw health data and granular derived signals on-device by default.
- Use TLS for any future cloud route, certificate/hostname validation, short-lived access tokens, rotating refresh tokens, and OS secure storage. Confidential client secrets belong on a backend, never in Flutter assets.
- A future backend requires tenant-scoped authorization, encryption at rest, KMS separation, key rotation, deletion/retention jobs, rate limits, audit events, and least-privileged service identities.
- Verify webhooks with the vendor's signature scheme, timestamp/nonce/replay window, and idempotency key before processing.
- Treat provider payloads as untrusted: strict schema/range/size validation, bounded metadata, safe parsing, and quarantine/error counts.
- Redact measurements, tokens, external IDs, user identifiers, and payload bodies from logs, analytics, crash breadcrumbs, screenshots, and support exports.

## 26. Threat Model

| Threat | Control and residual risk |
| --- | --- |
| Local DB disclosure | Encryption/key store, file protection, backup policy, screen/privacy controls; a fully compromised unlocked device remains a risk |
| Excessive permissions | Feature-scoped requests, permission inventory tests, periodic review, graceful partial access |
| OAuth/refresh-token theft | Backend-held confidential flows where required, encrypted token vault, rotation/revocation, no token logging |
| Backend/account compromise | MFA options, session controls, tenant authorization, anomaly detection, breach plan; avoided entirely in initial local-only path |
| Malicious/malformed provider data | Schema/range/time validation, size limits, provenance, quarantine, no direct calculation use |
| Replayed/forged webhook | Signature and timestamp verification, replay cache, idempotent event processing |
| Duplicate/poisoned health records | Stable identity, source policy, visible provenance, reversible feature derivation |
| Sensitive logs/analytics/crashes | Metadata-only diagnostics, redaction tests, explicit analytics event allowlist; no raw samples |
| Backup/export leakage | Exclude by default, encrypted explicit export, authentication before export, deletion policy |
| Dependency compromise | Pin/review packages, SBOM/license checks, native boundary review, rapid patch ownership |
| Insider/support access | No raw central data initially; later least privilege, audited access, just-in-time approval |

## 27. Privacy / Regulatory Considerations

This is architecture guidance, not legal advice. Applicability depends on markets, business relationships, purposes, and actual data flows.

**Platform policy:** Apple restricts health/fitness data use for advertising, marketing, and data mining and requires accurate disclosure and consent. Google Play health permissions require an approved health use case, minimum access, clear disclosure/consent, and policy declarations. These obligations apply even when statutory health-sector law does not.

**Canada:** PIPEDA may apply to commercial personal-information processing depending on jurisdiction and organization; sensitive health data generally calls for express, meaningful consent, limited purpose/collection/use/retention, safeguards, access/correction, accountability, and breach processes. Provincial laws may also apply. Ontario PHIPA applicability depends on whether Hydrion acts as a health information custodian, agent, or service provider in a covered relationship; a consumer wellness app is not automatically a custodian.

**EU/UK:** health data is special-category data. A rollout needs an Article 6 lawful basis plus an Article 9 condition (often explicit consent for an optional consumer feature), transparent purpose limitation, minimization, retention/deletion, access/portability/correction, privacy by design, processor agreements/transfers, and likely a DPIA before cloud expansion. UK GDPR analysis is parallel but jurisdiction-specific.

**United States:** HIPAA does not automatically apply because an app handles health data. It depends on Hydrion acting for a covered entity/business associate or another covered relationship. A user-directed consumer app may fall outside HIPAA while still being subject to FTC and state health/privacy/breach laws. Reassess before provider/employer/insurer integrations.

**Medical-device boundary:** reading activity to offer general wellness guidance does not itself establish a medical device, but claims, intended use, risk, and decision impact matter. Do not claim diagnosis, treatment, clinical dehydration detection, or precision fluid replacement. Obtain regulatory/legal review before using physiological metrics to direct care or serve clinical customers.

Before release: update privacy notices and in-app disclosures; maintain a data inventory/retention schedule; define export, correction, deletion, revocation, and processor procedures; prohibit advertising use; and complete threat/privacy impact reviews for every new route.

## 28. Hydration Intelligence Boundary

```text
Imported records
  -> structural/range/time validation
  -> provenance and semantic classification
  -> deduplication and source selection
  -> versioned hydration-relevant feature extraction
  -> bounded daily activity proposal
  -> existing recommendation engine and explanation
```

Phase-one feature policy:

- A completed workout may propose activity duration and a conservative intensity band.
- Active energy, steps, distance, and workout HR can corroborate classification but must not stack as independent water additions for the same activity.
- Manual user activity remains available and can override the proposed context.
- Source, freshness, coverage gaps, and uncertainty are visible in the explanation.
- Weight import requires confirmation before affecting the baseline.
- Sleep, HRV, resting HR, respiratory rate, SpO2, temperature, stress, readiness, and recovery do not affect the hydration calculation.
- Environmental heat remains sourced/validated independently; skin temperature is not a weather signal.

The extractor needs a versioned rule/evidence record and bounded output accepted by the current personalization rules. Product copy must say that wearable estimates may be incomplete/delayed and that Hydrion provides wellness guidance, not individualized medical fluid therapy. Special populations and users with fluid restrictions require existing safety language and professional guidance.

## 29. Failure Handling

| Failure | Behavior |
| --- | --- |
| Hub unavailable/unsupported OS | Hide/disable connect with explanation; preserve manual behavior |
| Provider/companion app absent or wearable offline | Keep prior records, show stale source/last sync, retry on resume; do not invent zero activity |
| Partial/denied/revoked permission | Sync allowed metrics only, pause affected jobs, preserve data until user-selected deletion |
| Cursor expired/corrupt | Bounded overlap re-read and dedupe; never wipe manual data |
| Malformed/out-of-range record | Quarantine/drop record with metadata-only diagnostic count; continue page where safe |
| Duplicate/conflicting samples | Apply deterministic source policy and retain lineage; ask user only when effective result is ambiguous/high impact |
| Interrupted/partial sync | Roll back page and cursor or atomically commit both; retry idempotently |
| Rate limit/transient cloud outage | Honor retry-after and bounded exponential backoff; show delayed state |
| OAuth expired/revoked | Attempt standards-compliant refresh once; then require explicit reconnect |
| Backend/aggregator outage | Existing local records/manual mode continue; no phase-one dependency |
| Unsupported metric/schema change | Preserve known fields, reject unknown unsafe semantics, flag adapter incompatibility |
| Local corruption/key loss | Fail closed for affected store, retain unaffected Hydrion data, offer safe reimport after consent |

## 30. Observability

Maintain local diagnostic events with provider ID, adapter/schema version, availability category, coarse permission state, attempt/success time, checkpoint age/hash (not value), record counts, delete/duplicate/reject counts, latency bucket, retry count, and stable error category. Do not record raw values, timestamps precise enough to expose behavior unless strictly needed, payloads, tokens, source account IDs, or health descriptions.

A user-facing connection screen should answer: connected/available state, enabled categories, source priority, last successful sync, data-through time (distinct), delayed/error category, and reconnect/delete actions. A support bundle must be previewable, explicit opt-in, redacted, and contain schema/build/diagnostic metadata only. If future telemetry is introduced, use an allowlist and privacy review; the repository currently has no analytics/crash pipeline to assume.

## 31. Testing Strategy

- **Unit:** every unit/semantic mapping, range validation, source priority, exact and cross-route dedupe, overlap/conflict handling, deletion, feature bounds, DST/time-zone/calendar boundaries, consent and permission states.
- **Adapter contract:** each provider runs common fixtures for pagination, stable IDs, updates, tombstones, partial authorization, malformed fields, cursor invalidation, provenance, and idempotent replay.
- **Repository:** transactional record+cursor commits, migrations, encryption/key failure, selective deletion, corruption recovery, and recomputation of affected days.
- **Platform integration:** real-device HealthKit and Health Connect tests for initial/history reads, partial/revoked access, source metadata, background delivery, termination/reboot, and no-data ambiguity. Simulators/emulators supplement but do not certify behavior.
- **Vendor sandbox:** only for approved vendors; OAuth expiry/revocation, pagination, rate limits, webhook signature/replay, schema drift, deletion, and outages.
- **End to end:** connect, import, explain activity adjustment, override, source switch, disconnect/retain, disconnect/delete, and reinstall behavior.
- **Privacy/security:** manifest/entitlement permission allowlists, log-redaction assertions, export inspection, dependency/license scanning, abuse payloads, and backup behavior.

Commit only anonymized synthetic reference fixtures. Include midnight, leap day, DST gap/fold, year boundary, travel/zone changes, dense samples, missing intervals, duplicated relay routes, and vendor-derived-score fixtures. Never commit real user health data or production tokens.

## 32. Dependency Strategy

No dependency should be added during architecture validation. At implementation time, conduct a time-boxed spike comparing:

1. A current Flutter wrapper with both HealthKit and Health Connect coverage.
2. Hydrion-owned Swift/Kotlin adapters exposed through platform channels.

The `health` package was current at audit time (13.3.2, MIT, verified `carp.dk` publisher) and supports both hubs, but its then-current requirements include Dart 3.8 and iOS 15+. Hydrion currently targets iOS 14, so adopting it requires an explicit supported-OS decision. Its Android setup also affects activity/manifest configuration. Popularity is not sufficient; spike source metadata, anchored/changes semantics, deletions, background support, permission edge cases, and upgrade cadence.

The similarly named `health_connect` package showed version `0.0.0`, an old publication date, and an unverified uploader at audit time; do not select it for core infrastructure. See [`health`](https://pub.dev/packages/health), its [version history](https://pub.dev/packages/health/versions), and [`health_connect` versions](https://pub.dev/packages/health_connect/versions).

Owned native adapters increase code but provide explicit platform semantics and reduce wrapper abandonment risk. Prefer them if the wrapper cannot expose required provenance, cursors/deletions, or testability. Vendor SDKs remain isolated behind provider contracts and require licensing, privacy, native support, and lifecycle review.

## 33. Backend Requirements

No backend is required for phase-one on-device hub ingestion. A backend is justified only by an approved capability such as:

- vendor OAuth needing confidential client-secret exchange/refresh-token storage;
- signed vendor webhooks and durable cloud cursors;
- opt-in cross-device health synchronization or account recovery;
- centralized processing that cannot safely/reliably occur on-device.

If one is approved, begin with data-flow minimization. Prefer derived daily features over granular heart-rate/sleep samples where the capability permits. Vendor cloud data inherently traverses vendor and Hydrion infrastructure; disclose this separately. Establish authentication, authorization, encrypted token/data stores, regional/retention controls, deletion propagation, processor agreements, incident response, auditability, and an offline local fallback before ingesting production health data.

## 34. Account Requirements

Hydrion does not need user accounts to read HealthKit or Health Connect on the current device. Connecting OS hubs should not force sign-up.

Accounts become necessary only for optional cross-device sync, server-side vendor OAuth association, cloud recovery, or multi-device ownership. If introduced, separate the Hydrion account consent from each health-source consent. Support disconnecting a provider, deleting its cloud/local data, and deleting the account independently. Do not use device advertising identifiers as health identities.

## 35. Phased Implementation Roadmap

### Phase 0 - Architecture and evidence validation

- **Objective:** approve metric/purpose list, hub feasibility, privacy posture, and iOS support floor.
- **Dependencies:** product, clinical/wellness, privacy/legal, security review; physical iOS/Android devices.
- **Areas:** documentation and throwaway spikes only.
- **Tests:** source metadata, incremental APIs, partial permission, representative vendor exports.
- **Security:** data-flow/threat/privacy impact assessments.
- **Exit:** approved ADR, data inventory, supported OS/device matrix, dependency decision.
- **Non-goals:** production permission requests or user data storage.

### Phase 1 - Canonical domain and secure local store

- **Objective:** implement canonical records, semantics/provenance, repository, sync ledger, retention/deletion, and synthetic fixtures.
- **Dependencies:** database/encryption/key-management selection.
- **Areas:** new focused domain/repository/storage modules and `HydrionServices` composition.
- **Tests:** migrations, crypto/key loss, atomic cursor commits, dedupe and time boundaries.
- **Security:** encrypted storage, backup exclusion, log redaction.
- **Exit:** provider-neutral contract suite and recovery tests pass.
- **Non-goals:** platform reads or hydration behavior changes.

### Phase 2 - Read-only platform adapters

- **Objective:** Apple HealthKit and Android Health Connect foreground/manual import for the approved minimum metrics.
- **Dependencies:** phase 1; Apple/Google policy configuration; package/native decision.
- **Areas:** iOS entitlements/plist/native adapter, Android manifest/native adapter, Flutter connection UI.
- **Tests:** contract tests plus real-device permission/history/source/cursor/deletion tests.
- **Security:** least privilege; no write access; local consent records.
- **Exit:** reproducible import and revocation/deletion on supported physical devices.
- **Non-goals:** background sync, vendor cloud, BLE, accounts.

### Phase 3 - Provenance, source policy, and user control

- **Objective:** relay duplicate handling, source priority, explanations, correction/override, disconnect/retain/delete.
- **Dependencies:** representative synthetic and multi-device datasets.
- **Areas:** normalization/repository/settings/UI/localization.
- **Tests:** overlapping hubs/vendors, manual precedence, loop and recomputation cases.
- **Security:** avoid exposing source account identifiers.
- **Exit:** no known double-counting in reference fixtures and all decisions are reversible/explainable.
- **Non-goals:** hydration target changes.

### Phase 4 - Hydration feature extraction

- **Objective:** produce bounded activity features and connect them to the existing daily context/recommendation boundary.
- **Dependencies:** approved scientific/product rules and safety copy.
- **Areas:** new feature extractor, existing daily context integration, recommendation explanations.
- **Tests:** bounds, overlap, stale/missing data, manual override, reproductive/body-profile regressions.
- **Security:** engine receives minimum derived features, not dense raw samples.
- **Exit:** independent rule review, full regression, explainable result on physical devices.
- **Non-goals:** use of HRV/sleep/SpO2/stress/recovery for dosing.

### Phase 5 - Background freshness

- **Objective:** add opportunistic background sync only if foreground latency is inadequate.
- **Dependencies:** phase 2 production telemetry/user evidence; platform entitlement/policy approval.
- **Areas:** iOS observer/background delivery; Android background permission and scheduled work.
- **Tests:** physical termination, reboot, low power, battery optimization, delayed delivery.
- **Security:** background work reveals no sensitive notifications/logs.
- **Exit:** measured battery/freshness SLO and honest UX.
- **Non-goals:** continuous real-time guarantees.

### Phase 6 - Selected vendor-cloud integration

- **Objective:** add one vendor only where a high-value metric/coverage gap is proven.
- **Dependencies:** backend/account approval, vendor access/terms, DPA/privacy update.
- **Areas:** backend OAuth/webhook/token services plus isolated provider adapter.
- **Tests:** vendor sandbox, tokens, rate limits, signatures, deletion, outages, semantics.
- **Security:** KMS/token vault, tenant auth, incident and retention controls.
- **Exit:** vendor approval, production security/privacy readiness, demonstrated feature value.
- **Non-goals:** broad vendor collection or aggregator-by-default.

### Phase 7 - Optional accounts and synchronization

- **Objective:** cross-device/recovery only if users demand it.
- **Dependencies:** account product, cloud data model/conflict policy, legal/security operations.
- **Areas:** authentication, sync API, encrypted cloud persistence, account/deletion UI.
- **Tests:** takeover/session threats, offline conflicts, export/deletion, regional operations.
- **Security:** full cloud threat model and independent assessment.
- **Exit:** data rights and incident operations proven.
- **Non-goals:** mandatory account for local hub use.

### Phase 8 - Extended device/live BLE coverage

- **Objective:** an authenticated smart bottle or standardized live sensor for a defined experience.
- **Dependencies:** protocol/license, hardware matrix, live-workout requirement.
- **Areas:** BLE adapter, permissions, foreground session/device UI.
- **Tests:** firmware/device interoperability, reconnect, spoof/replay, battery/background behavior.
- **Security:** authenticated pairing/message integrity where protocol permits.
- **Exit:** supported-device certification matrix and support plan.
- **Non-goals:** reverse-engineered closed watches.

## 36. Risks

- Hub export coverage and freshness vary by vendor, metric, region, companion-app setting, and OS version.
- Source metadata may be insufficient to prove physical-device identity across relay paths, making cross-route dedupe probabilistic.
- A Flutter wrapper may raise Hydrion's iOS minimum from 14 to 15 or fail to expose deletion/provenance semantics.
- Consumer-derived metrics and vendor algorithms can change without semantic versioning.
- Health-permission policy/review and purpose-copy mistakes can block releases.
- Granular health storage materially raises the consequence of device compromise, logging mistakes, and backup leakage.
- Activity heuristics can double-count or create false precision unless source selection and bounded feature rules are rigorous.
- Cloud expansion creates ongoing security, privacy, support, incident, and commercial obligations.

## 37. Open Questions

1. Which supported-market and iOS-version commitments prevent or allow moving from iOS 14 to iOS 15?
2. Which exact activity data produces enough user benefit to justify each permission: workout only, active energy, steps, or distance?
3. Should imported activity automatically update the effective daily context or first appear as a user-confirmable suggestion?
4. What history choices and retention period are valuable to users beyond 30 days?
5. Which vendor export combinations are present on the actual physical-device test matrix, and what provenance survives?
6. Is any seconds-level live-workout or smart-bottle experience approved strongly enough to justify BLE?
7. Are proprietary Garmin/Oura/WHOOP metrics actually needed, or are hub workouts sufficient?
8. Which launch jurisdictions and age groups require additional consent, parental, residency, or health-data analysis?
9. What encrypted local database best fits Hydrion's supported platforms and recovery constraints?
10. Who owns ongoing clinical/wellness rule review when provider semantics or the hydration engine changes?

## 38. Final Architecture Decision

1. **Build first:** the canonical model, secure local repository/sync ledger, and read-only foreground HealthKit/Health Connect adapters for the smallest activity data set; then add dedupe/source controls and bounded feature extraction.
2. **Do not build yet:** live heart-rate coaching, write-back, closed-watch BLE, vendor clouds, an aggregator, accounts, backend sync, or collection of broad wellness metrics.
3. **HealthKit:** yes, as the primary iOS ingestion boundary.
4. **Health Connect:** yes, as the primary modern Android ingestion boundary; not legacy Google Fit.
5. **Direct BLE:** only for an owned/licensed smart bottle, a documented standard GATT sensor needed for live behavior, or an approved vendor SDK; never as the default watch strategy.
6. **Hub gaps:** proprietary/less-exported semantics such as WHOOP recovery, Oura readiness, some Garmin metrics, and market/vendor-specific Huawei/Samsung data may require official vendor routes. Amazfit/Xiaomi general API support remains unverified.
7. **Aggregator now:** no. Reconsider only after measured multi-vendor cloud demand and privacy/commercial due diligence.
8. **Accounts now:** no. Local device authorization is sufficient.
9. **Backend now:** no. It becomes necessary for server-side vendor OAuth/webhooks or optional cross-device cloud sync.
10. **On-device-only by default:** raw/granular heart rate, HRV, sleep, SpO2, respiratory, temperature, stress/recovery, and detailed workout/activity records, plus local provenance and derived daily features.
11. **Backend data later:** only records strictly required for an opted-in cloud-vendor capability or cross-device feature; prefer minimized derived data when possible.
12. **Privacy-preserving architecture:** OS hub -> local provider adapter -> encrypted local normalized repository -> local feature extractor -> existing engine, with no mandatory account.
13. **Best balance:** a staged local-first hybrid: hub-first now, provider abstraction for later evidence-driven cloud/BLE additions, full provenance throughout.

## 39. Authoritative Sources

Sources were checked on 2026-09-11. Product availability, policies, package versions, pricing, and partner terms must be rechecked at implementation/procurement time.

### Apple

- [Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [Configuring HealthKit access](https://developer.apple.com/documentation/xcode/configuring-healthkit-access)
- [Reading data from HealthKit](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [Executing observer queries](https://developer.apple.com/documentation/healthkit/executing-observer-queries)
- [HealthKit workout sessions and workout mirroring](https://developer.apple.com/documentation/healthkit/hkworkoutsession)
- [HealthKit background-delivery entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery)
- [HealthKit source revision](https://developer.apple.com/documentation/healthkit/hkobject/sourcerevision)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Android and Google

- [Health Connect data types](https://developer.android.com/health-and-fitness/guides/health-connect/data-types)
- [Health Connect architecture](https://developer.android.com/health-and-fitness/health-connect/architecture)
- [Health Connect availability](https://developer.android.com/health-and-fitness/health-connect/availability)
- [Reading Health Connect data](https://developer.android.com/health-and-fitness/health-connect/read-data)
- [Synchronizing Health Connect data](https://developer.android.com/health-and-fitness/health-connect/sync-data)
- [Wear OS Health Services ExerciseClient](https://developer.android.com/reference/androidx/health/services/client/ExerciseClient)
- [Wear OS Data Layer client types](https://developer.android.com/training/wearables/data/client-types)
- [Google Fit API deprecation](https://developers.google.com/android/reference/com/google/android/gms/fitness/Fitness)
- [Google Play health permissions policy](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
- [Google Health connected apps/devices](https://support.google.com/googlehealth/answer/14237221?hl=en)

### Vendors and BLE

- [Bluetooth SIG Assigned Numbers](https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/Assigned_Numbers/out/en/Assigned_Numbers.pdf)
- [Garmin Health API](https://developer.garmin.com/gc-developer-program/health-api/)
- [Garmin developer program overview](https://developer.garmin.com/gc-developer-program/overview/)
- [Garmin Connect IQ mobile communication](https://developer.garmin.com/connect-iq/core-topics/communicating-with-mobile-apps/)
- [Fitbit Web API explorer](https://dev.fitbit.com/build/reference/web-api/explore/)
- [Fitbit intraday heart-rate restrictions](https://dev.fitbit.com/build/reference/web-api/intraday/get-heartrate-intraday-by-date-range/)
- [Oura API v2](https://cloud.ouraring.com/v2/docs)
- [WHOOP developer API](https://developer.whoop.com/api/)
- [Samsung Health Connect FAQ](https://developer.samsung.com/health/health-connect-faq.html)
- [Samsung Health Data SDK](https://developer.samsung.com/health/data/overview.html)
- [Polar AccessLink API](https://www.polar.com/accesslink-api/)
- [Huawei Health Kit](https://developer.huawei.com/consumer/en/hms/huaweihealth/)
- [Withings public health-data OAuth flow](https://developer.withings.com/developer-guide/v3/integration-guide/public-health-data-api/get-access/oauth-web-flow/)
- [Zepp OS addHealthData API](https://docs.zepp.com/docs/reference/device-app-api/newAPI/user/addHealthData/)

### Aggregators and Flutter

- [Terra getting started](https://docs.tryterra.co/health-and-fitness-api/getting-started)
- [Terra pricing](https://docs.tryterra.co/health-and-fitness-api/pricing)
- [ROOK data sources](https://docs.tryrook.io/data-sources/)
- [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [`health` Flutter package](https://pub.dev/packages/health)

### Privacy, regulation, and hydration context

- [PIPEDA overview](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/pipeda_brief/)
- [PIPEDA fair information principles](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/p_principle/)
- [Ontario PHIPA](https://www.ontario.ca/laws/statute/04p03)
- [EU GDPR principles](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/principles-gdpr_en)
- [EU legal grounds and sensitive data](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en)
- [UK ICO special-category data](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-are-the-rules-on-special-category-data/)
- [HHS covered entities and business associates](https://www.hhs.gov/hipaa/for-professionals/covered-entities/index.html)
- [HHS health apps guidance](https://www.hhs.gov/hipaa/for-professionals/special-topics/health-apps/index.html)
- [National Academies dietary reference intake for water](https://www.nationalacademies.org/read/10925)
- [CDC heat and athletes guidance](https://www.cdc.gov/heat-health/risk-factors/heat-and-athletes.html)
- [NIOSH heat-stress hydration guidance](https://www.cdc.gov/niosh/docs/mining/userfiles/works/pdfs/2017-126.pdf)
