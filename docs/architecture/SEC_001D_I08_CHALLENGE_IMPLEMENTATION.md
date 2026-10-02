# SEC-001D / M4 / I08: Challenge State and History

Status: IMPLEMENTED_PENDING_ACCEPTANCE (I08 only). Implementation evidence is
not independent acceptance. Base: `32b9d3fa328e582996644964e53f6efba64898a2`.

Owner-authorized order: I08, then I09, then I13, then private I05. Each requires
its own local implementation commit, independent acceptance and administrative
closure before the next repository starts. No later repository is implemented
by this checkpoint. Overall SEC-001 and SEC-001D remain IN_PROGRESS.

## Pre-Implementation Inventory

- Dataset: active challenges and challenge history, including nested Pomodoro
  and activity-session state.
- Current repository: `lib/repositories/challenge_repository.dart`.
- Current storage / legacy source: plaintext `hydrion.joined_challenge.v1`
  through `HydrionLocalStore`; schema 6 and historical single-challenge forms.
- Classification: I08 B; unconstrained or free-text parameter contents inherit
  A until constrained. All challenge payload remains protected, including IDs,
  timestamps, targets, completion evidence and parameter values. No challenge
  payload is approved as ordinary preference residue.
- Current plaintext fields: schemaVersion, activeChallenges, challengeHistory;
  each entry contains id, targetMl, durationDays, joinedAt, bingo tile indices,
  parameters, completedActionIds, instanceId, lifecycleStatus, endedAt,
  pendingParameters and pendingParametersEffectiveDate. Legacy name/description
  are display copies; current display text is resolved from the catalog.
- Derived copies: in-memory progress/qualification maps are TRANSIENT. Reminder
  records and native notifications, widget summaries, AI context and report
  outputs retain their existing separate ownership. Persisted reminder copies
  are later I09; projections are later M6. No claim of projection protection or
  erasure accompanies source-store protection.
- Delete owner: ChallengeRepository.clear; LocalProfileResetService invokes it.
  Hydration logs and provider records must not be deleted by challenge cleanup.
- Consumers: challenge list/detail/history, PomodoroSessionService, activity
  sessions, challenge personalization, qualification calculations, reset and
  existing notification/widget/AI readers.
- Supported protection: existing Android/iOS app persistence factory only.
  Unsupported desktop/Web must expose unknown/unavailable storage without a
  plaintext fallback. Explicit test-memory repositories remain test facilities.
- Existing failure semantics: native false write acknowledgements are ignored;
  some mutations roll back on exceptions, others publish before persistence;
  malformed legacy records may be cleared or skipped. None of those behaviors
  establishes safe protected migration.
- Target: named `challenge_state` record in the accepted app database and key,
  with schema/revision/phase and a closed challenge/parameter contract. No new
  database, key, general KV API or feature-specific encryption wrapper.

## Required Authority and Boundaries

Legacy data is preserved until acknowledged protected write and equivalent
readback, followed by verified activation. Provisional mismatches, unknown
fields and future schemas quarantine rather than selecting defaults. Active
protected state wins over retained legacy copies. Cleanup is separately
acknowledged and retryable. Deletion intent precedes destruction and fences
restart migration; verified tombstones prevent resurrection.

DATA-005 global journaling, PRIV-002 backup/retention, SEC-002 credentials,
hydration persistence and all projection migrations remain out of scope.
Acknowledgement is not physical durability or forensic erasure. No full-suite,
build, hosted or device certification is implied.

## Implemented Checkpoint

The existing encrypted app database advances from schema 2 to 3, adding a named
`challenge_state` singleton. Existing context/settings/photo tables and the app
key remain unchanged. The row has schema, revision, phase and a closed canonical
challenge payload; it is not an arbitrary encrypted key/value facility.
`ProtectedChallengeRecord` validates entry fields and the supported activity,
setup and Pomodoro parameter vocabulary. Unknown extensions are rejected, not
silently discarded. The existing facade receives defensive decoded copies.

