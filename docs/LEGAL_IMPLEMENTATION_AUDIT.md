# Hydrion Legal Implementation Audit

Status: implementation-aligned draft. This document is not legal approval.

Audit date: July 6, 2026.

## Files Inspected

- `docs/Hydrion_Legal_Pack_Markdown/00_READ_BEFORE_PUBLISHING.md`
- `docs/Hydrion_Legal_Pack_Markdown/01_PRIVACY_POLICY.md`
- `docs/Hydrion_Legal_Pack_Markdown/02_TERMS_OF_USE.md`
- `docs/Hydrion_Legal_Pack_Markdown/03_HEALTH_AND_WELLNESS_DISCLAIMER.md`
- `docs/Hydrion_Legal_Pack_Markdown/04_ALPHA_BETA_TESTING_NOTICE.md`
- `docs/Hydrion_Legal_Pack_Markdown/05_INTERNAL_DRAFTING_REFERENCES.md`
- `pubspec.yaml`, `pubspec.lock`
- `lib/main.dart`
- `lib/domain/legal_document_registry.dart`
- `lib/domain/release_metadata.dart`
- `lib/repositories/settings_repository.dart`
- `lib/repositories/hydration_repository.dart`
- `lib/repositories/reminder_repository.dart`
- `lib/repositories/challenge_repository.dart`
- `lib/services/weather_goal_service.dart`
- `lib/services/location_service.dart`
- `lib/services/notifications.dart`
- `lib/services/profile_photo_service.dart`
- `lib/adapters/gemini/gemini_adapter.dart`
- `lib/ui/screens/legal_about_screen.dart`
- `lib/ui/screens/onboarding_screen.dart`
- `lib/ui/screens/settings_screen.dart`
- `lib/ui/screens/profile_screen.dart`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Podfile`
- `ios/Runner/Info.plist`
- `ios/Runner/PrivacyInfo.xcprivacy`
- `.github/workflows/flutter-ci.yml`
- `codemagic.yaml`

## Legal File Inventory

| File | Title | Version | Effective | Updated | Intended display | Notes |
|---|---|---:|---|---|---|---|
| `00_READ_BEFORE_PUBLISHING.md` | Read Before Publishing | 1.0.0 | 2026-07-06 | 2026-07-06 | Internal only | Owner decisions and publication guardrails. |
| `01_PRIVACY_POLICY.md` | Hydrion Privacy Policy | 1.0.0 | 2026-07-06 | 2026-07-06 | In-app and public | Rewritten for local-first app and Open-Meteo flow. |
| `02_TERMS_OF_USE.md` | Hydrion Terms of Use | 1.0.0 | 2026-07-06 | 2026-07-06 | In-app and public | Rewritten without invented operator, address, governing law, accounts, or arbitration. |
| `03_HEALTH_AND_WELLNESS_DISCLAIMER.md` | Hydrion Health and Safety Disclaimer | 1.0.0 | 2026-07-06 | 2026-07-06 | In-app and public | Separate acknowledgement required. |
| `04_ALPHA_BETA_TESTING_NOTICE.md` | Hydrion Alpha and Beta Testing Notice | 1.0.0 | 2026-07-06 | 2026-07-06 | In-app and public | Explains pre-release limitations and local data loss risk. |
| `05_INTERNAL_DRAFTING_REFERENCES.md` | Internal Drafting References | 1.0.0 | 2026-07-06 | 2026-07-06 | Internal only | Implementation evidence and policy references. |

## Actual Data-Flow Findings

| Category | Source | Local storage | Transmission | Recipient | Edit/delete path |
|---|---|---|---|---|---|
| Nickname | User entry | Settings JSON | No routine transmission | None | Profile editor; app storage/uninstall. |
| Age | Optional user entry | Settings JSON | No routine transmission | None | Profile editor; app storage/uninstall. |
| Sex selection | Optional user entry | Settings JSON | No routine transmission | None | Profile editor; app storage/uninstall. |
| Avatar | User selection | Settings JSON | No routine transmission | None | Onboarding/profile editor. |
| Local profile photo | Photo picker | Base64 in settings | No routine transmission | None | Remove photo in profile editor. |
| Hydration logs | User logging | Local hydration repository | No routine transmission | None | Edit/delete logs; app storage/uninstall. |
| Intake amount and timestamp | User logging/app timestamp | Local hydration repository | No routine transmission | None | Edit/delete logs. |
| Daily goal and units | User settings/app logic | Settings JSON | No routine transmission | None | Settings/profile editor. |
| Weather goal preferences | User settings/app logic | Settings JSON | No routine transmission except weather request | Open-Meteo receives rounded coordinates during request | Settings. |
| Approximate coordinates | Geolocator low-accuracy lookup | Not stored as history | Sent for weather request | Open-Meteo | Decline permission or disable weather mode. |
| Cached forecast | Open-Meteo response | Local forecast cache | No further transmission | None | Replaced/cleared by app storage. |
| Reminders | User/app scheduling | Local reminder repository | Local OS scheduling only | Android notification service | Edit/delete reminders. |
| Notification permission prompt date | App generated | Settings JSON | No routine transmission | None | App storage/uninstall. |
| Challenge state and Bottle Bingo tiles | User/app | Local challenge repository | No social sync | None | Leave/reset challenge controls where available; app storage. |
| Streaks, achievements, eco estimates | App generated | Derived from logs/settings | No routine transmission | None | Change/delete source logs/settings. |
| Language | User setting | Settings JSON | No routine transmission | None | Settings. |
| Legal acceptance state | User checkbox | Settings JSON | No routine transmission | None | Renewed only for material version changes; app storage. |
| Support communications | User email/feedback | Outside app if user sends | User initiated | Email or support platform | User controls message content; provider rules apply. |
| Diagnostics/logs | Recovery events only | Local recovery metadata | No analytics/crash SDK | None | App storage/uninstall. |

## Features Verified Absent

Current repository behavior does not implement accounts, authentication, remote Hydrion database, Hydrion-hosted cloud sync, advertising, analytics SDK, crash-reporting SDK, data sale, tracking, remote push tokens, social sync, HealthKit, Google Fit, Health Connect, camera, microphone, contacts, Bluetooth, background location, or exact alarm permission.

## Contradictions Found And Corrected

| Conflict | Resolution |
|---|---|
| Legal pack claimed or anticipated accounts, cloud sync, account deletion, wearables, HealthKit, Health Connect, analytics, crash reporting, subscriptions, and future services as if active. | User-facing docs now describe only current behavior and move future decisions to internal owner notes. |
| Privacy language could imply data never leaves the device. | Privacy Policy and contextual UI now disclose that rounded coordinates may be sent to Open-Meteo for weather requests. |
| iOS privacy manifest declared no collected data while weather mode can transmit coarse location. | `PrivacyInfo.xcprivacy` now declares coarse location for app functionality, no tracking, not linked. |
| Onboarding had one combined legal/health checkbox. | Terms acceptance and Health acknowledgement are separate unchecked controls. |
| Legal/About screen duplicated hardcoded legal text in Dart. | App now renders bundled Markdown from one source of truth. |
| Existing users had no versioned legal record. | Startup routes them to focused legal review without resetting local data. |
| Challenge safety language did not explicitly mention progress or rewards. | Health language now warns not to force fluids for progress, streaks, rewards, or challenges. |
| CI did not have a Codemagic primary iOS path. | Added `codemagic.yaml` workflows and setup docs. |
| Shorebird was requested for audit. | Verified no ordinary build requirement and documented future-only decision. |

## Documents Exposed In Application

The in-app `About & Legal` hub exposes:

- Terms of Use;
- Privacy Policy;
- Health and Safety Disclaimer;
- Alpha and Beta Testing Notice;
- Open Source Licenses through Flutter's license page;
- App information;
- Support email.

Internal owner notes and drafting references are not exposed in the user-facing menu.

## Onboarding Acceptance Behavior

- Privacy Policy is presented as notice, not a contract checkbox.
- Terms acceptance is separate from Health and Safety acknowledgement.
- Checkboxes are not preselected.
- Terms acceptance cannot be checked until the Terms document has been opened
  through the Hydrion legal viewer.
- Health acknowledgement cannot be checked until the Health and Safety
  Disclaimer has been opened through the Hydrion legal viewer.
- Privacy review cannot be completed until the Privacy Policy has been opened.
- Alpha and beta builds also require the Alpha and Beta Testing Notice to be
  opened before completion.
- Opening a document does not record acceptance.
- Opening a document does not automatically check any box.
- Document-opening state is tracked for the active in-app document version
  during the review session.
- Attempting to check too early shows an inline live-region error and
  highlights the required document control instead of showing a blocking
  full-screen error.
- Alpha/beta/stable builds use
  `Open the required legal document before continuing.` from
  `HydrionReleaseMetadata`.
- Legal acceptance is stored locally with version and timestamp.
- Existing users with old local storage go to a focused legal review screen.
- Local hydration data survives legal-state migration.
- Location, notification, and photo permissions are not requested from legal screens.

## Legal Versioning Strategy

Current required acceptance versions:

- Terms: `1.0.0`
- Health and Safety Disclaimer: `1.0.0`
- Privacy Policy notice shown: `1.0.0`

Material Terms or Health Disclaimer changes should increment the required version and trigger review. Nonmaterial spelling, formatting, date, or contact corrections should update document text and last-updated date without changing the required acceptance version.

## Public URL Requirements

The app bundles offline Markdown documents, but store submission still requires public URLs:

- public Privacy Policy URL;
- public support URL.

These URLs are not verified in the repository and remain owner actions.

## Store Questionnaire Mapping

See `docs/STORE_COMPLIANCE_MATRIX.md`.

## Tests Added Or Updated

- Legal registry uniqueness, file existence, metadata, version, and route checks.
- Placeholder scan for user-facing legal documents.
- Legal screen rendering in light/dark and large text.
- Legal document loading and missing-document fallback.
- Legal hub excludes internal documents.
- Open Source Licenses access.
- Terms acceptance not preselected.
- Legal checkbox blocked before corresponding document opening.
- Inline alpha and production legal gate copy.
- Opening documents does not record acceptance or check boxes.
- Alpha/beta notice opening required before completion.
- Existing-user migration preserves hydration logs.
- Material version change triggers review; same version does not.
- Health acknowledgement stored separately from Terms acceptance.
- Legal review does not request location or notification permissions.
- Shorebird not required by ordinary build configuration.
- Codemagic workflow and artifact-name checks.

## Remaining Owner And Legal Review

- Qualified legal review of all user-facing legal documents.
- Final public privacy-policy URL and support URL.
- Final target audience and age settings.
- Store privacy questionnaires and Data Safety submissions.
- Production signing credentials.
- Real-device validation for Android and iOS permission flows, notification delivery, weather lookup, startup, onboarding, legal review, and uninstall behavior.
