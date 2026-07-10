# Hydrion V1 Release Notes

Status: draft, not approved for production release.

## Highlights

- Local-first hydration logging, goals, history, reminders, analytics, and
  settings.
- First-run onboarding with profile, avatar, unit, goal, container, and legal
  review steps.
- Returning users skip onboarding after completion, and partial onboarding now
  resumes at the saved step.
- Minimal startup buffer with the bundled shark Lottie animation, a two-step
  text sequence, and reduced-motion static playback.
- In-app About & Legal hub with credits and licences.
- Weather-informed goal mode using Open-Meteo after explicit user action and
  foreground location permission.
- Local coach and challenge flows remain available without cloud account setup.

## 2026-07-07 Validation Snapshot

- Formatting, Flutter analysis, full automated tests, secret scan, and diff
  whitespace checks passed locally.
- The final About & Legal credits wording change was rechecked with focused
  analysis and `test/legal_document_test.dart`.
- Android APK and App Bundle packaging were attempted locally but blocked by a
  missing Android SDK.
- iOS build/signing and manual device validation were not run locally.

## Release Decision

Hydrion V1 remains `Not Ready` until Android/iOS artifacts, manual validation,
owner/legal approval, and Lottie licence evidence are complete.
