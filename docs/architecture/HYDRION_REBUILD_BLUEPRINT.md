# Hydrion Rebuild Blueprint

Status: **DRAFT — awaiting owner approval.** No code changes are authorized
by this document until the owner approves it and resolves the decisions in
section 7. Base: `origin/main` at `e7d805d` (includes I09, PR #141).

This blueprint replaces HTD.md's "one repository checkpoint at a time"
sequencing (owner decision, 2026-10-05). HTD.md remains the authority for
findings, evidence and history; this document is the single building plan
that every implementation agent follows. Its rule is simple: **every domain
mechanism exists once.** A new feature reuses the canonical component or
extends it; it never gets its own copy.

Sources: six independent read-only architecture audits (persistence, intake,
time/projections, targets, lifecycle/boundaries, baseline/validation) at
`c88b896`, merged and conflict-resolved here. Findings marked **verified**
were re-checked in source by the integrator.

---

## 1. Diagnosis in numbers

| Area | What exists today |
|---|---|
| Protected storage | The same migrate/verify/cutover/cleanup/deletion protocol re-implemented 4–5 times (challenge, reminder, settings, daily context, body); acknowledged-remove helper ×5, write+readback ×~12; 4 SQLCipher connections opened at startup, each with its own retry logic; 3 near-identical key stores; status enums and "unavailable" exceptions duplicated per dataset. |
| Water logging | 10 write paths; validation bounds ≥0 / 50–2000 / 1–5000 / >0 / none; 4 action-ID schemes; 3 day-token formatters; 3 in-flight guards; 2 copies of challenge rollback; whole-list rollback that can undo another write. |
| Time | 135 direct `DateTime.now()` calls in 44 files; 6 date-key formatters (one differs on UTC input); fixed-24h "day" arithmetic in 5 places; `inDays` DST off-by-ones in 4 places. |
| Aggregates | "Today total + %" computed 6 ways; 2 streak rules (365 cap, 30 cap — the latter unused in the app); attainment always uses the *current* goal for past days. |
| Targets | 2 calculators that disagree (engine vs weather preview); 6 commit paths, the automatic weather path bypassing policy; goal state spread over 11 persisted flags with contradictory combinations. |
| Lifecycle | 6 reconciliation entry points with different orders and error handling; 2 notification mechanisms; 4 sources of "notification permission" truth; health "connected" derived from a persisted flag. |
| Composition | 47 service fields, ~45 published to the UI, 16 with no consumer; UI reads repositories directly ~115 times across 27 files; domain imports repositories in 4 files. |
| Validation | Full suite passes in default order (1,159 tests, 842 s) but **fails under randomized order**; CI summarizer counts `error` results as passing; literal audit has 32 unresolved findings and is not in CI; historical hangs were masked by a test workaround, not fixed. |

## 2. Verified defects to fix first (Wave 0)

These are user-visible or safety-relevant, independent of the restructure,
and small. Each gets a negative-control regression test.

| # | Defect | Evidence | Severity |
|---|---|---|---|
| D1 | Clinician mode with a missing/out-of-range clinician target silently produces a normal personalized goal with **no safety notice** | `body_metrics.dart:428-434` → `personalized_hydration_engine.dart:129-150` (verified) | HIGH (safety) |
| D2 | Any startup step failure leaves the app **stuck on the splash screen** with no retry | `startup_screen.dart:80-85` (verified) | HIGH |
| D3 | Daily context has no authority marker: protected DB loss after legacy cleanup loads as "ready, empty" instead of unavailable | `daily_hydration_context_repository.dart:124-158` (verified) | HIGH (data) |
| D4 | Confirming an AI suggestion twice quickly **logs water twice** | `coach_suggestion_service.dart:80-93` (verified) | MEDIUM |
| D5 | Android widget tap ID minted at render, so a second tap before redraw is **silently dropped** | `HydrionWidgets.kt:61` (verified) | MEDIUM |
| D6 | Confirming a weather suggestion silently turns **off** the user's auto-apply preference | `hydrion_shell.dart:327-333`, default `autoApplyEnabled=false` at `settings_repository.dart:1035` (verified) | MEDIUM |
| D7 | Widget shows 0 checkpoints after midnight during an overnight shift (calendar vs activity day token) | `android_widget_service.dart:90-98` vs `challenge_repository.dart:1027` | MEDIUM |
| D8 | DST off-by-one in challenge schedules and "yesterday" labels | `challenge_repository.dart:1887-1915`, `log_screen.dart:185`, `reminders_screen.dart:302` | MEDIUM |
| D9 | Order-dependent test failure: legal screen creates its asset Future in `build`, cached process-wide | `legal_about_screen.dart:117-119` (verified) | MEDIUM (validation) |
| D10 | CI summarizer treats test `error` results and timeouts as passing | `flutter-ci.yml:383,478` (verified) | HIGH (validation) |
| D11 | Web startup throws on unguarded `dart:io Platform` (HTD-PLATFORM-003) | `android_widget_service.dart:128,282,310`; `watch_connectivity_service.dart:35,52` (verified) | MEDIUM |

## 3. Canonical components (the building plan)

Each component has one owner module. Interface sketches are in the source
audits; this section fixes the decisions.

| ID | Component | Owner path | Replaces | HTD findings |
|---|---|---|---|---|
| K1 | **Clock & calendar authority**: `HydrionClock`, `LocalDate`, half-open `DayInterval`, `HydrionCalendar.changes` (midnight, timezone change, resume), backed by `package:timezone` with an injected zone | `lib/domain/time/` | 135 `now()` calls in logic, 6 key formatters, 24h arithmetic, `inDays`, shell rollover timer | TIME-001/002/003, DATA-003 |
| K2 | **Protected dataset authority**: `ProtectedDataset<T>` (the M-protocol written once), `ProtectedCodec<T>` per dataset, one `ProtectedAppDatabase` connection owner, shared status/exception vocabulary carrying the I08 commit-ambiguity outcome, `HydrionLocalStore.writeAcknowledged/removeAcknowledged`, `DatasetMarkers`, one `SecureKeyProvisioner`, one SQLCipher factory | `lib/storage/`, `lib/repositories/protected_dataset.dart` | challenge/reminder/settings/context protection forks, 5 remove helpers, 4 connections, 3 key stores | SEC-001, OBS-001, ARCH-005 |
| K3 | **Deletion plan**: `DeletionParticipant` per dataset; reset runs an ordered, resumable plan with a payload-free journal | `lib/application/reset/` | sequential `LocalProfileResetService` that loses pending states | DATA-005 |
| K4 | **Hydration intake service**: `submit(IntakeCommand) → IntakeOutcome` owning validation (`IntakePolicy`), canonical ml, UUID event IDs + persisted idempotency keys, provenance, one FIFO queue, typed change stream | `lib/application/intake/` | 10 write paths, 4 ID schemes, 3 guards, whole-list rollback | INGEST-001/002, DATA-002, DATA-010, DEAD-001 |
| K5 | **Target decision service**: `PersonalizedHydrationEngine` sole calculator; `TargetDecisionService.execute(TargetCommand)` sole committer with explicit modes (automated, userConfirmed, manualEdit, clinicianLocked); `ActiveTargetState` replacing 11 flags; append-only `TargetDecisionRecord` ledger | `lib/application/targets/` | weather preview calculator, 6 commit paths, flag archaeology | ARCH-001, ORCH-001/002, STATE-001, DATA-001, TEST-001 |
| K6 | **Hydration facts**: `HydrationFactsQuery` (day, range, streak with one `StreakPolicy`, period summaries), attainment from `targetOn(LocalDate) → known/unknown` | `lib/application/facts/` | 6 today-total computations, 2 streaks, reports/analytics rebuilds | ARCH-002/003/004/008, DATA-004/009/011 |
| K7 | **Projection envelope & publisher**: `ProjectionEnvelope` (generatedAt, dataDate, zone, factsVersion, staleAfter); one builder per purpose (widget, watch, AI-daily, AI-trend, report) with an allow-list; coalescing publisher; atomic widget write | `lib/application/projections/` | ad-hoc widget/watch/AI/report assembly, dropped syncs | DATA-006, PRIV-001, ORCH-004 |
| K8 | **Lifecycle coordinator**: one `AppLifecycleListener`; ordered, idempotent `ReconciliationStep`s with per-step containment and typed outcomes; coalescing | `lib/application/lifecycle/` | 6 entry points, per-feature shell catches, startup that can block routing | ORCH-003, OBS-001 |
| K9 | **Notification orchestrator**: `upsertScheduled`, `setTimedSession`, `converge`; distinct scheduled/timed adapters; `TimedSessionSource`; one `NotificationIdAllocator` | `lib/application/notifications/` | AI/UI/Pomodoro direct reminder writers, duplicated homework projection, in-memory timed state | ORCH-003 |
| K10 | **Observed state & capability source**: `Observed<T>` with age; `ProviderConnectionState`; one `CapabilitySource` (supported vs deliverable) | `lib/application/capabilities/` | 4 permission truths, persisted "connected", frozen capability snapshot | STATE-002, PLATFORM-001/002 |
| K11 | **Composition root & boundaries**: `HydrionServices` private; UI receives per-domain command/read-model interfaces; boundary tests for domain→repositories/services and UI→repositories; no memory fallback in `HydrionApp` | `lib/main.dart`, `lib/app/` | service locator, layer inversions, 16 unused providers | ARCH-005/006, PERF-002, DEAD-002 |
| K12 | **Test & CI platform**: `composeTestServices`, `flutter_test_config.dart` (fail on unmocked channels, reset globals), controllable fakes in `test/support/`, fixed clocks and zone fixtures, tested CI summarizer with TIMEOUT/INCOMPLETE, logged random seed, literal audit as a gate | `test/support/`, `tool/` | ~60 per-file fakes, masked hangs, untrustworthy summary | TEST-002, Stage 0B debt, PLATFORM-003 |

Shared primitives used by several components (written once in `lib/core/`):
`SerialQueue` (single-writer queue: K2, K4, settings, reminders),
`Coalescer` (one in flight + dirty follow-up: K7, K8, K10), and the typed
`ProtectedWriteStatus.definitelyNotCommitted` rule (K2 → K4 outcomes).

### Must stay separate (by design, not duplication)

- Health database, schema, key and provider deletion vs the app database.
- The four key materials (health DB, app DB, body, recommendation equality).
- Body-metrics semantics (pending secure, ambiguous, in-place deletion
  envelope); it adopts K2's vocabulary and markers only (decision O3).
- SEC-003 equality tokens and their memory-only degradation.
- Per-dataset closed codecs and challenge-specific day policies
  (`ChallengeDayPolicy` built on K1, shared by repository and widget).
- Imported health records vs manual intake; activity metrics are not intake.
- Scheduled reminders vs timed-session notifications (distinct adapters under K9).
- Genuine durations (weather cooldown, timer elapsed) vs calendar days.

### Cross-audit conflicts resolved

1. **On-disk compatibility is frozen.** `yyyy-MM-dd` keys, existing preference
   and marker keys, DB schema 4 tables, legacy challenge action-ID formats and
   `log-<actionId>` IDs are read as-is. New formats are versioned, never swapped.
2. **Event time.** Intake stores the UTC instant plus the offset/zone at
   observation (K4 needs it, K1 defines it). Existing offset-less records are
   read as local wall time, as today.
3. **I09 is refactored, not reverted.** `ReminderProtection` moves onto K2 with
   identical behavior and tests (orphan-ID survival is a `DeletionPolicy` hook).
4. **Weather auto-apply** is a K5 command dispatched by a K8 lifecycle step;
   the shell only renders `NeedsConfirmation`.
5. **Challenge hydration actions** become K4 callers using `CompensateIntake`,
   preserving every I08 commit-ambiguity guarantee and its tests.

## 4. Waves

Dependencies follow HTD's stage table. Inside a wave, workstreams run in
parallel in isolated worktrees. Every wave ends with auditor agents (who did
not write the code) and owner sign-off before merge.

| Wave | Workstreams (parallel) | Needs |
|---|---|---|
| **0 — Truth & safety** | W0-A K12 test/CI platform (summarizer, seed, test config, `composeTestServices`, injectable body store in `fromStore`, legal Future fix D9, literal-audit classifier) · W0-B defect fixes D1–D8 · W0-C Web guards D11 | — |
| **1 — Foundations** | W1-A K2 protected dataset consolidation (challenge, reminder, context, settings; body vocabulary only) · W1-B K1 clock & calendar + migration of pure-calendar consumers · W1-C K5 target policy (calculator removal, committer, explicit state; ledger schema only) | Wave 0 gates |
| **2 — Commands** | W2-A K4 intake service and caller migration · W2-B K8 lifecycle coordinator with current steps wrapped 1:1 · W2-C K3 deletion plan | K1 (for K4), K2 |
| **3 — Facts** | W3-A K5 ledger + K6 facts, consumer migration (Home, analytics, reports, challenges, streak) · W3-B protected hydration log storage (SEC-001E/M5) on K2 using K4's queue · W3-C I13 and private I05 built directly on K2 | K1, K4, K5 |
| **4 — Projections & lifecycle completion** | W4-A K7 envelopes and publishers (widget, watch, AI, report) · W4-B K9 notification orchestrator + K10 observed state/capabilities · W4-C Stage 8 health context wiring | K6, K8 |
| **5 — Boundaries & closure** | W5-A K11 composition root, use-case interfaces, boundary guards, removal of unused providers/dead code · W5-B HTD reconciliation of every finding · CodeRabbit required check | all callers migrated |

Muse (HTD Stage 10) stays paused until all waves are accepted.

## 5. Gates (definition of done for every wave)

- Full suite PASS in default order **and** with a logged random seed, via the
  repaired summarizer (TIMEOUT/INCOMPLETE are never PASS).
- `flutter analyze`, format, secret scan, localization parity, literal audit.
- Architecture guards: no new duplicate of a canonical mechanism (import and
  call-site guards per component), no domain→repository/UI imports.
- System invariant tests for the wave's component (e.g. every intake source
  converges on one daily total; one target committer; report, streak and widget
  agree on day and historical target).
