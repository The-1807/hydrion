# Hydrion Release Size and Runtime Measurement

Measurement date: 2026-09-06  
Workspace: `C:\Users\User\StudioProjects\hydrion`  
Audit output: `audit-output/release-size-runtime/`  
Data policy: synthetic data only

## Executive conclusion

Hydrion's unsigned universal release-equivalent Android APK is 98,334,246 bytes (93.779 MiB), 55.55% smaller than the existing 221,232,666-byte universal debug APK. The unsigned ARM64 split is 51,508,516 bytes (49.122 MiB), 47.62% smaller than the universal release APK. Local `apkanalyzer` estimates the ARM64 split download at 37,181,972 bytes (35.46 MiB). This estimate is not a Play Console result.

The release AAB is 93,641,562 bytes (89.304 MiB). It includes 35,207,761 compressed bytes of native debug-symbol metadata, which contributes to upload size but is not an installable device payload. No production signing credentials were present or used.

Installed size and Android runtime memory remain blocked because `adb devices -l` returned no connected device on every retry. No installation was attempted. Host synthetic benchmarks confirmed nonlinear operational cost from whole-history JSON persistence at large histories, but they do not substitute for Android device profiling.

The iOS application was not removed or replaced. Static inspection confirms the `Runner` app, `HydrionWidgets` WidgetKit extension, `RunnerTests`, shared App Group, privacy manifest, and macOS CI build job remain present. No `.app`, `.ipa`, or `.xcarchive` exists locally, and Windows cannot run Xcode, an iOS simulator, or an iPhone deployment. Consequently, iOS binary size, installed storage, runtime memory, and share-cache behavior are explicitly blocked rather than omitted or estimated.

## Platform coverage

| Platform | Static configuration | Build artifact | Installed storage | Runtime memory | Share lifecycle |
|---|---|---|---|---|---|
| Android | Inspected | Measured from APK/AAB | Blocked: no ADB device | Blocked: no ADB device | Static evidence only |
| iOS/iPadOS | Inspected | Blocked: Windows has no Xcode; no local artifact | Blocked: no macOS/iPhone target | Blocked: no macOS/iPhone target | Static exporter evidence only |

This report must not be read as a complete iOS release measurement. It accounts explicitly for what was and was not measurable in the available Windows environment.

## Measurement environment

| Item | Value | Evidence status |
|---|---|---|
| Host | Windows 11, NT 10.0.26200, x64 | Measured |
| Flutter | 3.44.8 stable, revision `058e0af2c2` | Measured |
| Dart | 3.12.2 stable | Measured |
| DevTools | 2.57.0 | Measured |
| Java | Temurin 17.0.20+8; Android builds selected Android Studio JBR | Measured |
| Gradle | 8.12 | Measured |
| Android Gradle Plugin | 8.9.1 | Configuration |
| Kotlin Gradle Plugin | 2.1.0 | Configuration |
| Android build tools installed | 35.0.0, 36.0.0, 37.0.0 | Measured |
| Compile / target / minimum SDK | 36 / 36 / 24 | Artifact/configuration |
| App identity | `com.the1807.hydrion`, `1.2.0+4` | Artifact |
| Free disk before first release build | 25,654,894,592 B (23.89 GiB) | Measured |
| Existing workspace / build / `.dart_tool` | 3,367,295,866 B / 2,913,658,153 B / 211,237,829 B | Measured before builds |
| Existing project Gradle state | 5,665,786 B | Measured before builds |
| User Gradle / Pub cache | Unavailable: two recursive-size methods exceeded five minutes and were stopped | Blocked |

No clean build was performed because the task prohibited deleting existing outputs or caches. All build measurements are warm-workspace/warm-cache measurements. The first release build still required release compilation and was materially slower than later builds.

## Signing boundary

`android/app/build.gradle.kts` applies a release signing configuration only when `android/key.properties` exists. Before building:

- `android/key.properties`: absent
- `android/hydrion-release.jks`: absent
- `android/app/hydrion-release.jks`: absent
- `android/app/debug.keystore`: absent

All measurement APKs and the AAB are unsigned. `apksigner` reported `DOES NOT VERIFY` with missing signing metadata, and `jarsigner` reported the AAB unsigned. No secret was requested, printed, copied, or created. These artifacts are not production distributables.

## iOS static audit