`ChallengeProtection` verifies provisional and active writes before cutover.
Active protected data is authoritative; conflicting provisional data, corrupt
data and future schemas remain quarantined. A payload-free revision reference
at `hydrion.challenge_state.authority.v1` prevents missing/older protected state
from becoming an empty successful bootstrap. Legacy source removal requires
native acknowledgement and absence readback. Invalid retained source remains
preserved even beside active protected state, with explicit cleanup-pending
status. Retry never silently reprocesses or discards incompatible source.

Deletion first acknowledges `hydrion.challenge_state.deletion.v1`, then verifies
an empty protected tombstone, the revision reference, source absence and intent
cleanup. Incomplete work remains deletion-pending through restart. These two
control keys contain no challenge payload. Other preferences are untouched.
This is dataset-local recovery, not DATA-005 global reset atomicity.

The repository rejects competing mutations while a write is pending and hides
unverified state. Retry reloads protected truth and recalculates bound hydration
qualification caches. The supported assumption is one repository-instance
writer in one isolate, not cross-process coordination. Closing a busy facade is
rejected; no broader lifecycle/drain certification is claimed.

Challenge screens expose localized unavailable/deletion-pending/cleanup-pending
states and retry. Existing widget publication skips unknown challenge state;
existing AI action execution reports persistence rejection instead of success.
These are consumer guards only: no widget/AI projection migration was added.
Existing reset orchestration receives challenge deletion failures unchanged.
Unsupported production platforms do not fall back to plaintext or test memory.

## Validation

- Broad focused run: 57 test files, 706 tests passed. Coverage includes the
  accepted protected-store/settings/body/token regressions, challenge lifecycle,
  Pomodoro, persistence, startup, localization and architecture controls.
- Final refresh/cache adjustment: six-file rerun, 85 tests passed:
  `protected_challenge_state_test`, `challenge_storage_notice_test`,
  `release18_shared_qualification_test`, `persistence_test`,
  `boundary_architecture_test`, `remediation_control_test`.
- New coverage: 26 protected challenge tests and four localized widget tests.
  Real encrypted-store tests cover migration/reopen/tombstones, transaction
  rollback and post-commit verification failure; controlled failures cover
  source preservation, authority loss, cleanup retry, rejected intent, restart
  fencing, unsupported storage, concurrency and private diagnostics.
- `flutter analyze --no-pub`: passed.
- Scoped formatting: 31 changed/new Dart files checked.
- Secret scan: passed. EN/FR/ES localization: 974 messages per locale, no
  missing/extra keys; mixed-language and placeholder audits: zero drift.
- Whitespace checks: passed.
- Intermediate fixture/schema/validation failures were corrected before the
  passing focused run; this is not a claim that every intermediate run passed.

No full-suite, build, hosted CI, physical-device, backup, forensic-erasure or
performance certification was performed. Native acknowledgement is not flash
durability. History remains aggregate/unbounded. Existing reminder, OS and
projection copies are not protected or erased by this checkpoint. Unrecognized
legacy data may require a separately approved compatible recovery path; retry
alone is not claimed to repair malformed source.

The implementation commit containing this receipt must exclude `edge_case.md`.
Preserved file SHA-256:
`ac65c576d20c7d63175f1053b61a0fc99d06648659f841f9e088f0eda0733538`.
Preserved staged blob: `0384da11c265db4f4bb4b6ad376d491f6bbd38fc`.
Independent read-only acceptance and administrative recording are required
before I09 starts. SEC-001D and overall SEC-001 remain IN_PROGRESS.

## Independent Blocked Review and H1/M1/M2 Correction (2026-10-02)

The independent review of implementation `bf2aa5b9a05bda5b863c5a807f364b382483751c`
was BLOCKED by HIGH H1, MEDIUM M1 and MEDIUM M2. The preceding implementation
results are retained as historical evidence, not acceptance. The owner reports
that the protected schema, DB/key reuse, authority/migration, cleanup, base
write/revision/deletion protocols, corruption handling and slice boundaries
passed that review. This correction does not redesign those foundations.

### H1: Ambiguous Commit and Hydration Compensation

Root cause: ChallengeProtection collapsed all write outcomes to a boolean and a
generic exception. Both challenge hydration-action paths then deleted the
acknowledged hydration log on any exception. A committed challenge transaction
whose readback failed was incorrectly treated as definitely rolled back.

