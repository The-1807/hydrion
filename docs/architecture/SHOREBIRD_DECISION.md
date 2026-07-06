# Shorebird Decision

Status: not required for Hydrion v1.0.0.

Hydrion does not currently have a demonstrated production requirement for over-the-air code patching. The ordinary build and release path is standard Flutter build output through GitHub validation and Codemagic platform workflows.

## Decision

Shorebird is not part of the required Hydrion build path.

The following must not depend on Shorebird or `SHOREBIRD_TOKEN`:

- dependency resolution;
- formatting;
- secret scanning;
- static analysis;
- tests;
- web builds;
- Android APK or App Bundle builds;
- iOS simulator or unsigned compatibility builds;
- signed iOS IPA preparation;
- TestFlight preparation.

## Current Repository State

No `shorebird.yaml`, Shorebird install command, Shorebird release command, Shorebird patch command, Shorebird cache setup, or `SHOREBIRD_TOKEN` requirement is present in the ordinary build configuration.

Automated tests assert that `codemagic.yaml`, `.github/workflows/flutter-ci.yml`, `pubspec.yaml`, and normal helper scripts do not require Shorebird release or patch commands.

## Future Reconsideration

Shorebird may be reconsidered after Hydrion reaches stable production and has a clear, owner-approved code-push requirement, store-policy review, rollback process, user-support process, and release governance model.

Do not initialize a Shorebird project until that decision is made.
