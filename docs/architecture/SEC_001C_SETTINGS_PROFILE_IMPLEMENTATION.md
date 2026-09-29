# SEC-001C Settings/Profile and Photo Implementation Receipt

Date: 2026-09-29
Branch: `audit/full-hydrion-integration`
Base: `ac65254e36c4a7827b444e7a30647b5c8b869fdc`
Authority: current HTD M3 / I03-I05 and owner approval.
Status: IMPLEMENTED_PENDING_SLICE_ACCEPTANCE; independent acceptance not performed.
This receipt is included in the implementation commit, not a separate acceptance.

## Owner Decision and Scope

Protected photo maximum: **1,200,000 decoded bytes**. Legacy Base64 maximum:
**1,600,000 characters**, used only at ingestion/migration. Successful Base64
decoding where applicable, actual image decoding, width <=720 and height <=720
are required before persistence. Invalid legacy bytes/text are retained without
automatic resizing, recompression, truncation or deletion. Retry and explicit
reselection are exposed. No separate automatic reprocessing service is added.

Only settings-owned I03/I04 and the ordinary/settings split of I05 are included.
The separate guided-tour history is M4, not migrated here. Targets keep current
calculation, legal/consent, source and provenance semantics. This is not a new
target history model.

## Exact Field Inventory

Protected typed profile fields (29):
- Identity: nickname, age, sex.
- Targets: dailyGoalMl, baselineDailyGoalMl, goalMode, baselineSource,
  weatherModifierEnabled, weatherGoalAutoApplyEnabled,
  lastWeatherGoalDecisionAt, lastWeatherGoalLocalDate, lastWeatherGoalExplanation,
  weatherGoalDailyConfirmationEnabled, weatherAdjustedGoalActive, lastManualGoalEditAt.
- Consent/history: nonLocalProviderConsentGranted, legalAndHealthAcknowledged,
  acceptedTermsVersion, acceptedTermsAt, acknowledgedHealthDisclaimerVersion,
  acknowledgedHealthDisclaimerAt, privacyPolicyVersionShown, privacyPolicyShownAt,
  locationPermissionPromptedAt, notificationPermissionPromptedAt,
  onboardingCompleted, onboardingStep, missionIntroductionHandled, recognitionEventIds.
- Photo: separately validated decoded BLOB, width, height; not a profile JSON field.

Ordinary settings fields (7): languageCode, countryCode,
reusableContainerEnabled, avatarId, volumeUnit, themePreference, containerSizeMl.
The sanitized document also holds a non-payload `_protectedRevision` reference.
Existing locale/tour stores are not migrated. Unknown legacy keys are preserved
and quarantined because the repository has no allowlist declaring them ordinary.

## Schema and Ownership

The existing application SQLCipher database upgrades transactionally from
schema 1 to 2. The existing daily_context table and app-owned key remain intact.
No new database path, key, dependency or generic KV store is introduced.

The explicit settings_profile singleton contains schema_version (1), revision,
phase, classified profile TEXT, photo BLOB, width and height. The TEXT serializer
has a closed typed field allowlist; it is not the whole UserSettings JSON.
BLOB length/dimensions also have SQL constraints. Reads verify photo decoding and
metadata. Writes transact, reject stale/conflicting revisions, and verify exact
profile/bytes/dimensions on readback before returning committed.

Repository mutations are serialized. SQLite coordinates connections to the same
database; the supported ownership assumption is one repository writer per dataset
in one isolate, not a certified cross-process/multi-writer service.

## Authority, Cutover and Recovery

| State | Authority and action |
|---|---|
| Legacy only | Preserve source; validate canonical classified values and photo; write provisional, verify, activate, verify, then sanitize preferences. |
| Matching provisional + legacy | Verify exact candidate equivalence and resume activation; mismatches quarantine both copies. |
| Active protected + legacy | Active protected wins; old sensitive source is cleanup-pending, never a fallback authority. |
| Protected only | Read verified protected record plus ordinary config; a missing photo is a known absence. |
| Cleanup rejected/mismatched | Keep verified protected authority and explicit incomplete state; retained legacy is retried without stale rollback. |
| Protected unavailable/unsupported/corrupt | No grant, target mutation or new plaintext fallback. UI gates untrusted profile consumers; retry and ordinary theme/locale remain exposed. |
| Missing protected record with generation marker | Unavailable, not a fresh profile authorized by defaults. |
| Ahead/invalid generation reference | Quarantine rather than guessing which copy wins. |