Reproduction used real EncryptedAppStore/SQLCipher with failure injected at
`AppStoreStage.beforeVerification`, after transaction commit. Ordinary measured
intake and Pomodoro both retained completed action evidence after reload while
their hydration log count was zero. Both regression cases failed on original
production code at the retained-log assertion.

The narrow protection-layer change now carries the existing ProtectedWriteStatus
through ChallengeStorageUnavailable. A committed result followed by failed or
throwing readback becomes verificationFailed. Missing/unknown outcome is not
proof of rollback. The exception string remains payload-free.

Both hydration action paths reload canonical protected authority after a typed
failure and inspect matching challenge-instance evidence, including history.
Recovered committed evidence returns the saved log. Only a definitely rejected
write (failed transaction, unsupported destination or pre-write unavailable)
can compensate a log created by this invocation, and only when reloaded
authority is readable and has no matching evidence. An existing log is never
deleted by this retry path. Ambiguous outcomes, including readable-but-absent
evidence, retain the log and throw an explicit retryable typed failure.
Retry reuses the existing action-ID log and repairs missing challenge evidence
without adding hydration again. Already-completed duplicate taps still return
no new intake. No hydration schema/migration or cross-store transaction is added.

Pomodoro's existing pending-drink action/time/amount checkpoint is reused. When
the challenge action commits, the log survives; authoritative recovery allows
the measured-drink path to advance and clear its pending checkpoint. Repeated
retry does not duplicate intake. The production Pomodoro service is unchanged.

### M1: Unknown Is Not Absence

Home now checks repository isKnown before displaying challenge-picking/Bottle
Bingo fallback. It uses existing localized unavailable copy without inventing
progress. The coaching boundary has ChallengeContext.unavailable with null
presence, identifiers, quantities and progress, distinct from none/false/zero.
The existing adapter serialization therefore propagates null rather than false
absence; no projection-storage contract or migration was introduced.

Tests preserve an active protected instance across outage/reload/recovery and
verify true absence separately. Final test fixtures were also run against the
original Home/context implementations as a negative control: Home lacked the
unavailable message and coaching returned false where unknown was required.

### M2: Lifecycle Isolation

Resume and day rollover now await the same challenge reconciliation helper.
It retries unknown canonical storage, contains only ChallengeStorageUnavailable
and allows independent notification reconciliation to continue. Day rollover
also awaits Pomodoro reconciliation through this helper. Unexpected errors are
reported through FlutterError with a fixed payload-free error and stack; they
are not silently swallowed or logged with raw private exception messages.
Both callback entry points observe their asynchronous work explicitly.

The original shell, exercised with the final explicit locale-channel fixture,
failed both resume and fake-time day rollover with an escaped typed exception;
notification reconciliation remained uncalled. Recovery tests exercise the real
observer/timer and verify that a subsequent resume reloads the original active
challenge. No notification/reminder persistence is migrated.

### Correction Files and Validation

Production changes are limited to challenge_protection.dart,
challenge_repository.dart, hydration_contracts.dart, hydration_context_builder.dart,
home_screen.dart and hydrion_shell.dart. Tests add challenge_commit_recovery_test.dart
and challenge_outage_consumers_test.dart; the existing Pomodoro test fixture gains
an optional protected-store injection. Documentation changes are HTD.md and this
receipt. No encrypted-app-store schema/key/dependency changes are made.

Fresh validation on final source (2026-10-02):

- 65-file focused regression run: **769 passed**, zero failures (2m40s).
- Final correction assertions and governance recheck: **41 passed**; immediate
  recovered success and the restored Home summary are asserted explicitly.
- Includes 14 new correction regressions (nine H1, five M1/M2), all original
  I08 tests and accepted Body Containment, Protected-Store Pilot, SEC-001C,
  DATA-007, DATA-008 and SEC-003 regression files.
- Analyzer (`flutter analyze --no-pub`): passed, no issues.
- Scoped Dart formatting: nine files checked, zero changes.
- Secret scan including staged new tests: passed.
- EN/FR/ES: 974/974 Flutter messages, 24/24 Android messages; no missing/extra
  keys, identical untranslated strings or placeholder drift. No strings changed.