| Item | Verified repository state | Evidence type |
|---|---|---|
| Host application | `Runner`, bundle ID `com.the1807.hydrion` | Xcode project and plist |
| Widget extension | `HydrionWidgets`, bundle ID `com.the1807.hydrion.widgets` | Xcode target and plist |
| Version | App and extension resolve to `1.2.0 (4)` | Flutter settings and extension overrides |
| Deployment target | iOS 14.0 for project, app, and widget configurations | Xcode project and Podfile |
| Shared state | Both targets declare `group.com.the1807.hydrion` | Entitlements |
| Widget delivery | Extension is a Runner dependency and embedded as `HydrionWidgets.appex` | Xcode build phases |
| Widget data boundary | Schema, update time, intake, goal, percentage, and status only | Dart bridge and Swift provider |
| Widget families | Small and medium | Swift source |
| Privacy and permissions | Tracking disabled; coarse location, location, and photo-library declarations present | Privacy manifest and plist |
| Native tests | `RunnerTests.swift` contains only the template test | Source inspection |
| Dart configuration tests | iOS project, version, App Group, widget, permission, and privacy assertions exist | Test inspection |
| CI | macOS 14 builds simulator and unsigned release, validates embedded widget/App Group, and uploads a hashed archive | Workflow inspection |
| Local source/config footprint | 95,338 B across 55 files; icons 23,968 B; launch images 958 B | Filesystem measurement, not app size |

No local iOS build artifact exists. Therefore no iOS binary/component size, signing identity, architecture slice, symbol contribution, installed footprint, launch behavior, widget installation, or runtime-memory result is claimed. The focused iOS configuration tests were attempted, but the Flutter process produced no output for more than three minutes and was interrupted; they are not recorded as passed.

## Exact commands executed

```text
C:\Dev\flutter\bin\flutter.bat --version
android\gradlew.bat --version
C:\Dev\flutter\bin\flutter.bat build apk --release
C:\Dev\flutter\bin\flutter.bat build apk --release --split-per-abi
C:\Dev\flutter\bin\flutter.bat build appbundle --release
C:\Dev\flutter\bin\flutter.bat build apk --release --target-platform android-arm64 --analyze-size --code-size-directory audit-output\release-size-runtime\analysis\flutter-arm64
aapt dump badging <artifact>
apksigner verify --verbose --print-certs <artifact>
jarsigner -verify -verbose <aab>
apkanalyzer apk download-size <apk>
flutter test audit-output\release-size-runtime\benchmarks\storage_growth_benchmark_test.dart --reporter expanded
flutter test audit-output\release-size-runtime\benchmarks\pdf_benchmark_test.dart --reporter expanded
adb devices -l
```

The PDF benchmark first failed because the audit harness had not initialized `intl` locale data. The harness alone was corrected with `initializeDateFormatting('en')`; the successful retry is the source of final PDF results. A subsequent audit-only page-count parser correction was also rerun successfully. Production code was unchanged.

## Artifact identity

| Artifact | Bytes | MiB | SHA-256 | Identity / ABI | Signing |
|---|---:|---:|---|---|---|
| Existing universal debug APK | 221,232,666 | 210.984 | `75EEDE3E3268233C6E1B459E4B516A17E74AFDE42602A4C5880C4F3FC941E375` | `com.the1807.hydrion.debug`, `1.2.0-debug+4`, armv7/arm64/x86_64 | Android debug |
| Universal release APK | 98,334,246 | 93.779 | `829A2558F695325A79349AE8D2239D04DC52B288DEFB6397AEAEB9E35B86176D` | `com.the1807.hydrion`, `1.2.0+4`, armv7/arm64/x86_64 | Unsigned |
| ARM64 split release APK | 51,508,516 | 49.122 | `BB92DB98CFDDF18D5B55C63ABB34C198D3DA05CFBDE47F6C38F173D4FB3A00C4` | versionCode 2004, arm64-v8a | Unsigned |
| ARMv7 split release APK | 49,953,336 | 47.639 | `58BA358C2E6D335BB92CD7DDD691F8B60569D47A19AB99EC11358DD81907C1DB` | versionCode 1004, armeabi-v7a | Unsigned |
| x86_64 split release APK | 53,031,872 | 50.575 | `52A260AA3665431A510193AECAFD33050C1D8E9091CC641CCDB6F3931DFCA8CB` | versionCode 4004, x86_64 | Unsigned |
| Release AAB | 93,641,562 | 89.304 | `796532E525774E8434FACCC5B218A8C7005A5CB7426AC6C797972D4CB1AFA61F` | Base module, three ABIs | Unsigned |
| ARM64 analysis APK | 51,746,068 | 49.349 | `3E6456E4D52D6AFBD9FB4AF64BE60117AA7430A1D98378BB5BA907330B43F6E2` | versionCode 4; ARM64 AOT plus small cross-ABI plugin libs | Unsigned |
| Flutter size JSON | 13,263,094 | 12.649 | `8F2C661BE1DD4E5CC542EEBCEFE72E1A795F14529C393A3EB76251B5A3D4206B` | ARM64 code-size analysis | Not applicable |

