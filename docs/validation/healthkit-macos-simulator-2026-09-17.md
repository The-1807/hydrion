# HealthKit Mac and Simulator validation — 2026-09-17

Status: in progress; no physical-iPhone certification.

The user explicitly selected Xcode Simulator because no physical device is
available. Simulator evidence must not be promoted to physical-device,
Apple Watch, vendor, battery or hardware Keychain certification.

## Starting repository and environment

- Repository: `/Users/uchennaanozie/Documents/hydrion`.
- Starting branch: `main`, `a12e2d6df1e490a4541e88ab69cdda5bc09d4020`.
  That commit already incorporated PR #129 before this validation run.
- Working branch and verified origin handoff:
  `feature/healthkit-provider`, `ea062f4f76d957f030f3c8fac1531dbab72af1a7`.
- Base `25a5b4973fa5b0fa5f195a914f892cea34e0d038` verified as an ancestor.
- Reviewed Windows commits: `6f7b51b`, `d6ee087`, `ea062f4`.
- Clean checkout; pre-existing stash preserved.
- macOS 14.8.9 (23J631), Intel x86_64; Xcode 16.2 (16C5032a), Swift 6.0.3.
- Flutter 3.44.9 / Dart 3.12.2; repository `.fvmrc` pins 3.44.8.
  Installed SDK used without upgrading or changing the pin.
- CocoaPods 1.17.0 using Homebrew Ruby 4.0.6.
- Installed simulator: iOS 18.3.1 (22D8075); project minimum iOS 14.0.
- No physical devices detected; zero valid signing identities reported.
- Flutter doctor accepts Xcode; unrelated Java discovery and Chrome checks fail.

## Audit findings recorded before implementation changes

- Native requests use `toShare: []` and only workout, active energy, steps and
  walking/running distance. Runner declares HealthKit; the widget does not.
- Production uses the existing provider contract, coordinator and encrypted
  SQLCipher repository. Metric checkpoints commit with imported records;
  failures are handled per metric. Optional source/device fields stay optional.
- Apple read authorization is opaque. The UI uses request-completed language,
  and empty results mention both empty history and denied read access.
- Threat-model wording overstates native input validation: the Swift boundary
  checks date parsing/order but not input length, and accepts a non-string anchor
  as absent. Dart bounds anchor strings, but the native decoder itself does not.
- Existing Runner entitlements hardcode the production Keychain and app groups.
  A bundle identifier override alone does not provide complete test isolation.
- `RunnerTests.swift` contains only an empty example, providing no native
  HealthKit regression evidence.
- Sample mapping currently executes inside the main-thread response closure.
  This warrants native validation before making any performance claim.
- The query is a one-shot query without `updateHandler`. Apple's SDK documents
  automatic stopping after its results callback; absence of explicit `stop`
  alone is not evidence of a leak. In-flight cancellation is not implemented.

## Evidence gates

Results will be recorded here as commands finish. Existing physical acceptance
checkboxes remain unchanged.

### Completed Mac checks

- `flutter pub get --enforce-lockfile`: passed; lockfile unchanged.
- Focused provider/UI/sync/encryption/configuration suite: **90/90 passed**.
  This is the actual selected Mac suite, not the Windows 103-test matrix.
- `flutter analyze --no-pub`: no issues (45.5 seconds reported).
- `dart format --output=none --set-exit-if-changed .`: 237 files, zero changes.
- Localization: EN/FR/ES each 943/943 Flutter messages and 24/24 Android messages.
- Mixed-language audit: zero placeholder drift; two reviewed identical French
  strings (`reportsDate`, `reportsPage`), zero identical Spanish strings.
- Production literals: 940 findings, all reviewed, zero unresolved.
- Secret scan: no committed API keys, credentials or private key blocks found.
- CI validator: two workflows validated; no GitHub configuration changed.
- `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 pod install --deployment`: passed;
  CocoaPods lockfile unchanged. Inherited non-UTF-8 locale failed first.
- Existing CocoaPods custom-base-configuration warning remains; no migration
  or Podfile rewrite performed. Workspace includes both Runner and Pods.
- Initial `swiftc -typecheck` of the unchanged handoff host against the installed
  iOS Simulator SDK and Flutter framework: passed. This is not an app build.

### Native changes under validation

- Reject wrong-typed, empty and oversized native anchors instead of silently
  dropping the anchor and restarting a query. Bound encoded anchors as well.
- Bound native ISO date input strings before parsing.
- Validate sample type before unit conversion, avoiding incompatible-unit
  Objective-C exceptions if the mapping contract is violated.
