# MrGoldApple Apple wearable sprint — 2026-09-19

Status: source/build repair validated; simulator application/runtime acceptance
remains blocked on MrGoldApple. Physical iPhones available: **0**. Completed
physical-iPhone tests: **0**. No physical Apple Watch certification. Historical
results in the September 17 report are not presented as reruns here.

## Read-only preflight and target topology

Repository `/Users/uchennaanozie/Documents/hydrion` started clean on
`feature/healthkit-provider`, HEAD `c6379e605dc0a33e253147010ce9a7340671f75b`.
Origin fetch and push URL: `https://github.com/The-1807/hydrion.git`.
`git fetch origin feature/healthkit-provider` succeeded. The fetched tip contains
handoff `ea062f4f76d957f030f3c8fac1531dbab72af1a7` and commits `6f7b51b`,
`d6ee087`, `ea062f4`; ancestry was checked with `git merge-base --is-ancestor`.
No checkout, stash, reset, clean, rebase or unrelated commit was required.

| Target | Product / bundle ID | Minimum | Entitlements and membership |
|---|---|---|---|
| Runner | iOS app, `com.the1807.hydrion` | iOS 14.0 | `HealthKitHost.swift`, `WatchConnectivityHost.swift`; HealthKit, Keychain group, `group.com.the1807.hydrion` |
| RunnerTests | XCTest, `com.the1807.hydrion.RunnerTests` | inherited iOS 14.0 | depends on Runner; no entitlement file |
| HydrionWatch | single SwiftUI app, `com.the1807.hydrion.watchkitapp` | watchOS 10.0 | no HealthKit/App Group entitlement file; no separate watch extension |
| HydrionWidgets | WidgetKit extension, `com.the1807.hydrion.widgets` | iOS 14.0 | App Group only; no HealthKit |

Runner originally depended on/embedded only HydrionWidgets, alongside its
framework phases. The watch product existed but had neither a Runner target
dependency nor an Embed Watch Content phase. Both Runner and HydrionWatch have
committed shared schemes. Project/workspace `-list` succeeded and found all four
targets and the expected package/Pods schemes; the widget scheme is generated.
`WKCompanionAppBundleIdentifier` is `com.the1807.hydrion`. The original plist
claimed independent operation even though the watch has no independent source.
The repair makes that relationship dependent and embeds the watch app under
`Runner.app/Watch`, separately from `PlugIns/HydrionWidgets.appex`. All original
HealthKit, Keychain and App Group entitlements remain unchanged.

## Confirmed original failure and repair

Installed Flutter `packages/flutter_tools/lib/src/ios/mac.dart` checks for a
watch companion before invoking the build. At lines 403–418 it deliberately
omits the global `-sdk` option for mixed iOS/watchOS targets and rejects simulator
builds with no device ID. The original CI command, `flutter build ios
--simulator`, supplied none. This explains the exact reported error:

```
No simulator device ID has been set.
Watch companion app found.
A device ID is required to build an app with a watchOS companion app.
```

`tool/apple_simulator.py` now discovers a paired destination and passes the
**iPhone UDID** explicitly to Flutter. It checks project minimum versions,
CoreSimulator availability, bootstatus, Flutter device visibility and Xcode's
eligible destinations for both schemes. Distinct error categories and bounded
subprocesses prevent missing runtimes, absent devices, unpaired devices, boot
failure, Flutter visibility, Xcode rejection and later compilation failure from
being conflated. CI installs a missing watch runtime matching the selected SDK,
then uses the same helper. No permanent UDID is a workflow/source constant.
CocoaPods remains in place and `pod install --deployment` succeeds.

The companion also referenced Foundation through a hardcoded WatchOS26.0 SDK
path. It now resolves `System/Library/Frameworks/Foundation.framework` from
`SDKROOT`, allowing Xcode to choose the actual platform SDK.

## Environment and isolated destination