## Build timing and disk checkpoints

| Build | Mode | Duration | Free-space delta | Result |
|---|---|---:|---:|---|
| Universal APK | First release build in warm workspace | 521.238 s | -2,538,721,280 B | Passed |
| Split APKs | Warm release build | 52.641 s | -220,479,488 B | Passed |
| AAB | Warm release build | 43.119 s | -402,931,712 B | Passed |
| ARM64 size analysis | Warm release build | 112.291 s | +616,202,240 B | Passed; Gradle replaced/reclaimed intermediates |

The deltas are endpoint changes, not true instantaneous peaks. The final workspace was 5,307,120,370 bytes, `build/` was 4,181,856,868 bytes, `.dart_tool/` was 427,372,923 bytes, and audit output was 439,992,809 bytes at the checkpoint following benchmarks.

## Debug versus release

The debug artifact contains a 91,782,704-byte `kernel_blob.bin`, debug snapshots, three Flutter engines, and a 15,240,080-byte ARM64 Vulkan validation layer. Release replaces JIT/debug program material with ABI-specific `libapp.so`, omits the Vulkan validation layer, and tree-shakes Material Icons from 1,645,184 to 16,564 bytes. The universal release remains large because it carries Flutter engine and Dart AOT binaries for three ABIs plus the common 20.27 MB image set.

## Package composition

The consolidated component ledger appears later in this report. For the ARM64 split:

| Component | Stored bytes |
|---|---:|
| Bundled images | 20,268,467 |
| Dart AOT `libapp.so` | 11,666,320 |
| Flutter engine | 11,581,856 |
| DEX | 5,892,384 |
| Android resources | 1,245,669 |
| Fonts | 311,383 |
| Plugin native libraries | 138,512 |
| Other Flutter assets | 127,146 |
| Legal documents | 14,974 |
| Config | 2,426 |

The AAB contains 35,207,761 compressed bytes (90,946,396 expanded) under `BUNDLE-METADATA/com.android.tools.build.debugsymbols`. Subtracting those ZIP entry payloads gives a non-artifact estimate of 58,433,801 bytes; this is explanatory arithmetic, not a valid rebuilt AAB size.

## Local download estimates

| APK | `apkanalyzer apk download-size` |
|---|---:|
| Universal release | 57,666,414 B (54.99 MiB) |
| ARM64 split | 37,181,972 B (35.46 MiB) |
| ARMv7 split | 37,089,550 B (35.37 MiB) |
| x86_64 split | 37,359,427 B (35.63 MiB) |

No runnable local Bundletool all-in-one assembly was available, no device spec could be obtained, and no Play Console was accessed. Device-specific Play delivery therefore remains unmeasured.

## Installed storage

Blocked. `adb devices -l` returned an empty device list on four audit attempts. Because the artifacts are unsigned and no authorized target was connected, no signing-for-test, install, launch, reset, or data mutation was attempted.

| Checkpoint | Code | Data | Cache/temp | Total | Status |
|---|---:|---:|---:|---:|---|
| Fresh install through reset | Unavailable | Unavailable | Unavailable | Unavailable | Blocked: no ADB device |

iOS installed application, extension, data-container, App Group container, caches, and temporary files are also unavailable. Measuring them requires macOS/Xcode and an authorized iPhone or simulator build.

## Runtime memory

Android runtime RSS/PSS, Dart heap, native heap, graphics memory, file descriptors, frame timing, background/foreground behavior, and 30-minute trends are blocked. The complete runtime ledger appears later in this report.

Host-only synthetic measurements:

- Ten-year heavy hydration load: 73,640,205-byte JSON, 175,344 rows, 9.097 s load, +150,360,064 B RSS at the immediate checkpoint.
- Ten-year heavy append/update/delete with full persistence: 1.902/1.935/1.916 s.
- Ten repeated yearly PDF renders: 41,816-byte, 12-page result; 367.78 ms median; sampled host RSS 244,371,456 B to a high of 262,672,384 B and ended at 258,146,304 B.

These process-level host checkpoints include Flutter test overhead, allocator reservation, and preceding scenarios. They do not prove a leak or Android peak.

iOS Runner and WidgetKit extension memory, extension timeline execution, jetsam behavior, background/foreground transitions, image decoding, PDF rendering, and share-sheet behavior were not measured. The Windows host benchmark cannot substitute for Instruments, MetricKit, Xcode memory tools, or device measurements.

## Persistent-storage benchmark

The complete storage ledger appears later in this report. The benchmark confirms that hydration storage grows without a retention bound and each mutation rewrites the full JSON list. Challenge history is also unbounded, but its measured synthetic contribution was smaller: 278,212 bytes for 480 rich-enough synthetic attempts.

