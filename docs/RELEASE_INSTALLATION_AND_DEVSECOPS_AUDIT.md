# Hydrion Release Installation and DevSecOps Audit

## Executive Summary

The published Android APKs are valid ZIP/APK files and verify with APK Signature
Scheme v2. The installation failure class was an Android package identity and
certificate collision: Android Studio installed a debug-signed app as
`com.the1807.hydrion`, while the downloaded APK used Hydrion's production
certificate under the same application ID. Android does not permit one signer
to replace another signer for an existing package.

The public asset attached to the release named v1.2 also declared app version
`1.1.0` and build `3`. The repository baseline is now `1.2.0+4`. Future debug
builds use `com.the1807.hydrion.debug`, and production candidates are validated,
renamed, hashed, and recorded in manifests before upload.

No release was published and no store submission occurred during this audit.

## Android Installation Failure

### Symptom

A downloaded release APK failed to install on a device where Android
Studio-installed Hydrion builds worked.

### Evidence

The three GitHub release assets available on 2026-08-14 were inspected directly:

| Asset | Bytes | Declared version | SHA-256 |
|---|---:|---|---|
| `Hydrion-v1.o.o-rc.1.apk` | 93,510,743 | `1.0.0 (1)` | `92e14ff0e8f87ad6131449e0267c0e503ab7babee96c7d9c9a977635888e5fea` |
| `Hydrion.apk` | 78,670,177 | `1.1.0 (3)` | `775fc0de365ad2769dea1f0770be2b0a6e66af47f93847ee276787b062776e16` |
| `hydrionshark.apk` | 92,408,468 | `1.1.0 (3)` | `aac139529501246e7e9004f8d0c50572cb0df6e10f8dc155c667caa62b52a83c` |

All three declare `com.the1807.hydrion`, `minSdk 24`, `targetSdk 36`, and
`arm64-v8a`, `armeabi-v7a`, and `x86_64`. All pass ZIP inspection and
`apksigner verify`, and all use production certificate SHA-256:

`0e72fea179b2631e7b8379dac1b4fa9f6e75c8e82052aef582bad6cee2a03fea`

The local Android Studio debug APK used the same production application ID but
the Android debug certificate SHA-256:

`56fe5c7ae21cd1752bbd3e8e9a46f19f0e3ad8a38b43ceef9dd3578c5f6cd730`

The original Android package-installer error text was not recoverable. The
published APKs themselves rule out unsigned, corrupt, incomplete split, ABI,
minSdk, and package-ID explanations.

### Root Cause

The reported update path attempted to replace a debug-signed package with a
production-signed package of the same application ID. Android rejects that
certificate transition. A separate version-drift defect also allowed a v1.2
release asset to retain v1.1 metadata and build number 3.

### Why Development Builds Worked

Android Studio signs debug builds with the local Android debug key. Repeated
Studio installs use that same local debug certificate, so they can replace one
another.

### Why the Release Artifact Failed

The release APK was signed correctly, but its production certificate could not
replace the already-installed debug certificate. Correct signing does not make
two unrelated signing identities update-compatible.

### Exact Fix

- Debug builds now use `com.the1807.hydrion.debug` and a `-debug` version suffix.
- The app baseline is `1.2.0+4`; Android and WidgetKit consume aligned metadata.
- `tool/validate_android_release.dart` verifies the exact candidate APK.
- Production candidates require the expected certificate fingerprint.
- Artifact names contain version, build, platform, signing kind, and build type.
- The validator produces an APK hash and JSON manifest before upload.
- The release workflow produces an overall manifest and checksums.
- Normal CI never receives production Android signing credentials.

### Validation and Recurrence Prevention

The validator fails for package, version, SDK, ABI, signing, fingerprint, ZIP,
or signature drift. The protected release workflow runs only by manual dispatch
from `main`, requires complete signing configuration, validates before staging,
and never publishes automatically.

An old debug install that still owns `com.the1807.hydrion` cannot be converted
in place to the production signer. Do not uninstall it without owner approval.
Preserve/export any needed data, then perform the explicitly approved one-time
removal before a production fresh install. New `.debug` builds avoid recurrence.

## iOS Installation Assessment

### Existing Risks

Runner uses `com.the1807.hydrion`; WidgetKit uses
`com.the1807.hydrion.widgets`; both use App Group
`group.com.the1807.hydrion`. Both target iOS 14.0. The prior simulator failure
class was missing or unresolved extension placeholder metadata.

### Defects Found and Fixes

Codemagic previously fetched signing files only for Runner. It now fetches
profiles for Runner and WidgetKit, verifies both code signatures in the IPA,
checks embedded bundle identifiers and version/build alignment, and hashes the
IPA. Source tests require all installability-critical WidgetKit plist keys.