- macOS 14.8.9 (23J631), Intel x86_64.
- Flutter 3.44.9, framework `6b182d2c75`; Dart 3.12.2. No SDK upgrade performed.
- Xcode 16.2 (16C5032a); iOS/iOS Simulator SDK 18.2; watchOS/watch Simulator SDK 11.2.
- CocoaPods 1.17.0. UTF-8 locale used for installation.
- Initial runtime: iOS 18.3.1 (22D8075); no watch runtime and no pairs.
- `xcodebuild -downloadPlatform watchOS -buildVersion 11.2`: exit 0; installed
  watchOS 11.2 (22S99). Download bounded to 1,200 seconds.
- Created isolated `HydrionAppleSprint`, iPhone 16,
  `DDC7DB96-1351-4CC5-98DA-DEA941A46D0F`, iOS 18.3.1.
- Created isolated `HydrionAppleSprintWatch`, Apple Watch Series 10 (46mm),
  `4742ED21-E501-4058-8773-9E6F8773F8B4`, watchOS 11.2.
- `simctl pair` succeeded. These identifiers are historical evidence only;
  reproduce by discovery, never by copying them into CI.
- Flutter doctor: Apple toolchain passes; Android Java discovery remains an
  unrelated toolchain issue (`/usr/bin/java` cannot report a version).

## Command and test ledger

Raw local command logs are under `/tmp/hydrion-sprint/`; generated products and
runtime state are not staged. Commands below are the reproducible validation
entry points; source-reading commands and status polling are inspection only.

| Command/check | Current-run result |
|---|---|
| `git status --short --branch`, `git rev-parse HEAD`, `git remote -v`, `git log -6 --oneline` | clean starting branch and handoff verified |
| `git fetch origin feature/healthkit-provider`; ancestry check | pass; initial sandbox fetch denied, authorized tool rerun passed |
| `flutter --version`, `dart --version`, `xcodebuild -version`, `pod --version` | versions above; initial Flutter sandbox cache write denied, rerun passed |
| `flutter devices`; `simctl list devices available`, `list runtimes`, `list pairs`, `list --json`; `xcodebuild -showsdks` | inventory captured; initially no watch runtime/pair |
| project and workspace `xcodebuild -list` | pass |
| `flutter doctor -v` | Apple passes; Android Java warning |
| `flutter pub get --enforce-lockfile` | pass; no dependency upgrade |
| `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 pod install --deployment` in ios | pass; existing custom-base-configuration warning retained |
| `flutter test --no-pub --reporter expanded` | **743 passed, 2 skipped**, 8m26s; skipped tests are Windows-only PowerShell checks |
| `flutter analyze --no-pub` | pass; no issues |
| `dart format --output=none --set-exit-if-changed .` | pass, final 242 files, zero changes |
| `dart run tool/localization_audit.dart` | pass |
| `dart run tool/mixed_language_audit.dart` | initially failed on reviewed French labels and placeholder-only strings; corrected audit passes, zero identical/placeholder drift |
| `dart run tool/production_string_audit.dart` | pass |
| `dart run tool/secret_scan.dart` | pass |
| `dart run tool/validate_ci_workflows.dart` | pass |
| `python3 -m unittest discover -s tool/tests -p 'test_apple_simulator.py'` | **13 passed**: runtime/device/pair/deployment/timeout/boot/Flutter/Xcode/build-argument and denied-termination cases |
| `python3 tool/apple_simulator.py --output ...` before runtime install | correctly fails `NO_WATCHOS_RUNTIME` |
| `plutil -lint ios/Runner.xcodeproj/project.pbxproj` | pass |
| `git diff --check` | pass at intermediate review |

## Behavioral scope and truthfulness

The watch has a hydration ring/amount/goal/status screen and a no-data waiting
screen, with no navigation or editable controls. New runtime fixes retain the
latest pending snapshot through activation, report queued rather than delivered,
validate received schema/types/bounds, reject duplicate/older timestamps, show
unreachable/error states with a retained snapshot, and avoid raw exception logs.
Native snapshot tests are separate from transport acceptance.