## PDF lifecycle

The complete PDF lifecycle ledger appears later in this report. Actual synthetic outputs measured 14,938 B/1 page weekly, 17,638 B/2 pages monthly, 21,803 B/4 pages quarterly, and 41,816 B/12 pages yearly. Android share success/cancel/failure/restart cache states remain blocked because no target was connected. Static plugin evidence still shows one UUID temporary file and an Android `cache/share_plus` copy, with different cleanup authorities.

## CI cancellation

The 55-minute cancellation cause is unresolved. No local run log or final GitHub annotation exists. Configuration proves only:

- `flutter-ci.yml` Android job timeout: 45 minutes.
- `flutter-ci.yml` concurrency: `cancel-in-progress: true` per workflow/ref.
- Release-candidate build job timeout: 60 minutes with `cancel-in-progress: false`.

A total workflow duration near 55 minutes does not distinguish an Android job timeout, superseding run, manual cancellation, or runner shutdown. The final annotation, job timeline, and last operation are required.

## Security and privacy observations

- Measurement artifacts contain synthetic data only.
- Release-equivalent artifacts are unsigned and must not be distributed as production builds.
- Generated benchmark PDFs are plaintext synthetic artifacts under the local audit directory.
- Production report sharing uses plaintext temporary/cache files; device lifecycle remains unverified.
- No external analysis service, production signing material, Git, or GitHub operation was used.

## Confirmed findings

| ID | Severity | Confidence | Finding |
|---|---|---|---|
| RSM-001 | High | High | Hydration history is unbounded and whole-list load/persistence reaches multi-second costs in heavy long-term synthetic cases. |
| RSM-002 | High | High | Android installed footprint and runtime memory remain unknown because no device was visible. |
| RSM-003 | Medium | High | Universal direct distribution carries about 46.83 MB more than the ARM64 split. |
| RSM-004 | Medium | High | Bundled images are the largest common ARM64 APK component at 20.27 MB. |
| RSM-005 | Medium | High | AAB upload size includes 35.21 MB compressed native debug-symbol metadata. |
| RSM-006 | Medium | High | Report temp/share terminal-state cleanup is not owned end-to-end by Hydrion and remains unverified on device. |
| RSM-007 | Medium | High | The 55-minute CI cancellation cannot be attributed without run annotations/timeline. |
| RSM-008 | Low | High | Challenge history is unbounded but measured smaller than hydration history in the defined synthetic model. |

## Evidence-backed optimization candidates

No optimization was implemented. Ranked candidates for a separate engineering task:

1. Replace whole-history preference persistence with a bounded or incremental persistence design after the owner defines retention. Expected benefit: seconds of heavy-history mutation/load time and large transient allocations.
2. Prefer AAB/device ABI delivery or explicit ABI-specific direct artifacts. Expected benefit: universal APK falls from 98.33 MB to 49.95-53.03 MB depending on ABI.
3. Profile and then right-size bundled raster artwork. Maximum measured common APK opportunity is within the 20.27 MB image group; no per-image change is justified yet.
4. Define and implement application-owned report-temp retention. Benefit is privacy and bounded cache behavior more than package size.
5. Decide whether native symbol metadata belongs inside the candidate AAB workflow artifact or a separate symbol channel, subject to Play/crash-symbolication requirements.

## Unknowns and blockers

- Installed code/data/cache/temp/total size.
- Android runtime and repeated-run memory.
- Play-generated device split and actual Play download size.
- Share success/cancel/failure/restart cache behavior.
- Clean-build duration and true peak disk use.
- Exact Gradle/Pub cache sizes because enumeration timed out.
- CI cancellation annotation and job timeline.
- iOS build size/composition, installed app/App Group/cache footprint, Runner and WidgetKit runtime memory, and share lifecycle. Static configuration was inspected; measurement requires macOS/Xcode and an authorized iPhone or simulator.
- Visual PDF rendering inspection; Poppler and `pypdf` were unavailable. Page counts were parsed from the PDF page-tree count.

## Consolidated package component ledger

All package figures below are ZIP-entry compressed/stored bytes unless stated otherwise. Archive overhead means category totals do not exactly equal artifact file length. Android is the only platform with local package artifacts. The 95,338-byte iOS source/configuration tree is not an iOS application-size measurement.

