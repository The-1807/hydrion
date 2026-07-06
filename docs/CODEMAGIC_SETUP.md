# Hydrion Codemagic Setup

Status: configured in repository; owner credentials still required for signed distribution.

Hydrion uses `codemagic.yaml` as its primary Apple-compatible CI/CD entry point. GitHub Actions remains Linux-only validation and Android/web build support. No duplicate GitHub macOS iOS workflow was added.

## Workflows

### `hydrion-validation`

Runs on Linux with Flutter `3.35.6`.

Commands:

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `dart run tool/secret_scan.dart`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

Artifacts:

- `codemagic-artifacts/validation/**`
- `build/web/**`

### `hydrion-android`

Runs on Linux with Flutter `3.35.6`.

Artifacts:

- `hydrion-android-debug-smoke.apk`
- `hydrion-android-ci-ephemeral-signed-release.apk` when production signing secrets are absent
- `hydrion-android-production-signed-release.apk` when production signing secrets are present
- `hydrion-android-production-signed-release.aab` when production signing secrets are present
- `apksigner-release.log`

The ephemeral APK is for clean install testing only. It is not suitable for Play Store upload or update-path testing because the key can change.

Protected Android variables required for production signing:

- `HYDRION_ANDROID_KEYSTORE_BASE64`
- `HYDRION_ANDROID_KEYSTORE_PASSWORD`
- `HYDRION_ANDROID_KEY_ALIAS`
- `HYDRION_ANDROID_KEY_PASSWORD`

All four must be present together.

### `hydrion-ios-compatibility`

Runs on Codemagic macOS with Flutter `3.35.6`, latest Xcode, and CocoaPods.

Commands include validation, `pod install`, iOS simulator build, and unsigned iOS release build.

Artifacts:

- `hydrion-ios-simulator-compatibility.app.zip`
- `flutter-build-ios-simulator.log`
- `flutter-build-ios-release-nocodesign.log`
- `pod-install.log`

Unsigned output is only for compilation compatibility. It is not installable on a physical iPhone.

### `hydrion-ios-signed-testflight-prep`

Runs on Codemagic macOS. This workflow is intentionally gated.

Gate:

- `HYDRION_SIGNED_IOS_ENABLED=true`

Bundle identifier:

- `com.the1807.hydrion`

Artifact:

- `hydrion-ios-production-signed-release.ipa`

This workflow prepares a signed IPA. It does not publish automatically to TestFlight or the public App Store.

## Apple Configuration Still Required

The owner must configure these in Codemagic or Apple Developer systems before the signed iOS workflow can pass:

- Apple Developer Program membership;
- App Store Connect API integration available to Codemagic;
- bundle identifier `com.the1807.hydrion`;
- App Store distribution certificate;
- provisioning profile for `com.the1807.hydrion`;
- Apple team selection inside Codemagic signing integration;
- App Store Connect app record if TestFlight upload is later enabled;
- `HYDRION_SIGNED_IOS_ENABLED=true` in a protected Codemagic environment.

Do not add a Team ID, Issuer ID, Key ID, profile name, certificate, or App Store app id to the repository unless the owner supplies verified values and approves storing the non-secret identifier.

## Publishing

Codemagic publishing is not enabled in `codemagic.yaml`.

If the owner later wants TestFlight upload from Codemagic, add a protected, manually approved publishing block after confirming App Store Connect integration and release governance.

Official Codemagic docs used for this setup:

- https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/
- https://docs.codemagic.io/yaml-code-signing/ios-code-signing/
- https://docs.codemagic.io/yaml-publishing/app-store-connect/