The HealthKit implementation remains read-only (`toShare: []`) for workouts,
active energy, steps and walking/running distance. It uses bounded 250-record
anchored queries and bounded dates/anchors. The shared coordinator handles
independent metric checkpoints, idempotent records, corrections/tombstones,
partial failures and atomic encrypted persistence. Optional device metadata and
contributing-application provenance remain distinct; no brand support or
hydration-target modification is inferred. The full suite includes provider,
synchronization, connection UI, startup and encrypted repository tests.

Wear OS is **not implemented**: Android has only the `:app` module, with no Wear
manifest/Gradle module/UI, Data Layer, Health Services, Wear permissions, tests
or emulator workflow. Its bounded follow-on plan is in
`wearable_support_devices.md`. No new Wear OS product was created.

## Checklist integrity

Before editing authoritative `HWI_progress.md`: **61 total, 48 checked,
13 unchecked, 545 lines**, SHA-256
`7c65062b193a8115c642dc4894645d2f12d57df4af72b44058f70d636eff3fc0`.
Existing acceptance boxes are preserved; physical-device gates cannot be closed
with simulator or unit evidence. Final counts, results and Git completion are
recorded below after validation finishes.

## First-boot diagnostics and final source checks

This Mac is a MacBookAir8,2 with 8 GB RAM and four logical CPUs. Both new
simulators reached CoreSimulator's `Booted` state, while the pair reported
`(active, disconnected)`. The initial watch `simctl boot` exceeded 60 seconds;
the helper's boot-command bound was increased to 180 seconds. A later watch
`bootstatus -b` exceeded its 300-second readiness bound. These are boot failures,
not compilation failures, and no destination JSON was emitted as success.

The watch screenshot showed Apple's startup logo, not Hydrion. The installed
watch runtime contains x86_64 and arm64 binaries, ruling out an ARM-only
download. Watch `launchctl list` exceeded a separate 60-second diagnostic bound.
A serialized `bootstatus` attempt bounded to 600 seconds eventually logged
`Waiting on Data Migration` for `com.apple.securityd.KeychainMigrator`, then
`Finished` at 16:05:02 UTC, concurrently with targeted watch shutdown. Because
shutdown overlapped completion, that exit 0 is **not** counted as usable-watch
readiness. Only the two newly created simulators were shut down. Resource
pressure was suspected; the logged migration wait is the observed evidence.

A parallel Swift bridge typecheck hit its 180-second bound during first boot.
No compilation success is inferred from it. Native compilation is retried with
simulators shut down, using the already discovered paired iPhone UDID.

After the final source changes, the two affected Flutter configuration/CI files
passed **16 tests**. Final analysis caught one missing-braces lint in the new
watch integration test; it was corrected and analysis reran with no issues.
The final workflow validator passes. Localization covers 954/954 Flutter and
24/24 Android messages for each of EN/FR/ES. Production literals: 941 reviewed,
zero unresolved. These audits do not certify translations of native watch UI.

Checklist after documentation update: **61 total, 48 checked, 13 unchecked,
572 lines**, SHA-256
`9655f0f7a2bbd5e6754cd72f8b8ee60a4e50f3b8833a3000e0df5a64788b54b4`.
Newly checked existing criteria: **none**. No boxes were removed or unchecked.

## Debug compilation and built-product verification

The first explicit-destination compilation attempt exited 1 when Flutter reran
CocoaPods with the shell's non-UTF-8 locale (`Encoding::CompatibilityError`).
This is a separate environment failure from the original missing-destination
error. The helper's child environment and the entire Apple CI job now set
`LANG=en_US.UTF-8` and `LC_ALL=en_US.UTF-8`, including implicit pod invocations.
The informational Swift Package Manager migration message is not acted upon.

With that locale, `flutter build ios --simulator --debug --no-pub -d <discovered
iphone>` exited **0**, reporting Xcode build time **179.9 seconds**. Runner's
native Swift/HealthKit/WatchConnectivity code and HydrionWatch compiled. This
paragraph certifies compilation and bundle checks; launch is a separate gate.

Built `Runner.app` version 1.2.0 (4), minimum iOS 14.0, contains:

- `Watch/HydrionWatch.app`: `com.the1807.hydrion.watchkitapp`, version 1.2.0 (4),
  minimum watchOS 10.0, `WKApplication=true`, correct Runner companion ID.
- `PlugIns/HydrionWidgets.appex`: `com.the1807.hydrion.widgets`, version 1.2.0 (4),
  minimum iOS 14.0, separate from the watch product.
- EN/FR/ES built `InfoPlist.strings` with read-only HealthKit usage descriptions;
  Runner's built plist contains the read description and no write description.

`xcrun lipo -archs` reports x86_64 Runner/widget and x86_64+arm64 watch simulator
executables. Extracting each x86_64 `__TEXT,__entitlements` section with `segedit`
confirms HealthKit **true only in Runner**. Runner/widget carry the App Group;
watch carries neither HealthKit nor an App Group. These are simulator binary
checks, not physical signing/Keychain certification.

`flutter build ios --simulator --release --no-pub -d <discovered iphone>` exited
1 with `Release mode is not supported for simulators.` The unsigned device
release is checked separately; it is never described as a simulator release.
Repository `.fvmrc` remains pinned to 3.44.8; installed 3.44.9 was used without
changing it. Final formatting covers 242 Dart files, zero changes.

## Release-only target and architecture defects

The first UTF-8 unsigned device release failed because the watch target
inherited the project's Release/Profile `SUPPORTED_PLATFORMS=iphoneos`.
Xcode consequently compiled watch Swift as iOS code, producing iOS-15
`foregroundStyle` availability errors and iOS-specific WCSessionDelegate
conformance errors. The repair explicitly sets `watchos watchsimulator` for all
three watch configurations. The 16 topology/CI tests pass with this regression
check; the iOS deployment target remains 14.0.

The next release reached the actual watch architecture and exposed a 32-bit
`Int` overflow in the new timestamp bound. The simulator's x86_64/arm64 builds
could not catch it. The decoder now uses a bounded `Int64` millisecond timestamp
through NSNumber, rejects booleans, non-finite/fractional values and overflow,
and only then converts to Date. The native regression set includes these
malformed timestamp cases. Final release and native-test outcomes follow.

### Final unsigned release compilation

`flutter build ios --release --no-codesign --no-pub`, with the UTF-8 locale and
platform/Int64 repairs, exited **0**, reporting **198.6 seconds** of Xcode build
time and a 56.1 MB Runner.app. Built plists identify Runner/widget as `iphoneos`
and the embedded companion as `watchos`, with the intended iOS 14/watchOS 10
minimums. This is unsigned device-architecture compilation, not installation
or launch on a physical iPhone or Apple Watch. Runtime validation continued
on September 20 after a host/session pause; no physical devices were added.

### Final debug compilation and simulator service recovery

The final simulator debug compilation, including the Release/Profile platform
repair and Int64 decoder, exited **0** (234.1 seconds of Xcode compilation).
A copy of its normal production entrypoint app is preserved under
`/tmp/hydrion-sprint/RunnerProduction.app` before installing test entrypoints.
Release binary inspection confirms watch `arm64_32 arm64`; `codesign -d` reports
the device release is unsigned, as intended.

On September 20, the paired helper's watch boot failed with exit 60:
`launchd failed to respond` / `Failed to start launchd_sim: could not bind to
session`. A phone installation attempt overlapped the subsequent targeted
shutdown and returned Mach server-died (-308); that interrupted attempt is not
counted as an app defect or successful installation. Both task-created devices
were shut down. The watch was already shut down (405 on its shutdown request).
The current user's exact CoreSimulatorService process was then sent TERM;
no simulator, application data or runtime was erased.