| Artifact | File bytes | Local download estimate | ABIs | Key difference |
|---|---:|---:|---|---|
| Universal debug APK | 221,232,666 | 110,048,290 | armv7, arm64, x86_64 | JIT/debug payload and Vulkan validation layer |
| Universal release APK | 98,334,246 | 57,666,414 | armv7, arm64, x86_64 | Three engines and three AOT libraries |
| ARMv7 release split | 49,953,336 | 37,089,550 | armv7 | One engine/AOT/plugin slice |
| ARM64 release split | 51,508,516 | 37,181,972 | arm64 | One engine/AOT/plugin slice |
| x86_64 release split | 53,031,872 | 37,359,427 | x86_64 | One engine/AOT/plugin slice |
| Release AAB | 93,641,562 | Not a download estimate | Three | Compressed modules plus native symbols |

| Component | Universal | ARM64 split | ARMv7 split | x86_64 split |
|---|---:|---:|---:|---:|
| Bundled images | 20,268,467 | 20,268,467 | 20,268,467 | 20,268,467 |
| Dart AOT `libapp.so` | 36,899,180 | 11,666,320 | 13,304,396 | 11,928,464 |
| Flutter engine | 32,895,124 | 11,581,856 | 8,453,804 | 12,859,464 |
| DEX | 5,892,384 | 5,892,384 | 5,892,384 | 5,892,384 |
| Android resources | 1,245,669 | 1,245,669 | 1,245,669 | 1,245,669 |
| Fonts | 311,383 | 311,383 | 311,383 | 311,383 |
| Plugin native libraries | 347,544 | 138,512 | 86,016 | 123,016 |
| Other Flutter assets | 127,146 | 127,146 | 127,146 | 127,146 |
| Legal documents | 14,974 | 14,974 | 14,974 | 14,974 |
| Config | 2,426 | 2,426 | 2,426 | 2,426 |
| Unsigned metadata entries | 15,084 | 15,084 | 15,084 | 15,084 |

Expanded DEX is 16,413,876 bytes in every release APK. Expanded fonts total 627,986 bytes. ARM64 key entries are `libapp.so` 11,666,320 B, `libflutter.so` 11,581,856 B, `classes.dex` 3,134,928 B stored/8,764,468 B expanded, and `classes4.dex` 2,646,400 B stored/7,391,716 B expanded.

| AAB component | Compressed | Expanded |
|---|---:|---:|
| Native debug-symbol metadata | 35,207,761 | 90,946,396 |
| Bundled images | 19,869,749 | 20,268,467 |
| Flutter engines | 15,637,886 | 32,895,124 |
| Dart AOT | 15,084,940 | 36,899,180 |
| DEX | 5,892,384 | 16,413,876 |
| Android resources | 879,714 | 2,512,691 |
| Fonts | 311,383 | 627,986 |
| Other Flutter assets | 127,146 | 169,063 |
| Plugin native libraries | 86,085 | 347,544 |
| Legal documents | 14,974 | 36,490 |
| Config | 2,426 | 5,038 |

The release APKs omit `kernel_blob.bin`, debug isolate snapshots, and `libVkLayer_khronos_validation.so`; Material Icons are tree-shaken to 16,564 bytes. No duplicate archive path was found. Cross-ABI libraries are intentional variants. Flutter AOT attribution reported Flutter about 4 MB, Hydrion about 1 MB, `image` 753 KB, Flutter localizations 365 KB, Lottie 346 KB, timezone 334 KB, PDF 267 KB, Markdown 106 KB, intl 104 KB, and Flutter Markdown Plus 48 KB.

## Consolidated runtime memory ledger

No Android or iOS device row is measured. Android had no ADB target. iOS had no macOS/Xcode/iPhone target. Host test-process RSS is diagnostic only and is not device RAM, Dart heap, native heap, graphics memory, or leak proof.

| Platform scenario | Baseline | Peak | Post-operation | Repeated trend | Status |
|---|---:|---:|---:|---:|---|
| Android cold/warm launch and dashboard | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| Android navigation and hydration mutation | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| Android analytics, challenges, timers, and photos | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| Android PDF/share and background cycles | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| Android 30-minute use and file-descriptor trend | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| iOS Runner launch, navigation, history, and PDF | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| iOS WidgetKit timeline load and refresh | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |
| iOS App Group storage and background behavior | Unavailable | Unavailable | Unavailable | Unavailable | Blocked |

| PDF period | PDF/pages | First render | Median | RSS start | Highest sample | RSS end |
|---|---:|---:|---:|---:|---:|---:|
| Weekly | 14,938 B / 1 | 313.06 ms | 39.06 ms | 197,423,104 | 237,428,736 | 237,428,736 |
| Monthly | 17,638 B / 2 | 67.72 ms | 35.54 ms | 242,757,632 | 276,054,016 | 233,943,040 |
| Quarterly | 21,803 B / 4 | 63.66 ms | 100.31 ms | 233,005,056 | 244,207,616 | 244,207,616 |
| Yearly | 41,816 B / 12 | 499.99 ms | 367.78 ms | 244,371,456 | 262,672,384 | 258,146,304 |

