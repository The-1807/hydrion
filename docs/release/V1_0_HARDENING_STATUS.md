# Hydrion V1.0 hardening status

Date: 2026-07-15

Status: **PARTIALLY COMPLETE WITH DOCUMENTED BLOCKERS**

## Release protection

This work is isolated on `codex/v1.0-hardening`. It does not publish, move a
tag, change a release, modify `main`, or alter the Android application ID.
The existing tester release and its artifact remain immutable. A new candidate
must use a new tag after all manual gates pass.

The product version remains `1.0.0`; the candidate build number is now `2`.
The application ID remains `com.the1807.hydrion`.

Signing continuity is not verified. `android/app/build.gradle.kts` loads the
release identity from ignored `android/key.properties` when available, but the
original tester APK and production signing material are unavailable here.
Do not claim update compatibility until an update-install test succeeds.

## Architecture and data flow

The shared local repositories are provided once at application bootstrap.
Hydration records are stored as JSON in SharedPreferences under
`hydrion.hydration_logs.v1`. Home, history/log, analytics, achievements,
context, and challenge progress derive their values from `HydrationRepository`.

The authoritative flow is:

```text
User action
-> explicit amount
-> validation in canonical command/repository
-> canonical millilitre value
-> HydrationRepository.addLog
-> persisted HydrationLog (source + optional actionId)
-> local-day aggregation
-> challenge evaluation
-> achievement/score and analytics derivation
-> ChangeNotifier UI refresh
```

Bottle Bingo hydration tiles use this path and store a normal hydration record.
Non-hydration Bingo tasks remain explicit check-ins and do not claim water.
Challenge-qualified intake (water before lunch) is intentionally distinct from
total daily hydration.

## Correctness changes in this pass

- Added stable persisted action identifiers and repository duplicate detection.
- Added in-flight guards for rapid/retried Bottle Bingo hydration actions.
- Roll back in-memory hydration when persistence fails.
- Roll back challenge state when challenge persistence fails.
- Remove a just-created hydration record if challenge progress cannot persist.
- Home and Bottle Bingo show a retryable error instead of false success.
- Home quick-add uses explicit `quick-add` origin metadata.
- Preserved local calendar-day aggregation and historical records.

## Audit decisions

- Weather remains active because the existing Open-Meteo path is bounded,
  explainable, cached, permission-aware, and tested not to block manual logging.
- The existing single reusable-container size is retained. Full multi-preset
  CRUD and legacy migration are not implemented and remain a release gap.
- Theme architecture already supports application theme behavior, but the full
  system/light/dark persistence acceptance matrix was not completed here.
- Coaching is intentionally exposed as a non-interactive future-update notice;
  dynamic coaching is therefore not release-ready.

## Validation evidence

| Command | Result |
|---|---|
| `flutter --version` | Flutter 3.35.6, Dart 3.9.2 |
| `java -version` | Java 25.0.1 LTS |
| `flutter pub get` | Pass (34 constrained updates reported) |
| `dart format --output=none --set-exit-if-changed .` | Baseline pass, 96 files, 0 changed |
| `flutter analyze` | Pass, no issues |
| `flutter test` (baseline) | Pass, 212 tests |
| Focused persistence and V1 scope tests | Pass, 25 tests |
| `flutter build web --release` | Pass |
| `flutter build apk --release` | Blocked: Android SDK not installed |
| `flutter build appbundle --release` | Blocked: Android SDK not installed |

## Release gate matrix

| Capability | Implementation / test status | Android | Web | Release decision | Limitation / evidence |
|---|---|---|---|---|---|
| Manual and quick logging | Shared repository; automated tests pass | Build blocked | Built | Ship after Android gates | APK not produced here |
| Bottle Bingo hydration | Canonical log, explicit amount, idempotent; tests pass | Build blocked | Built | Ship after Android gates | Device smoke test pending |
| Daily totals/history/analytics | Shared logs and local-day totals; tests pass | Build blocked | Built | Ship after Android gates | Midnight live-screen timer not proven |
| Streaks/scores | Derived achievement logic tested | Build blocked | Built | Ship with limitation | Full product matrix incomplete |
| Container | One local persisted size | Build blocked | Built | Ship with limitation | Multi-preset CRUD/migration deferred |
| Units | Shared formatter exists; partial tests pass | Build blocked | Built | Ship with limitation | Whole-app unit audit incomplete |
| Notifications | Repository/service tests pass | Build blocked | Platform-limited | Ship with limitation | Real-device delivery pending |
| Weather | Bounded/cached/fallback tests pass | Build blocked | Built | Ship with limitation | Permission/device validation pending |
| Coaching | Static future-update notice | N/A | N/A | Hidden/deferred | Dynamic policy not shipped |
| Theme | Existing theme coverage partial | Build blocked | Built | Ship with limitation | Persistence matrix incomplete |
| Persistence/migration | Existing-data recovery tests pass | Build blocked | Built | Ship after upgrade test | Tester-APK upgrade not executed |
| Startup/onboarding/legal | Automated tests pass | Build blocked | Built | Ship after Android smoke | Owner legal approval pending |
| APK/AAB | Not built | Blocked | N/A | Blocked | Android SDK unavailable |
| Web artifact | Release build produced | N/A | Pass | Ship candidate | Browser smoke still manual |
| iOS | Not compiled | N/A | N/A | Blocked | macOS/Xcode unavailable |
| BLE/health/accounts/cloud sync | Not in V1.0 | Excluded | Excluded | Excluded | Post-V1.0 scope |

## Manual release blockers

1. Install the immutable tester APK, seed all V1.0 data, then install the
   signed `1.0.0+2` candidate over it and verify data preservation.
2. Verify the candidate certificate matches the tester APK certificate.
3. Build APK and AAB with the Android SDK and production signing environment.
4. Run clean-install Android smoke tests on a supported small device/emulator.
5. Complete container-preset, unit-consistency, theme-persistence, dynamic
   coaching, and live-midnight acceptance work or explicitly hide/defer it.
6. Obtain product-owner legal and final release approval.

No GitHub release or tag was created or changed by this pass.
