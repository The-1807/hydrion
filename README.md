# Hydrion

Hydrion is a standalone-first Flutter hydration companion. The current app
stores hydration logs, settings, reminder definitions, and local challenge
state on the device through `shared_preferences`.

## Current Runtime

- Local hydration logging with amount selection.
- Persisted log edit/delete.
- Analytics, eco impact, challenges, and coach context derived from saved logs.
- Flutter `gen_l10n` localization for English, Spanish, and French.
- Adapter boundary for AI providers.
- `local_rules` default coach/provider mode.
- Optional Gemini provider for local development only.
- Android local notifications are wired for user-created reminders, subject to
  runtime permission, OS delivery policy, reboot/timezone handling, and
  real-device validation.
- Weather-informed goals use a one-shot foreground approximate location lookup
  and Open-Meteo daily forecast data when the user enables weather mode and
  grants required permissions.
- ELKA, cloud sync, connected-device sync, Health, and voice capture remain
  disabled or unconfigured unless future adapters are added.

## Setup

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

Run in Chrome:

```sh
flutter run -d chrome
```

Build web:

```sh
flutter build web --release
```

Build Android APK:

```sh
flutter build apk --release
```

Local APK builds require an Android SDK and `ANDROID_HOME` or
`ANDROID_SDK_ROOT` to be configured.

Android release signing uses `android/key.properties` when the owner provides
local credentials. Release builds no longer fall back to the debug key. Do not
commit keystores, passwords, or `key.properties`.

GitHub Actions uploads a debug-signed APK for ad hoc phone smoke testing. The
signed release APK artifact is uploaded only when protected repository secrets
provide `HYDRION_ANDROID_KEYSTORE_BASE64`,
`HYDRION_ANDROID_KEYSTORE_PASSWORD`, `HYDRION_ANDROID_KEY_ALIAS`, and
`HYDRION_ANDROID_KEY_PASSWORD`.

See `docs/V1_RELEASE_READINESS.md` for weather setup, privacy behavior,
notification limitations, signing setup, application-id status, build commands,
known limitations, owner decisions, and manual device validation.

## Optional Gemini For Local Development

Gemini is optional and unavailable by default. `local_rules` remains the default
provider and Hydrion must work without Gemini.

For local development only:

```sh
flutter run -d chrome \
  --dart-define=HYDRION_AI_PROVIDER=gemini \
  --dart-define=HYDRION_GEMINI_API_KEY=$HYDRION_GEMINI_API_KEY
```

Do not commit API keys. Do not ship a shared production Gemini key in web or
mobile client artifacts. Future production provider options are BYOK, a secure
backend proxy, or another strategy that keeps shared secrets out of clients.

## Validation

The CI baseline runs:

- `flutter pub get`
- `dart run tool/secret_scan.dart`
- `flutter analyze`
- `flutter test --coverage`
- `flutter build web --release`
- `flutter build apk --release`

Architecture and provider safety notes live in `docs/architecture/`.

## Release Readiness

Hydrion V1 release validation is tracked in the
[Hydrion V1 Release Readiness Checklist](docs/release/HYDRION_V1_RELEASE_READINESS_CHECKLIST.md).