- Map samples and archive anchors on the HealthKit callback queue; deliver only
  the completed result on the Flutter main thread.
- Replace the empty XCTest with six native mapping/anchor/date regression tests.

### Simulator isolation

Created a new simulator, `HydrionHealthKitCertification`, iPhone 16 / iOS 18.3.1,
UDID `92E4FA9F-6E74-4D81-8C74-163F6E68E08E`. Existing simulators are preserved.
No physical device is attached and no production app has been installed or
modified by this validation run.

### Completed native build and full regression checks

- Full Mac Flutter suite: **742 passed, 2 skipped**, reported test duration
  14m26s. The two skipped tests in `issue_sync_security_test.dart` are explicitly
  Windows-only PowerShell process checks. Windows totals are not reused here.
- Final analysis including the simulator integration entrypoint: no issues.
- `flutter build ios --simulator --debug --no-pub`: passed. Xcode compilation
  reported 565.0 seconds. CocoaPods and Swift Package Manager coexist unchanged.
- Built Runner version 1.2.0 (4), bundle `com.the1807.hydrion`, minimum iOS 14.0,
  iPhoneSimulator SDK 18.2 (22C146), Xcode 16.2.
- Built EN/FR/ES `InfoPlist.strings` each contain `NSHealthShareUsageDescription`;
  no write usage description is present.
- Extracted the x86_64 executable `__TEXT,__entitlements` section with `lipo`
  and `segedit`: Runner includes `com.apple.developer.healthkit=true`; widget
  executable omits it. Xcode uses a simulator-only `FAKETEAMID` prefix.
  `codesign -d --entitlements` alone shows an empty signature entitlement set
  for this simulator build and is not the appropriate standalone verification.
- The original production bundle namespace is used only inside the newly
  created simulator. This does not establish an isolated physical-device build;
  a distinct bundle plus Keychain/app-group configuration is still required
  before any installation alongside production on a physical iPhone.

### Native RunnerTests rerun (corrected sync-identifier fixture)

- `xcodebuild test -workspace Runner.xcworkspace -scheme Runner
  -only-testing:RunnerTests -destination 'id=92E4FA9F-6E74-4D81-8C74-163F6E68E08E'
  -jobs 1`: **TEST SUCCEEDED**, 6/6 passed —
  `testSecureAnchorRoundTripAndAbsentAnchor`,
  `testMalformedAnchorsNeverBecomeInitialQueries`,
  `testDatesAcceptDartPrecisionAndRejectMalformedOrOversizedValues`,
  `testQuantityMappingUsesCanonicalUnitsAndOptionalDeviceMetadata`,
  `testWorkoutMappingPreservesDurationCategoryAndDevice`,
  `testMetricMismatchIsRejectedBeforeIncompatibleUnitConversion`.
- The prior failure (synthetic workout supplied `HKMetadataKeySyncVersion`
  without `HKMetadataKeySyncIdentifier`, which HealthKit rejects) is corrected
  in `RunnerTests.swift`; the workout fixture now sets both keys together.
- This certifies native sample mapping, anchor validation and date bounding in
  the Simulator's real HealthKit store. It does not certify the synthetic
  fixture app's end-to-end import/correction/deletion/pagination flow or the
  unsigned release build; those remain open below.

### Unsigned iOS release build

- `flutter build ios --release --no-codesign --no-pub`: passed. `Xcode build
  done.` reported 180.1 seconds. Codesigning was intentionally disabled; this
  is a device-architecture (`arm64`) build artifact, not a simulator artifact,
  and is not installable without a later signing step.
- Built `Runner.app` is 54 MB, version 1.2.0 (4), minimum iOS 14.0.
- `codesign -d --entitlements :- Runner.app`: confirms the object is not
  signed at all, as intended for an unsigned artifact.
- `Runner.app/Info.plist` contains `NSHealthShareUsageDescription` with the
  expected read-only wording and no `NSHealthUpdateUsageDescription` key,
  confirming the release configuration matches the simulator debug build's
  read-only HealthKit posture.
- This certifies that the HealthKit provider changes compile and link cleanly
  in a release configuration for a real device architecture. It does not
  certify installation, launch, runtime behavior or Keychain access on a
  physical iPhone.

### Synthetic HealthKit fixture (real Simulator import/correction/deletion/pagination)

