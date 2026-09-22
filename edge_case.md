# Hydrion Wearable Integration: Evidence and Edge-Case Audit

## 1. Audit Date and Repository Identity

- Audit date: 2026-09-21; Windows host, America/Toronto.
- Repository: [Hydrion root](.).
- Branch: `main`; HEAD: `de06688f010a533e41f9e258b274d1329587ec8b`.
- Origin: `https://github.com/The-1807/hydrion.git`.
- Sections 1-20 preserve the 2026-09-21 audit and QA installation; section 21 records the subsequent correctness sprint. Neither is release certification.
- The original audit performed no commit, push, merge, branch switch, credential change, or acceptance-checkbox edit. The subsequent sprint has its own authorization and evidence below.

The following work existed before this audit and must remain unchanged:

| File | Initial state | Initial SHA-256 |
| --- | --- | --- |
| `HWI_progress.md` | Modified | `CC46BEED3F1FDC63E60DD152E3A944E051CFC46C00628364B2AB12A0E2BBEADE` |
| `lib/ui/screens/startup_screen.dart` | Modified | `E37A9466F6CCF38448734CE2A69FA713DB6A2E6A47F4161EEDC90968EE72BE0C` |
| `test/startup_buffer_test.dart` | Modified | `BA5FE517BA3DF3D0CCCA5C4C1EE147B11B5A09B6942EA5E7BBA22CC5037CF59E` |
| `tool/mixed_language_audit.dart` | Modified | `8ACC3C324026EBF6FCCC0FFA2A07213F2E5F43099A548CFCFBA3D7F92A451B21` |
| `integration_test/wearable_storage_device_test.dart` | Untracked | `1A7CB03D04B6145A28EEE8162C29FA14C0927156230CCEE893710B6970D4DE54` |

The QA build includes the existing working-tree startup-screen change. Its provenance is HEAD plus the preserved working tree, not a pristine release build.

## 2. Executive Summary

Hydrion has two real, read-only health-provider adapters: Android Health Connect and Apple HealthKit. Each imports four metric families: workouts, active energy, steps, and distance. Neither implements universal wearable pairing.

Historical evidence establishes synthetic Health Connect ingestion on an Infinix X6835B and synthetic HealthKit ingestion on an iOS simulator. Current hosted CI establishes Android/Web builds and iPhone/watchOS simulator installation and launch. These are different evidence gates.

The watchOS app displays phone-originated hydration snapshots; it is not a watch-sensor ingestion adapter. There is no implemented Wear OS app, vendor-cloud adapter, health-export-file importer, or functioning direct BLE wearable/bottle integration. No named wearable OEM is end-to-end certified.

Wearable records are available to the imported-data dashboard. `HydrationFeatureExtractor` has tested activity-context logic but no production consumer in the hydration recommendation engine. Wearable data does not currently adjust the production hydration target.

Release readiness remains **NO** for comprehensive wearable integration. Physical Apple acceptance, representative OEM routes, Android OEM service restrictions and large-history memory behavior remain gaps. The original deletion and dashboard-error defects are addressed by the scoped correctness work in section 21, with physical limits stated separately.

## 3. Methodology and Limitations

Evidence consists of source inspection, existing automated tests executed locally, current GitHub run metadata/logs read without dispatching a run, earlier repository validation reports, public manufacturer/platform documentation, and the authorized Infinix QA session.

The user explicitly confirmed during this audit that Health Connect and the existing Hydrion QA app contain only synthetic test records. That confirmation permits synthetic-only runtime checks; it does not authorize inspection of FitPro or HealthLife records. No app-private files, keys, tokens, personal identifiers, or personal health records are exported. Device serial and application-install path random identifiers are omitted.

No physical iPhone, Apple Watch, Wear OS watch, or OEM wearable is exercised in this audit. No operation is run on MrGoldApple. Existing simulator reports are historical evidence, not fresh physical tests. Read-only GitHub inspection does not start new CI.

An APK is inspected by manifest, ABI, hash, and certificate, not its filename. The package ID isolates QA from production. An APK signature matching a debug certificate proves update compatibility, not production certification.

## 4. Evidence Levels

| Level | Meaning | What it does not prove |
| --- | --- | --- |
| L0 | Planned or researched route; no implementation | Connectivity |
| L1 | Model, interface, or stub exists | Real provider reads |
| L2 | Automated logic passes with synthetic/fake inputs | Native integration or device support |
| L3 | Native target/adapter compiles | Runtime success |
| L4 | Named simulator/emulator behavior succeeds | Physical-device behavior |
| L5 | Named physical hardware successfully exercises the stated behavior | General OEM compatibility or release readiness |
| L6 | Security, lifecycle, performance, recovery, controls, and representative compatibility verified | Universal compatibility |

Levels are scoped to a behavior. L5 synthetic import does not imply that revocation, cold provider startup, all metrics, or every watch was tested. L4 watch launch does not imply delivery of a hydration snapshot.

## 5. Infinix Installation and Runtime Results

### Preflight

| Property | Measured result |
| --- | --- |
| USB authorization | One connected ADB transport, state `device` |
| Manufacturer/model | INFINIX / Infinix X6835B |
| Android/API | Android 13 / API 33 |
| Primary ABI | `arm64-v8a` |
| Supported ABIs | `arm64-v8a,armeabi-v7a,armeabi` |
| Initial `/data` free capacity | 3,170,128 KiB, approximately 3.02 GiB; filesystem 98% used |
| Initial host free capacity | 30,223,978,496 bytes, approximately 28.15 GiB |
| Existing QA package | `com.the1807.hydrion.hwi_test`, `1.2.0-hwi-test`, code 2005; debuggable, ARM64 |
| Existing QA APK size | 128,384,374 bytes; executable APK pulled only for identity verification |
| Existing QA signer | Android Debug, SHA-256 `56fe5c7ae21cd1752bbd3e8e9a46f19f0e3ad8a38b43ceef9dd3578c5f6cd730` |
| Other Hydrion packages | No production `com.the1807.hydrion` or ordinary `.debug` package found |
| Installed related applications | Health Connect `com.google.android.apps.healthdata`; FitPro `cn.xiaofengkj.fitpro`; HealthLife/My Health `com.transsion.healthlife`; Health Connect Toolbox `androidx.health.connect.client.devtool` |
| Installer metadata | QA installer reported `null`; not proof of Play installation |

No current validated QA artifact existed at `build/app/outputs/flutter-apk`. Older unsigned size-audit APKs are not QA candidates. A fresh ARM64 debug build uses the existing `hydrionWearableCertification` Gradle property with build number 2006. Estimated temporary build use was 3-8 GiB against 28.15 GiB free. No source/configuration changes are required.

### Verified Artifact and Installation

The first Flutter/environment-property build succeeded but failed identity preflight: it produced ordinary `.debug` and included three ABIs. It was **not installed**. A direct Gradle invocation with explicit QA and ABI-split properties produced the correct artifact; no Gradle file was edited.

| Property | Verified artifact |
| --- | --- |
| Path | `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` |
| Package | `com.the1807.hydrion.hwi_test` |
| Version | `1.2.0-hwi-test`, versionCode **4006** (base 2006 plus Flutter ARM64 split offset 2000) |
| Native ABI | `arm64-v8a` only |
| Size | **128,412,098 bytes** |
| APK SHA-256 | `16E28B28BEA3245F95FB6B8022766906B9E97F75CE06C1A7CF2C0084593349BE` |
| Signing | Android Debug; certificate `56fe5c7ae21cd1752bbd3e8e9a46f19f0e3ad8a38b43ceef9dd3578c5f6cd730`; identical to installed QA signer, different from production |
| Debug state | `application-debuggable` |
| SDK | minSdk 24, target/compile SDK 36 |

Requested health permissions are exactly `READ_EXERCISE`, `READ_ACTIVE_CALORIES_BURNED`, `READ_STEPS`, and `READ_DISTANCE`. Other merged permissions are INTERNET, ACCESS_COARSE_LOCATION, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, VIBRATE, WAKE_LOCK, ACCESS_NETWORK_STATE, FOREGROUND_SERVICE, and the QA-namespaced DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. No health-write permission is requested.