- Working-tree and staged whitespace checks: passed.
- Negative controls: both original H1 production paths lost the hydration log;
  all four original M1/M2 consumer controls failed. Early fixture compile/setup
  and analyzer lint issues were corrected before the final passing run.

Exact correction file set (11 files):

- `HTD.md`
- `docs/architecture/SEC_001D_I08_CHALLENGE_IMPLEMENTATION.md`
- `lib/domain/hydration_contracts.dart`
- `lib/repositories/challenge_protection.dart`
- `lib/repositories/challenge_repository.dart`
- `lib/services/hydration_context_builder.dart`
- `lib/ui/screens/home_screen.dart`
- `lib/ui/screens/hydrion_shell.dart`
- `test/challenge_commit_recovery_test.dart`
- `test/challenge_outage_consumers_test.dart`
- `test/pomodoro_session_service_test.dart`

Reproducible focused test manifest: pass the following paths to
`flutter test --no-pub` (paths are arguments, not separate invocations):

```text
  test/protected_challenge_state_test.dart
  test/challenge_storage_notice_test.dart
  test/protected_app_store_test.dart
  test/protected_daily_context_test.dart
  test/app_database_key_store_test.dart
  test/protected_settings_profile_test.dart
  test/settings_protection_gate_test.dart
  test/body_metrics_authority_regression_test.dart
  test/body_metrics_deletion_test.dart
  test/body_metrics_containment_test.dart
  test/sensitive_body_metrics_store_test.dart
  test/recommendation_input_token_test.dart
  test/boundary_architecture_test.dart
  test/remediation_control_test.dart
  test/daily_hydration_recommendation_coordinator_test.dart
  test/startup_onboarding_test.dart
  test/profile_age_review_test.dart
  test/persistence_test.dart
  test/app_locale_repository_test.dart
  test/v1_release_scope_test.dart
  test/storage_recovery_test.dart
  test/recognition_moment_test.dart
  test/permission_consent_test.dart
  test/localization_test.dart
  test/mission_and_farewell_test.dart
  test/rc2_ux_repair_test.dart
  test/legal_document_test.dart
  test/startup_buffer_test.dart
  test/personalization_repository_test.dart
  test/body_metrics_async_shell_test.dart
  test/profile_lifestyle_art_test.dart
  test/weather_location_goal_test.dart
  test/local_diagnostic_test.dart
  test/remediation_characterization_test.dart
  test/local_store_publication_test.dart
  test/runtime_ux_test.dart
  test/app_persistence_test.dart
  test/personalized_hydration_ui_test.dart
  test/personalized_hydration_engine_test.dart
  test/personalized_goal_override_confirmation_test.dart
  test/hydration_pacing_engine_test.dart
  test/challenge_personalization_correction_test.dart
  test/health_database_key_store_test.dart
  test/encrypted_health_data_repository_test.dart
  test/notification_service_test.dart
  test/challenge_activity_test.dart
  test/challenge_activity_lifecycle_ui_test.dart
  test/challenge_visual_game_test.dart
  test/challenge_history_test.dart
  test/pomodoro_session_service_test.dart
  test/pomodoro_session_ui_test.dart
  test/release18_shared_qualification_test.dart
  test/release18_challenge_lifecycle_test.dart
  test/release18_behavior_test.dart
  test/ai_action_executor_test.dart
  test/ai_action_contract_test.dart
  test/timed_session_notification_test.dart
  test/challenge_commit_recovery_test.dart
  test/challenge_outage_consumers_test.dart
  test/challenge_runtime_integration_test.dart
  test/challenge_recommendation_test.dart
  test/challenge_eligibility_test.dart
  test/release18_challenge_ui_test.dart
  test/adapter_contract_test.dart
  test/bottle_bingo_ui_test.dart
```

Limitations remain: one repository writer; no new global reconciliation journal;
an ambiguous retained log requires retry to complete missing challenge evidence.
This does not reconstruct hydration records already deleted by the previous
implementation; it must not fabricate historical intake.
No full-suite/build/hosted/device/backup/forensic certification. History retention,
derived persistent copies and I09/I13/private I05 remain separately scoped and
unstarted. Overall SEC-001 and SEC-001D remain IN_PROGRESS; I08 remains
IMPLEMENTED_PENDING_ACCEPTANCE until a separate independent re-review.