Full-process maximum RSS was 281,767,936 bytes. Samples occurred after rendering and can miss transient peaks. No monotonic ten-sample PDF trend or retained-object evidence established a leak.

Static lifecycle inspection found challenge, Pomodoro, shell, theme, guided-tour, screen-controller, and widget-service timers/listeners disposed or cancelled in their current ownership paths. The iOS widget reads a narrow App Group snapshot, refreshes every 30 minutes, and marks data stale after six hours or a calendar-day change. This is static ownership evidence, not device runtime proof.

## Consolidated synthetic storage benchmark

The audit harness used fixed synthetic dates, fresh in-memory stores per scenario, production repository serialization, and host stopwatch/RSS checkpoints. It did not alter production records.

| Dataset | Rows | JSON bytes | Load | RSS delta | Append | Update | Delete |
|---|---:|---:|---:|---:|---:|---:|---:|
| 30-day typical | 240 | 23,441 | 54.78 ms | +827,392 B | 12.22 ms | 7.35 ms | 6.49 ms |
| 30-day heavy | 1,440 | 598,921 | 155.24 ms | +4,231,168 B | 33.89 ms | 28.51 ms | 20.90 ms |
| 1-year typical | 2,920 | 288,201 | 192.22 ms | +1,732,608 B | 11.99 ms | 9.37 ms | 11.82 ms |
| 1-year heavy | 17,520 | 7,323,021 | 859.33 ms | +1,880,064 B | 157.68 ms | 241.55 ms | 221.03 ms |
| 5-year typical | 14,608 | 1,451,921 | 639.18 ms | +5,152,768 B | 46.00 ms | 63.61 ms | 39.92 ms |
| 5-year heavy | 87,648 | 36,756,729 | 4,448.55 ms | +73,854,976 B | 900.94 ms | 940.99 ms | 998.63 ms |
| 10-year typical | 29,224 | 2,913,521 | 1,299.48 ms | -565,248 B | 107.24 ms | 102.35 ms | 160.45 ms |
| 10-year heavy | 175,344 | 73,640,205 | 9,097.07 ms | +150,360,064 B | 1,902.36 ms | 1,934.70 ms | 1,915.80 ms |

Ten-year heavy aggregation took 10.149 ms weekly, 14.391 ms monthly, 16.046 ms quarterly, and 42.389 ms yearly. Challenge history measured 6,804 B for 12 attempts, 27,360 B for 48, 34,212 B for 60, 138,532 B for 240, 68,692 B for 120, and 278,212 B for 480 attempts. Corresponding loads ranged from 11.293 to 113.226 ms.

An audit-only store rejected a write one byte beyond a synthetic 116,891-byte threshold. `HydrationRepository.addLog` propagated `FileSystemException` and restored the prior in-memory event count. This verifies rollback for that synthetic failure, not an Android backend limit. Confirmed risks are unbounded hydration/challenge history and whole-collection decoding, copying, sorting, serialization, and rewriting on every mutation.

Raw evidence: `audit-output/release-size-runtime/analysis/storage-benchmark.json`.

## Consolidated PDF and temporary-file lifecycle

Each period was rendered ten times with production `HydrationReportPdfRenderer`, synthetic rows, and fixed dates.

| Frequency | Rows | Pages | Bytes | SHA-256 | Median host generation |
|---|---:|---:|---:|---|---:|
| Weekly | 7 | 1 | 14,938 | `59EEF8EE0803B5F135E692F8CC091AC5CB49DFE580B7165994559AC4D1613C0F` | 39.06 ms |
| Monthly | 31 | 2 | 17,638 | `26789A447F6B9E83791DFF92093C89A4814C53C856256EF3CC38FC1EC805B594` | 35.54 ms |
| Quarterly | 92 | 4 | 21,803 | `88A3508E8DD22B8A82B0C8F8C93A8688F97C613D6A82AFDA3238166F23759579` | 100.31 ms |
| Yearly | 365 | 12 | 41,816 | `6F16D9EF6F8919809B464815FBAC3AB36ADD726F6F9AD2F69407B17B2516DB2D` | 367.78 ms |

The renderer loads two Roboto fonts, builds a PDF document, and returns an in-memory byte buffer. The exporter creates a byte-backed `XFile`; the platform interface writes it beneath the platform temporary directory. Android `share_plus` clears its previous `cache/share_plus` directory, copies the temporary file there, and grants a scoped content URI. Hydrion has no explicit deletion path for the original UUID temporary file.

