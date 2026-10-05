# SEC-001D / M4 / I09: Reminders and Orphan Notification IDs

Status: IMPLEMENTED_PENDING_ACCEPTANCE (I09 only). Implementation evidence is
not independent acceptance. Base: `fe4d7ac9075f1a59b35d8cf41c87596cbd6b1b5b`
(`origin/main` after PR #140), which contains the accepted I08 correction
`a7f3104ee5c29a813824fb7f7f551fb81291e59a`, the I08 acceptance record
`bf19ae6e2b793e631dcfd13c6165d7618d5fac30` and the handoff documentation
`648c6a7cf76d3f2b0023e9c76d175147b8f6f41b`. Branch:
`remediation/sec-001d-i09-reminders`.

Owner-authorized order: I08 (ACCEPTED), then I09, then I13, then private I05.
I13 and private I05 remain UNSTARTED. Overall SEC-001 and SEC-001D remain
IN_PROGRESS.

## Owner Decisions Applied (2026-10-05)

- Orphan notification IDs are protected under the same I09 authority as the
  reminder definitions. No permanent preference residue; no plaintext fallback
  so that OS cleanup can run while the protected database is unavailable.
- Orphan IDs survive deletion of reminder definitions until OS cancellation is
  confirmed. An empty reminder collection never implies an empty cleanup set.
- OS scheduling/cancellation remains a separately reconciled projection outside
  the protected database transaction.
- The schema-3 to schema-4 upgrade defect (see below) is fixed as a necessary
  prerequisite, with a real SQLCipher upgrade regression.
- Out of scope, unchanged: visible notification content/disclosure, Stage 7
  lifecycle architecture, ReminderTile wake/sleep and sent-today inputs,
  immediate scheduling of AI suggestions, permission observation,
  `String.hashCode` notification-ID derivation, OS ID sweeping, timezone/DST
  semantics, timed-session convergence, DATA-005, PRIV-002, SEC-002, I13,
  private I05, hydration-log and projection migration.

## Pre-Implementation Inventory

- Dataset: reminder definitions and the outstanding OS-cancellation set.
- Repository: `lib/repositories/reminder_repository.dart`.
- Legacy sources: plaintext `hydrion.reminders.v1` (list of definitions) and
  `hydrion.reminder_orphans.v1` (sorted platform IDs) through
  `HydrionLocalStore`.
- Classification (HTD I09 row): id, triggerTime, message, priority, enabled,
  challengeId, scheduleState, scheduleError, lastScheduledAt: B; free-text
  message A-capable; orphan IDs: C. Reminder IDs embed microsecond timestamps
  and are not D. Payload-free authority and deletion markers are D.
- Derived copies: `platformNotificationId` (not stored), scheduled OS
  notifications (title plus message body; SEC-001F/Stage 7), AI
  `ReminderContext`, Profile/tile summaries (transient). Challenge parameters
  holding reminder IDs remain I08-owned and unchanged.
- Writers: `NotificationService` (create/update/delete, reconcile schedule
  state, orphan record/resolve, cancel-all, policy suggestion),
  `HydrationAiActionExecutor` (direct `save`), `PomodoroSessionService`,
  challenge experience screens, Reminders screen, ReminderTile, and
  `LocalProfileResetService` (`clear`).
- Readers: Reminders screen, Profile, ReminderTile, `LocalHydrationContextProvider`,
  Pomodoro reminder-existence check, `NotificationService` duplicate detection
  and reconciliation.
- Previous failure semantics: native false acknowledgements ignored;
  mutations published before persistence; future-schema, wrong-shape and
  malformed sources loaded as an empty writable list that the next save
  overwrote; invalid records were skipped and lost on the next write;
  malformed orphan JSON became an empty set; `clear()` used an unacknowledged
  remove.

## Implemented Checkpoint

**Schema.** The existing encrypted app database advances from schema 3 to 4,
adding a named `reminder_state` singleton (schema, revision, phase, payload).
Existing daily-context, settings/photo and challenge tables, the app key and
the database file are unchanged. No new database, key, dependency or general
key/value API is introduced.

**Upgrade defect fixed.** The schema-3 upgrade step created `challenge_state`
whenever `version != schemaVersion`. Raising the version to 4 without changing
it would have attempted to recreate `challenge_state` on every existing
schema-3 database, so the database failed to open (`AppStoreOpenFailure`).
Each table is now created only by the step that introduced it
(`version <= 2` for `challenge_state`, `version <= 3` for `reminder_state`),
and supported versions are `0..4`.

**Closed record.** `ProtectedReminderRecord` holds `schemaVersion`,
`reminders` and `orphanNotificationIds` as one authority. Entries allow only
the nine classified fields; identifiers, normalized message (at most 160
characters), priority `0..5`, enabled flag, the eight schedule states, dates
and challenge links are validated. `scheduleError` is a closed vocabulary of
the seven current codes plus `legacy_unclassified`. Orphan IDs are unique
integers in `0..0x7fffffff`. A deleted tombstone holds no definitions but may
hold orphan IDs. Payloads are canonically ordered; `toString` is payload-free.

**Migration authority** (`ReminderProtection`, mirroring accepted I08):

- Both legacy keys form one source, decoded strictly. Malformed, wrong-shape,
  future-schema, partially invalid, unknown-field, non-boolean `enabled`,
  invalid challenge-link, duplicate-identity and invalid orphan sources are
  quarantined (`corrupt`/`unsupported`) with every source byte preserved and
  all writes refused.
- Operational fields normalize as before: legacy schedule-state aliases map to
  current states, and free-form legacy `scheduleError` text (written by
  earlier builds) maps to `legacy_unclassified` rather than being retained or
  quarantined. A missing legacy `id` keeps the existing millisecond fallback,
  so platform notification IDs are not re-derived.
- Provisional write and verified readback precede active cutover; a
  payload-free revision reference at `hydrion.reminder_state.authority.v1`
  prevents missing/older protected state from booting empty. A conflicting
  provisional record is quarantined.
- Legacy removal requires native acknowledgement and absence readback for each
  key; failures leave the store known but `cleanupPending`, retried later.

**Write authority.** All repository loads and mutations are serialized
through one per-instance queue (one writer per isolate). Each mutation
computes the complete next state, commits it with verified readback, and only
then publishes and notifies. A rejected write throws a typed
`ReminderStorageUnavailable` carrying the write status; post-commit
verification failure is ambiguous (`verificationFailed`), not rolled back.
Schema-invalid caller input is rejected without degrading the store. New
reminders whose generated ID would collide receive a numeric suffix, so the
protected record keeps unique identities.

**Deletion.** `clear()` first acknowledges
`hydrion.reminder_state.deletion.v1`, then writes a verified tombstone,
updates the revision reference, removes legacy sources and the intent. The
tombstone retains outstanding orphan IDs, the platform IDs of the deleted
definitions and any interpretable never-migrated legacy orphan IDs (plus
legacy definitions' platform IDs). An uninterpretable legacy orphan source is
preserved and reported as `cleanupPending`. Restart finishes pending deletion
before migration; replay is idempotent. This is dataset-local, not DATA-005
global reset journaling.

**Consumers (availability safety only).**

- `NotificationService`: creation/update return
  `NotificationScheduleResult.storageUnavailable` and perform no OS side
  effect before the definition commits; delete throws the typed failure for
  unknown storage; reconciliation and orphan cleanup skip unknown storage and
  stop on mid-run storage failure; failed cancel-all during an outage stays
  pending; the policy suggestion reports unknown storage. Added
  `deleteRemindersIfKnown` for post-commit challenge cleanup. Scheduling
  semantics are unchanged.
- Pomodoro never treats unknown reminder storage as a missing reminder (no
  dropped association, no duplicate). Natural/early completion is not blocked
  by reminder storage; user transitions surface the typed failure.
- Challenge screens: post-commit obsolete-reminder deletion is contained; the
  pre-commit activity edit aborts with the storage message; daily checkpoint
  cleanup keeps reminder links whose deletion is unconfirmed.
- AI `SuggestReminderAction` reports rejection when storage is unavailable.
  It still persists without immediate scheduling (Stage 7 debt preserved).
- `ReminderContext.unavailable` uses null count/time rather than zero.
- Startup wiring passes the protected store; shell resume and day rollover
  retry unknown reminder storage, contain its typed failure and continue.
- Reminders screen, ReminderTile and Profile show unavailable,
  deletion-pending and cleanup-pending states with retry; EN/FR/ES strings
  `reminderStorageUnavailable` and `reminderDeletionPending` were added
  (cleanup-pending reuses the existing protected-copy cleanup message).
- `LocalProfileResetService` is unchanged; reminder deletion failures now
  surface truthfully through its existing per-subsystem status.

Unsupported production platforms (desktop/Web) report `unsupported`; there is
no plaintext or memory fallback. `ReminderRepository.memory()` remains an
explicit test/preview facility.

## Validation

All implementation-side results below were produced on the final source and
are implementation evidence, not independent acceptance.

- Baseline at `fe4d7ac`, clean worktree: 14 reminder/notification/persistence/
  governance files, **220 passed**, exit 0.
- Final focused regression: the 65-file I08 manifest plus the two new I09
  files (67 files), **826 passed**, zero failures, exit 0 (311 s). It ran in an
  isolated worktree verified byte-identical to the implementation's `lib/`,
  `test/`, `docs/` and `HTD.md`, because an external process repeatedly
  regenerated `.dart_tool/package_config.json` in the primary checkout and
  stalled two earlier runs (INCOMPLETE, not counted). The last stalled run had
  348 passes and no failures before stalling.
- An earlier complete run on pre-final source reported one failure:
  `protected_settings_profile_test.dart` "schema-one pilot upgrades without
  changing its accepted record". Its fixture simulated schema 1 by dropping
  later tables but predated `reminder_state`; the fixture now also drops it.
  No production change was needed; the file then passed (50 tests).
- New coverage: 37 tests in `protected_reminder_state_test.dart` (real SQLCipher
  v3->v4 upgrade preserving daily-context, settings/photo and challenge rows;
  encrypted migration and plaintext scan; interruption at write/verification;
  future protected schema; ambiguous post-commit verification; 12 quarantine
  cases with byte-preserved source; legacy normalization; orphan-only state;
  cleanup retry; authority reference; provisional conflict; unsupported
  platform; rejected write; schema-invalid input; serialized concurrency;
  deletion, restart, rejected intent, never-migrated and uninterpretable legacy
  cleanup; payload-free diagnostics; closed schema) and 20 tests in
  `reminder_outage_consumers_test.dart` (service, Pomodoro, AI, coaching
  context, startup/reset, shell resume and day rollover, EN/FR/ES UI).
- Updated tests: `storage_recovery_test`, `local_store_publication_test` and
  `persistence_test` previously characterized lenient/plaintext behavior; they
  now assert the accepted quarantine/protected invariants with the original
  inputs retained. `pomodoro_session_service_test` and
  `protected_settings_profile_test` received fixture-only updates.
- Negative controls (each failed when its guard was removed, passed restored):
  the original upgrade condition (`AppStoreOpenFailure(corrupt)`); the
  Pomodoro unknown-storage guard; the coaching-context unavailable mapping; the
  Reminders-screen unknown/empty distinction; the AI rejection mapping; the
  Pomodoro completion containment; the shell resume retry. Quarantine tests
  assert that the former overwrite path (save after failed load) is refused.
- `flutter analyze --no-pub`: no issues.
- Scoped formatting: 27 changed/new Dart files, zero changes.
- Secret scan: passed. Localization audit: EN/FR/ES 976/976 Flutter messages
  (two added), Android 24/24; mixed-language audit: zero identical strings or
  placeholder drift.
- `git diff --check`: passed.

Not run: complete Flutter suite, platform builds, hosted CI, physical devices,
backup/restore, forensic erasure, performance.

## Limitations

- One repository writer per isolate; no cross-process coordination.
- Native acknowledgement/readback is not flash durability or forensic erasure.
- Existing users whose legacy reminder source is uninterpretable see
  reminders as unavailable until a separately approved recovery path exists;
  their source is preserved, not repaired.
- A reminder whose deletion could not be confirmed during an outage remains a
  saved definition (and may fire) until deleted after recovery.
- OS-delivered notification content and history are not protected or erased
  by this checkpoint. Older app binaries reading the sanitized preferences
  would see no reminders; downgrade safety is a release decision.
- No full-suite, build, hosted CI, physical-device, backup, forensic-erasure or
  performance certification.

Independent read-only acceptance of this pushed branch and administrative
recording are required before I13 starts. Overall SEC-001 and SEC-001D remain
IN_PROGRESS.