Data-preserving command, executed only after manifest/version/signature comparison:

```text
adb -d install -r build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk
Performing Streamed Install
Success
```

Installed package metadata subsequently reported code 4006 and `1.2.0-hwi-test`. No production package was touched. `/data` free space after installation was 3,200,384 KiB; local C: free after the first build was 28,535,164,928 bytes. These are filesystem measurements, not exact app-data footprint or isolated build-cost measurements.

### Audit-Date Physical Session (2026-09-21)

| Check | Observation | Result / limitation |
| --- | --- | --- |
| First cold launch | `am start -W` returned `Status: timeout`, WaitTime 10348 ms; process and focused activity existed; UI subsequently appeared | Functional eventual launch, **performance gate not passed**; no invented successful cold timing |
| Startup frame pacing | QA process logged skipped-frame batches of 308, 505, and 47 | Debug-device jank observed; root cause not established by this audit |
| Manual hydration | Selected 150 ml, confirmed once; home showed 150 ml and 1 log | Successful synthetic manual entry |
| Navigation | Home -> Settings -> Connect health data | Controls reachable |
| Initial HC refresh | `authorizationState` remote failure, one rebind then `RemoteException`; UI unavailable/failure | Real error handling exercised; exact current OS cause not proven solely by exception |
| Error-screen counts | Initial unavailable state showed `Granted: none`, imported 0 and no sources; later recovery exposed the existing three records | Misleading initial display, **not data loss**; cached summary is loaded only after authorization succeeds |
| Recovery | Used Hydrion's Manage access to open HC; returned to QA | All four granted metrics visible; three existing synthetic Toolbox records restored in summary |
| Incremental sync | Explicit Sync now; native `readChanges` completed for workout, activeEnergy, steps, distance | Success; 0 read/new/updated/deleted/rejected; total still 3 |
| Warm launch/resume | Home key then activity launch; `Status: ok`, WaitTime 202 ms | Existing task brought to front, not cold-start time |
| Logs | Bounded 450-line QA PID sample: 0 fatal exceptions, ANR markers, unhandled exceptions, Flutter errors, or searched sensitive identifier/token/key markers | Scoped negative finding, not comprehensive privacy/performance certification; category/count logging remains |
| Empty-store state | Existing synthetic store was not deleted | Not physically tested; automated empty-state coverage only |
| Permission denial/revocation | Existing four grants preserved | Not forced; automated coverage only |
| New record ingestion this session | Incremental provider returned zero changes | Does not prove a new sample was imported today; earlier physical synthetic import remains historical evidence |

The second sync also completed with zero changes and three imported records. A Home/resume interaction occurred during that attempt; it subsequently reached successful state. This is a brief lifecycle observation, not an in-flight process-kill test.

After force-stop, the second cold launch returned `Status: ok`, `LaunchState: COLD`, TotalTime 9064 ms, WaitTime 9088 ms. Home still showed the synthetic 150 ml. Returning to health controls showed connected-and-synchronized, four granted categories, three Toolbox records, and the saved last-success time. No permission or record deletion was needed. The new PID's bounded 250-line log sample contained zero fatal/ANR/unhandled markers. Nine-second debug startup remains a performance concern, not an L6 pass.

### Historical Physical Evidence, Not Repeated Claims

`HWI_progress.md:366-395` records an earlier code-2005 QA session: three imported synthetic Toolbox records, preserved source, absent optional device metadata, duplicate workout handling, repeat sync with zero changes, and synthetic 150 ml hydration plus imported-record persistence across force-stop.

That session also records XOS `AutoStart Limit` and official Toolbox binding failure after Health Connect is killed. Manually opening Health Connect restored availability then. The production host performs one fresh-client rebind and reports failure rather than looping. Historical APK hash/size differs from the currently installed APK; the old report is not used as identity proof for today's installed bytes.

## 6. Implemented Provider Inventory

Evidence identifiers used below are expanded in section 20.

| Platform | Provider/route | Implementation present | Build status | Runtime status | Data types | Test environment | Highest level | Evidence | Remaining work |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Android | Health Connect | Yes, Dart adapter and Kotlin SDK host | Current main CI and local QA build | Earlier physical synthetic ingestion; current session below | Workout, active energy, steps, distance | Fake bridge, SQLCipher tests, Infinix | L5, narrow historical synthetic behavior | HC, SYNC, DEVICE | OEM background behavior, failure matrix, all-metric physical acceptance |
| iOS | HealthKit | Yes, Dart adapter and Swift host | Current CI simulator and unsigned release | Historical real simulator synthetic read/update/delete/pagination | Workout, active energy, steps, walking/running distance | Fake bridge, native XCTest, isolated iOS simulator | L4 | HK, MAC, CI | Physical iPhone, protected-data lifecycle, signing/isolation, performance |
| watchOS | Phone hydration snapshot display | Yes, SwiftUI target and WatchConnectivity | Embedded app built in CI | Paired simulator install and launch; transport delivery not certified | Local hydration total/goal/progress/status | Hosted iPhone/watch pair | L4 smoke only | WATCH, CI | Actual context receipt, offline/stale/reconnect, physical watch |
| Wear OS | Watch app/Health Services | No | Not applicable | None | None | None | L0 | Inventory | Implement separately if approved |
| Android/iOS | Direct BLE wearable | No working adapter | None | None | None | None | L1 stub only | BLE | Documented protocol, permissions, real parser, reconnection tests |
| Android/iOS | Vendor APIs/SDKs | No | None | None | None | None | L0 | Inventory | Provider approval/scopes, privacy design, implementation |
| Android/iOS | Health-data file import | No | None | None | None | None | L0 | Inventory | Bounded schema parser, consent, provenance, deduplication |
| Android/iOS | Manual hydration fallback | Yes | Android and iOS CI | Prior Infinix synthetic persistence; current check below | Hydration volume and event time | Unit/widget tests and phone | L5 scoped | MANUAL, DEVICE | Full platform accessibility and lifecycle acceptance |

The shared contract is one `HealthDataProvider` abstraction, not a third real provider. Memory repositories, bridge fakes, sample fixtures, and the older `WearableService` do not increase adapter counts.

## 7. Android Integration Status

`AndroidHealthConnectHost` uses `androidx.health.connect:connect-client:1.1.0`, actual `HealthConnectClient` reads and change tokens. It maps four record types, performs bounded initial pages, preserves optional provenance, and emits typed errors. No write permission or health-record write API is used by the production adapter.

The application distinguishes the phone manufacturer, Android health service, companion application, permission state, and contributing source. Health Connect is a route available on eligible Android phones, not another name for every manufacturer's health app. Work profiles are explicitly unsupported; installation/update/unavailable states have UI handling. Official platform prerequisites include Android 9+ and Google Play services; Android 14+ integrates the service differently from this Android 13 device. [Android availability](https://developer.android.com/health-and-fitness/health-connect/availability) (accessed 2026-09-21).

Synchronization is foreground/user-initiated. Resuming the controls screen refreshes status but does not automatically ingest health records. The controls expose success, no readable data, partial categories, failure, and retry. An installed FitPro/HealthLife package proves discovery only, not exported records.

## 8. iOS and HealthKit Integration Status

`HealthKitHost.swift` calls `HKHealthStore`, requests `toShare: []`, and reads `HKAnchoredObjectQuery` pages of 250. Native mapping bounds/validates anchors and dates, preserves sample/source/device provenance, supports deletion identifiers, and passes typed failures without raw native detail. Anchors and records persist through the shared encrypted repository.

Read authorization is opaque: a completed HealthKit authorization request does not prove that every read was granted. `AppleHealthKitProvider.readAuthorizationIsOpaque` is true; the UI qualifies empty results and request-completed state. Do not reinterpret its internal queryable metric set as permission proof.

Historical validation on iPhone 16 / iOS 18.3.1 simulator includes six native XCTest cases, actual synthetic HealthKit fixture import/correction/deletion/pagination, and two Flutter simulator integration tests including protected storage. Current main CI separately proves a simulator build/launch and unsigned device-architecture build. Neither is physical-iPhone acceptance. [Historical evidence](docs/validation/healthkit-macos-simulator-2026-09-17.md).