| Outcome | UUID temporary file | Android share-cache copy | iOS state | Evidence |
|---|---|---|---|---|
| Generation-only benchmark | Not created by sharing | Not created | Not created | Measured |
| Successful share | OS/plugin cleanup authority | Cleared by next share or OS | Unknown | Android static evidence; runtime blocked |
| Dismissal | No Hydrion deletion path | Next-share/OS cleanup | Unknown | Static evidence; runtime blocked |
| Failure | May remain after creation | Depends on failure point | Unknown | Static evidence; runtime blocked |
| Restart | No Hydrion startup cleanup found | Plugin cleanup on next share | Unknown | Static evidence; runtime blocked |
| Repeated sharing | New UUID directory | Previous copy cleared | Unknown | Static evidence; runtime blocked |

iOS uses the same exporter and byte-backed `XFile`, but no iOS-specific final path, provider, share outcome, restart, or cleanup behavior was measured. No iOS retention claim is inferred from Android implementation details. The picker separately requests a maximum 720x720 image at quality 82, reads it into memory, Base64-encodes it, and replaces the settings value; platform picker-cache behavior remains unmeasured.

Raw evidence: `audit-output/release-size-runtime/analysis/pdf-benchmark.json` and the synthetic PDFs beside it.

## Consolidated static repository baseline

These Phase 1 measurements predate the release builds above and explain repository and build-time storage. They are not installed-size measurements.

| Category | Baseline bytes | Scope |
|---|---:|---|
| Entire workspace | 3,367,235,740 | Source, Git history, and generated output |
| `build/` | 2,913,658,153 | Flutter/Gradle intermediates and outputs |
| `.dart_tool/` | 211,237,829 | Generated Dart/Flutter state |
| `.git/` | 137,218,022 | Repository history/index |
| `assets_source_original/` | 72,539,380 | Source originals, not runtime assets |
| `assets/` | 20,630,414 | Candidate runtime assets |
| `android/` | 5,903,686 | Android source/config/local Gradle state |
| `lib/` | 2,032,349 | Dart source, not byte-for-byte packaged |
| `web/` | 1,035,827 | Web-only sources |
| `test/` | 614,913 | 66 test files, not runtime assets |
| `docs/` | 326,137 | 54 documents; only declared legal files are bundled |
| `core/` | 90,061 | Rust/source workspace with no located build integration |
| `models/` | 22,418 | Training/source files, not bundled |

The baseline workspace contained 3,776 files. `build/app` was 2.720 GB, including 2.277 GB of intermediates: 1.375 GB merged debug native libraries, 439.7 MB incremental state, 221.2 MB APK outputs, 125.6 MB debug Flutter assets, 124.0 MB stripped-native intermediates, 90.5 MB test cache, and 67.6 MB web output. This demonstrates build amplification rather than application installation size.

| Runtime asset group | Source bytes/previous compressed measurement | Consumer |
|---|---:|---|
| UI artwork | 13,664,716 | Home, onboarding, challenges, UI manifest |
| Challenge artwork | 5,518,412 | Challenge catalog/screens |
| Profile/mascot artwork | 1,004,663 | Profile, onboarding, settings |
| Report fonts | 199,316 compressed | PDF renderer |
| Legal Markdown | 16,322 compressed | Legal/about screen |
| Runtime config | 2,497 compressed | Prompt/config loaders |
| App icon JPG | 81,889 | Flutter UI branding |
| Shark Lottie | 1,381 compressed | Startup animation |

Largest bundled rasters include `goals.png` at 1,442,444 B, `goals-lady.png` at 1,299,233 B, `temp-roulette.png` at 1,288,218 B, and `men-goals.png` at 993,148 B. A 1600x1600 ARGB decode can require about 10.24 MB. Some consumers request `cacheWidth` from 192 to 720, but not every consumer was proven to downsample. Transparent-canvas occupancy remains unmeasured.

The nested `assets/UI_BETA/pride/` declaration overlaps its parent declaration but produced only one APK entry per path. Exact duplicates were found mainly across repository/source or platform-output boundaries: two identical debug APK outputs, a source icon and web favicon pair, two source-original images, and five Android round/non-round launcher pairs. No material exact duplicate group was confirmed inside Flutter runtime assets.

## Consolidated persistence inventory

Android maps the local store to SharedPreferences/DataStore; iOS maps it to NSUserDefaults. No secure-storage dependency is declared.

