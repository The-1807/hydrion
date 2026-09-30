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