Booting the watch first after the service restart succeeded. Its readiness
monitor progressed through migration to `Waiting on System App`; the old
300-second readiness bound was insufficient. Leaving it running allowed
readiness to finish, rather than repeatedly interrupting first-boot work.
The helper now boots the watch before the phone, logs both selected models/OS
versions/UDIDs and pair state before boot, defaults to 900 seconds per-device
readiness, and accepts a validated `--boot-timeout` from 30 to 1200 seconds.
CI's Apple step is bounded to 60 minutes and its job to 90 minutes. The local
continuation used `--boot-timeout 1200`. Python regression tests still pass 12/12.
The helper requires both devices to remain Booted after their readiness checks;
a monitor exiting during shutdown cannot produce a successful destination.


## Final native execution and remaining acceptance gates — September 20

`xcodebuild build-for-testing -workspace ios/Runner.xcworkspace -scheme Runner
-configuration Debug -destination id=<selected-phone> -destination-timeout 30
-jobs 1 -parallel-testing-enabled NO -only-testing:RunnerTests
BUILD_DIR=<repository>/build/ios` exited **0**, with **TEST BUILD SUCCEEDED**.
This compiles the six existing native HealthKit tests and three new snapshot
cases. The corresponding `test-without-building` command exited **70**:
Xcode could not find the selected iPhone; its available destinations contained
only generic iOS/device placeholders. **No iPhone XCTest pass is claimed.**

After service recovery, the watch reached its actual clock face (screenshot
`watch-ready.png`), and its readiness monitor completed without shutdown.
Installing HydrionWatch nevertheless exceeded 120 seconds. A phone screenshot
exceeded 45 seconds. macOS denied process-group SIGKILL during timeout cleanup;
these commands did not provide app installation or application UI evidence.
The helper now falls back to signaling the direct child, bounds both cleanup
waits, closes pipes, and preserves the original categorized timeout even when
termination is denied. A regression test exercises that exact failure path:
**13 Python tests pass**. The outer CI deadlines remain in force.

Free space fell to approximately **1.4 GiB** during test compilation and simulator
startup. Existing caches, unrelated simulators and user data were not deleted.
The isolated native HealthKit fixture project was regenerated successfully with
`GEM_HOME=/usr/local/Cellar/cocoapods/1.17.0/libexec ruby
tool/healthkit_fixture/generate_project.rb /usr/local/share/flutter`; its runtime
suite and the two HealthKit/four watch Flutter integration cases were **not run**
after Xcode lost the destination. They require a usable iPhone simulator and
sufficient build space; repeating those builds cannot establish runtime evidence
while that prerequisite is missing. The new watch integration source passes
analysis and uses isolated real preference keys, not mocked persistence.

| Acceptance boundary | Evidence in this continuation |
|---|---|
| Debug and unsigned release compilation, including HealthKit host/watch | Commands exit 0; native test build also succeeds |
| Companion embedding, bundle relationship, widget separation, entitlements | Built-product inspection passes |
| Watch simulator OS boots to usable system UI | Clock-face screenshot and completed readiness monitor |
| iPhone/watch applications install and launch | Not established; installation/runtime commands blocked |
| Hydration ring, waiting/error labels, connection, disconnect/reconnect | Source present; application runtime unverified |
| Duplicate/delayed/invalid context handling | Three production-decoder XCTest cases pass on macOS; simulator transport execution blocked |
| Termination/relaunch and simulator restart preserve state | Unverified; no acceptance box closed |
| Manual tracking with unavailable watch | Existing Flutter regression scope passes; new native-service integration not executed |
| HealthKit four-metric pagination, correction/deletion, provenance | Existing Dart suite passes; native fixture not rerun successfully |
| Real simulator Keychain/SQLCipher integration | Existing integration source preserved; not rerun in this continuation |
| Native watch localization | Not certified by Flutter/Android localization audits |
| Physical iPhone / Apple Watch | No physical validation; zero available iPhones and zero completed iPhone tests |
| Wear OS | Not implemented; separate bounded plan documented |

The original missing-destination failure is repaired in source and the explicit-ID
compilations pass. The stronger user acceptance requirement includes an actual
application launch; therefore **the Apple simulator sprint is not declared
complete**, and no complete compatibility or brand-support claim is made.


