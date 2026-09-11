# Hydrion — Device / OS Matrix

## What was actually verified in this audit's environment

| Platform | Tool/Device | Result |
|---|---|---|
| macOS (desktop, this sandbox) | Flutter 3.44.9 | `flutter test`, `flutter analyze`, `dart format` all run natively — verified |
| iOS Simulator | iPhone 16 Pro, iOS 18.3 (booted via `xcrun simctl`) | App **built, installed, and launched** — verified live (see `AUDIT_REPORT.md` §4/§6.4). Did not confirm normal startup completion (HYD-BLOCK-004, open) |
| iOS Simulator | iPhone 16 Pro Max, 16e, 16, 16 Plus, SE (3rd gen), iPad Pro 11"/13" (M4), iPad (A16), iPad Air 11"/13" (M2/M3), iPad mini (A17 Pro), iPad (10th gen) — all iOS 18.3 | **Available in this environment but not exercised** (only one device was used for the live-launch check) |
| Android (any) | — | **Completely unavailable in this environment** — no Android SDK installed, `flutter doctor` reports "Unable to locate Android SDK," no `adb`, no emulator (`emulator -list-avds` → command not found) |
| Web (Chrome) | — | `flutter build web --release` succeeds; **no Chrome executable present** to actually run/interact with it |
| Physical devices (any) | — | None connected to this environment |

**This means: everything Android-specific in `tester_bible.md` (§4 TC-PERM-005, §11 TC-KILL-001/002, §12 TC-NOTIF-002, §26 all of TC-AND-*, and every Android row below) is completely unverified by this audit and requires a real Android SDK/emulator/device environment before it can even be attempted.**

## Recommended target matrix for the testing team (not independently verified here — a proposal based on typical Flutter app support windows and this app's actual `minSdkVersion`/iOS deployment target, which should be read directly from `android/app/build.gradle.kts` and `ios/Runner.xcodeproj` before finalizing)

| Tier | Android | iOS |
|---|---|---|
| **Must-test (P0 smoke)** | Minimum supported SDK version (read from `build.gradle.kts`), and latest stable Android version, both on a mainstream OEM (Pixel or Samsung) | Minimum supported deployment target, and latest stable iOS (18.3 confirmed available in this environment) |
| **Should-test (P1)** | One mid-range OEM device with a heavily customized OS skin (e.g. Samsung One UI, Xiaomi MIUI) — these are the most common source of notification/background-execution divergence from stock Android | iPad (large-screen layout, TC-RESP-003) |
| **Nice-to-test (P2)** | A foldable (large-screen layout) | Older iPhone SE-class device (small screen) |
| **Explicitly deprioritized** | Android tablets, unless product scope changes | macOS Catalyst / visionOS — not in current product scope per `docs/release/HYDRION_V1_KNOWN_LIMITATIONS.md` |

## OS-version-specific behaviors to explicitly track

- **Android 12+ (API 31+)**: exact-alarm scheduling (`SCHEDULE_EXACT_ALARM`) behavior for reminders — TC-AND-001. Also the API 26+ `.setTimeoutAfter()` notification backstop (HYD-PERF-003) only applies from Android 8.0 (API 26) onward — devices below that have **no** timeout backstop for either the running or paused timed-session notification state; this should be a separate, lower-bound test case once a minimum-SDK device is available.
- **Android 13+ (API 33+)**: runtime `POST_NOTIFICATIONS` permission prompt behavior (already declared in manifest) — TC-PERM-002.
- **iOS 17+**: privacy-manifest (`PrivacyInfo.xcprivacy`) enforcement is an active App Store submission gate — TC-IOS-002 / HYD-SEC-002 is not optional on any iOS 17+ submission.
- **iOS with reduced-data/Low Power Mode**: not assessed in this audit; add as a new test case once device access exists (relevant to TC-RES-003 and the weather-polling behavior in `weather_goal_service.dart`).

## Owner decisions needed before this matrix can be finalized

1. What is the actual `minSdkVersion`/iOS deployment target committed in `android/app/build.gradle.kts`/`ios/Runner.xcodeproj`? (Not independently re-extracted in this pass — read directly before publishing a final matrix.)
2. Does the product intend to support tablets/foldables in the near term, or is TC-RESP-003 purely defensive?
3. Is there a real Android device or CI runner with Android SDK access the team can point this testing effort at, given this audit's environment had none?
