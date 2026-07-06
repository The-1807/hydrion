# Hydrion iOS Readiness

Status: repository-ready for compatibility review; App Store release still
requires Apple Developer account configuration, signing, provisioning, and
manual device validation.

## Bundle And Display Metadata

- Bundle identifier: `com.the1807.hydrion`
- Runner test bundle identifier: `com.the1807.hydrion.RunnerTests`
- Display name: `Hydrion`
- Flutter version pinned in CI/Codemagic: `3.35.6`
- iOS deployment target in `ios/Podfile`: `13.0`

The bundle id is now aligned with the Android package identity. Changing this
after a shipped App Store build would create a different iOS app identity.

## Native Plugin Readiness

Hydrion uses plugins that require iOS CocoaPods integration:

- `image_picker` for local profile-photo selection
- `geolocator` for optional foreground weather-location lookup
- `flutter_local_notifications` for notification abstractions where platform
  support is available
- `shared_preferences` through Flutter plugin registration

`ios/Podfile` has been added using the standard Flutter pod helper flow. Run
`flutter pub get` before `pod install` or iOS builds so `Generated.xcconfig`
exists.

## Info.plist Permissions

Hydrion declares:

- `NSLocationWhenInUseUsageDescription` for weather-informed goals. The app
  does not request background location.
- `NSPhotoLibraryUsageDescription` for selecting a local profile photo. Hydrion
  stores the selected photo locally in app settings and lets users remove it.

No camera, microphone, Bluetooth, HealthKit, tracking, or background-location
usage string is declared because those features are not active in this build.

## Privacy Manifest

`ios/Runner/PrivacyInfo.xcprivacy` declares no tracking domains and declares
coarse location for app functionality. This reflects the optional weather flow:
Hydrion can send rounded foreground coordinates to Open-Meteo for a forecast
request while avoiding tracking and location history storage.

If future SDKs or Hydrion features collect, track, or access required-reason API
categories, this manifest must be updated before submission.

## Codemagic iOS Path

Codemagic is the primary Apple-compatible CI/CD path:

- `hydrion-ios-compatibility` runs validation, CocoaPods install, simulator
  build, and unsigned release compilation.
- `hydrion-ios-signed-testflight-prep` is gated by
  `HYDRION_SIGNED_IOS_ENABLED=true` and produces
  `hydrion-ios-production-signed-release.ipa` only when Apple credentials are
  configured.

No TestFlight upload or public App Store release is performed automatically.

## Manual iOS Validation

Run these on a real iPhone or iOS simulator before claiming iOS release
readiness:

- `flutter pub get`
- `cd ios && pod install`
- `flutter build ios --simulator`
- `flutter build ios --release --no-codesign`
- Clean install launch and startup flow
- Onboarding safe-area layout on small and notched devices
- Profile photo choose, save, remove, and fallback avatar behavior
- Weather-mode location permission prompt, denial, settings route, and fallback
- Notification permission copy and reminder behavior on the target iOS version
- Local persistence after restart
- About & Legal hub, Markdown document viewer, acceptance migration, and support
  contact
- VoiceOver traversal for Home progress, Bottle Bingo, Profile, and Settings

## Remaining Release Work

- Apple team id, provisioning profiles, signing certificates, and App Store
  Connect metadata are not stored in this repository.
- Public privacy-policy URL and support URL are not verified.
- App Store privacy questionnaire answers need owner/legal review.
- Real-device notification delivery and permission behavior must be verified.
- Legal copy is implementation-aligned draft text and requires qualified legal
  review before public release.
