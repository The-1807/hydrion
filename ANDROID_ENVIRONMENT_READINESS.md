# Android Environment Readiness — Sprint 1, Workstream D

**Status at report time**: Android SDK **was successfully provisioned during this sprint** in the same sandbox that `AUDIT_REPORT.md` originally reported as having zero Android capability. A real `flutter build apk --debug` was launched against the actual Hydrion project and was still running (genuinely compiling, not hung — confirmed via live process inspection) when this document was written. This document records the exact provisioning steps, exact versions, and the honest state of execution — it does not claim Android validation is complete until the build/install/test results below are filled in with real, inspected output.

**Prior state (do not re-litigate)**: `AUDIT_REPORT.md` §9 classified Android APK/AAB build, Android emulator/device testing as **Blocked** — no Android SDK, no `adb`, no emulator. That was accurate for the environment as first audited. This document supersedes it with what was actually done next.

---

## 1. Exact requirements established from the project itself (not assumed)

Read directly from `android/app/build.gradle.kts` and the installed Flutter SDK's own `FlutterExtension.kt` (`/usr/local/share/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`), since Hydrion's own `build.gradle.kts` delegates `compileSdk`/`minSdk`/`targetSdk`/`ndkVersion` to Flutter's defaults rather than pinning its own values:

| Requirement | Value | Source |
|---|---|---|
| `compileSdk` | **36** | `FlutterExtension.kt:23` (Flutter 3.44.9's bundled default) |
| `minSdk` | **24** (Android 7.0) | `FlutterExtension.kt:26` |
| `targetSdk` | **36** | `FlutterExtension.kt:34` |
| `ndkVersion` | **28.2.13676358** | `FlutterExtension.kt:42` |
| `compileOptions` Java compatibility | Java 11 (source/target) | `android/app/build.gradle.kts:24-26` |
| Core library desugaring | enabled, `com.android.tools:desugar_jdk_libs:2.1.4` | `android/app/build.gradle.kts:26,74` |
| Kotlin/Gradle/AGP versions actually in use | Gradle **8.12**, AGP **8.9.1**, Kotlin **2.2.20** (compiler) — Flutter itself warns these are below its currently-recommended minimums (Gradle ≥8.14.0, AGP ≥8.11.1, Kotlin ≥2.2.20 for AGP; Kotlin compiler resolved to 2.2.20 despite an app-level Kotlin plugin reference to 2.1.0, per real build-log warnings — see §6 finding) | Live `flutter build apk` output, this sprint |

**Note on the `compileSdk`/`minSdk`/`targetSdk` = 36 finding**: API level 36 corresponds to a very recent/preview-adjacent Android platform revision as of this sprint's date. Because Hydrion's `build.gradle.kts` does not pin these values itself, they will silently shift upward on every Flutter SDK upgrade. This is a **new observation** worth flagging to the owner separately from Android build execution itself: an unpinned `compileSdk`/`targetSdk` tied to "whatever this month's Flutter stable bundles" is a reproducibility risk or intentional flexibility depending on the team's release process — not evaluated further here since it's outside this workstream's scope, but recorded so it isn't lost.

## 2. Exact provisioning steps executed in this sandbox (real commands, real outcomes)

| # | Step | Command | Outcome |
|---|---|---|---|
| 1 | Install Android command-line tools | `brew install --cask android-commandlinetools` | **Success** — installed to `/usr/local/share/android-commandlinetools`; linked `sdkmanager`, `avdmanager`, `apkanalyzer`, `d8`, `r8`, `lint`, `retrace`, `profgen`, `resourceshrinker`, `screenshot2` to `/usr/local/bin` |
| 2 | Install a JDK (none was present) | `brew install openjdk@17` | **Success** — `/usr/local/opt/openjdk@17`, OpenJDK 17.0.20.1 (Homebrew build) |
| 3 | Accept SDK licenses | `yes \| sdkmanager --licenses` (with `JAVA_HOME`/`PATH` set to the above) | **Success** — "All SDK package licenses accepted" |
| 4 | Install required SDK components | `sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;35.0.0" "system-images;android-34;google_apis;x86_64" "emulator"` | **Success** — all five components installed; confirmed present on disk (`build-tools`, `cmdline-tools`, `emulator`, `licenses`, `platform-tools`, `platforms`, `system-images` all populated under `$ANDROID_HOME`) |
| 5 | Point Flutter at the SDK | `flutter config --android-sdk /usr/local/share/android-commandlinetools` | **Success** — "Setting android-sdk value" confirmed |
| 6 | Validate via `flutter doctor -v` | (with `ANDROID_HOME`/`ANDROID_SDK_ROOT`/`JAVA_HOME`/`PATH` exported) | **Partial** — Flutter, Xcode, Connected-device, Network-resources sections all `[✓]`; the **Android toolchain check itself crashed**: `Exception: Android toolchain - develop for Android devices exceeded maximum allowed duration of 0:04:30.000000`. This is a `flutter doctor` internal timeout on its own toolchain probe (likely an NDK/license-check subprocess it spawns), not evidence the SDK is unusable — confirmed by step 7 succeeding independently. |
| 7 | Attempt a real build | `flutter build apk --debug` (with the same env vars) | **In progress / genuinely compiling at report time** — real Gradle daemon and Kotlin compiler daemon processes confirmed alive and consuming CPU via `ps aux` (not hung); NDK 28.2.13676358 auto-downloaded and installed mid-build after accepting its license non-interactively; build had progressed through dependency resolution and into Kotlin/native compilation when this document was written. **Final pass/fail result not yet available — see §7 for what remains to be filled in.** |

**Disk usage**: available space before provisioning was 31GiB free; the SDK + NDK + emulator system image + Gradle/Kotlin caches consumed several GiB during this process — re-check available space before repeating this on a smaller volume.

**Exact installed package versions** (`sdkmanager --list_installed`, real output):

| Path | Version |
|---|---|
| `build-tools;35.0.0` | 35.0.0 |
| `emulator` | 37.1.11 |
| `ndk;28.2.13676358` | 28.2.13676358 |
| `platform-tools` | 37.0.1 |
| `platforms;android-36` | 2 |
| `system-images;android-34;google_apis;x86_64` | 14 |

## 3. Exact environment variables required (for whoever runs this next)

```
export ANDROID_HOME=/usr/local/share/android-commandlinetools
export ANDROID_SDK_ROOT=/usr/local/share/android-commandlinetools
export JAVA_HOME=/usr/local/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

Plus the one-time `flutter config --android-sdk "$ANDROID_HOME"` to persist the SDK path in Flutter's own config (`~/.flutter_config`-equivalent), so subsequent `flutter` invocations don't need `ANDROID_HOME` re-exported every session (though `JAVA_HOME` still should be, since Flutter's own Java discovery prefers it).

## 4. Emulator status

An x86_64 system image (`system-images;android-34;google_apis;x86_64`, matching this sandbox's Intel/`x86_64` host architecture — confirmed via `uname -m`) and the `emulator` package were installed successfully. **No AVD (emulator instance) had been created or booted yet at report time** — creating one (`avdmanager create avd ...`) and booting it (`emulator -avd ...`) is a straightforward next step using the now-installed tooling, but was not reached before this document was written given the build itself was still the priority in-flight task. This is recorded as **not yet done**, not blocked.

## 5. What "Android readiness" now means, precisely

- **Provisioning**: done, real, verified on disk.
- **`flutter doctor`'s own Android section**: does not cleanly pass (internal timeout) — this should be re-attempted in a follow-up session with a longer timeout or by investigating which specific sub-probe it's timing out on, since it's inconsistent with the SDK components being genuinely present and a real Gradle build genuinely progressing.
- **A real debug APK build**: in progress, not yet confirmed complete/passing at the time this document was written.
- **Emulator boot, install, launch, smoke test, unit/widget/integration test execution on Android, permission/lifecycle checks, startup CPU/memory observation, APK static inspection**: **none of these have been executed yet** — each requires the debug build (or a subsequent release-equivalent build) to finish first, and each is a distinct step that must be run and inspected before being reported as passing. Per the sprint's own instruction, these are classified as **not yet executed**, not as passing, until each one actually runs and its output is read.

## 6. New finding surfaced by this provisioning work

**HYD-BUILD-006 — Project's Gradle/AGP/Kotlin versions are below Flutter's current recommended minimums**
- **Severity**: Low | **Confidence**: Confirmed (real build-log warnings, not inferred)
- **Evidence**: live `flutter build apk` output: "Flutter support for your project's Gradle version (8.12.0) will soon be dropped... upgrade to at least 8.14.0"; "...Android Gradle Plugin version 8.9.1... upgrade to at least Android Gradle Plugin version 8.11.1"; "...Kotlin version (2.1.0)... upgrade to at least 2.2.20."
- **Impact**: not yet build-breaking (the build proceeded past these as warnings), but these are the project's own stated deprecation-path versions — Flutter's own tooling is explicitly warning they will stop being supported. This is a real, time-sensitive maintenance item independent of anything else in this sprint.
- **Recommended correction**: schedule a Gradle wrapper / AGP / Kotlin version bump (`android/gradle/wrapper/gradle-wrapper.properties`, the AGP version in `android/settings.gradle`'s plugins block, and the Kotlin plugin version) — coordinate with a full `flutter test` + Android build re-run afterward, since these bumps can introduce build breaks independent of Hydrion's own code.
- **Standard**: n/a (SDLC/tooling currency).

## 7. What remains to fill in (do not mark any of these as passing without doing them and reading the actual result)

- [ ] `flutter build apk --debug` — exact exit code and final output.
- [ ] `flutter build apk --release` where signing permits (per `AUDIT_REPORT.md` HYD-CI-002, CI's ephemeral-signing pattern can be reused locally for a smoke-test release build without touching real production signing material).
- [ ] Create and boot an AVD from the now-installed `system-images;android-34;google_apis;x86_64`.
- [ ] Clean install of the built APK onto the booted AVD (`adb install`).
- [ ] Cold launch and warm launch timing/observation — this is the Android-side counterpart to the iOS `IOS_STARTUP_INVESTIGATION.md` work in this same sprint; run the same instrumentation added to `lib/main.dart` this sprint and capture the `HYDRION_STARTUP`/gate-by-gate trace via `adb logcat`.
- [ ] Critical smoke journey (onboarding → log water → view analytics) on the emulator.
- [ ] `flutter test integration_test/android_notification_delivery_test.dart` against the booted emulator — this is the one Android-specific `integration_test` file that already exists in the repo and has never been run against a real Android target until an emulator exists.
- [ ] Permission/lifecycle checks from `tester_bible.md` §4/§10/§11 (Android-specific rows).
- [ ] Startup CPU/memory observation via `adb shell dumpsys meminfo` / a basic `top`-style sample during launch.
- [ ] APK static inspection: `apkanalyzer` (now installed) against the built debug APK for size/manifest/permission sanity, and `dart run tool/validate_android_release.dart --apk <path>` (this tool exists in the repo and was previously blocked purely for lack of an APK to point it at — it can now actually run).
- [ ] Security checks: confirm `allowBackup=false` and `usesCleartextTraffic=false` survive into the actual built manifest (`aapt dump badging` or `apkanalyzer manifest print`), rather than relying on source-level reading alone.

**None of the above should be reported as "passed" in any later document until each is actually run and its real output is recorded here or in `SPRINT_1_VALIDATION_REPORT.md`.**