- First two attempts failed. Root cause found by dumping the sheet's real
  accessibility tree: on this iOS 18.3 Simulator, the sheet's "Turn On All"
  control is a table `Cell` (`UIA.Health.AuthSheet.AllCategoryButton`), not a
  `Button`, so `app.buttons["Turn On All"]` never matched it. Its `Allow`
  confirm button (`UIA.Health.AuthSheet.DoneButton`) starts **Disabled** until
  a category cell is toggled on, so the original test was tapping a disabled,
  no-op button; the sheet never dismissed and `requestAuthorization`'s
  completion handler never fired. This was a UI-automation defect in the test
  harness, not a HealthKitHost defect — confirmed because raising the wait
  timeout to 420 seconds still left the status stuck on `Running`, ruling out
  slow-save latency as the cause.
- `FixtureUITests.swift` was corrected to tap `UIA.Health.AuthSheet.AllCategoryButton`
  then `UIA.Health.AuthSheet.DoneButton` by accessibility identifier, with an
  explicit assertion that the Done button is enabled before tapping.
- With that fix, `xcodebuild test-without-building` on the isolated
  `HydrionHealthKitCertification` simulator: **passed in 23.7 seconds**
  (`** TEST EXECUTE SUCCEEDED **`), confirming the earlier hangs were purely
  the automation bug, not slow bulk writes.
- Evidence from the fixture's own `Documents/result.json` (synthetic counts
  and timings only; no UUIDs, anchors, health values or keys, per the
  fixture's design):
  - Workout, active energy and distance each imported exactly 1 record;
    steps imported 503 records (501 fixture samples + 2 deliberately
    duplicated) across 3 paginated pages of ≤250, confirming the 250-record
    page limit and that the 30-day-boundary-excluded sample was correctly
    absent.
  - `correctionReconciled: true` — an energy-sample correction (same sync
    identifier, incremented sync version) was read back as an insert of the
    new value plus a tombstone of the superseded record.
  - `deletionReconciled: true` — a deleted distance sample was read back as
    a tombstone.
  - Ten repeat incremental-anchor sync cycles each returned 0 new records
    (`repeatRecords: 0`), confirming no duplicate import on repeated sync.
  - Initial four-metric query: 2,150 ms. Repeat incremental cycles: 62–106 ms
    each. These are Simulator timings on this Mac, not physical-iPhone or
    battery evidence.
- This certifies the production `HealthKitHost.swift` code path end-to-end
  against the Simulator's real HealthKit store — the same file that ships in
  Runner, unmodified for this fixture. It does not certify physical-device
  behavior, Apple Watch contribution, or the Keychain-protected encrypted
  repository (which is exercised separately by the Dart-level coordinator
  tests, not by this native fixture).

### Flutter-level HealthKit integration test (`integration_test/healthkit_simulator_test.dart`)

- First attempt failed at `setUpAll`: the test's own device-vs-simulator guard
  read `Platform.environment['SIMULATOR_UDID']`, but on-device Dart processes
  do not inherit the launching shell's environment — only compile-time
  `--dart-define` values reach them. This is a real bug in the test's guard,
  inconsistent with the adjacent `HYDRION_SIMULATOR_VALIDATION` guard in the
  same file, which already correctly used `bool.fromEnvironment`. Fixed by
  switching to `String.fromEnvironment('SIMULATOR_UDID')` and passing it as a
  `--dart-define`, matching the existing pattern.
- With that fix: `flutter test integration_test/healthkit_simulator_test.dart
  -d 92E4FA9F-6E74-4D81-8C74-163F6E68E08E
  --dart-define=HYDRION_SIMULATOR_VALIDATION=true
  --dart-define=SIMULATOR_UDID=92E4FA9F-6E74-4D81-8C74-163F6E68E08E`:
  **All tests passed!** (2/2, 12 seconds after an 89.6s Xcode build).
- `registered native bridge reports availability and opaque consent`: the
  production `AppleHealthKitProvider.availability()` reports `available` and
  `authorizationState()` reports `notRequested` with no granted metrics on a
  real Simulator HealthKit store, with no permission prompt shown — confirming
  the read-only, explicit-user-action consent posture at the Dart provider
  layer (not just the native Swift layer already covered above).
- `simulator Keychain and SQLCipher preserve atomic encrypted state`: a real
  iOS Simulator Keychain key was obtained via `PlatformHealthDatabaseKeyStore`,
  used to open a SQLCipher-encrypted repository, survived a close/reopen cycle
  with the same restored key, rejected an unkeyed reader and a wrong key,
  rolled back atomically on an injected mid-transaction failure without
  advancing the checkpoint, and left no plaintext SQLite header, record
  content, checkpoint cursor or key encoding (base64/base64url/hex) anywhere
  on disk after close.