The final discovery continuation exited **1**: the iPhone `bootstatus -b`
exceeded **1200 seconds**, reporting `Waiting on System App`. No successful
destination JSON was emitted. The final, uninterrupted phone installation
attempt exceeded **90 seconds**, with its child still not exiting after bounded
termination. Neither phone nor watch launch was established. These are current
CoreSimulator/Xcode infrastructure blocks, not passing application results.

The exact three snapshot methods in `ios/RunnerTests/RunnerTests.swift` were also
extracted unchanged into a temporary macOS XCTest class, alongside the exact
production `HydrationSnapshot.swift`. `xcrun swiftc` used the installed macOS
platform's `Developer/Library/Frameworks` and `Developer/usr/lib` for XCTest,
then ran `SnapshotTests.defaultTestSuite`. A guard required executionCount == 3
and totalFailureCount == 0; compilation and execution exited **0**. This is
**three macOS parser tests**, not iPhone XCTest or watch transport certification.
The first standalone harness omitted the XCTest Swift module search path and
failed compilation; correcting the temporary harness resolved it without a
production-source change. Logs and harness are in
`/tmp/hydrion-sprint/snapshot-macos-tests-final.log` and `snapshot-tests/`.

Final Python tests: **13 passed**. Final workflow validator: **2 workflows pass**.
The checklist remains **61 total / 48 checked / 13 unchecked / 572 lines**;
its final SHA-256 is
`9655f0f7a2bbd5e6754cd72f8b8ee60a4e50f3b8833a3000e0df5a64788b54b4`.
No newly checked criterion, removed box or unchecked existing box.

## Changed files and Git scope

- Destination/CI: `tool/apple_simulator.py`,
  `tool/tests/test_apple_simulator.py`, `.github/workflows/flutter-ci.yml`,
  `test/ci_workflow_policy_test.dart`.
- Native companion: `ios/Runner.xcodeproj/project.pbxproj`,
  `ios/HydrionWatch/Info.plist`, `ContentView.swift`,
  `HydrationConnectivityReceiver.swift`, new `HydrationSnapshot.swift`,
  `ios/Runner/WatchConnectivityHost.swift`, `ios/RunnerTests/RunnerTests.swift`.
- Phone/tests: `lib/services/watch_connectivity_service.dart`,
  `test/ios_release_configuration_test.dart`,
  `integration_test/watch_companion_simulator_test.dart`.
- Audit: `tool/mixed_language_audit.dart`.
- Documentation: `HWI.md`, `HWI_progress.md`, `tester_bible.md`,
  `wearable_support_devices.md`, `docs/CI_CACHE_AND_DISK_OPERATIONS.md`,
  `docs/architecture/WEARABLE_HEALTH_THREAT_MODEL.md`, new
  `docs/architecture/ADR-0007-watchos-hydration-companion.md`, and this report.

The September 20 pre-commit fetch succeeded; local HEAD and the remote feature
branch still matched (`0 0` divergence). Only the listed source/tests/docs are
eligible for focused commits. Build products, Pods, DerivedData, runtime data,
destination JSON, signing material and raw temporary logs are excluded. No PR,
merge, force push, rebase or branch deletion is part of this task.


The final staged-file secret scan passed: no API keys, credentials or private
key blocks found. `git diff --cached --check` passed. Focused source commits:

| Commit | Scope |
|---|---|
| `f69fba6` | Paired destination discovery, timeout cleanup, CI and 13 helper tests |
| `b905869` | Companion embedding/platform fixes, snapshot validation, native and integration test sources |
| `5407a9d` | Mixed-language audit false-positive correction |

The documentation commit follows these source commits. Its SHA, the actual push
result, and final branch/worktree status are reported in the final delivery.
Only `feature/healthkit-provider` is the authorized push destination.

After validation ended, shutdown was requested only for the task-created phone
and watch. **Both shutdown requests exceeded 60 seconds**; neither is reported
as successful cleanup. No erase, cache deletion or further service restart was
performed. The host's CoreSimulator state needs recovery before runtime work
continues; the isolated devices and temporary diagnostics are retained.