GitHub CI continues to compile simulator and unsigned device release bundles,
verify the embedded extension, validate bundle metadata, compare host/extension
versions, and compare App Groups. Its unsigned app archive is now distinctly
named, hashed, and accompanied by a manifest.

### Signed Release Status

Signed installation is not validated locally because Windows has no Xcode,
codesign, provisioning profiles, or iOS device. A Codemagic signed IPA result and
physical iPhone upgrade/install test remain required.

## DevSecOps Assessment

### Existing Controls

- CI defaults to `contents: read`.
- Flutter is pinned to 3.44.8.
- Format, analyzer, tests, audits, and secret scanning are blocking gates.
- Android release signing material is ignored by Git and injected at runtime.
- Android disables backup and cleartext traffic.
- Hydrion does not request camera, microphone, Bluetooth, health, storage, fine
  location, or background location permission.
- Startup trace logging is disabled in release mode.
- Widgets expose hydration progress/challenge state but not age, body metrics,
  reproductive state, clinician target, fluid restriction, or wake/sleep times.

### Missing or Partial Controls

- Published asset identity was manual and not traceable to validated bytes.
- Normal CI could previously access production Android signing secrets.
- Release action tags were mutable.
- There was no dependency-update automation or security reporting policy.
- The custom URL handler did not reject non-Hydrion schemes or unknown session
  actions.
- Flutter does not currently provide a reliable complete native/mobile SBOM in
  this repository.

### New Controls Implemented

- Immutable action SHAs in the secret-bearing Android release workflow.
- Production signing isolated to the manual, main-only release workflow.
- Expected production certificate fingerprint policy.
- Exact APK validation, deterministic names, SHA-256, and JSON manifests.
- Accurate `flutter pub deps --json` release dependency inventory.
- Dependabot coverage for Pub, Gradle, and GitHub Actions.
- Secret scanner detection for committed mobile signing files, GitHub tokens,
  and AWS access key IDs.
- `SECURITY.md` private reporting guidance.
- Strict Hydrion deep-link route, scheme, parameter, and action validation.

### Deferred Controls

- A standards-compliant SBOM remains deferred until a tool can accurately cover
  Dart plus resolved Android/iOS native dependencies. The dependency inventory
  must not be represented as an SBOM.
- GitHub branch protection and environment approval rules require repository
  administration and cannot be proven from source alone.
- Store signing, Play App Signing, App Store Connect, notarized distribution,
  and provenance attestations require owner/store configuration.

## Release Security Model

Normal validation CI uses no production signing material. Android smoke APKs
are ephemeral and explicitly named `ci-ephemeral`; they support fresh-install
testing only and never represent a production update path. The production
Android workflow requires all key material plus the expected certificate
fingerprint, stages only validated bytes, and does not publish them.

Unsigned iOS compilation demonstrates build compatibility only. Signed IPA
creation is separately gated in Codemagic and still does not publish
automatically.

## Remaining Physical Validation

- Connect an expendable or explicitly approved Android test state.
- Confirm a fresh install of the exact validated production APK.
- Confirm an upgrade from a prior production-signed APK with user data intact.
- Confirm debug and production packages coexist after the `.debug` suffix.
- Run signed iPhone fresh-install and production-signed upgrade tests.
- Verify WidgetKit installation, App Group refresh, notifications, and Hydrion
  deep links on a physical iPhone.

## Finding Classification

| Severity | Finding | Status |
|---|---|---|
| SEC-P1 / R0 | Debug signer occupied the production Android package identity, blocking the reported release-over-debug installation path. | Fixed for future builds; old conflicting installs require an approved one-time migration. |
| SEC-P1 / R1 | Normal Android CI could receive production signing secrets. | Fixed; normal CI is ephemeral-only. |
| SEC-P1 / R1 | Published bytes lacked enforced source/version/certificate provenance. | Fixed in the candidate pipeline; existing releases remain historical evidence. |
| SEC-P2 / R1 | The v1.2-named public APK declared `1.1.0 (3)`. | Repository fixed to `1.2.0+4`; new candidate build pending. |
| SEC-P2 / R1 | Signed iOS preparation fetched only the Runner profile. | Fixed to fetch and verify Runner plus WidgetKit. |
| SEC-P2 / R2 | Custom URL handling accepted unverified schemes and session actions. | Fixed and tested. |
| SEC-P3 / R2 | Release names were hard-coded/ambiguous and manifests were incomplete. | Fixed. |
| SEC-P3 / R3 | Dependency update automation and a security reporting policy were absent. | Fixed. |
| SEC-P3 / R3 | Complete standards-based mobile SBOM unavailable. | Deferred and documented; accurate dependency inventory added. |

## Final Verdict

The source and pipeline are hardened for generation of a trustworthy candidate.
Android and iOS remain release-blocked until the new candidate builds complete
and the listed physical/signing validations pass. Local compilation alone must
not be reported as release installation success.
