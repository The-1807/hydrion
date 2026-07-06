# Hydrion Pre-Push Hardening Report

Status: completed local pass on July 6, 2026. No release was published.

## 1. Files Inspected

- Prompt/context: `iOS_Apk_Ui.pdf`, the supplied continuation prompt, `pubspec.yaml`, `codemagic.yaml`, `.github/workflows/flutter-ci.yml`.
- Runtime code: `lib/main.dart`, `lib/domain/avatar_manifest.dart`, `lib/domain/ui_asset_manifest.dart`, `lib/domain/release_metadata.dart`, `lib/domain/legal_document_registry.dart`, `lib/repositories/settings_repository.dart`, `lib/services/weather_goal_service.dart`, `lib/services/location_service.dart`, `lib/services/notifications.dart`, `lib/ui/components/intake_ring.dart`, `lib/ui/components/hydrion_logo.dart`, `lib/ui/screens/home_screen.dart`, `lib/ui/screens/analytics_screen.dart`, `lib/ui/screens/legal_about_screen.dart`, `lib/ui/screens/onboarding_screen.dart`, `lib/ui/screens/profile_screen.dart`, `lib/ui/screens/settings_screen.dart`, `lib/ui/screens/social_challenges_screen.dart`, `lib/ui/screens/startup_screen.dart`.
- Platform/build: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt`, `ios/Runner/Info.plist`, `ios/Runner/PrivacyInfo.xcprivacy`, `ios/Podfile`.
- Tests: all files under `test/`, with focused edits listed below.
- Legal/docs: `docs/Hydrion_Legal_Pack_Markdown/*.md`, `docs/ASSET_MAPPING.md`, `docs/LEGAL_IMPLEMENTATION_AUDIT.md`, `docs/V1_RELEASE_READINESS.md`, `docs/CODEMAGIC_SETUP.md`, architecture docs that referenced the app icon.
- Assets: all runtime files under `assets/` and moved originals under `assets_source_original/assets/`.

## 2. Files Changed, Added, Moved, Converted, Or Removed

Changed code:

- `lib/domain/avatar_manifest.dart`
- `lib/domain/release_metadata.dart`
- `lib/domain/ui_asset_manifest.dart`
- `lib/services/weather_goal_service.dart`
- `lib/ui/components/hydrion_logo.dart`
- `lib/ui/components/intake_ring.dart`
- `lib/ui/screens/analytics_screen.dart`
- `lib/ui/screens/home_screen.dart`
- `lib/ui/screens/legal_about_screen.dart`
- `lib/ui/screens/onboarding_screen.dart`
- `lib/ui/screens/profile_screen.dart`
- `lib/ui/screens/settings_screen.dart`
- `lib/ui/screens/social_challenges_screen.dart`
- `lib/ui/screens/startup_screen.dart`
- `pubspec.yaml`

Changed tests:

- `test/adapter_contract_test.dart`
- `test/legal_document_test.dart`
- `test/product_qa_test.dart`
- `test/runtime_ux_test.dart`
- `test/startup_onboarding_test.dart`
- `test/v1_release_scope_test.dart`
- `test/weather_location_goal_test.dart`

Added tests:

- `test/asset_registry_test.dart`
- `test/hydration_progress_gauge_test.dart`
- `test/profile_lifestyle_art_test.dart`
- `test/responsive_layout_test.dart`

Changed docs:

- `docs/ASSET_MAPPING.md`
- `docs/CODEMAGIC_SETUP.md`
- `docs/Hydrion_Legal_Pack_Markdown/01_PRIVACY_POLICY.md`
- `docs/Hydrion_Legal_Pack_Markdown/02_TERMS_OF_USE.md`
- `docs/Hydrion_Legal_Pack_Markdown/03_HEALTH_AND_WELLNESS_DISCLAIMER.md`
- `docs/LEGAL_IMPLEMENTATION_AUDIT.md`
- `docs/V1_RELEASE_READINESS.md`
- `docs/architecture/AI_ACTION_CONTRACT.md`
- `docs/architecture/STALE_SCAFFOLD_AUDIT.md`
- `docs/architecture/may5th.md`

Added docs:

- `docs/ASSET_OPTIMIZATION_REPORT.md`
- `docs/RESPONSIVE_UI_AUDIT.md`
- `docs/WEATHER_PERMISSION_FLOW.md`
- `docs/PRE_PUSH_HARDENING_REPORT.md`

Converted runtime assets:

- All `assets/UI_BETA/*.png` lifestyle images were converted to optimized `.jpg` derivatives.
- `assets/icons/icon1807.png` was converted to `assets/icons/icon1807.jpg`.
- `assets/pfp_mascot/hydrion_mascot.png` was converted to `assets/pfp_mascot/hydrion_mascot.jpg`.
- Human profile-avatar JPG derivatives were moved out of runtime to `assets_source_original/removed_runtime_assets/assets/pfp_mascot/hpfp/`.
- All `assets/pfp_mascot/pfp/*.png` shark profile images were converted to optimized `.jpg` derivatives.

Moved out of runtime bundle:

- Original PNGs and `assets/pfp_mascot/pfp/1000064425.mp4` are preserved under `assets_source_original/assets/...`.
- Removed human profile-avatar JPG derivatives are preserved under `assets_source_original/removed_runtime_assets/...`.

Removed from runtime declarations:

- Old PNG paths.
- `assets/pfp_mascot/pfp/1000064425.mp4`.
- `assets/pfp_mascot/hpfp/`.

## 3. Character-Selection Mapping Implemented

Automatic lifestyle-art selection is centralized in `HydrionLifestyleArtResolver`.

- Male: male mapped scenes.
- Female: female mapped scenes.
- Intersex: neutral/default scenes.
- Prefer not to say: neutral/default scenes.
- Missing/null: neutral/default scenes.

Hydrion does not infer sex or gender from nickname, avatar, profile image, device information, location, behavior, or previous artwork. Manual avatar selection remains independent.

## 4. Hydration Gauge Behavior Implemented

Home now uses `HydrationProgressGauge`, a Hydrion-native segmented semi-circular gauge. It shows percent, intake/goal, selected units, safe status text, theme-aware colors, semantics, and over-goal clamping. Over-goal intake shows actual numbers but clamps the visible arc at 100 percent and uses restrained copy.

## 5. Coming Soon Features Discovered

- Connected Devices when BLE/wearable capabilities are unavailable.
- Social sync when capability is unavailable.
- Social Challenges hero marks social sync Coming Soon while local challenges remain usable.

These controls explain availability and do not navigate into incomplete screens.

## 6. Permission-Flow Changes

- Weather setup explains approximate foreground location and Open-Meteo before live lookup.
- Location is requested only at point of use.
- Notification permission is requested from reminder/notification flows.
- Notification denial does not block weather lookup, in-app recommendation, manual goal mode, or manual logging.
- Selecting Weather Mode now starts the location and forecast setup flow immediately; failures leave the mode manual and show an explanation.

## 7. Legal-Opening Gate Behavior

- Terms checkbox requires opening Terms first.
- Health checkbox requires opening Health and Safety Disclaimer first.
- Privacy must be opened before the legal review can complete.
- Alpha/beta builds require Alpha and Beta Testing Notice opening.
- Opening a document does not check a box and does not record acceptance.
- Legal viewer route has an immediate shell key for stable testing and asynchronous Markdown loading.

## 8. Alpha And Production Validation Copy

- Alpha/beta: `fahhhhhhh!!! open legal pack`
- Production/stable: `Open the required legal document before continuing.`

Both are controlled by `HydrionReleaseMetadata`.

## 9. Responsive-Layout Corrections

- Startup was made scrollable and constrained for short/landscape screens.
- Home gauge and quick logging remain reachable on compact screens.
- Legal viewer/review and settings permission dialogs use safe areas, scrollable content, and readable max widths.
- Legal document Markdown typography is restrained for mobile reading.

## 10. Assets Optimized

Runtime image derivatives are JPG because original PNGs were RGB and did not require alpha. See `docs/ASSET_OPTIMIZATION_REPORT.md` for dimensions and largest-file tables.

## 11. Assets Removed From Runtime Bundle

- All original PNG runtime files.
- `assets/pfp_mascot/pfp/1000064425.mp4`.
- `assets/pfp_mascot/hpfp/*.jpg` generated human profile defaults.

Originals remain in `assets_source_original/assets/...`.

## 12. Before And After Asset Totals

- Before runtime assets: 44 files, 76,702,320 bytes.
- After runtime assets: 21 runtime-declared files, 1,790,496 bytes.
- Reduction: 74,911,824 bytes, 97.67%.

## 13. Before And After Measured Build Sizes

- Web release before: not measured before asset conversion.
- Web release after: 64 files, 35,428,770 bytes under `build/web`.
- Release APK before/after: not measured locally because this machine has no Android SDK.

## 14. Tests Added Or Updated

Added: asset registry, hydration gauge, profile lifestyle art, responsive layout.

Updated: legal document, startup onboarding, weather/location goal, runtime UX, product QA, adapter contract, v1 release scope.

## 15. Exact Test Count

`flutter test` passed 206 tests.

## 16. Commands Executed

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `dart run tool\secret_scan.dart`
- `flutter analyze`
- `flutter test`
- focused `flutter test` batches
- `flutter build web --release`
- PowerShell asset inventory/dimension/size audit
- stale runtime asset reference scan
- user-facing legal placeholder scan
- `python -c "import yaml; yaml.safe_load(...)"` for `codemagic.yaml`
- `flutter build apk --release`
- `flutter doctor -v`

## 17. Build Results

- Web release build succeeded.
- Android release build did not run locally because no Android SDK is installed.
- Android CI now runs `tool/android_size_audit.dart` and publishes `hydrion-android-size-audit.txt`.

## 18. Commands Blocked By Environment

- `flutter build apk --release`: blocked by missing Android SDK/`ANDROID_HOME`.
- Local APK size analysis: blocked by missing Android SDK/`ANDROID_HOME`.
- Local iOS device/IPA build: not supported on this Windows host.

## 19. Remaining Codemagic Or Device Validation

- Codemagic must run Android and iOS workflows to validate APK/AAB/IPA artifacts.
- Real Android install testing is still required for release APK artifacts.
- Real iOS testing is still required for signed IPA/TestFlight preparation.
- Real-device permission dialogs, notification delivery, weather lookup, and install/update behavior remain manual validation items.

## 20. Known Limitations

- Legal copy remains owner/legal-review required.
- Public privacy-policy and support URLs are still owner actions.
- Production signing secrets are not present locally.
- Social sync remains local-only/Coming Soon.
- Connected Devices remains roadmap-only; no Bluetooth or Health permission is requested.
- Web/APK before-size deltas must not be claimed retroactively because pre-optimization builds were not measured.