- Negative controls for every behavior change; equivalence tests for refactors.
- Auditor report with no BLOCKER/HIGH open; owner sign-off.

## 6. Proposed HTD amendments

1. Replace "no general storage framework or one secure service per feature"
   with: "One typed protected-dataset authority with closed per-dataset codecs
   is mandatory; arbitrary key/map APIs, per-feature stores and per-feature
   keys remain forbidden."
2. Replace one-slice-at-a-time sequencing with this blueprint's waves and gates.
3. Add invariants: one app-DB connection owner per process; one canonical
   component per mechanism listed in section 3.
4. Acceptance per wave = auditor agents + owner sign-off (owner decision).
5. Record new defects D1–D11 as findings with evidence.

## 7. Owner decisions (recommended defaults in bold)

| # | Decision | Needed by | Recommended |
|---|---|---|---|
| O1 | Clinician mode with invalid target | W0 | **Block auto-apply and show the fluid-restriction notice until a valid target is entered** |
| O2 | Startup step failure | W0 | **Route into the app in a degraded state with a visible notice and retry; never block on splash** |
| O3 | Body metrics onto K2 or keep its accepted protocol | W1 | **Keep its protocol, adopt shared vocabulary/markers only** |
| O4 | Day-scoped recommended target at midnight | W1 | **Expire to the baseline at local midnight** |
| O5 | Manual edit under clinician mode | W1 | **Allow with a mandatory clinician notice (user-authoritative)** |
| O6 | Auto-apply as a production feature | W1 | **Supported, with an explicit settings toggle** |
| O7 | Intake bounds and zero | W2 | **1–5000 ml; 0 rejected; edit dialog rejects instead of clamping; restoring an existing event exempt** |
| O8 | Future-time tolerance for edits | W2 | **No future times beyond 5 minutes** |
| O9 | Widget dedupe | W0/W2 | **Per-tap native nonce** |
| O10 | Legacy writers `CoreBridge.logEcoEvent`, `WearableService.syncHydration` | W2 | **Delete** |
| O11 | History grouping when travelling | W1 | **Group by the zone at the time of drinking** |
| O12 | "Today" for shift users | W1 | **Calendar day for totals; waking window only for pacing** |
| O13 | Streak counts today while in progress | W3 | **Today in progress never breaks a streak** |
| O14 | Hydration score and eco estimate | W3 | **Keep both, as named, versioned derivations; eco labelled "estimate"** |
| O15 | Unused `AchievementService`, `HydrionCompanionDirector` | W3 | **Delete** |
| O16 | Target ledger retention and reset | W3 | **Keep 400 days; included in reset and export** |
| O17 | Reminders across timezone changes | W4 | **Local wall time (8:00 stays 8:00)** |
| O18 | Max age of permission/health observations | W4 | **Re-observe on every resume; stale after 24 h** |
| O19 | Pomodoro: scheduled reminder and timed notification | W4 | **Keep both (distinct roles)** |
| O20 | Restore timed sessions after reboot | W4 | **On next launch only** |
| O21 | Notification ID re-derivation (stable hash via orphan set) | W4 | **Approve** |
| O22 | AI trend context may include lifetime totals | W4 | **No; minimized daily facts only** |
| O23 | Staleness threshold for widget/watch | W4 | **Earlier of local midnight or 6 hours** |
| O24 | Wearable dashboard day grouping | W4 | **Local day** |

## 8. Limits

Agent audits and tests do not replace physical-device validation (Android
and iOS widgets, watch, notifications, keychain/keystore, backup/restore),
which remains the owner's responsibility per wave. Hosted CI wall time must be
measured after Wave 0; the suite may need sharding. Legal/compliance review is
out of scope.
