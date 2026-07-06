# Hydrion Corrective Pass Report

Status: completed on July 6, 2026.

## Product Corrections

- Weather Mode setup now starts when the user selects Weather in Settings. It
  requests/checks location, fetches today's forecast, shows forecast details and
  the bounded goal adjustment, and enables Weather Mode only on success.
- Notification permission remains independent from Weather Mode.
- Legal Markdown typography is restrained for mobile reading.
- Startup no longer waits on a fixed splash duration; it routes after real
  warmup completes and the current frame boundary is reached.
- AR route, screen, capability, localization keys, roadmap card, tests, docs,
  and placeholder asset `.gitkeep` were removed.
- Connected Devices Coming Soon replaced AR-facing roadmap surfaces. It stays
  permission-free and explicitly avoids Bluetooth scans, bottle connections,
  HealthKit/Google Fit reads, wearable reads, and fake device data.
- Generated human profile-avatar JPGs were moved out of runtime to
  `assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp/`.
  Saved removed human avatar ids migrate to `savvy-eco_shark`.

## Retained References

- `hydrion-human-*` ids remain only as migration keys and tests for migration.
- Human source images remain in `assets_source_original/...` for owner/design
  review, outside the runtime bundle.
- `AR` text remains only as a substring inside words/paths such as
  `Architecture` and `docs/architecture`.

## Size And CI

- Runtime-declared image assets: 21 files, 1,790,496 bytes.
- Web release build: 64 files, 35,428,770 bytes under `build/web`.
- Codemagic now builds split-per-ABI release APKs where Flutter produces them.
- `tool/android_size_audit.dart` writes `hydrion-android-size-audit.txt` with
  runtime asset totals, APK/AAB file sizes, grouped zip contents when `unzip` is
  available, and largest entries.

## Validation

- `dart format --set-exit-if-changed .`
- `dart run tool/secret_scan.dart`
- `flutter analyze`
- `flutter test` - 208 tests passed
- `dart run tool/android_size_audit.dart --output build/android-size-audit-smoke.txt build`
- `flutter build web --release`

Local Android APK/AAB builds were not attempted because `ANDROID_HOME` and
`ANDROID_SDK_ROOT` are not set on this machine.