Cleanup strips only the classified allowlist and photo, retains ordinary values,
and requires acknowledged write plus matching readback. Existing preferences
adapter invalidates its cache after native false/exception; cache optimism is not
accepted as native success. Unknown fields block destructive cleanup.

Classified updates go to the protected record. Ordinary updates do not change
its revision. A combined action is deliberately not called cross-store ACID:
if private commit succeeds but preferences publication fails, latest verified
private state and prior ordinary state remain visible with partialFailure.
The operation reports incomplete. No old whole-settings snapshot overwrites it.

## Photo and Reset Behavior

The picker returns bytes; the repository validates them before a BLOB write.
Flutter ImmutableBuffer/ImageDescriptor/Codec decode the image (including every
frame), check dimensions and dispose native decoding resources. No production
custom parser is introduced. Exact-byte-cap PNG fixtures use a test-only ancillary
chunk generator. No lower host-RSS-derived cap is imposed.

Legacy photo validation precedes provisional cutover. Invalid source stays exact;
explicit valid reselection replaces it only through verified protected cutover.
The UI facade supplies an in-memory Base64 view for existing image widgets; no
Base64 is persisted to SQLCipher or new ordinary preference payloads.

Photo removal first persists non-payload deletion intent, performs a verified
protected no-photo update, sanitizes any legacy copy and acknowledges intent
removal. Failures remain retryable across repository restart.
Settings-only reset uses its own non-payload intent and keeps existing legal
retention semantics. LocalProfileResetService already catches per-store failure;
its global orchestration/journaling is unchanged. DATA-005 stays OPEN.

## Consumers and Diagnostics

The root protection gate separates unavailable profile state from known absence,
prevents unknown profile defaults driving normal onboarding/target UI, offers
retry/reselection and ordinary appearance/locale controls. Cleanup/partial states
show an incomplete banner. Profile, onboarding, legal and mission actions retain
truthful save failure handling. Photo display uses the repository, not widget SQL.
Target calculation is guarded against unknown settings without changing formulas.
Widget/watch writers skip publishing unknown defaults; existing native snapshots
are not migrated, cleared or certified by this slice.

Four EN/FR/ES messages contain no payload interpolation. Typed failures expose only
bounded status/reason names. Serialized-source tests assert the complete protected
field allowlist and photo text disappear while all seven ordinary values survive.
Synthetic identity and byte comparisons are host evidence, not whole-device
plaintext/backup/forensic certification.

## Validation

Final combined focused run: **430 tests passed across 34 files**, exit 0.
The earlier 33-file combined run passed 414 tests. A further photo-picker fixture
was corrected to use a valid decoded PNG and await native decoding; the final run
includes its complete runtime-UX file. Earlier fixture/async failures and two
onboarding brace lints were resolved before this final result; no test was skipped.

- Analyzer: `flutter analyze --no-pub` passed, no issues.
- Scoped formatting: 40 changed Dart files, zero further changes required.
- Localization: EN/FR/ES each 972/972 Flutter and 24/24 Android messages.
- New-message placeholder check: four messages in each locale, no placeholders.
- Secret scan: passed; no credential/private-key blocks found.
- Whitespace: `git diff --check` passed.

Reproduction (run from the repository root; no pub resolution requested):

```powershell
flutter test --no-pub `
  test/protected_settings_profile_test.dart `
  test/settings_protection_gate_test.dart `
  test/protected_app_store_test.dart `
  test/protected_daily_context_test.dart `
  test/app_database_key_store_test.dart `
  test/body_metrics_authority_regression_test.dart `
  test/body_metrics_deletion_test.dart `
  test/body_metrics_containment_test.dart `
  test/sensitive_body_metrics_store_test.dart `
  test/recommendation_input_token_test.dart `
  test/boundary_architecture_test.dart `
  test/remediation_control_test.dart `
  test/daily_hydration_recommendation_coordinator_test.dart `
  test/startup_onboarding_test.dart `
  test/profile_age_review_test.dart `
  test/persistence_test.dart `
  test/app_locale_repository_test.dart `
  test/v1_release_scope_test.dart `
  test/storage_recovery_test.dart `
  test/recognition_moment_test.dart `
  test/permission_consent_test.dart `
  test/localization_test.dart `
  test/mission_and_farewell_test.dart `
  test/rc2_ux_repair_test.dart `
  test/legal_document_test.dart `
  test/startup_buffer_test.dart `
  test/personalization_repository_test.dart `
  test/body_metrics_async_shell_test.dart `
  test/profile_lifestyle_art_test.dart `
  test/weather_location_goal_test.dart `
  test/local_diagnostic_test.dart `
  test/remediation_characterization_test.dart `
  test/local_store_publication_test.dart `
  test/runtime_ux_test.dart
flutter analyze --no-pub
dart run tool/localization_audit.dart
dart run tool/secret_scan.dart
git diff --check
```

