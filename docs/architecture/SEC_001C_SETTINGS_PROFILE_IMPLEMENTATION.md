# SEC-001C Settings/Profile and Photo Implementation Receipt

Date: 2026-09-29
Branch: `audit/full-hydrion-integration`
Base: `ac65254e36c4a7827b444e7a30647b5c8b869fdc`
Authority: current HTD M3 / I03-I05 and owner approval.
Status: IMPLEMENTED_PENDING_SLICE_ACCEPTANCE; first independent acceptance BLOCKED;
H1/H2/M1/M2 correction awaits independent re-acceptance.
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

## H1/H2/M1/M2 Correction (2026-09-29)

Full correction SHA: `f1bd7ad2011c372aa45b29c68d712db46364d22f`.

The first independent acceptance of `92a9cd5ff29be97440fdbaf66033c6656073a787`
was BLOCKED by HIGH H1/H2 and MEDIUM M1/M2. The original implementation and
validation above are historical evidence, not first-pass acceptance. The owner
authorized only these four corrections and one local correction commit; no push.

### Reproductions and corrections

- H1: real SQLCipher provisional-photo migration followed by acknowledged photo
  deletion failed recovery with `corrupt` instead of `ready`, both on Retry and
  reconstruction. With deletion intent, reconciliation now compares all non-photo
  provisional fields exactly and permits only the authorized photo difference.
  It activates a photo-free record at the next revision and requires verified
  storage and acknowledged cleanup before retiring intent. Genuine profile
  conflicts still quarantine both copies.
- H2: failed old photo deletion followed by successful reset and a new photo save
  lost the new photo on reload. Reset now retires existing photo deletion intent
  after verified photo absence and legacy cleanup, before retiring reset intent.
  Failure to acknowledge either removal keeps reset incomplete and blocks new
  protected writes. No global DATA-005 reset journal is introduced.
- M1: a migrated positive generation marker plus unavailable protected storage
  caused an ordinary theme save to throw. The seven ordinary fields now have an
  explicitly ordinary-only repository path. It preserves the source and marker,
  requires preference acknowledgement/readback, and neither reads nor writes
  protected payload. Protected/mixed mutations still require known authority;
  revision fencing for those writes remains intact. The facade rejects protected
  changes even if a caller incorrectly marks the request ordinary-only.
- M2: Profile Save ignored false avatar/goal/container results and allowed void
  setter exceptions to escape. All six operations now contribute to one action
  result. False or thrown failures remain incomplete even if later saves succeed;
  fixed localized feedback reports the outcome without sensitive interpolation.
  The editor closes only when all requested operations succeed. Committed data
  is never rolled back through an old whole-settings snapshot.

Profile Save operation audit: profile, avatar, daily goal and container setters
return bool; volume-unit and personalized-goal-option setters return void and may
throw. Profile/goal/options are protected writes with ordinary publication;
avatar/unit/container are ordinary. The action retains the existing six-call
order and does not add an unchanged-value optimization that could skip existing
manual-goal bookkeeping.

### Correction regression evidence

There are 22 new cases: 14 repository/SQLCipher cases and eight Profile Save widget
cases. They cover provisional deletion retry/reconstruction, all migration/photo
phases, retained non-photo conflict quarantine, reset intent-removal rejection,
new-photo survival, all seven ordinary fields under protected unavailability,
protected/mixed rejection, ordinary failure/recovery, success and each of six
compound-save failure positions, thrown failure, unavailable protected writes,
and successful retry. Existing exact photo limits and foundation tests remain.

Pre-fix production reproduced all four findings. Initial widget harness attempts
required viewport and async-zone corrections before producing the intended M2
failures; those harness failures are not defect evidence. Corrected fixtures
showed the missing failure message, premature editor closure and escaped
SettingsProtectionFailure against unchanged Profile Save production code.

Final correction tests: **568 passed across 43 files**, exit 0. This is the
34-file selection above plus app_persistence, personalized_hydration_ui,
personalized_hydration_engine, personalized_goal_override_confirmation,
hydration_pacing_engine, challenge_personalization_correction,
health_database_key_store, encrypted_health_data_repository and
notification_service tests (all under `test/`, with `_test.dart` suffix).
The two focused settings/photo suites contain 61 tests including the 22 new cases.
Scoped formatting checks five Dart files with no changes; localization remains
972/972 Flutter and 24/24 Android messages for EN/FR/ES; secret and whitespace
checks passed. No strings changed. One test-only braces lint was corrected;
the final `flutter analyze --no-pub` rerun passed with no issues.

Correction scope is exactly seven paths: `lib/repositories/settings_protection.dart`,
`lib/repositories/settings_repository.dart`, `lib/ui/screens/profile_screen.dart`,
`test/protected_settings_profile_test.dart`, `test/settings_protection_gate_test.dart`,
this receipt and `HTD.md`. Database schema/key, 29/7 classification, photo policy,
target/consent semantics and later slices are unchanged. SEC-001 remains
IN_PROGRESS; SEC-001C remains IMPLEMENTED_PENDING_SLICE_ACCEPTANCE. This is
implementation evidence, not independent acceptance. All original platform,
backup, forensic and full-suite limitations remain.

## L1/L2 Follow-up (2026-09-30)

Base/canonical H1/H2/M1/M2 correction:
`f1bd7ad2011c372aa45b29c68d712db46364d22f`.
Original implementation remains `92a9cd5ff29be97440fdbaf66033c6656073a787`.
This follow-up addresses only the two LOW findings; it is not acceptance.

- L1 reproduced before the production edit: the operation-2 Profile Save widget
  regression failed with one incomplete-save message still present after a
  successful full retry, where zero were expected (exit 1).
- Root cause: the successful action popped the editor without retiring feedback
  previously registered with the enclosing ScaffoldMessenger. Repeated failures
  could also queue more than one message.
- Correction: only after the complete six-operation result succeeds, clear the
  screen's snackbar queue and immediately remove its current snackbar before
  closing the editor. No feedback cleanup occurs on a merely successful later
  sub-operation within a failed compound attempt. Immediate removal avoids a
  pending animated-dismissal callback after UI teardown.
- Widget assertions now cover message absence after every successful failure
  retry, repeated failed attempts followed by success, a subsequent failure
  showing feedback again, later-operation successes not masking failure, and
  absence of synthetic profile values in feedback. Existing test cases were
  extended; no tests were removed or skipped.
- L2 records the full correction SHA above and in its original correction
  section. The first BLOCKED review, H1/H2/M1/M2 and original evidence remain.
- Validation: 111 tests passed across protected_settings_profile,
  settings_protection_gate, localization, boundary_architecture,
  remediation_control and runtime_ux test files. The initial animated-only fix
  produced six widget lifecycle failures; the final immediate cleanup passed
  the identical six-file selection. Analyzer passed; two-file formatting,
  EN/FR/ES localization parity, secret scan and whitespace checks passed.
- Only ProfileScreen, its widget test, this receipt and HTD changed. Repository,
  reconciliation, 29/7 classification, photo limits and target/consent semantics
  are unchanged. No later slice started; SEC-001 remains IN_PROGRESS and SEC-001C
  remains IMPLEMENTED_PENDING_SLICE_ACCEPTANCE. No new full-suite, build, hosted,
  physical-device, backup or forensic certification. No push.
