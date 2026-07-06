# Hydrion v1.0.0 Release Readiness Notes

Status: draft, owner review required. This document records implemented release
work and remaining validation needs. It does not approve public release.

## Location Behavior

Hydrion does not request location permission on cold launch. Weather-informed
goals request foreground location only after the user enables weather mode and
uses a contextual permission action or is otherwise eligible for the daily flow.
The Android manifest requests `ACCESS_COARSE_LOCATION` only. Hydrion does not
request background location and does not continuously track location.

Coordinates are held only for the current forecast lookup and are not written to
the Hydrion local store, logs, or diagnostics.

## Weather Provider Setup

The v1 provider is Open-Meteo. It does not require a Hydrion API key. No weather
secret should be committed. The app requests a daily maximum temperature,
current humidity when available, broad condition, retrieval timestamp, and
provider identity.

Forecast calls use the selected provider only after location permission is
granted. If a future provider requires an API key, configure it through
repository-standard environment or secure build configuration and keep real
secrets out of source control.

## Forecast Caching

Hydrion caches only the minimum daily forecast summary for the current local
day. It does not store latitude or longitude. Same-day cache reuse avoids
unnecessary repeat provider requests. The next local day refreshes the provider.
If a provider fails and only stale cache exists, Hydrion reports the fallback
state and does not treat the result as a fresh successful forecast.

## Recommendation Formula

Weather goals are deterministic and conservative:

`recommended goal = user-approved baseline + bounded weather adjustment + optional user adjustment`

Temperature, humidity, and UV adjustments are bounded, rounded to useful
increments, and clamped to Hydrion's safety guardrails. Age and sex are
eligibility/profile inputs only; they are not used to invent medical precision.
Hydrion never forces drinking and does not reward excessive intake.

## Daily Prompt

The daily prompt appears only when eligibility is complete:

- onboarding completed
- age provided
- explicit sex option other than "Prefer not to say"
- weather goal mode enabled
- current Terms acceptance and Health/Safety acknowledgement recorded
- location permission granted
- notification permission granted
- weather provider configured
- forecast retrieved successfully

The prompt shows the recommendation, baseline, weather summary, adjustment,
plain-language explanation, safety note, and actions to use the recommendation,
adjust settings, or keep the previous goal. The user can disable daily
confirmation and restore it later in Settings.

Hydrion does not show the prompt repeatedly on the same local day and does not
silently replace a manually edited same-day goal.

## Notification Scheduling

Hydrion uses `flutter_local_notifications` for Android local notifications.
Reminder creation, edit/reschedule, delete/cancel, duplicate prevention, and
restart reconciliation are implemented through a notification abstraction.

The app requests `POST_NOTIFICATIONS` only from contextual reminder/weather
permission actions. It uses inexact scheduling and does not request exact alarm
permission. Android delivery can still be affected by permission denial, Do Not
Disturb, reboot behavior, timezone changes, OEM battery policy, and user
notification-channel settings.

## Android Permissions

Current main manifest permissions:

- `INTERNET` for weather provider calls
- `ACCESS_COARSE_LOCATION` for approximate foreground weather lookup
- `POST_NOTIFICATIONS` for Android 13+ local notification permission
- `RECEIVE_BOOT_COMPLETED` for notification reschedule receiver support

No background location, fine location, camera, microphone, Bluetooth, health,
remote push, or exact-alarm permission is requested for v1.

## Android Application ID

Current namespace and application id are `com.the1807.hydrion`, matching the
package identity requested in the iOS/APK/UI corrective prompt. Changing the
application id again would create a different Android app identity and affects
update paths from existing local installs.

If a tester previously installed an APK using `com.example.hydrion_app`, they
should uninstall that build before installing the new package identity.

## Release Signing

Release builds no longer sign with the debug key. If `android/key.properties`
exists locally, Gradle reads:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

Do not commit `key.properties`, keystores, `.jks`, passwords, or CI secrets.
CI uploads a debug-signed APK for ad hoc phone smoke testing. CI uploads a
signed release APK only when protected repository secrets provide:

- `HYDRION_ANDROID_KEYSTORE_BASE64`
- `HYDRION_ANDROID_KEYSTORE_PASSWORD`
- `HYDRION_ANDROID_KEY_ALIAS`
- `HYDRION_ANDROID_KEY_PASSWORD`