The dedicated new settings/photo/recovery suites contain 39 passing tests.
Their matrix covers exact byte/dimension boundaries, bad Base64/image data,
write/readback failure, cleanup false/mismatch, restart, conflicts, schema-one
upgrade, corrupt/future records, deletion retry, mixed-store failure, source
classification, absence/unavailable UI, reselection and protected photo rendering.
Existing persistence, profile, onboarding and related fixtures now explicitly
inject a test protected store instead of accidentally using unsupported storage.
The goal-persistence regression asserts no rollback of already committed private
state when ordinary publication fails.

## Scope and Limitations

Body Containment and Protected-Store Pilot remain ACCEPTED. DATA-007, DATA-008 and
SEC-003 remain ACCEPTED; their tests are in the focused set. Overall SEC-001 remains
IN_PROGRESS. This implementation cannot approve itself.

DATA-005, PRIV-002 and SEC-002 remain OPEN. No M4/M5/M6 migration, hydration-log
migration, projection convergence, Stage 0B/2/4 or Muse work is implemented.
Original HTD findings and historical checkpoints are retained.

No full-suite, build, hosted-CI, simulator or physical-device certification.
No Android/iPhone performance, battery or low-memory certification. Native
acknowledgement/readback is not physical flash durability. Logical deletion is
not backup/transfer or forensic erasure; old SQLite pages/backups are not claimed
erased. Older-binary downgrade/rollout remains an owner release decision.
Missing keys are not regenerated for an existing database. Unsupported platforms
stay explicitly non-ready rather than gaining a plaintext persistence fallback.

## Exact Implementation File List

The local implementation commit contains only these 45 paths:

```text
HTD.md
lib/l10n/app_en.arb
lib/l10n/app_es.arb
lib/l10n/app_fr.arb
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_en.dart
lib/l10n/app_localizations_es.dart
lib/l10n/app_localizations_fr.dart
lib/main.dart
lib/repositories/settings_repository.dart
lib/services/android_widget_service.dart
lib/services/daily_hydration_recommendation_coordinator.dart
lib/services/profile_photo_service.dart
lib/services/watch_connectivity_service.dart
lib/services/weather_goal_service.dart
lib/storage/encrypted_app_store.dart
lib/storage/protected_app_store.dart
lib/ui/screens/legal_about_screen.dart
lib/ui/screens/mission_screen.dart
lib/ui/screens/onboarding_screen.dart
lib/ui/screens/profile_screen.dart
test/app_locale_repository_test.dart
test/daily_hydration_recommendation_coordinator_test.dart
test/legal_document_test.dart
test/localization_test.dart
test/mission_and_farewell_test.dart
test/permission_consent_test.dart
test/persistence_test.dart
test/protected_app_store_test.dart
test/rc2_ux_repair_test.dart
test/recognition_moment_test.dart
test/runtime_ux_test.dart
test/startup_buffer_test.dart
test/startup_onboarding_test.dart
test/storage_recovery_test.dart
test/support/memory_protected_app_store.dart
test/v1_release_scope_test.dart
docs/architecture/SEC_001C_SETTINGS_PROFILE_IMPLEMENTATION.md
lib/repositories/settings_protection.dart
lib/services/validated_profile_photo.dart
lib/storage/protected_settings_record.dart
lib/ui/components/settings_protection_gate.dart
test/protected_settings_profile_test.dart
test/settings_protection_gate_test.dart
test/support/profile_photo_fixture.dart
```

## Preserved User Work

`edge_case.md` is excluded from this implementation:
SHA-256 `ac65c576d20c7d63175f1053b61a0fc99d06648659f841f9e088f0eda0733538`;
staged blob `0384da11c265db4f4bb4b6ad376d491f6bbd38fc`.
No push is authorized or performed.