The physical-iOS QA bundle, Keychain group, and app-group isolation must be verified together; a bundle ID override alone is insufficient. No physical-iPhone installation is attempted here.

## 9. watchOS Integration Status

The repository contains `ios/HydrionWatch`, its Xcode target/scheme, an embedded app, SwiftUI presentation, validated snapshots, and `WCSession` receivers. Runner pushes latest hydration application context. The watch does not supply workouts, heart rate, or other sensors to Hydrion.

Current hosted CI selected iPhone 16 Pro Max / iOS 18.2 and Apple Watch Series 10 (46mm) / watchOS 11.2 dynamically, booted both, waited for the pair to become connected, rechecked after compilation, and installed/launched both applications. This is L4 **installation/launch smoke evidence**, not proof of WatchConnectivity payload delivery or physical watch performance.

Receiver validation rejects malformed fields and stale timestamps and preserves a previous snapshot on invalid input. Disconnected/reachability/error state exists. The Dart sender drops scheduling while `_syncing` is true without an explicit pending replay; lost-last-update behavior requires a focused concurrency test. No new defect fix is authorized in this audit.

## 10. Wear OS Integration Status

No Wear OS application module, manifest/target, Health Services `ExerciseClient` ingestion, Data Layer transport, or corresponding runtime tests were found. Status: **L0, unimplemented**.

A Galaxy Watch or Pixel Watch contributing through its companion and Health Connect is a phone-hub ingestion route, not a Hydrion Wear OS companion. Apple watchOS build evidence contributes zero Wear OS completions.

## 11. BLE, Vendor API, and File-Import Status

