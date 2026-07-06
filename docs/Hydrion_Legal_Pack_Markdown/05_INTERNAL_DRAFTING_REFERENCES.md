---
document_id: internal_drafting_references
title: Internal Drafting References
version: 1.0.0
effective_date: 2026-07-06
last_updated: 2026-07-06
intended_display: internal_only
---

# Internal Drafting References

This file is internal. It records the implementation evidence and policy sources used to align Hydrion's legal pack. It must not appear in the in-app Legal menu.

## Implementation Evidence

- `pubspec.yaml` dependency list and bundled assets
- `lib/main.dart` application routes and service wiring
- `lib/repositories/settings_repository.dart` local settings persistence
- `lib/repositories/hydration_repository.dart` local hydration log persistence
- `lib/repositories/reminder_repository.dart` local reminder persistence
- `lib/repositories/challenge_repository.dart` local challenge persistence
- `lib/services/weather_goal_service.dart` Open-Meteo request flow and weather cache
- `lib/services/location_service.dart` foreground low-accuracy location request flow
- `lib/services/notifications.dart` Android local notification adapter
- `lib/services/profile_photo_service.dart` local profile-photo picker
- `lib/adapters/gemini/gemini_adapter.dart` optional non-local AI adapter
- `android/app/src/main/AndroidManifest.xml` Android permissions
- `ios/Runner/Info.plist` iOS usage descriptions
- `ios/Runner/PrivacyInfo.xcprivacy` iOS privacy manifest

## Official Policy Sources Checked

- Apple App Store Review Guidelines
- Apple App Privacy Details
- Google Play User Data policy
- Google Play Data Safety documentation
- Google Play Health Content and Services policy
- Codemagic first signed build pipeline documentation
- Codemagic iOS signing documentation
- Codemagic App Store Connect publishing documentation

## Drafting Rules Used

- Do not claim an account, cloud, medical, analytics, advertising, or deletion feature unless the repository implements it.
- Distinguish local device processing from third-party transmission.
- Identify Open-Meteo as the current weather provider.
- Keep account deletion out of public user-facing promises while the app has no accounts.
- Keep governing law, legal entity, business address, age restriction, Apple credentials, and policy URLs out of public copy until the owner supplies verified values.
- Require separate Terms acceptance and Health and Safety acknowledgement.
- Treat the Privacy Policy as notice, not a contract requiring checkbox consent.
- Use Flutter's license page for open-source notices instead of pasting third-party licenses into the Terms or Privacy Policy.