Without those credentials, CI generates an ephemeral CI-signed release APK so a
clean install can be tested on a phone. That artifact is intentionally named
`hydrion-android-ci-ephemeral-signed-release-apk-*`. It is not suitable for
store upload or reliable update testing because each run can use a different
signing key. Configure the protected secrets above for production signing.

CI must not upload an unsigned release APK as an installable phone artifact.

## Codemagic CI/CD

Hydrion now includes `codemagic.yaml` as the primary Apple-compatible CI/CD
configuration. Workflows:

- `hydrion-validation`
- `hydrion-android`
- `hydrion-ios-compatibility`
- `hydrion-ios-signed-testflight-prep`

Important artifact names:

- `hydrion-android-debug-smoke.apk`
- `hydrion-android-ci-ephemeral-signed-release.apk`
- `hydrion-android-production-signed-release.apk`
- `hydrion-android-production-signed-release.aab`
- `hydrion-ios-simulator-compatibility.app.zip`
- `hydrion-ios-production-signed-release.ipa`

The signed iOS workflow is gated and does not upload to TestFlight
automatically.

## Legal Implementation

Hydrion now bundles Markdown legal documents under
`docs/Hydrion_Legal_Pack_Markdown/` and exposes them through the in-app
`About & Legal` hub:

- Terms of Use
- Privacy Policy
- Health and Safety Disclaimer
- Alpha and Beta Testing Notice
- Open Source Licenses
- App information
- Support

Internal owner notes are not exposed in the user-facing menu.

Onboarding stores:

- accepted Terms version;
- Terms acceptance timestamp;
- acknowledged Health and Safety Disclaimer version;
- acknowledgement timestamp;
- Privacy Policy version shown.

Existing users with old one-boolean legal state receive a focused legal review
screen without resetting hydration logs or profile data.

## Shorebird

Shorebird is not required for Hydrion v1.0.0 builds. `SHOREBIRD_TOKEN`,
Shorebird install commands, release commands, and patch commands are not part
of ordinary validation, Android, iOS, web, or TestFlight-prep workflows. See
`docs/architecture/SHOREBIRD_DECISION.md`.

## Build Commands

```sh
flutter pub get
dart format --set-exit-if-changed .
dart run tool/secret_scan.dart
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Android builds require a configured Android SDK. Check `flutter doctor -v`,
`android/local.properties`, Android Studio SDK settings, Java, and Gradle before
classifying a build failure.

## Migration Behavior

Existing v1 local storage keys are preserved for hydration logs, settings,
reminders, and active challenge state. New settings fields default safely when
missing. Corrupted categories recover independently where possible. Existing
users are not forced to delete data and can complete new profile fields later.

## Known Limitations

- Legal copy is implementation-aligned draft text and owner/legal approval is
  still required.
- Public privacy-policy URL and support URL are still required for store
  submission.
- Release date is pending.
- Android package identity is configured as `com.the1807.hydrion`; store-owner
  approval is still required before public upload.
- Production signing credentials are not present.
- CI-signed release artifacts are installable for clean smoke tests but are not
  production-signed artifacts.
- Notification delivery and location/weather flows require real-device testing.
- Open-Meteo availability and network errors must fall back honestly.
- Social sync is not connected; challenges remain local-only.

## Owner Decisions Required

- Confirm the `com.the1807.hydrion` package identity before store upload.
- Production signing setup and CI secret names.
- Codemagic Apple Developer and App Store Connect signing integration.
- Public release date.
- Legal approval for Terms, Privacy Policy, and Health/Safety Disclaimer.
- Public privacy-policy URL and support URL.
- Store listing, screenshots, rating questionnaire, and support process.

## Manual Device Validation Checklist

Do not mark these manually verified until executed on real devices:

- clean install
- update over previous debug build where possible
- app launch and startup animation
- reduced-motion behavior
- first-run onboarding
- returning-user onboarding skip
- nickname, age, sex, avatar, unit, goal, and container persistence
- all ten shark PFPs and all nineteen human default profile avatars
- profile editing
- manual goal
- weather goal eligibility
- location denial and app-settings route
- notification denial and app-settings route
- forecast success and forecast failure
- daily prompt, auto-apply, and restore confirmation
- hydration add, edit, delete, and undo
- restart persistence
- challenge start, progress, completion signal, and cancellation
- reminder scheduling, firing, edit/reschedule, deletion, and cancellation
- language switching
- dark/light mode
- offline behavior
- legal pages and version/build display
- local reset
- uninstall/reinstall data behavior
- crash monitoring