- `BLEService.isAvailable` is false, scanning returns an empty list, and water-level reads return null. It is a stub, not an operating smart-bottle or wearable adapter.
- `WearableService.supportsBleSync` and `supportsHealthSync` remain false. The real hub adapters are composed separately in `main.dart`; these legacy flags do not negate that implementation and must not be advertised as implemented BLE.
- No Garmin, Huawei, Oura, Polar, Withings, WHOOP, or other vendor-cloud ingestion adapter/OAuth pipeline was found.
- No health-export-file ingestion route was found. Hydration reporting/export is not wearable-history import.
- A standard Bluetooth Heart Rate Service exists, but no Hydrion parser/connection lifecycle implements it. It is a candidate for compatible sensors, not universal watch pairing. [Bluetooth SIG HRS](https://www.bluetooth.com/specifications/specs/heart-rate-service-1-0/) (accessed 2026-09-21).
- Apple permits XML health-data export; Hydrion has no importer for it. No export of the user's health data is performed. [Apple export documentation](https://support.apple.com/en-bw/guide/iphone/iph5ede58c3d/ios) (accessed 2026-09-21).

Smart bottles are excluded from the OEM/wearable compatibility denominator.

## 12. OEM Compatibility Matrix

All external sources below were accessed on **2026-09-21**. These are candidate routes, not certified brand support. Highest level is for the **exact OEM-to-Hydrion end-to-end route**, not the generic hub adapter. No named OEM device has been tested end-to-end, so these routes remain L0 research candidates.

Google's current documentation uses the Google Health app name for Fitbit/Pixel Watch integration; preserve the distinction between that contributing application and the Health Connect service.

| ID | Brand/ecosystem | Target OS | Proposed route and official evidence | Required metrics exported | Implemented in Hydrion | Verified device/app | Level | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| O01 | Apple Watch | iOS | Apple Health to HealthKit; [Apple sources](https://support.apple.com/en-ie/108779) | Apple Health collects watch activity; exact four-metric/device route still untested | Generic HK adapter only | Simulator is not a physical watch | L0 OEM | `hub-dependent` |
| O02 | Pixel Watch / Fitbit | Android | Google Health/Fitbit to HC; [official data-direction table](https://support.google.com/googlehealth/answer/14506680?hl=en) | Writes steps, distance, exercise, total calories; active-calorie write is not established by that table | Generic HC only | No named device tested | L0 OEM | `hub-dependent` |
| O03 | Samsung Galaxy Watch | Android | Samsung Health to HC; [Samsung mapping](https://developer.samsung.com/health/blog/en/accessing-samsung-health-data-through-health-connect) | Steps, exercise, distance; exercise calories mapped to TOTAL, not Hydrion's ACTIVE-calorie type | Generic HC only | No Samsung device tested | L0 OEM | `hub-dependent` |
| O04 | Garmin | Android, iOS candidate | Garmin Connect to HC; [Garmin export](https://support.garmin.com/lv-LV/?faq=JToBEy0jfe6pIygark2Ui5); API optional | Active calories, steps, distance documented; session/type mapping needs proof. Official HC route requires Android 14+, unavailable on this Android 13 phone | Generic HC only; no Garmin adapter | None | L0 OEM | `hub-dependent` |
| O05 | Oura | Android | Oura to HC; [official export list](https://support.ouraring.com/hc/en-us/articles/10786105824531-Health-Connect-by-Android-Integration) | Exercise, active calories, steps, distance documented; membership/device constraints apply | Generic HC only | None | L0 OEM | `hub-dependent` |
| O06 | Polar | iOS; Android alternate research | Polar Flow to Apple Health; [Polar mapping](https://support.polar.com/en/support/connecting_polar_flow_with_apple_health) | Workout type/time/duration, active energy, steps; workout distance does not itself prove separate walking/running-distance quantities | Generic HK only | None | L0 OEM | `hub-dependent` |
| O07 | Withings | Android | Withings to HC; [official export setup](https://support.withings.com/hc/en-us/articles/27322856325905-Partner-Apps-Health-Connect-Exporting-Withings-data-into-Health-Connect) | Route exists; exact four-type export coverage is unverified from this setup document | Generic HC only | None | L0 OEM | `hub-dependent` |
| O08 | Huawei | Android/HarmonyOS; other platform API research | Huawei Health Kit, not Google's HC; [Huawei API](https://developer.huawei.com/consumer/en/hms/huaweihealth/) | Scope/partner/region/device approval determines accessible activity data | No Huawei adapter | None | L0 OEM | `vendor-adapter-required` |
| O09 | Xiaomi / Mi Fitness | iOS; Android route unverified | Mi Fitness to Apple Health; [Xiaomi setup](https://www.mi.com/uk/support/faq/details/KA-230360/) | Export categories selectable; precise four-metric mapping unverified | Generic HK only | None | L0 OEM | `hub-dependent` |
| O10 | Amazfit / Zepp | iOS; Android route requires verification | Zepp to Apple Health; [Amazfit support](https://support.amazfit.com/en/amazfit_gts_2_mini/docs/N6cUdJxDRo6rbfxiLs1cJDBrnRd) | Hub route documented; exact four-type coverage unknown; old Google Fit listing is not HC proof | Generic HK only | None | L0 OEM | `hub-dependent` |
| O11 | WHOOP | Android, iOS candidate | WHOOP to HC; [official direction list](https://support.whoop.com/s/article/Google-Health-Integration-For-Android) | Exports exercise, calories, steps; exact calorie subtype unverified; distance listed as import, not export | Generic HC only | None | L0 OEM | `hub-dependent` |
| O12 | FitPro generic watches | Android/iOS candidate | Companion app; [publisher listing](https://play.google.com/store/apps/details?id=cn.xiaofengkj.fitpro) | BLE companion existence does not establish HC/HK export; no verified metrics | No FitPro adapter | App installed on Infinix; no watch model/export proof | L0 OEM | `requires-verification` |
| O13 | Infinix HealthLife / My Health | Android | Companion app; [publisher listing](https://play.google.com/store/apps/details?id=com.transsion.healthlife&hl=en) | No official HC export/metric evidence established in this audit | No HealthLife adapter | App installed; no ingestion route tested | L0 OEM | `requires-verification` |
| O14 | Other generic companion watches | Depends on exact product | Identify exact model, publisher, protocol, and export route first | Unknown | No generic adapter | None | L0 OEM | `requires-verification` |
| R15 | Vendor export files | Android/iOS candidate | Explicit-consent export; Apple XML is one documented format | Schema-dependent, unimplemented | No importer | None | L0 | `file-import-candidate` |
| R16 | Documented standard BLE sensors | Android/iOS candidate | Bluetooth HRS for compatible sensors | Heart rate, which is outside current four-metric ingestion scope | No working BLE adapter | None | L0 route | `documented-BLE-candidate` |

Garmin Health API requires approval/evaluation; Polar AccessLink requires OAuth client and user consent. These are possible alternatives, not mandatory replacements for an available hub route, and no account was created. [Garmin API](https://developer.garmin.com/gc-developer-program/health-api/), [Polar AccessLink](https://www.polar.com/accesslink-api/?shellpolar-accesslink-api=).

Preserve provider ID, contributing app ID/name, optional device metadata, acquisition route, and source record identity. Manufacturer branding alone cannot establish provenance when optional metadata is missing.

## 13. Exact Completion Counts

Denominators are explicit sets, not a combined percentage. Provider set P = {Health Connect, HealthKit}. Candidate set C = {O01..O14, R15, R16}, 16 rows. OEM set O = {O01..O14}, 14 rows. A candidate's classification is not implemented support.

| Measure | Numerator/denominator | Entries included and meaning |
| --- | --- | --- |
| Provider foundations implemented | 2/2 P | HC and HK use the shared contract/model/storage/sync foundation; one shared contract, not two separate frameworks |
| Real provider adapters implemented | 2/2 P | HC Kotlin/Dart and HK Swift/Dart |
| Real provider adapters compiled | 2/2 P | Android and iOS CI on current main |
| Real provider ingestion simulator-verified | 1/2 P | HK historical synthetic fixture; no HC emulator ingestion evidence |
| Real provider ingestion physical-device-verified | 1/2 P | HC on Infinix X6835B, synthetic and narrowly scoped; not full failure certification |
| Real provider adapters release-ready | 0/2 P | Neither has all L6 gates |
| Direct OEM health integrations implemented | 0/14 O | None; Apple HK is a hub API, not a direct watch health adapter |
| Hub-dependent OEM candidates | 10/16 C | O01, O02, O03, O04, O05, O06, O07, O09, O10, O11 |
| Selected route requiring vendor API/SDK adapter | 1/16 C | O08 Huawei; optional APIs for hub candidates are not counted twice |
| Selected route requiring file importer | 1/16 C | R15 |
| Selected route requiring documented BLE adapter | 1/16 C | R16 |
| Unresolved companion routes | 3/16 C | O12 FitPro, O13 HealthLife, O14 generic |
| Named OEM end-to-end supported-and-verified | 0/14 O | None |
| OEM routes still unverified end-to-end | 14/14 O | O01..O14, including all hub candidates |
| All candidate routes unverified end-to-end | 16/16 C | No candidate route is certified by generic hub tests |
| iOS health integrations completed at L6 | 0/1 | HK: implemented/build/simulator gates only |
| Android health integrations completed at L6 | 0/1 | HC: implementation/build/scoped physical gates only |
| watchOS integrations completed at L6 | 0/1 | Snapshot companion built and simulator-launched only |
| Wear OS integrations completed at L6 | 0/1 | Proposed watch app absent |
| watchOS companion targets built / simulator smoke-tested | 1/1 / 1/1 | HydrionWatch; separate from provider denominator |
| Physical Apple companion verification | 0/1 | No physical Apple Watch tested |

Candidate classifications sum to 10 + 1 + 1 + 1 + 3 = 16. No smart bottle, simulator, synthetic source application, or stub is counted as a supported wearable brand.

## 14. Metric-Support Matrix

Read support below means actual adapter mapping, not mere enum presence. Runtime proof remains qualified by provider/environment; it is not all-OEM proof.

| Metric | HC adapter | HK adapter | Persistence/display/context | Production hydration target |
| --- | --- | --- | --- | --- |
| Workout type | Exercise type mapped to category | HK activity type mapped to category | Canonical category stored; dashboard primarily shows duration, not a rich translated type taxonomy | Not consumed |
| Workout start/end/duration | Record interval and minutes | Sample interval and HK workout duration | Stored; timeline; extractor merges intervals in tests | Not consumed |
| Active energy | `ActiveCaloriesBurnedRecord`, kcal | `.activeEnergyBurned`, kcal | Stored, charted; tested extractor retains energy, does not convert calories to water | Not consumed |
| Steps | `StepsRecord` | `.stepCount` | Stored/charted; tested fallback | Not consumed |
| Distance | `DistanceRecord`, meters | `.distanceWalkingRunning` only | Stored/charted; tested fallback; HK is not all sports distance | Not consumed |
| Heart rate | No | No | Enum only | No |
| HRV | No | No | SDNN/RMSSD enums only | No |
| Sleep | No | No | Enum only | No |
| SpO2 | No | No | Enum only | No |
| Temperature | No | No | Skin/body enums only; weather context is a different feature | No wearable input |
| Stress/recovery/readiness | No | No | Enums only | No |
| Body composition | No | No | Enum only; manually entered body metrics are separate | No wearable input |
| Hydration events | No health-hub water ingestion/write | No dietary-water ingestion/write | Manual Hydrion repository works; widgets/watch consume local snapshot | Manual hydration tracking, not wearable ingestion |

Four of four selected metric families are implemented in each adapter. That is not four of all possible health metrics. Imported records are used for visible history; computed wearable activity context is L2 and disconnected from the production target engine.

## 15. Edge-Case Ledger

`A` means automated coverage; `P` means physical evidence. A historical phone result is labeled `historical`. Absence of P is not a test pass. Evidence IDs resolve in section 20.

| ID / Edge case | Current handling and evidence | User-visible result | Security/privacy impact | A / P evidence | Remaining remediation |
| --- | --- | --- | --- | --- | --- |
| E01 Provider absent/unavailable | Discovery and provider capabilities return unavailable/unsupported (DISC, HC, HK) | Install/unavailable/unsupported state | No fake records | A yes; P installed case only | Physical absence/unsupported device matrix |
| E02 HC install/update required | SDK status mapped distinctly (DISC) | Installation/update prompt | No bypass of service prerequisites | A yes; P not forced | Exercise outdated/missing provider safely |
| E03 Permission not requested/denied/revoked | Explicit connect; granular grants and refresh; missing grants block reads (CTRL, SYNC) | Consent/denied/revoked/missing categories | No implicit health permission request | A yes; P current state below, revoke not forced | Physical revoke/restore lifecycle |
| E04 Authorization succeeds but reads opaque | HK uses requestCompleted/queryable, not proven read grants (HK) | Empty data may also mean denied access | Avoids inferring sensitive permission choice | A yes; simulator historical; P no | Physical iPhone denied/partial/restore |
| E05 Connected with no records | Successful empty sync is stored separately from failure (CTRL, UI) | Qualified no-data message, retry | No invented health values | A yes; P current session below | Repeat with isolated empty provider store, without deleting user's data |
| E06 Companion has non-exported records | Installed app is discovery only (DISC) | No readable records; does not establish companion compatibility | Never scrape private companion storage | A discovery distinction; P app presence only | Verify official app export types per model |
| E07 Unsupported/missing metric | Capabilities restricted to four types; missing grants separated (HC, HK, SYNC) | Categories/partial or unsupported state | Data minimization | A yes; P full metric matrix open | Show export-gap guidance without implying permission failure |
| E08 Partial synchronization | Independent per-metric outcome/checkpoint; scoped failed-metric retry (SYNC, CTRL) | Partial state lists successful/failed categories | Successful data not discarded | A yes; P not injected | Physical mixed success/failure |
| E09 Provider service unavailable | One HC fresh-client retry for remote failure; safe typed error (HC) | Failure rather than false success | No unbounded retry or credential logging | A mapped errors; P historical XOS failure | Reliable device-specific cold service acceptance |
| E10 OEM background/autostart restriction | Foreground sync, truthful failure; app cannot override XOS policy (DEVICE) | Error/open-provider guidance | No hidden autostart/security bypass | P historical; A error handling | Explain supported recovery and measure recurrence |
| E11 Background/kill/restart during sync | Per-metric DB transaction/checkpoint; resume refresh; native HC scope disposal (SYNC, STORE) | Previous durable state remains; retry | No partial DB/checkpoint commit | A rollback/cancel; P idle restart historical | Kill during actual query/commit; UI-metadata commit is separate from DB transaction |
| E12 Expired/malformed/legacy checkpoint | Bounded expiry recovery; legacy HC token migration; invalid schemas fail (HC, HK, SYNC) | Failed metric/retry if invalid | Bounded tokens/anchors, no silent arbitrary schema acceptance | A yes; P no expiry forced | Verify late/deleted records outside recovery window |
| E13 Duplicate records | Stable provider upsert and exact fingerprint classification (SYNC) | Repeat sync should not increase imported total | Retains provenance | A yes; P historical duplicate workout | Distinct legitimate events with missing device metadata can collide; cross-provider existing sets are separate |
| E14 Corrections/deletions | Stable identity updates and typed tombstones; HK anchors/HC changes (SYNC, HK) | Updated/deleted imported copy | Source record not edited by Hydrion | A yes; simulator HK historical; P no | Physical correction/deletion and duplicate-owner promotion after deletion |
| E15 Late/out-of-order records | Incremental reads/upserts; initial/recovery window is 30 days (SYNC) | New imported records when provider returns them | No exhaustive historical guarantee | A correction cases; P no | Late records outside window, out-of-order correction versions |
| E16 Multiple contributing apps | Provenance stored; source counts shown; exact duplicate comparison (MODEL, CTRL) | Source-labeled counts | Optional device identity not invented | A yes; P synthetic Toolbox only | Test real multi-app overlap and route identity |
| E17 Double-count activity | Extractor merges workout intervals and chooses one aggregate source; fallback steps/distance (FEATURE) | Imported dashboard still charts raw imported aggregates | Target unaffected because extractor not wired | A extractor; P no mixed sources | Partial-overlap aggregates and source priority UX before target integration |
| E18 Missing manufacturer/model | Native mapping allows absent optional metadata (HC, HK) | Source app retained; device may be unknown | No guessed brand/device | A yes; P historical missing workout metadata | Verify each vendor provenance path |
| E19 Timezone/DST/clock skew | Canonical timestamps/offsets preserved; invalid ranges rejected (MODEL). FEATURE day end uses start + 24 hours | Timeline/day buckets may misclassify at DST | Correctness risk, no current target effect | A normal midnight only; P no DST | Use explicit calendar-day boundaries and test DST/clock skew in future implementation task |
| E20 Extremely large history | Provider pages bounded, 100-page sync cap; existing-record and summary scans accumulate all records (SYNC, CTRL) | Long sync or failure; possible memory pressure | Paging alone is not bounded total memory | A repository paging; P no representative scale | SQL aggregation/streaming, retention schedule, 10k+ memory/time/battery gates |
| E21 Corrupt encrypted DB | Open fails closed, no replacement (STORE, KEY) | Health connection blocked; dashboard error branch gap | Existing bytes preserved | A corruption; P no corruption injected | Add actionable repair/export policy without destructive reset |
| E22 Missing/invalid key | Missing key for existing DB never silently regenerated; inaccessible status (KEY) | Protected-storage failure | Prevents destructive re-key/data loss | A yes; simulator storage historical; P no key tampering | Physical lock/unlock/restore/Keystore invalidation |
| E23 Low device storage | DB write exceptions mapped to failure; install needs free space | Sync/install failure | No cleanup/data deletion bypass | A injected transaction failure; P phone 98% full, not intentionally exhausted | Dedicated ENOSPC test and clear storage-specific UI |
| E24 Interrupted atomic write | Records/checkpoint in one transaction (STORE) | Prior committed state remains | Avoids record/checkpoint divergence | A rollback; P no power/kill injection | Physical interrupted-write and separate UI metadata reconciliation |
| E25 Disconnect | Local connection flag cleared (CTRL); no manual-history deletion | Disconnected; existing imported data remains | Does not revoke OS grant automatically | A yes; P not changed in audit | Clarify disconnect versus system revoke; real-device lifecycle |
| E26 Delete imported copy | Deletes imported rows/checkpoints for provider only (STORE, CTRL); derived rows explicitly retained | Imported summary resets | Does not delete provider/manual history; derived-data privacy gap if populated | A test intentionally retains derived rows; P deletion not performed | Cascade/invalidate dependent context before claiming complete deletion |
| E27 No wearable | Manual repository independent of health providers | Manual hydration remains available | No account or wearable required | A application tests; P historical and current below | Ongoing platform/accessibility regression |
| E28 watchOS disconnected | Best-effort latest context, reachability/empty/error state (WATCH) | Cached or waiting/disconnected display | No sensor read, no cloud transport added | A native validation historically; L4 launch; P no | Actual delivery, out-of-order, reconnect, latest-write concurrency, physical pair |
| E29 Wear OS absent | No module or adapter | No working Hydrion Wear OS experience | Do not advertise watch support via HC alone | A/P none for absent feature | Separate implementation sprint |
| E30 BLE interruption/reconnect/malformed payload | BLE stub returns unavailable/empty/null (BLE) | No working BLE connection | No undocumented pairing or private protocol access | A/P no real BLE | Protocol-specific parser, permission, disconnect and fuzz tests |
| E31 File duplicate/tamper/schema/oversized archive | No health-file importer | No import workflow | No attack surface from nonexistent importer | A/P none | Size/expansion caps, traversal defense, versioned schema, authenticity/provenance, idempotency before shipping |
| E32 Sensitive logs/diagnostics/analytics | HC logs metric category/count/error class, not values/tokens; HK returns safe categories; WATCH generic errors | Generic failure text | Category/count/timing still reveal health-usage metadata; release logging review needed | A key/error mapping and secret scan; P scoped logs below | Production redaction/telemetry audit; do not equate secret scan with health privacy certification |
| E33 Medical claims | Consent/dashboard use wellness disclaimer (UI) | Non-medical positioning | No diagnostic inference authorized | A UI tests; P controls below | Review all locales/marketing against actual functionality |
| E34 Unexplained target changes | No production extractor consumer; feature flag false (FEATURE, composition) | Imported history, not wearable-adjusted recommendation | Avoids unvalidated physiological adjustment | A extractor; source search; P target effect not claimed | Explainable engine integration and safety validation before activation |
| E35 Imported-dashboard read fails | FutureBuilder checks hasData but not hasError (DASH) | Indefinite spinner on repository error | Conceals storage failure; no data corruption proved | A only success-path dashboard test; P not fault-injected | Explicit error/retry UI and test |
| E36 Whole-profile reset | Existing reset service omits wearable repository/controller (RESET) | Broader reset may leave wearable state | Potential retention mismatch; separate imported-delete control exists | Source inspection; P reset prohibited | Align deletion disclosure/scope and test without touching user data |
| E37 Initial provider refresh fails before summary load | Authorization fails before `_refreshRecordSummary`; summary remains default zero (CTRL) | Zero imported records/no sources despite existing database; three records reappear after HC recovery | Misleading loss impression, not demonstrated data deletion | P reproduced this audit; A no preservation-on-initial-failure test identified | Load durable local summary independently of provider availability; distinguish unknown grants from denied |

## 16. Security and Privacy Findings

Positive controls: read-only four-type native access, contextual consent, SQLCipher encrypted wearable records, a platform-protected 256-bit key, missing-key fail-closed behavior, atomic record/checkpoint transactions, Android backup disabled, typed errors, and optional provenance rather than guessed devices. These controls are implemented and tested to the levels stated, not universally certified.

Original audit findings included retained derived records and omitted wearable profile cleanup; section 21 documents those repairs. Remaining concerns: connection metadata (counts/timestamps/outcomes) remains in the existing local settings store; native logs include category/count metadata; large-history reads are not globally memory-bounded. No finding authorizes exporting user databases or personal health values.

The report intentionally excludes raw health samples, provider record IDs, anchor/change tokens, encryption keys, phone serial, and account/profile identifiers. Public APK hashes and signing-certificate fingerprints are not secret keys.

QA uses Android Debug signing, separate from expected production certificate `0e72fea179b2631e7b8379dac1b4fa9f6e75c8e82052aef582bad6cee2a03fea`. No production credentials are changed or used for the QA artifact.

## 17. Testing and Platform-Parity Gaps

Current automated and device results are listed in section 20 and the final runtime table. Fake-provider tests validate mapping/state/transactions, not OS permission sheets or vendor exports. Hosted smoke launches validate installation and startup, not all UI, data transport, widgets at runtime, or physiological correctness.

Open gates include physical iPhone/Apple Watch, Wear OS implementation, named OEM four-metric route certification, Android revoke/restore and cold provider behavior, large-history resource/battery tests, low-storage failure injection, timezone/DST tests, malformed-import fuzzing if an importer is added, watch latest-context delivery, and all-locale accessibility.

The Windows tree has pre-existing edits not covered by pristine-main hosted CI. Local tests/build are reported separately. The original audit left `HWI_progress.md` untouched; section 21 records the one subsequent checkbox change.

## 18. Prioritized Remaining Work

### P0: Security and Correctness

- Reconcile imported/derived/profile-deletion semantics and disclosures before release; preserve manual history.
- Add explicit database-error/retry handling to the imported-data dashboard.
- Preserve/display local imported-summary evidence even when initial provider authorization lookup fails; do not present unknown access as proven denial.
- Bound whole-history memory use and test low storage, interrupted persistence, corruption and lost keys on dedicated synthetic installations.
- Fix/test calendar-day boundaries under DST before enabling activity-context recommendations; test duplicate correction/deletion ownership.
- Review release log metadata and physical protected-storage behavior without exporting health records.

### P1: Provider Completion

- Complete HC physical grant/deny/revoke/restore, all four metrics, provider cold start, partial-failure/retry and lifecycle gates on named Android devices.
- Complete isolated physical-iPhone HealthKit and physical-Apple-Watch acceptance. Prove actual snapshot receipt, not only app launch.
- Add resource/battery measurements and explainable, independently validated context integration only under a new implementation authorization.

### P2: OEM Expansion

- Certify Apple Watch, Pixel/Fitbit and Samsung first, per OS/app/model/metric. Verify active versus total calorie direction explicitly.
- Validate Garmin Android 14+ constraint, Oura, Polar, Withings, Xiaomi, Zepp and WHOOP export coverage; do not extrapolate from one successful metric.
- Verify FitPro/HealthLife official export routes before promising compatibility. Record exact device model and firmware.

### P3: Experimental Routes

- Evaluate Huawei/vendor APIs with approval and privacy scope; do not create accounts or backend uploads implicitly.
- Consider bounded, consented export-file ingestion and documented BLE sensor protocols as separate integrations.
- Treat Wear OS and smart bottles as separate feature work, not completed by HC or watchOS.

## 19. Release-Readiness Verdict

**Not release-certified for broad wearable integration.** Two real hub adapters exist; scoped physical Android and simulator Apple evidence is meaningful but incomplete. Zero named OEM wearable routes and zero provider adapters meet the full L6 gate. Missing integrations remain absent rather than simulated as working.

The safe QA artifact and synthetic device session are validation tools, not a production release. Existing physical-device acceptance criteria remain unchanged.

## 20. Evidence Appendix

### Source and Test Index

| ID | Source evidence | Representative existing test evidence |
| --- | --- | --- |
| MODEL | `lib/domain/health_data.dart:1` | `test/health_data_domain_test.dart`: provenance, invalid ranges/non-finite values, versioned extensions |
| HC | `lib/services/health_connect_provider.dart:42`; `android/app/src/main/kotlin/com/the1807/hydrion/AndroidHealthConnectHost.kt:126` | `test/health_connect_provider_test.dart`: bounded import, normalization, checkpoints, tombstones, optional metadata, safe errors |
| HK | `lib/services/health_kit_provider.dart:40`; `ios/Runner/HealthKitHost.swift:6` | `test/health_kit_provider_test.dart`: opaque authorization, native mapping, saved anchors, deletes, partial retry |
| DISC | `lib/services/android_health_provider_discovery.dart`; `android/app/src/main/kotlin/com/the1807/hydrion/AndroidHealthProviderDiscovery.kt` | `test/android_health_provider_discovery_test.dart`: manufacturer/service/companion distinction, work profile, malformed status |
| SYNC | `lib/services/health_data_sync_coordinator.dart:32`, `:145`, `:262`, `:338` | `test/health_data_sync_coordinator_test.dart`: permissions, expiry, duplicate, cancellation, correction/tombstone, rollback/retry, per-metric isolation |
| STORE | `lib/repositories/encrypted_health_data_repository.dart:262`, `:303`; `lib/services/health_data_persistence_io.dart:11` | `test/encrypted_health_data_repository_test.dart`: encrypted reopen, wrong key, atomic rollback, paging, concurrent commits, corruption, derived-record retention |
| KEY | `lib/services/health_database_key_store.dart:37` | `test/health_database_key_store_test.dart`: key reuse, missing existing key, inaccessible storage |
| CTRL | `lib/services/health_connection_controller.dart:213`, `:286`, `:293`, `:348` | `test/health_connection_controller_test.dart`: durable state/counts, failure preserving prior success, scoped retry, disconnect/delete separation |
| UI | `lib/ui/screens/health_data_connection_screen.dart:19`; `lib/ui/screens/settings_screen.dart:609` | `test/health_data_connection_screen_test.dart`; `test/health_kit_connection_screen_test.dart` |
| DASH | `lib/ui/screens/wearable_data_dashboard_screen.dart:43` | `test/wearable_data_dashboard_screen_test.dart`: successful imported timeline/trend only |
| FEATURE | `lib/services/hydration_feature_extractor.dart:23`; `lib/main.dart:1025` | `test/hydration_feature_extractor_test.dart`: interval overlap, fallback, source priority, excluded sensitive metrics, normal day clipping |
| WATCH | `lib/services/watch_connectivity_service.dart:17`; `ios/Runner/WatchConnectivityHost.swift`; `ios/HydrionWatch/HydrationSnapshot.swift`; `ios/HydrionWatch/HydrationConnectivityReceiver.swift` | `integration_test/watch_companion_simulator_test.dart` exists; presence is not a run claim; hosted helper runs are CI smoke evidence |
| BLE | `lib/services/ble_service.dart:11`; `lib/services/wearable_service.dart:12` | No real BLE device/parser evidence |
| RESET | `lib/services/local_profile_reset_service.dart:100` | No wearable-storage deletion dependency in this service |
| MANUAL | `lib/repositories/hydration_repository.dart` | Ordinary hydration/Pomodoro suite and historical DEVICE result |
| MAC | [HealthKit simulator report](docs/validation/healthkit-macos-simulator-2026-09-17.md) | Historical six native and two Flutter simulator tests; real synthetic fixture |
| DEVICE | `HWI_progress.md:366` and this report section 5 | Historical Infinix synthetic import and current authorized QA session, kept distinct |
| CI | [Current main run 35636814230](https://github.com/The-1807/hydrion/actions/runs/35636814230) | All five jobs successful; read-only verification on audit date |

### Commands and Validation Results

Repository checks: `git status --short` (with a command-local safe-directory override where needed), branch/HEAD/remotes inspection, source/test searches, and SHA-256 fingerprints of preserved files. Unscoped sandbox Git initially rejected ownership; the command-local safe-directory setting avoids changing global Git configuration.

Device checks: `adb devices -l` with serial redacted, selected `getprop` values, `pm list packages` filtered to relevant packages, `dumpsys package` filtered to public package/permission metadata, `pm path`, `df -k /data`, and pulling only the installed executable APK for `apksigner verify --print-certs`. No `run-as`, app-private file extraction, uninstall, data clear, or downgrade is used.

Build command: `ORG_GRADLE_PROJECT_hydrionWearableCertification=true` in the build process environment, then `flutter build apk --debug --target-platform android-arm64 --build-number 2006 --no-pub`. No dependency upgrade. Existing Gradle 8.12 / AGP 8.9.1 / Kotlin 2.1.0 deprecation notices are warnings to plan separately, not authorization to upgrade them.

That first command took 380.2 seconds but did not produce the requested package/ABI combination; identity verification rejected it. Corrected command from `android/` used the existing Android Studio JBR and `gradlew.bat --console=plain -PhydrionWearableCertification=true -Psplit-per-abi=true -Ptarget-platform=android-arm64 -Ptarget=../lib/main.dart assembleDebug`. It passed in 1m06s, 390 actionable tasks (26 executed, 364 up-to-date). The actual code 4006 is recorded above rather than assuming the unsplit base build number.

Hosted verification: `gh run view 35636814230 --json headSha,status,conclusion,url,jobs`, plus filtered iOS job logs. HEAD matches this report. Quality, Android debug, CI-ephemeral signed Android release, Web, and iOS jobs all actually ran and succeeded. Android release CI used ephemeral signing, not proof of a production-signed release. Apple helper tests: 28 passed. The initial plain `gh` lookup failed because it was not on PATH; the installed GitHub CLI executable was used successfully.

The first focused Flutter command passed 110 tests but also named nonexistent `test/ios_native_configuration_test.dart`, causing a load failure. This was an audit command error, not an application assertion failure. The corrected command uses `test/ios_release_configuration_test.dart`; its final result is recorded below. SQLCipher HMAC diagnostics during deliberate wrong-key/corruption tests are expected negative-test output, not spontaneous app database corruption.

### Audit-Date Local Validation (2026-09-21)

- Corrected focused Flutter suite: **120 passed**, exit 0, approximately 39 seconds. Selected files: domain, memory/encrypted repository, key store, sync coordinator, HC/HK adapters, connection controller, HC/HK connection screens, feature extractor, Android discovery, wearable dashboard, iOS release configuration, and Android widget service.
- `flutter analyze --no-pub`: **no issues**, 97.7 seconds.
- `dart format --output=none --set-exit-if-changed .`: **243 files, zero changes**, exit 0.
- `dart run tool/secret_scan.dart`: **passed**, no committed API keys/credentials/private-key blocks detected. This is not a health-data leak certification.
- `dart run tool/validate_ci_workflows.dart`: **passed**, two workflows validated; no workflow dispatched or modified.
- Full local Flutter suite was not rerun for this report-only audit. Current pristine-main full-suite CI passed; that does not certify the five existing local modifications.

### Preservation and Audit Boundaries

All five initial file hashes in section 1 matched after building, installation, testing, and report creation. No tracked source, dependency lock, platform configuration, signing configuration, or acceptance checkbox was changed by this audit. The only authored repository file is `edge_case.md`.

Generated artifacts remain under ignored `build/` and existing build/cache locations. They include the inspected installed QA executable, the rejected ordinary-debug artifact (never installed), and the verified isolated ARM64 QA artifact. A temporary `android/.kotlin/sessions/*.salive` compiler marker appeared during the build and was gone afterward; no source-cleanup command was used.

Final expected working tree (nothing staged):

```text
 M HWI_progress.md
 M lib/ui/screens/startup_screen.dart
 M test/startup_buffer_test.dart
 M tool/mixed_language_audit.dart
?? edge_case.md
?? integration_test/wearable_storage_device_test.dart
```

No Markdown formatter configuration was found at the repository root. Report validation checks section numbering, consistent table column counts, local Markdown link targets, referenced source/test paths, candidate IDs/counts, evidence levels, and trailing whitespace. External route citations are official pages retrieved during this audit; undocumented metric exports remain explicitly unknown. The report hash is supplied separately in the final response to avoid a self-referential hash.

`git diff --check` passed after the audit. An explicit untracked-file whitespace/structure check covers this new report because ordinary Git diff does not include an untracked file.

Unperformed physical operations: empty-provider-store setup, health permission revocation/restoration, source-record correction/deletion, provider process kill, low-storage exhaustion, database corruption/key tampering, personal companion-app inspection, and physical Apple/Wear OS testing. These remain gaps, not passes. No commit/push/merge/branch change, account creation, cloud health upload, uninstall, downgrade, or app-data clear occurred.

## 21. Correctness Sprint (2026-09-22)

### Scope and provenance

This section supersedes the original audit's unresolved E26/E35/E36/E37 source
findings, not its historical observations. Branch:
`fix/wearable-state-and-deletion-correctness`, base/HEAD
`de06688f010a533e41f9e258b274d1329587ec8b`. Main was not modified; no remote
operation, staging or commit occurred. The user authorized synthetic-only QA
testing, including local wearable deletion and permission revocation/restoration.

The original four unrelated files remain byte-for-byte unchanged: startup
screen, its buffer test, mixed-language audit and untracked storage device test.
Their hashes are in section 1 and were rechecked. Existing HWI edits were
preserved; only line 94 was checked and this sprint evidence appended. The QA APK
includes the pre-existing startup-screen change and this uncommitted sprint;
it is explicitly **not pristine main**. Signing and dependencies were unchanged.

### Root causes and repairs

| Finding | Root cause | Current repair | Verification boundary |
| --- | --- | --- | --- |
| E37 misleading empty state | Authorization ran before local summary loading; exceptions left default zeros | Load durable summaries independently; separate provider/permission state, last attempt/success and current outcome; unknown storage is not empty | Controller tests plus physical binding failure with 3 retained records |
| Ambiguous zero-change success | One success label covered both existing data and empty history | Separate no-new-data, no-records and new-data states; explicit retry state | Every state label tested; no-new-data physically observed |
| E26 incomplete deletion | Provider delete intentionally excluded derived rows | Recursive dependent-row deletion plus provider checkpoints in one SQLCipher transaction | Injected rollback/reopen/idempotency tests; physical imported-only deletion |
| E36 profile retention mismatch | Reset service had no wearable cleanup dependency | Clear all wearable rows/checkpoints first; fail closed before remaining reset; clear connection metadata; disclose full-profile scope | Automated reset success/failure; full-profile reset not executed on phone |
| E35 indefinite dashboard spinner | FutureBuilder handled data/waiting but not errors | Localized error plus retry | Widget failure/recovery test |
| Unbounded Android bridge wait | Dart bridge had no deadline for unanswered calls | 10 s discovery and 15 s non-permission-sheet deadlines; debug phase timings | Fake-clock deadline tests and measured physical calls; no OEM-security bypass |

Wearable-only deletion/disconnect never clear manual hydration or external
provider records. Full-profile reset intentionally includes manual history and
is a separate operation. SQL deletion is atomic; settings metadata is a separate
write and can fail after deletion, which is surfaced as incomplete cleanup with
retry. This does not claim a cross-store atomic transaction. Production derived
hydration-target consumption remains disabled; no algorithm was added.

### Automated and build results

| Check | Result |
| --- | --- |
| Final focused controller/repository/UI/reset/deadline/dashboard tests | 82 passed, 12 s |
| Full Flutter suite | 782 passed, 4m46s; includes existing HealthKit/widget/configuration tests |
| Analyzer | No issues, 7.2 s after test-only lint correction |
| Non-writing Dart format verification | 244 files, 0 changes |
| Localization audit | EN/FR/ES 962/962; Android 24/24 each |
| Mixed-language/placeholder audit | FR/ES identical=0, placeholderDrift=0 |
| Secret scan | Passed; not a health-data privacy certification |
| Workflow validation | Two workflows passed locally; no hosted workflow dispatched |
| Git diff whitespace | Passed |
| ARM64 isolated QA debug build | Passed in 3m56s; 390 tasks, 19 executed, 371 up-to-date |

Initial focused runs exposed two presentation/test sequencing issues and an
incorrect expected synthetic source label; those were corrected and rerun.
SQLCipher errors during intentional wrong-key/corruption tests are expected.
Existing Gradle/AGP/Kotlin deprecation warnings remain; no dependency upgrades.
The full suite ran before final test-only braces/formatting and documentation;
the final focused suite reran the changed tests afterward.

Build command from `android/`:
`gradlew.bat --console=plain -PhydrionWearableCertification=true -Psplit-per-abi=true -Ptarget-platform=android-arm64 -Ptarget=../lib/main.dart assembleDebug`.
The working invocation resolved the target to its absolute local path; this
portable equivalent intentionally omits machine-specific paths. Prebuild host
free space: 29,486,055,424 bytes; estimated temporary use: 3-8 GiB.

### Artifact and installation

| Property | Verified value |
| --- | --- |
| Artifact | `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` |
| Package | `com.the1807.hydrion.hwi_test` |
| Version | `1.2.0-hwi-test`, code 4006, same-code data-preserving QA update |
| ABI / mode | arm64-v8a only / debuggable |
| Exact size | 159,260,396 bytes |
| SHA-256 | `C3731B2D4EA4B704A6DA0AA96E82704E1B13CCF371D44886CDA735F3396D53BA` |
| Certificate SHA-256 | `56fe5c7ae21cd1752bbd3e8e9a46f19f0e3ad8a38b43ceef9dd3578c5f6cd730` |

Manifest and certificate were checked before installation; the QA signer matches
the existing installation, not production. Exact installer output:

```text
adb -d install -r build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk
Performing Streamed Install
Success
```

No uninstall, app-data clear, downgrade, production-package mutation, credentials
change, provider-record deletion or private-file extraction occurred. Artifact
size is measured, not a size-optimization claim; its increase was not attributed
to source changes without an APK composition comparison.

### Physical Infinix results

Device: Infinix X6835B, Android 13, ARM64. Health Connect version
`2026.08.06.00.release`, code 274060. Only confirmed synthetic records were used.

| Scenario | Observed result | Evidence limit |
| --- | --- | --- |
| Initial restart and binding failure | Provider unavailable/unknown access; 3 imported Toolbox records and source retained | Existing records, not a new live wearable import |
| Failed explicit retry | Latest attempt Sep 22 08:23; last success Sep 21 15:46; 3 retained records | One deliberate retry; RemoteException/binding died |
| Open provider and retry | All 4 read grants restored in status; no-new-data success at 08:24; still 3 records | Foreground recovery, not permanent OEM repair |
| Revoke QA access | Distinct missing-access warning, 3 records retained | Official UI; optional provider-data deletion checkbox verified false |
| Manual logging with access revoked | One 150 ml synthetic log added successfully | Provider-independent hydration path |
| Restore access | Same 4 read-only grants restored | No new permission categories |
| Local wearable deletion | 3 records to 0; source summary and synchronization history cleared | No derived rows were populated physically |
| Repeated deletion | Remained zero with no error | Idempotency exercised |
| Disconnect and force-stop | Both manual entries remained: today's 150 ml and yesterday's 150 ml | No full-profile reset |
| Post-restart wearable state | Consent/disconnected controls, 0 records, no sources, no prior sync timestamps; provider again unavailable | Empty local copy verified independently of binding failure |

The actual XOS background failure remains: native authorization logged
`Binding to service failed`, `Binding died`, one fresh-client rebind, then
`RemoteException`. Opening Health Connect restored access. It became unavailable
again after backgrounding. This run does not establish the exact XOS setting
responsible. Historical AutoStart Limit evidence is in section 5; no bypass or
system-policy change was attempted. The repair makes this failure bounded and
truthful rather than making Health Connect universally available.

### Controlled startup and storage observations

| Phase | First updated launch | Second force-stop launch |
| --- | --- | --- |
| Android activity launch | Status timeout, WaitTime 10,268 ms | COLD, TotalTime 9,803 ms, WaitTime 9,837 ms |
| Dart main timestamp (device local time) | 08:20:38.597 | 08:33:06.491 |
| First Flutter frame | 08:20:43.437 (4.840 s after Dart main) | 08:33:10.397 (3.906 s after Dart main) |
| Encrypted store initialization | 2,842 ms, ready | 2,982 ms, ready |
| Startup warmup complete | 08:20:47.466 | 08:33:14.693 |
| Startup-to-Home route handoff | 08:20:47.875 | 08:33:15.098 |
| Skipped-frame batches | 251, 518, 51 | 169, 293, 48 |

Home was verified usable by UI inspection and manual logging. Route handoff is
a proxy, not an instrumented time-to-first-interactive-frame measurement.
Android launch time is not startup-screen completion; the second immediate UI
capture still showed the startup screen. Native process creation time was not
separately instrumented. Provider discovery measured 9-27 ms in the sampled
failure sequence; authorization/binding failures measured 1,049-1,192 ms with
the existing native retry. HC is not required to enter Home.

Pretest `/data`: 3,476,468 KiB free, 97% used; 869,117 free inodes, 94% inode use.
After tests: 3,443,936 KiB free, 97% used; 860,984 free inodes, 94% inode use.
These are filesystem measurements, not isolated app data/cache size. Debug mode,
limited free storage and frame skipping are confounders; no single-cause startup
claim or performance acceptance is made. Bounded QA PID logs were inspected,
without exporting raw health values, keys, tokens or device serials.

### Platform gates, checklist and remaining work

| Area | Evidence level | Still unproven |
| --- | --- | --- |
| Health Connect | L5 scoped historical synthetic ingestion plus today's recovery/control checks | New live wearable import, broad OEM behavior, release certification |
| HealthKit | L4 historical simulator | Physical iPhone and current native runtime regression |
| watchOS | L4 install/launch only | Sensor ingestion and physical Watch behavior |
| Wear OS | L0 | Entire integration |
| Direct BLE | Stub/inactive | Working transport |
| Named OEM routes | 0/14 verified | Exact source/model/metric end-to-end routes |
| Release-certified providers | 0/2 | Full L6 gates |
| Wearable hydration-target consumption | Disabled/not implemented | New independently approved algorithm work |

HWI criteria remain 61: **47/14 to 48/13 checked/unchecked**. Only checkbox
line 94 changed, supported by encrypted cascade/rollback/reopen tests and scoped
Android local-delete evidence. Broad Android, physical Apple, OEM, storage/battery
and recommendation criteria remain unchecked. No acceptance text was rewritten.

Remaining physical-only gaps include first-time denial, partial provider failure,
empty source history, injected disk/key corruption, populated derived context,
full-profile reset and exact first-interactive timing. Automated coverage does
not replace those gates. Large-history memory, DST, release metadata logging and
OEM service stability remain separate work. No Apple machine was used.

### Exact working-tree classification

Sprint source: health repositories, controller, Android bridge/discovery,
profile reset/composition/timing, health controls/dashboard, three ARBs and their
four generated localization Dart files. Sprint tests: encrypted repository,
controller, connection UI, persistence/reset, dashboard and new bridge deadlines.
Sprint docs: this report, HWI progress, tester bible, supported devices, ADR and
threat model. Unrelated preserved work: startup screen, startup buffer test,
mixed-language audit and untracked storage device test. Ignored generated output:
APK/build/compiler caches; none staged. Full status follows.

```text
 M HWI_progress.md
 M docs/architecture/ADR-0004-encrypted-wearable-health-storage.md
 M docs/architecture/WEARABLE_HEALTH_THREAT_MODEL.md
 M lib/l10n/app_en.arb
 M lib/l10n/app_es.arb
 M lib/l10n/app_fr.arb
 M lib/l10n/app_localizations.dart
 M lib/l10n/app_localizations_en.dart
 M lib/l10n/app_localizations_es.dart
 M lib/l10n/app_localizations_fr.dart
 M lib/main.dart
 M lib/repositories/encrypted_health_data_repository.dart
 M lib/repositories/health_data_repository.dart
 M lib/services/android_health_provider_discovery.dart
 M lib/services/health_connect_provider.dart
 M lib/services/health_connection_controller.dart
 M lib/services/local_profile_reset_service.dart
 M lib/ui/screens/health_data_connection_screen.dart
 M lib/ui/screens/startup_screen.dart
 M lib/ui/screens/wearable_data_dashboard_screen.dart
 M test/encrypted_health_data_repository_test.dart
 M test/health_connection_controller_test.dart
 M test/health_data_connection_screen_test.dart
 M test/persistence_test.dart
 M test/startup_buffer_test.dart
 M test/wearable_data_dashboard_screen_test.dart
 M tester_bible.md
 M tool/mixed_language_audit.dart
 M wearable_support_devices.md
?? edge_case.md
?? integration_test/wearable_storage_device_test.dart
?? test/health_provider_deadline_test.dart
```

No commit or publication is authorized by this report. The final report provides
line counts and SHA-256 hashes separately to avoid a self-referential digest.