| Data | Storage/growth | Retention | Primary risk |
|---|---|---|---|
| Hydration logs | One JSON string; whole-list rewrite | Unbounded until manual/reset deletion | High long-term latency and allocation |
| Profile/settings/photo | One JSON string; photo Base64 capped at 1,600,000 characters | Latest replaces previous | Sensitive local profile and decode copies |
| Body metrics | Replace-in-place JSON | Latest/reset | Health-related local data |
| Reminders/orphan IDs | Small JSON lists | Delete/clear supported | Notification content exposure |
| Challenges/activity/history | One versioned object with nested histories | Active max 2; history unbounded | Gradual growth and whole-object rewrite |
| Daily context | Versioned JSON | Fourteen-day prune | Bounded |
| Personalization | Versioned JSON | Dismissals bounded; reviewed dates not observed pruning | Slow key growth |
| Weather cache | Replaced JSON entry | Explicit clear/reset | Approximate contextual metadata |
| Widget snapshot | Shared preferences/App Group fixed keys | Latest snapshot | Small bounded cross-process copy |
| Generated report | Memory, platform temp/cache, optional receiver copy | Platform/receiver authority | Plaintext sensitive export |

Storage decoders validate versions/shapes. Hydration skips invalid records; several other repositories fall back or clear their own invalid category. Profile reset clears listed repositories and weather cache while preserving language/appearance and normally legal acceptance; it does not explicitly clear plugin-created share caches.

## Consolidated security, privacy, and CI findings

- Hydration history, metrics, profile fields, and profile photos rely on platform sandbox/device protection without app-layer encryption. Base64 is encoding, not encryption.
- Android disables backup and cleartext traffic. iOS has no inspected explicit per-file `NSFileProtection` policy; effective protection and backup behavior require device verification.
- Generated reports are plaintext and may leave temporary, share-cache, or receiver-managed copies. Sharing intentionally grants another application access.
- No broad sensitive-value logging was found, but operational error payloads require runtime validation.
- No Android `FLAG_SECURE` or equivalent iOS capture policy was found, so sensitive views may appear in system screenshots/recents. Product ownership must decide the usability/privacy tradeoff.
- The prior CI no-space failure concerned build working space, not installed app size. Gradle can retain downloads, transforms, merged/stripped libraries, Java resources, incremental caches, and APK/AAB staging simultaneously.
- Release workflows contain phase disk/inode checkpoints and a guarded cleanup limited to enumerated generated workspace paths. They gate release builds on 10 GiB and 500,000 free inodes. A fresh hosted log is still required to establish actual phase/peak consumption.

The original static finding that release artifacts were unavailable is superseded by the measured APK/AAB results in this report. The remaining evidence-backed priorities are: close Android and iOS device measurements; define scalable hydration/challenge retention; own PDF temporary-file cleanup; profile raster decoding before artwork changes; validate local-data/file-protection and capture policy with synthetic markers; and calibrate CI disk gates from a complete hosted run.

## Acceptance criteria

- [x] The existing debug APK is clearly separated from every release artifact.
- [x] A universal release APK is built, identified, hashed, and measured.
- [x] ARM64 and other available ABI-specific release APKs are built, identified, hashed, and measured.
- [x] An AAB is built, identified, hashed, and measured.
- [x] Flutter release size-analysis output is captured and interpreted.
- [x] Debug, universal release, ARM64 release, and AAB artifacts are compared correctly.
- [x] Major package contributors are measured from release artifacts.
- [x] No production signing credentials or external analysis services are used.
- [x] The iOS app, WidgetKit extension, App Group bridge, native-test state, permissions, privacy manifest, and macOS CI build path are statically inventoried.
- [ ] An iOS release artifact is built, identified, hashed, and measured. Blocked: no macOS/Xcode environment and no local `.app`, `.ipa`, or `.xcarchive`.
- [ ] iOS installed app, extension, App Group data, cache, temporary, and total size are measured. Blocked: no macOS/iPhone test target.
- [ ] iOS Runner and WidgetKit runtime memory are measured across representative and repeated scenarios. Blocked: no macOS/iPhone test target.
- [ ] Installed code, data, cache, temporary, and total size are measured on an authorized test target. Blocked: ADB has no device.
- [ ] Runtime memory is measured across representative and repeated Android scenarios. Blocked: ADB has no device.
- [x] Long-term hydration and challenge-storage behavior is benchmarked using synthetic datasets.
- [ ] Actual PDF sizes and temporary-file behavior are measured. PDF sizes are measured, but Android and iOS share success, dismissal, failure, restart, and repeated-generation cleanup remain blocked because no authorized platform test target was available.
- [x] The 55-minute CI cancellation is explicitly unresolved because final run evidence is absent.
- [x] Security-sensitive artifacts and measurements contain no real user values or secrets.
- [x] No application optimization, dependency upgrade, storage migration, CI rewrite, or unrelated refactor is performed.
- [x] Executed commands, failures, assumptions, and limitations are reported.
- [x] No Git or GitHub operation is performed.