- This certifies the production Dart-level `AppleHealthKitProvider` and the
  encrypted repository's Keychain integration against a **real iOS Simulator
  Keychain**, which is a materially stronger result than a mocked or Windows
  Keystore stand-in. It is still not physical-device Keychain evidence
  (Simulator Keychain does not exercise Secure Enclave-backed protection
  classes the way a physical iPhone does), and it does not exercise the full
  16-state wearable connection-screen UI (`health_data_connection_screen.dart`)
  end-to-end — only the two provider-layer states above.

### Summary of what this session certifies vs. does not

Certified on this Mac, this session: native HealthKit sample mapping, anchor
validation and date bounding (XCTest); a release-configuration compile/link
for a real device architecture (unsigned build); real Simulator HealthKit
store import, pagination, correction and deletion through the unmodified
production native host (synthetic fixture); and real Simulator Keychain-backed
encrypted persistence plus provider-layer availability/authorization state
(Flutter integration test).

Not certified by this session: physical iPhone behavior of any kind, physical
Keychain/Secure Enclave protection, Apple Watch or any live wearable session,
the full wearable connection-screen UI across all required states, FitPro or
any Tier 2/3 vendor route, and battery/memory/performance measurement. These
remain open per the acceptance gates in `wearable_support_devices.md` and the
checkboxes in `HWI_progress.md`.

## watchOS companion app scaffold — 2026-09-18

A `HydrionWatch` watchOS App target (`ios/HydrionWatch/`: SwiftUI hydration
ring UI, `HydrationConnectivityReceiver` as a `WCSessionDelegate`) was added to
`Runner.xcodeproj` via a scripted `xcodeproj` gem edit, alongside a phone-side
`WatchConnectivityHost.swift` (Runner) and `lib/services/watch_connectivity_service.dart`
that pushes a hydration snapshot (today's ml, goal, progress, status) through
`WCSession.updateApplicationContext` whenever hydration or settings data
changes, mirroring the existing `AndroidWidgetService` sync pattern.

- `xcodebuild build -target HydrionWatch -sdk watchsimulator ARCHS=arm64`:
  **passed**, producing a real `HydrionWatch.app` with an arm64 Mach-O
  executable (confirmed with `file`). This is a genuine compile of the watch
  target's Swift source, not a syntax check.
- The target was initially wired as a companion app embedded in Runner via an
  "Embed Watch Content" copy phase. `flutter build ios --simulator --debug`
  with that embed in place **failed**: `xcodebuild: error: This scheme builds
  an embedded Apple Watch app. watchOS 11.2 must be installed in order to run
  the scheme`. This Mac has the watchOS Simulator SDK (headers/compiler) but
  not the watchOS platform runtime Xcode needs to embed and pair a companion
  app into a full scheme build.
- Embedding a target the host cannot actually build is a regression, not a
  scaffold: it would very likely also break the project's `codemagic.yaml` CI
  pipeline, which almost certainly lacks the watchOS runtime too. The embed
  phase and the Runner→HydrionWatch dependency were removed immediately
  (scripted `xcodeproj` edit). `flutter build ios --simulator --debug --no-pub`
  was re-run and now **passes** (`Xcode build done`, `Runner.app` built).
- That same rebuild attempt surfaced a second, unrelated real bug: `WatchConnectivityHost.swift`
  existed on disk and was referenced from `AppDelegate.swift`, but had never
  been added to Runner's Xcode Sources build phase, so it silently was not
  being compiled (`Cannot find type 'WatchConnectivityHost' in scope`). Fixed
  by registering the file reference via the same scripted approach. Runner
  now builds clean with the new phone-side watch-connectivity code included.
- Full `flutter test` (743 passed, 2 Windows-only skipped) and `flutter
  analyze` (no issues) both re-confirmed after all of the above.

### What this does and does not certify

Certified: the watch app's Swift source compiles for the watchOS Simulator
SDK; the phone-side `WatchConnectivityHost`/`WatchConnectivityService` code
compiles and passes static analysis and the full Dart test suite; Runner's
production build is unaffected.

Not certified: the watch app has never been launched, in any simulator or on
a physical Apple Watch — no watchOS Simulator runtime is installed on this
Mac. No WatchConnectivity pairing or message delivery has been observed. The
watch app is **not currently embedded** in the Runner build Apple would ship;
embedding is a deliberate choice left open, pending either installing the
watchOS runtime on a build Mac or accepting the CI-pipeline risk that comes
with it. No physical Apple Watch is available to this session.
