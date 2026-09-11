# Hydrion Tester Bible

**Source of truth**: this document is built exclusively from the verified feature inventory in `AUDIT_REPORT.md` (Stages 1–5 of the Hydrion production audit, 2026-08-27). Every test case cites the real file/route/service that backs it. No checkbox in this document has been marked complete — all execution is left to human testers or the automation named in each case. This is a first, evidence-backed pass over the *verified reachable* feature set, not an exhaustive combinatorial enumeration of every widget in the app; it is meant to be extended over time, not treated as final.

**App identity**: package `com.the1807.hydrion` (Android), bundle id `com.the1807.hydrion` (iOS). Platforms in scope for this bible: Android, iOS. Web/macOS/Linux/Windows builds exist but are out of the verified V1 product scope per `docs/release/HYDRION_V1_KNOWN_LIMITATIONS.md` and were not runtime-tested in the audit (no Chrome available) — they are not covered here.

**Important scope note — no account system exists.** Hydrion has no login, no server-side account, no password, and no email/phone verification anywhere in the verified codebase (confirmed absence of any auth service, token store, or backend account API). "Account creation, authentication and recovery" below is therefore mapped to what actually exists: local first-run onboarding, age/life-stage gating, legal consent, and local-profile reset — not credential-based authentication. Do not write or execute login/password test cases against this app; none apply.

**Priority key**: P0 = release-blocking if failed, P1 = high-impact, P2 = moderate, P3 = low/cosmetic.
**Automation eligibility key**: `Auto-CI` = suitable for `flutter test`/`integration_test` in CI, `Auto-Device` = needs a real/emulated device (native channel, permission dialog, background/kill behavior), `Manual` = requires human judgement or hardware not practical to automate yet.

---

## Template (for reference — not a test case)

```
### TC-XXX-000 — Title
- [ ] TC-XXX-000
- Platforms:
- Priority:
- Preconditions:
- Test data:
- Steps:
- Expected result:
- Negative/interruption variant:
- Evidence to capture:
- Automation eligibility / framework:
- Related feature/source evidence:
- Related requirement/finding ID:
- Result: ☐ Pass ☐ Fail ☐ Blocked
- Defect ID:
- Tester / Device / OS / Build:
```

---

## 1. Installation, Update, and First Launch

### TC-INST-001 — Clean install launches to first-run gate chain
- [ ] TC-INST-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: device/simulator with no prior Hydrion install; fresh app-data state.
- **Test data**: none.
- **Steps**: 1) Install the app from a signed build (release APK or TestFlight/ad-hoc IPA). 2) Launch it.
- **Expected result**: app shows the startup splash (`StartupScreen`, animated shark, "Preparing your hydration space…") then transitions to `/language` (first-run gate chain: `/language` → `/onboarding` → `/profile-age-review` → `/legal-review` → `/home`, per `lib/main.dart:121-143`).
- **Negative/interruption variant**: kill the app during the splash screen; relaunch; confirm it resumes the same gate chain rather than crashing or looping.
- **Evidence to capture**: screen recording of full launch sequence; timestamp from tap-to-launch to first interactive screen.
- **Automation eligibility**: Auto-Device (real-engine `integration_test`, not widget-test harness — see HYD-BLOCK-004 rationale).
- **Related feature/source evidence**: `lib/main.dart:73-204`.
- **Related requirement/finding ID**: **HYD-BLOCK-004** (a live reproduction on iOS Simulator during this audit showed the app *not* transitioning off this splash screen for 1+ minute at ~43% sustained CPU — this exact test case is the one that must be run on real hardware to determine whether that reproduces outside the audit's sandbox).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-INST-002 — Update from previous version preserves local data
- [ ] TC-INST-002
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: an existing install with hydration logs, body metrics, and at least one active challenge.
- **Test data**: any non-empty hydration/challenge history.
- **Steps**: 1) Install an older build. 2) Log water, set body metrics, join a challenge. 3) Install the new build over it (not a fresh install). 4) Launch.
- **Expected result**: all previously logged data (hydration logs, settings, body metrics, active challenge state) is intact; app does not re-run onboarding for an existing user.
- **Negative/interruption variant**: force-stop mid-update (Android "Update" from Play Store paused/resumed) and confirm no data corruption on resume.
- **Evidence to capture**: before/after screenshots of Analytics and Challenges screens.
- **Automation eligibility**: Manual (requires two distinct build artifacts and a real install-over-install path; not practical in a single CI run).
- **Related feature/source evidence**: `lib/storage/local_store.dart`, all `lib/repositories/*`.
- **Related requirement/finding ID**: n/a.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-INST-003 — Fresh install on a device with prior corrupt/foreign SharedPreferences data
- [ ] TC-INST-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Preconditions**: manually seed a malformed JSON value under one of Hydrion's known storage keys (e.g. `hydrion.user_settings.v1`) before first launch, or reuse a device where a prior corrupted install was uninstalled without clearing data (Android only, if "clear data on uninstall" is off).
- **Test data**: malformed JSON string.
- **Steps**: 1) Seed corrupt data. 2) Launch app.
- **Expected result**: app falls back gracefully per `lib/repositories/storage_recovery.dart` and `app_locale_repository.dart:66-68`'s documented corrupt-parse fallback, without crashing.
- **Negative/interruption variant**: n/a (this test IS the negative case).
- **Evidence to capture**: crash logs (should be none), screenshot of resulting state.
- **Automation eligibility**: Auto-CI (`test/storage_recovery_test.dart` already exists — confirm it covers this exact scenario or extend it).
- **Related feature/source evidence**: `lib/repositories/storage_recovery.dart`, `test/storage_recovery_test.dart`.
- **Related requirement/finding ID**: n/a.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 2. Onboarding

### TC-ONB-001 — Language selection persists and drives all subsequent screens
- [ ] TC-ONB-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: fresh install.
- **Test data**: select French, then Spanish on separate runs.
- **Steps**: 1) On `/language`, select "Français". 2) Continue through onboarding.
- **Expected result**: all subsequent screen text renders in French (confirmed 838/838 ARB messages translated per `tool/localization_audit.dart`, audit §5); selection persists across app restarts.
- **Negative/interruption variant**: kill app immediately after language selection, before onboarding completes; relaunch; confirm language choice persisted and onboarding resumes (not restarts from `/language`).
- **Evidence to capture**: screenshots in each language.
- **Automation eligibility**: Auto-CI (`test/app_locale_repository_test.dart`, `test/localization_test.dart`).
- **Related feature/source evidence**: `lib/ui/screens/language_selection_screen.dart`, `lib/repositories/app_locale_repository.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-ONB-002 — Onboarding → age review → life-stage gating for a minor
- [ ] TC-ONB-002
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: fresh install.
- **Test data**: enter age 10.
- **Steps**: 1) Complete onboarding. 2) On age review, enter age 10.
- **Expected result**: `HydrionLifeStagePolicy` resolves `unsupportedIndependentChild` (`lib/domain/life_stage_policy.dart`, age < 13); app shows the appropriate gated experience rather than proceeding as an unrestricted adult.
- **Negative/interruption variant**: enter age `0`, then age `-1` (should both be rejected/handled, not crash — confirmed at code level the policy explicitly branches on `age<0`); enter age `121` (explicit `invalid` branch).
- **Evidence to capture**: screenshots for ages 10, 13, 17, 18, 0, -1 (if enterable), 120, 121.
- **Automation eligibility**: Auto-CI, but **note test gap**: `test/life_stage_policy_test.dart` currently does not exercise `null`/negative/`>120` ages or the exact upper boundary (120) — extend before relying on this as full regression coverage (see HYD-CORR-004 detail in `AUDIT_REPORT.md`).
- **Related feature/source evidence**: `lib/ui/screens/profile_age_review_screen.dart`, `lib/domain/life_stage_policy.dart`.
- **Related requirement/finding ID**: test-gap noted in `TEST_COVERAGE_GAPS.md`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-ONB-003 — Legal consent gate blocks access to `/home` until accepted
- [ ] TC-ONB-003
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: fresh install, through age review.
- **Test data**: none.
- **Steps**: 1) Reach `/legal-review`. 2) Attempt to navigate away/back without accepting. 3) Accept the legal checkboxes without opening any document (verify this is allowed per `test/legal_document_test.dart` "legal checkboxes can be accepted without opening documents"). 4) Open a legal document, then back out — verify opening a document does not itself count as acceptance.
- **Expected result**: `/home` is unreachable until `HydrionLegalAcceptancePolicy.needsReview` is false; the two behaviors above match existing test names exactly.
- **Negative/interruption variant**: force-quit mid-legal-review; relaunch; confirm gate re-presents correctly.
- **Evidence to capture**: screenshots of gate states.
- **Automation eligibility**: Auto-CI (`test/legal_document_test.dart`, 10 existing cases).
- **Related feature/source evidence**: `lib/ui/screens/legal_about_screen.dart`, `lib/domain/legal_document_registry.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-ONB-004 — Legal review never requests platform permissions
- [ ] TC-ONB-004
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: fresh install, legal-review screen reached.
- **Steps**: observe whether any OS permission dialog (location, notifications, photos) appears during legal review.
- **Expected result**: no permission dialog appears (matches existing test `test/legal_document_test.dart` "legal review never requests platform permissions").
- **Automation eligibility**: Auto-CI (already covered).
- **Related feature/source evidence**: `test/legal_document_test.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 3. Account Creation, Authentication, and Recovery (mapped — no real accounts exist)

### TC-ACCT-001 — "Recovery" is local-profile reset, not password recovery
- [ ] TC-ACCT-001
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: an established local profile with data.
- **Test data**: any populated profile.
- **Steps**: 1) Navigate to Settings → profile reset option (backed by `local_profile_reset_service.dart`). 2) Trigger reset. 3) Confirm the confirmation dialog/flow.
- **Expected result**: `LocalProfileResetResult.status` is `completed` only if every subsystem reports success; a partial failure surfaces as `failed`, not a false "success" (per `local_profile_reset_service.dart:96-159`, verified in the audit as correctly built, not swallowed).
- **Negative/interruption variant**: kill the app mid-reset; relaunch; verify the app is left in a consistent state (either fully reset or fully intact, not partially wiped).
- **Evidence to capture**: before/after data snapshots.
- **Automation eligibility**: Auto-CI for the service logic; Auto-Device for the interruption variant.
- **Related feature/source evidence**: `lib/services/local_profile_reset_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

*(No further cases in this category — there is no password, no email verification, no OAuth, no server-side session to test. Do not invent them.)*

---

## 4. Permissions

### TC-PERM-001 — Location permission (coarse) for weather-goal feature
- [ ] TC-PERM-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: fresh install, permission not yet requested.
- **Steps**: 1) Trigger the flow that needs location (weather-based goal adjustment). 2) Observe the OS permission dialog. 3) Deny it. 4) Retry and grant it.
- **Expected result**: app requests **coarse/"when in use"** only (`ACCESS_COARSE_LOCATION` on Android manifest; `NSLocationWhenInUseUsageDescription` on iOS — confirmed, no "always" location request exists). On denial, `weather_goal_service.dart` degrades gracefully (no crash, feature simply unavailable) rather than repeatedly re-prompting.
- **Negative/interruption variant**: deny permission, then revoke it from OS settings after having granted it once; relaunch app; confirm graceful re-detection.
- **Evidence to capture**: screenshots of permission dialog text (verify it matches `NSLocationWhenInUseUsageDescription` string), Settings screen state.
- **Automation eligibility**: Auto-Device (real OS permission dialogs cannot be exercised in `flutter test`'s widget harness).
- **Related feature/source evidence**: `lib/services/location_service.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`.
- **Related requirement/finding ID**: n/a (permission scope confirmed minimal/appropriate — coarse only, no background location).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERM-002 — Notification permission gates the Reminders route entirely
- [ ] TC-PERM-002
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: fresh install.
- **Steps**: 1) Deny notification permission when prompted. 2) Check whether `/reminders` is reachable.
- **Expected result**: per `lib/main.dart:327-328`, the `/reminders` route is **conditionally registered only if `capabilityReporter.capabilities.osNotifications` is true** — confirm the route/tab is actually hidden, not just non-functional, when permission is denied.
- **Negative/interruption variant**: grant permission after initially denying (via OS settings); confirm the route becomes reachable without requiring app reinstall.
- **Evidence to capture**: screenshots of navigation with permission granted vs. denied.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/main.dart:327-328`, `lib/utils/permissions.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERM-003 — Photo library permission for profile photo
- [ ] TC-PERM-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: onboarded profile.
- **Steps**: 1) Attempt to set a profile photo. 2) Deny photo-library permission.
- **Expected result**: graceful denial handling; no crash; `NSPhotoLibraryUsageDescription` shown correctly on iOS.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/services/profile_photo_service.dart`, `ios/Runner/Info.plist`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERM-004 — Permission Center screen accurately reflects live OS state
- [ ] TC-PERM-004
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: 1) Change a permission from OS Settings (not from within the app). 2) Return to the app's Permission Center screen (`/permissions`).
- **Expected result**: displayed state matches the real OS permission state without requiring app restart.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/ui/screens/permission_center_screen.dart`, `test/permission_consent_test.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERM-005 (Android-only) — Self-revoked permissions on force-stop
- [ ] TC-PERM-005
- **Platforms**: Android
- **Priority**: P2
- **Preconditions**: real native handler exists (`android_permission_revocation_service.dart` → `MainActivity.kt:69-92`, `revokeSelfPermissionsOnKill`).
- **Steps**: 1) Grant permissions. 2) Trigger whatever in-app action calls this native method (verify exact trigger condition by reading the service). 3) Force-stop the app.
- **Expected result**: behavior matches the documented intent of `revokeSelfPermissionsOnKill` — confirm exactly what it does (self-revokes specific permissions) and that this doesn't unexpectedly strip permissions the user still wants active on next launch.
- **Automation eligibility**: Auto-Device (Android only, native method).
- **Related feature/source evidence**: `lib/services/android_permission_revocation_service.dart`, `android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt:69-92`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 5. Every Screen and Navigation Path

*(Full route table verified in `AUDIT_REPORT.md` §2.2/§3. One smoke-navigation case per reachable route; deep functional testing of each screen's content is covered under §7 Core Workflows.)*

### TC-NAV-001 — Full route-table reachability smoke test
- [ ] TC-NAV-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: from `/home`, navigate to and back from every route in `lib/main.dart`'s table: `/language`, `/onboarding`, `/mission`, `/analytics`, `/log`, `/reminders` (if registered), `/settings`, `/permissions`, `/profile`, `/profile-age-review`, `/body-metrics`, `/legal-about`, `/legal-review`, each per-legal-document route, `/challenges`.
- **Expected result**: every route renders without exception; back navigation returns to the expected prior screen; no route throws a null-provider error (all screens' `Provider`/`context.watch` dependencies must be satisfied by `HydrionServices`' DI graph).
- **Negative/interruption variant**: rapidly tap between tabs (`HydrionShell`'s `IndexedStack`) 20+ times in quick succession; confirm no dropped frames-induced crash and no duplicate network/persist calls beyond what §8's caching findings predict.
- **Evidence to capture**: full navigation screen-recording.
- **Automation eligibility**: Auto-Device (`integration_test/`) — no such full-route-table smoke test currently exists (test gap, see `TEST_COVERAGE_GAPS.md`).
- **Related feature/source evidence**: `lib/main.dart:281-339`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NAV-002 — `ChatCoachScreen` is confirmed unreachable (documentation-vs-reality check)
- [ ] TC-NAV-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: attempt to find any UI path (button, menu item, deep link) that opens the AI Coach chat screen.
- **Expected result**: **none exists** — confirm this matches HYD-ARCH-001's finding rather than assuming the feature is simply "hidden somewhere." If a tester ever finds a path to it, that is itself a defect report (undocumented/untested surface) or evidence the audit's finding is stale and needs re-verification.
- **Automation eligibility**: Manual (this is a "prove a negative" exploratory case).
- **Related requirement/finding ID**: HYD-ARCH-001.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NAV-003 — Mission/guided-tour screen navigation
- [ ] TC-NAV-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: reach `/mission`; step through the guided tour; verify it "navigates to actual destinations and returns home" (matches existing test name in `test/final_release_ux_test.dart`).
- **Automation eligibility**: Auto-CI (already covered).
- **Related feature/source evidence**: `lib/ui/screens/mission_screen.dart`, `lib/repositories/guided_tour_repository.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 6. Every Interactive Control (representative high-value set)

### TC-CTRL-001 — Home screen "log water" button, single tap
- [ ] TC-CTRL-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: tap the primary hydration-log control once.
- **Expected result**: exactly one `HydrationLog` entry created; UI updates immediately (optimistic or post-persist, confirm which); button re-enables after completion.
- **Negative/interruption variant**: see TC-CTRL-002 (rapid double-tap).
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/ui/screens/home_screen.dart:47-106` (`_logWater`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CTRL-002 — Home screen "log water" button, rapid double-tap
- [ ] TC-CTRL-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: tap the log-water button twice as fast as physically possible.
- **Expected result**: the UI-level `_isLogging` guard (checked synchronously before any `await`, `home_screen.dart:48-51`) should prevent a duplicate log from this exact call site.
- **Evidence to capture**: resulting hydration-log count (should be 1, not 2).
- **Automation eligibility**: Auto-CI (`test/pomodoro_session_ui_test.dart` has an analogous "rapid confirmed sip taps" test for the Pomodoro path — extend the same pattern here if not already covered for the plain Home-screen log button).
- **Related feature/source evidence**: `lib/ui/screens/home_screen.dart:48-51`.
- **Related requirement/finding ID**: related to HYD-CORR-002's broader finding that this per-widget guard does not generalize to a repository-level lock — this specific UI path is confirmed safe, but any *other* future caller of `addLog` without an actionId is not protected at the repository layer.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CTRL-003 — Challenge "Join"/"Activate" button, rapid double-tap
- [ ] TC-CTRL-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: rapidly double-tap "Join"/"Activate" on a challenge before the UI can swap to the active state.
- **Expected result**: per audit finding, `ChallengeRepository.join()` has no in-flight lock and the calling screen has no `_isJoining` guard — a rapid double-tap is expected to "re-stamp" the same challenge instance harmlessly under normal conditions, but this should be explicitly verified rather than assumed, and re-tested after any fix.
- **Automation eligibility**: Auto-CI (new test needed — test gap).
- **Related feature/source evidence**: `lib/repositories/challenge_repository.dart:463-505`, `lib/ui/screens/challenge_experience_screen.dart:886,1001`.
- **Related requirement/finding ID**: part of HYD-CORR-002's finding family.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CTRL-004 — Activity-challenge Start/Pause/Resume, immediate navigate-away
- [ ] TC-CTRL-004
- **Platforms**: Android, iOS
- **Priority**: **P0 (crash risk)**
- **Steps**: on an activity-type challenge (e.g. homework-hydration), tap Start (or Pause, or Resume), then immediately navigate away from the screen before it can visually update.
- **Expected result** (pre-fix): may crash — this is the exact reproduction for **HYD-CORR-001** (`_ChallengeActivityPanelState._syncTicker()` accesses `context` with no `mounted` check after an `await` gap). **Expected result (post-fix)**: no crash, ticker cleanly stops.
- **Evidence to capture**: crash log / stack trace if it reproduces.
- **Automation eligibility**: Auto-CI (widget test — see `AUDIT_REPORT.md` HYD-CORR-001's suggested regression test).
- **Related feature/source evidence**: `lib/ui/screens/challenge_experience_screen.dart:3170-3196,3465`.
- **Related requirement/finding ID**: **HYD-CORR-001**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CTRL-005 — Pomodoro timer Start/Pause/Resume/Restart/Stop, immediate navigate-away
- [ ] TC-CTRL-005
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: same as TC-CTRL-004 but on the Pomodoro variant (`_PomodoroTimerCardState`).
- **Expected result**: no crash — this variant already correctly guards with `if (!mounted) return;` (confirmed clean in the audit).
- **Automation eligibility**: Auto-CI (`test/pomodoro_session_ui_test.dart` "timer ticker is disposed when the challenge view is removed" — already covers this).
- **Related feature/source evidence**: `lib/ui/screens/challenge_experience_screen.dart:3701-3722`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CTRL-006 — Voice input button is permanently disabled (confirm stub, not broken feature)
- [ ] TC-CTRL-006
- **Platforms**: Android, iOS
- **Priority**: P3
- **Steps**: locate the voice-input control (`VoiceInputWidget`) and attempt to tap it.
- **Expected result**: `onPressed: null` — button visually renders disabled and does not respond, matching its stub status (§2.3 of `AUDIT_REPORT.md`).
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/ui/components/voice_input_widget.dart:25-37`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 7. Core Hydrion Workflows

### TC-CORE-001 — Manual hydration logging updates daily total and analytics history
- [ ] TC-CORE-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: log 3 separate hydration entries of varying volume; check Home daily total and Analytics history.
- **Expected result**: totals and history match exactly; entries sorted correctly.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/repositories/hydration_repository.dart`, `lib/ui/screens/analytics_screen.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CORE-002 — Weather-based daily goal adjustment (live network)
- [ ] TC-CORE-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: real network connectivity, location permission granted.
- **Steps**: trigger the weather-goal evaluation (app resume on a new day, or first grant of location permission).
- **Expected result**: a real HTTPS call to `api.open-meteo.com` occurs (verify via device network monitor); daily goal adjusts per `daily_hydration_recommendation_coordinator.dart`; result is cached for 18h and the "already handled today" gate prevents a second call the same day.
- **Negative/interruption variant**: see §9 (offline/interrupted networking) for the failure-path variant of this same workflow.
- **Automation eligibility**: Auto-Device (real network call) + Auto-CI for the cache/gating logic (`test/weather_location_goal_test.dart`).
- **Related feature/source evidence**: `lib/services/weather_goal_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CORE-003 — Challenge lifecycle: join → activity → complete → history
- [ ] TC-CORE-003
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: join a challenge (e.g. "Around-the-World Infusion Week"), complete its required actions, confirm it moves to history/archive.
- **Expected result**: full lifecycle completes without data loss; matches `test/release18_challenge_lifecycle_test.dart` and `challenge_history_test.dart`.
- **Automation eligibility**: Auto-CI (already covered for happy path).
- **Related feature/source evidence**: `lib/repositories/challenge_repository.dart`, `lib/ui/screens/challenge_experience_screen.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CORE-004 — Bottle Bingo tile completion via hydration action
- [ ] TC-CORE-004
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: complete a bottle-bingo tile by logging the required hydration action.
- **Expected result**: matches `test/bottle_bingo_ui_test.dart` / `challenge_visual_game_test.dart`; the action-id-based in-flight lock (`_inFlightHydrationActions`) prevents duplicate credit on rapid taps.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/repositories/challenge_repository.dart:319,1071,1136`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CORE-005 — Home-screen widget: quick-log tap
- [ ] TC-CORE-005
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: `HydrionQuickLogWidget` added to home screen.
- **Steps**: tap the widget's quick-log control without opening the app.
- **Expected result**: a hydration log is recorded; re-opening the app reflects it; the `home_widget` plugin's `HomeWidget.widgetClicked` stream correctly routes the tap (`android_widget_service.dart:135-136`).
- **Automation eligibility**: Auto-Device (`test/android_widget_service_test.dart` covers the service logic; the OS-level widget tap itself needs device testing).
- **Related feature/source evidence**: `lib/services/android_widget_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-CORE-006 — Home-screen widget: active-challenge tap opens the correct challenge
- [ ] TC-CORE-006
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: tap `HydrionActiveChallengeWidget` while a challenge is active.
- **Expected result**: app opens directly to `challenge_experience_screen.dart` for that specific challenge (via `main.dart:264-279`'s widget challenge-opener callback), not just to `/home`.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/main.dart:264-279`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 8. Input Validation and Error States

### TC-VAL-001 — Body-metrics screen rejects invalid weight/height
- [ ] TC-VAL-001
- **Platforms**: Android, iOS
- **Priority**: P1
- **Test data**: weight = 0, negative, extremely large (e.g. 9999 kg); height = 0, negative.
- **Steps**: enter each invalid value and attempt to save.
- **Expected result**: validation blocks save with a clear error, not a silent accept or a crash.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/domain/body_metrics.dart`, `lib/ui/screens/body_metrics_screen.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-VAL-002 — Pregnancy-gestational-days field boundary values
- [ ] TC-VAL-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Test data**: 0, 1, 280, 300, -1, non-numeric.
- **Steps**: enter each value.
- **Expected result**: sane clinical bounds enforced; no crash on non-numeric input.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/domain/body_metrics.dart:284-303`.
- **Related requirement/finding ID**: also relevant to **HYD-SEC-001** — this field is stored unencrypted; testing its validation does not change that finding, but confirm test fixtures used here never contain a real person's data.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-VAL-003 — Manual hydration log accepts only sane volume ranges
- [ ] TC-VAL-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Test data**: 0 ml, negative, 100,000 ml.
- **Steps**: attempt to log each.
- **Expected result**: unreasonable values are rejected or clamped with user feedback.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/repositories/hydration_repository.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-VAL-004 — Nickname field length/character limits
- [ ] TC-VAL-004
- **Platforms**: Android, iOS
- **Priority**: P2
- **Test data**: empty string, 1 character, very long string (500+ chars), emoji, RTL script.
- **Steps**: enter each and save.
- **Expected result**: reasonable limits enforced; no layout overflow/crash on extreme-length or RTL input (also relevant to §16 Accessibility/§17 Localization).
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/repositories/settings_repository.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 9. Offline, Slow, and Interrupted Networking

### TC-NET-001 — Weather-goal evaluation with airplane mode fully on
- [ ] TC-NET-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Preconditions**: airplane mode on, no cached forecast.
- **Steps**: trigger weather-goal evaluation.
- **Expected result**: fails fast (confirmed by audit: `http.ClientException` surfaces well before the 10s timeout in a fully-offline case), maps to `WeatherUserMessageCode.weatherOffline`, and shows an explicit offline state rather than hanging or silently showing nothing.
- **Automation eligibility**: Auto-Device (needs real airplane-mode toggle or a mocked no-network `http.Client` in a device test).
- **Related feature/source evidence**: `lib/services/weather_goal_service.dart:340-345,988`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NET-002 — Weather-goal evaluation with a stale cached forecast and no network
- [ ] TC-NET-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: a forecast cached from a previous session, then airplane mode on.
- **Steps**: trigger evaluation.
- **Expected result**: `_staleFallback` returns the stale cache with `fromCache: true`; **verify whether any visible UI badge actually communicates "showing cached weather" to the user** — the audit could not confirm this from static code reading alone (marked UNVERIFIED in `AUDIT_REPORT.md` §6.1a HYD-CORR-004).
- **Evidence to capture**: screenshot — does the UI show any "from cache"/"offline" indicator?
- **Automation eligibility**: Manual (visual confirmation needed) + Auto-CI for the underlying flag logic.
- **Related feature/source evidence**: `lib/services/weather_goal_service.dart:278-280`, `lib/services/current_weather_context.dart` (`fromCache` getter).
- **Related requirement/finding ID**: closes an UNVERIFIED item from the audit.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NET-003 — Slow/degraded network (throttled to 2G-equivalent) on weather fetch
- [ ] TC-NET-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: network-throttling tool (device-level or proxy).
- **Steps**: throttle to a very slow link; trigger weather evaluation.
- **Expected result**: either completes slowly within the 10s timeout, or times out cleanly and falls back to cache/offline state — no UI freeze.
- **Automation eligibility**: Manual/Auto-Device (needs network-conditioning tooling — see `MOBILE_TEST_PLATFORM_EVALUATION.md` for candidate tools).
- **Related feature/source evidence**: `lib/services/weather_goal_service.dart` (10s `.timeout()`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NET-004 — Network interrupted mid-request (connect then drop)
- [ ] TC-NET-004
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: start a weather fetch, then disable network mid-flight.
- **Expected result**: request fails cleanly (timeout or connection-reset exception handled), no partial/corrupt state persisted.
- **Automation eligibility**: Manual/Auto-Device.
- **Related feature/source evidence**: `lib/services/weather_goal_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 10. Background/Foreground Transitions

### TC-LC-001 — Backgrounding during an active Pomodoro session
- [ ] TC-LC-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: start a Pomodoro session; background the app for 5 minutes; foreground it.
- **Expected result**: countdown reflects real elapsed wall-clock time (not paused-while-backgrounded, unless that is the intended design — verify against `pomodoro_session_service.dart`'s actual semantics); the ongoing native notification (Android) continues correctly.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/services/pomodoro_session_service.dart`, `lib/services/timed_session_notification_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-LC-002 — App resume triggers weather re-evaluation exactly once per day
- [ ] TC-LC-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: resume the app from background 5 times within the same local calendar day.
- **Expected result**: per audit finding (HYD-CORR-004), the network call fires at most once per day due to the "already handled today" gate + 18h cache — confirm via network monitor that repeated resumes do **not** each trigger a fresh HTTP call.
- **Evidence to capture**: network request log/count.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/ui/screens/hydrion_shell.dart:66-105`, `lib/services/weather_goal_service.dart:792-796`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-LC-003 — Day-rollover timer fires correctly across midnight while backgrounded
- [ ] TC-LC-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: leave the app backgrounded across local midnight; foreground it the next day.
- **Expected result**: `HydrionShell._dayRolloverTimer` correctly reflects the new day (daily totals reset for display, "handled today" gates re-arm) without requiring a full app restart.
- **Automation eligibility**: Manual (requires real-time midnight crossing) or Auto-Device with device clock manipulation.
- **Related feature/source evidence**: `lib/ui/screens/hydrion_shell.dart:45,108-119`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 11. Process Termination and Restoration

### TC-KILL-001 — Force-kill during active Pomodoro session (paused state)
- [ ] TC-KILL-001
- **Platforms**: Android
- **Priority**: **P0 (confirmed gap)**
- **Preconditions**: start a Pomodoro/homework session, pause it.
- **Steps**: force-stop the app from OS app-switcher/settings while paused.
- **Expected result** (pre-fix): per **HYD-PERF-003**, the paused-state ongoing notification has **no native timeout backstop** (`setTimeoutAfter` is only applied to the "running" branch) — the notification is expected to persist indefinitely in the shade until manually dismissed. **Expected result (post-fix)**: notification either auto-clears within a bounded window or is cleaned up on process death via a native lifecycle hook.
- **Evidence to capture**: screenshot of notification shade minutes/hours after force-kill.
- **Automation eligibility**: Auto-Device (native, cannot be a pure Dart unit test).
- **Related feature/source evidence**: `android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt:93-178`.
- **Related requirement/finding ID**: **HYD-PERF-003**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-KILL-002 — Force-kill during active (running, not paused) Pomodoro session
- [ ] TC-KILL-002
- **Platforms**: Android
- **Priority**: P1
- **Steps**: force-stop while a session is actively running (not paused).
- **Expected result**: `.setTimeoutAfter(remainingSeconds * 1000L)` (API 26+) should cause the notification to auto-expire once the session's remaining time elapses, even without the app running.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `MainActivity.kt:166-173`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-KILL-003 — OS-initiated process death (low-memory reclaim) and state restoration
- [ ] TC-KILL-003
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: use OS developer tools to simulate a background low-memory kill (Android: `adb shell am kill <package>`; iOS: Xcode's "Simulate Memory Warning" plus background+relaunch). Reopen the app from the app switcher (not a fresh launch icon tap).
- **Expected result**: app restores to a reasonable state (last screen or `/home`), no data loss, no crash on restore.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/main.dart` boot sequence, all repositories.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 12. Notifications

### TC-NOTIF-001 — Scheduled hydration reminder fires at the correct local time
- [ ] TC-NOTIF-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: schedule a reminder for 2 minutes from now; wait.
- **Expected result**: fires within a reasonable margin; tapping it opens the app to a sensible screen.
- **Automation eligibility**: Auto-CI for scheduling logic (`test/notification_service_test.dart`); Auto-Device for actual OS delivery (`integration_test/android_notification_delivery_test.dart` already exists for Android).
- **Related feature/source evidence**: `lib/services/notifications.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NOTIF-002 — Reminder survives device reboot (Android boot receiver)
- [ ] TC-NOTIF-002
- **Platforms**: Android
- **Priority**: P0
- **Steps**: schedule a reminder for tomorrow; reboot the device; wait for the reminder time.
- **Expected result**: `ScheduledNotificationBootReceiver` (`AndroidManifest.xml`, `BOOT_COMPLETED`/`MY_PACKAGE_REPLACED`/`QUICKBOOT_POWERON`) correctly re-registers the alarm; notification still fires.
- **Automation eligibility**: Auto-Device (requires real reboot or `adb shell` broadcast simulation).
- **Related feature/source evidence**: `android/app/src/main/AndroidManifest.xml:46-55`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NOTIF-003 — Notification scheduling across a DST transition
- [ ] TC-NOTIF-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Preconditions**: device/timezone set to a region with an imminent DST transition, or manually advance device clock across one.
- **Steps**: schedule a reminder for a time that crosses the DST boundary.
- **Expected result**: since the app only uses one-shot `zonedSchedule` (not `matchDateTimeComponents`) and `tz.setLocalLocation()` is never called (**HYD-CORR-005**), verify the *absolute instant* still fires correctly despite the underlying zone metadata being wrong — confirm this is actually inert as the audit predicted, rather than assumed.
- **Automation eligibility**: Manual (requires real or simulated clock/timezone manipulation).
- **Related feature/source evidence**: `lib/services/notifications.dart`.
- **Related requirement/finding ID**: **HYD-CORR-005**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NOTIF-004 — Timed-session (Pomodoro) ongoing notification pause/stop/open actions
- [ ] TC-NOTIF-004
- **Platforms**: Android
- **Priority**: P1
- **Steps**: from the notification shade, tap Pause, then Stop, then Open on the ongoing timed-session notification.
- **Expected result**: each action correctly round-trips to the Dart-side session state via `MethodChannel('hydrion/timed_session')`.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `MainActivity.kt:93-178`, `lib/services/timed_session_notification_service.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-NOTIF-005 — Notification permission denied entirely — reminders route hidden, no silent failure elsewhere
- [ ] TC-NOTIF-005
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: deny notification permission; use the app normally, including challenge/Pomodoro flows that would otherwise post notifications.
- **Expected result**: no crash anywhere a notification would have been posted; features that depend on notifications degrade visibly rather than silently.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/main.dart:327-328`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 13. Deep Links

### TC-LINK-001 — `hydrion://home` widget tap-through (iOS)
- [ ] TC-LINK-001
- **Platforms**: iOS
- **Priority**: P1
- **Steps**: tap the iOS home-screen widget.
- **Expected result**: app opens/foregrounds to Home via the `widgetURL` scheme (`HydrionWidgets.swift:74`).
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `ios/HydrionWidgets/HydrionWidgets.swift:74`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-LINK-002 — Arbitrary external `hydrion://` URL (confirm it is NOT handled — negative/security test)
- [ ] TC-LINK-002
- **Platforms**: iOS
- **Priority**: P2
- **Steps**: from Safari or Notes, tap a manually-typed link `hydrion://anything?param=value`.
- **Expected result**: per audit finding, `AppDelegate.swift` implements **no** `application(_:open:options:)` handler — confirm the app either ignores the URL safely or, if iOS's default Flutter routing intercepts it in some way not previously identified, that no unintended screen/action is triggered by an arbitrary external caller. This is a security-relevant negative test (URL-scheme-hijacking risk class, MASVS-PLATFORM-3), even though risk was assessed as low since no sensitive action is currently gated behind the scheme.
- **Automation eligibility**: Manual.
- **Related feature/source evidence**: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist:27-37`.
- **Related requirement/finding ID**: **HYD-ARCH-004**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-LINK-003 — Android: confirm no data-bearing intent-filter exists (negative test)
- [ ] TC-LINK-003
- **Platforms**: Android
- **Priority**: P3
- **Steps**: attempt `adb shell am start -a android.intent.action.VIEW -d "hydrion://test"`.
- **Expected result**: no activity resolves this (Android manifest has no such intent-filter, confirmed in audit) — this is expected/correct, not a defect.
- **Automation eligibility**: Manual/Auto-Device (`adb` scriptable).
- **Related feature/source evidence**: `android/app/src/main/AndroidManifest.xml`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 14. Local Persistence and Synchronization

*(No cloud sync exists — "synchronization" here means cross-repository consistency and widget/app-state consistency, not server sync.)*

### TC-PERSIST-001 — Hydration log survives app restart
- [ ] TC-PERSIST-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: log water; fully quit and relaunch the app.
- **Expected result**: log persists exactly.
- **Automation eligibility**: Auto-CI (`test/persistence_test.dart`).
- **Related feature/source evidence**: `lib/storage/local_store.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERSIST-002 — Home-screen widget stays in sync with in-app state
- [ ] TC-PERSIST-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: log water in-app; check the home-screen widget without reopening it manually (widgets refresh on their own schedule/trigger).
- **Expected result**: widget reflects the new total within a reasonable delay; note the audit's finding that the widget-sync guard (`_syncing`) **drops** (does not queue) a sync request that arrives while one is in flight — verify this doesn't cause the widget to visibly miss an update under rapid successive logs.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/services/android_widget_service.dart:279-322`.
- **Related requirement/finding ID**: noted under HYD-PERF (§8, item 8 of the memory audit).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERSIST-003 — Long-history data integrity (large log count)
- [ ] TC-PERSIST-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: seed 2,000+ hydration log entries (via test fixture/debug tool, not manual tapping).
- **Steps**: log one more entry; measure time-to-complete; verify no data corruption or truncation.
- **Expected result**: completes without error; **measure and record actual latency** — this directly tests the real-world magnitude of **HYD-PERF-001/002**, which the audit could not measure live (UNVERIFIED without a multi-month device history) — this seeded-fixture test is the practical way to get that measurement without waiting months.
- **Evidence to capture**: wall-clock time for `addLog()` at this scale.
- **Automation eligibility**: Auto-CI (perf regression test — currently does not exist, test gap).
- **Related feature/source evidence**: `lib/repositories/hydration_repository.dart:178,214-260,367-370`.
- **Related requirement/finding ID**: **HYD-PERF-001**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 15. Device Rotation and Responsive Layout

### TC-RESP-001 — Rotate device during active challenge/Pomodoro timer
- [ ] TC-RESP-001
- **Platforms**: Android, iOS (tablets/foldables where rotation is enabled)
- **Priority**: P1
- **Steps**: rotate portrait↔landscape while a timer is running.
- **Expected result**: timer state is preserved across the rotation-induced rebuild (no reset, no duplicate timer instance).
- **Automation eligibility**: Auto-CI (`test/responsive_layout_test.dart`, `end_to_end_responsive_layout_test.dart` exist — confirm they cover this exact interaction, not just static layout).
- **Related feature/source evidence**: `lib/ui/screens/challenge_experience_screen.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-RESP-002 — Narrow/dark/large-text layout on Challenge Preferences
- [ ] TC-RESP-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: set a narrow window (small phone), dark theme, and large text scale simultaneously; open challenge preferences.
- **Expected result**: matches existing test `test/challenge_personalization_correction_test.dart` "challenge preferences work on narrow dark large-text layout" — no overflow/clipping.
- **Automation eligibility**: Auto-CI (already covered).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-RESP-003 — Foldable/tablet large-screen layout
- [ ] TC-RESP-003
- **Platforms**: Android (foldable), iOS (iPad)
- **Priority**: P2
- **Steps**: run on a large-screen/foldable device or simulator; check all screens for layout correctness (not just phone-sized breakpoints).
- **Automation eligibility**: Manual + Auto-Device (needs large-screen emulator/simulator profiles — see `DEVICE_OS_MATRIX.md`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 16. Accessibility

*(Audit note: a dedicated accessibility pass was not independently executed — see `AUDIT_REPORT.md` §9. The cases below are the minimum baseline; treat this whole section as higher-priority to actually execute than most others, since it is the least-verified area to date.)*

### TC-A11Y-001 — Screen reader (TalkBack/VoiceOver) can complete core hydration-logging flow
- [ ] TC-A11Y-001
- **Platforms**: Android (TalkBack), iOS (VoiceOver)
- **Priority**: **P0 (unverified — highest testing priority in this document)**
- **Steps**: enable TalkBack/VoiceOver; attempt to complete onboarding, log water, and join a challenge using only screen-reader navigation.
- **Expected result**: every interactive control has a meaningful accessible label; focus order is logical; no control is a screen-reader dead-end.
- **Automation eligibility**: Manual (screen-reader flows are best validated by a human, though basic semantics-tree assertions can be Auto-CI via `flutter_test`'s `Semantics` finders).
- **Related requirement/finding ID**: not previously assessed — genuinely new coverage.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-A11Y-002 — Dynamic/large text scaling does not clip or truncate critical text
- [ ] TC-A11Y-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: set OS text scale to maximum; navigate every screen.
- **Expected result**: partial coverage already exists (`legal_document_test.dart`'s "large text" cases, `challenge_personalization_correction_test.dart`) — extend to every screen, not just these two.
- **Automation eligibility**: Auto-CI (extend existing pattern).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-A11Y-003 — Color contrast meets WCAG AA on all themed screens (light + dark)
- [ ] TC-A11Y-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: audit key text/background color pairs in both light and dark themes against WCAG AA contrast ratios.
- **Automation eligibility**: Manual (contrast-checker tool) — no automated contrast-checking tool is currently part of the CI pipeline (test gap).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-A11Y-004 — Touch target sizing meets platform minimums
- [ ] TC-A11Y-004
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: inspect all tappable controls for minimum 44×44pt (iOS)/48×48dp (Android) hit targets.
- **Automation eligibility**: Manual/semi-automated (widget-tree size assertions possible in `flutter test`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 17. Localization, Dates, Time Zones, and Text Scaling

### TC-L10N-001 — Full app walkthrough in each supported language (en/fr/es)
- [ ] TC-L10N-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: complete onboarding through core workflows in each of en, fr, es.
- **Expected result**: no untranslated strings visible (matches `tool/localization_audit.dart`'s 838/838 result, but that tool checks ARB completeness, not actual on-screen rendering — this test closes that gap by visual confirmation).
- **Automation eligibility**: Auto-CI for string coverage (done); Manual for visual confirmation of actual rendering/truncation per language (French/Spanish strings often run longer than English).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-L10N-002 — pt_BR/de deferred-locale behavior
- [ ] TC-L10N-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: set device locale to Portuguese (Brazil) or German.
- **Expected result**: confirm these are correctly "deferred and hidden" per `tool/localization_audit.dart` output (0/838, 0/24) rather than showing a broken partial translation — app should fall back to a supported language cleanly.
- **Automation eligibility**: Auto-CI.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-L10N-003 — Date formatting is locale-neutral where required
- [ ] TC-L10N-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: check date-key strings (e.g. internal storage keys) are not accidentally shown to users in their locale-neutral `YYYY-MM-DD` internal form.
- **Automation eligibility**: Auto-CI (`tool/production_string_audit.dart` already flags these as "Locale-neutral interpolation" — confirm none leak into user-facing UI).
- **Related feature/source evidence**: `lib/domain/daily_hydration_context.dart:104-106`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-L10N-004 — Timezone change mid-session does not corrupt hydration log day-bucketing
- [ ] TC-L10N-004
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: log water, change device timezone (simulating travel), check whether the log appears on the expected day.
- **Expected result**: per audit finding, the underlying record is never lost/double-counted (absolute timestamp preserved), but *display bucketing* may shift which "day" a borderline entry appears under — confirm this is cosmetic only, not a data-integrity issue.
- **Automation eligibility**: Auto-Device (timezone manipulation).
- **Related requirement/finding ID**: detail under HYD-CORR-004 (§8 timezone/locale finding).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 18. Visual Quality

### TC-VIS-001 — Startup animation renders correctly across device sizes
- [ ] TC-VIS-001
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: launch on smallest and largest supported screen sizes; observe the Lottie shark animation.
- **Automation eligibility**: Manual (visual).
- **Related feature/source evidence**: `lib/ui/components/hydrion_startup_shark.dart`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-VIS-002 — Challenge artwork renders at correct resolution/aspect ratio
- [ ] TC-VIS-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: view every challenge card's artwork.
- **Expected result**: matches `tool/artwork_audit.dart`'s "12 challenge PNG files" clean result — confirm visually, not just via the file-presence check the tool performs.
- **Automation eligibility**: Auto-CI (file audit, done) + Manual (visual).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-VIS-003 — Dark mode visual consistency across every screen
- [ ] TC-VIS-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: toggle dark mode; visit every screen.
- **Automation eligibility**: Manual + partial Auto-CI (existing dark-theme test cases in `legal_document_test.dart`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 19. Performance and Perceived Responsiveness

### TC-PERF-001 — Cold-start time to first interactive screen
- [ ] TC-PERF-001
- **Platforms**: Android, iOS
- **Priority**: **P0 (directly tests HYD-BLOCK-004)**
- **Steps**: measure wall-clock time from tap-to-launch to `/home` (or the first-run gate screen) rendering and becoming interactive, on real hardware.
- **Expected result**: should be seconds, not indefinite — this is the formal, measured version of the ad hoc reproduction that produced **HYD-BLOCK-004**.
- **Evidence to capture**: exact timing, device model, OS version, build (debug vs. release — the audit's reproduction was a debug build; release-mode timing may differ and must be separately measured).
- **Automation eligibility**: Auto-Device (`flutter drive`/`integration_test` with a timing assertion, or a dedicated startup-time measurement harness).
- **Related requirement/finding ID**: **HYD-BLOCK-004**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERF-002 — Frame-rate/jank while all four `IndexedStack` tabs are live
- [ ] TC-PERF-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: with DevTools' performance overlay/timeline active, log hydration entries repeatedly while switching tabs.
- **Expected result**: measure actual jank against the theoretical cost identified in **HYD-PERF-002** (every log triggers a full-history recompute cascade across all mounted tabs) — this is the live measurement the audit's static pass could not perform.
- **Automation eligibility**: Auto-Device (DevTools timeline capture).
- **Related requirement/finding ID**: **HYD-PERF-002**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-PERF-003 — Large-history performance (paired with TC-PERSIST-003)
- [ ] TC-PERF-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Related requirement/finding ID**: **HYD-PERF-001**. See TC-PERSIST-003 — same scenario, measured from a performance rather than data-integrity angle (frame drops during the write, not just correctness).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 20. Privacy and Security Behavior

### TC-SEC-001 — Rooted/jailbroken-device data extraction (confirms HYD-SEC-001 in a real environment)
- [ ] TC-SEC-001
- **Platforms**: Android (rooted), iOS (jailbroken, or Simulator container inspection as a proxy)
- **Priority**: **P0**
- **Steps**: set body metrics including pregnancy status and a profile photo; on a rooted device, extract `shared_prefs/hydrion.body_metrics.v1` and `hydrion.user_settings.v1`.
- **Expected result** (pre-fix): plaintext JSON readable — confirms **HYD-SEC-001**. **Expected result (post-fix, after `flutter_secure_storage` migration)**: values are ciphertext.
- **Evidence to capture**: extracted file contents (handle as sensitive test evidence — do not commit real personal data; use synthetic test values only).
- **Automation eligibility**: Auto-Device (rooted test device/emulator required) — **use only synthetic test data, never a real tester's actual health information, per this audit's own data-handling rule.**
- **Related requirement/finding ID**: **HYD-SEC-001**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-SEC-002 — `tool/secret_scan.dart` remains clean after every dependency/config change
- [ ] TC-SEC-002
- **Platforms**: n/a (CI)
- **Priority**: P0
- **Steps**: run `dart run tool/secret_scan.dart` as part of every CI run (already wired in `flutter-ci.yml`) — this is a regression-suite entry, not a manual case, listed here for completeness of the security test matrix.
- **Automation eligibility**: Auto-CI (already implemented).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-SEC-003 — Non-local AI provider consent gate cannot be bypassed
- [ ] TC-SEC-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: without granting `nonLocalProviderConsentGranted`, attempt every UI path that might reach the Gemini coach (there should be none reachable per HYD-ARCH-001, but this test exists specifically to catch any future regression where a path is accidentally wired in without the consent check).
- **Expected result**: consent gate holds even if `ChatCoachScreen` is ever wired into the route table in a future release — verify `hydration_ai_orchestrator.dart:118-120`'s `_canUsePrimaryProvider` gate is exercised by a real UI-level test, not just a unit test on the orchestrator in isolation.
- **Automation eligibility**: Auto-CI.
- **Related feature/source evidence**: `lib/repositories/settings_repository.dart:53,94`, `lib/services/hydration_ai_orchestrator.dart:118-120`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-SEC-004 — App backup exclusion (Android `allowBackup=false`)
- [ ] TC-SEC-004
- **Platforms**: Android
- **Priority**: P1
- **Steps**: attempt `adb backup` against the app.
- **Expected result**: no app data extracted, confirming `allowBackup="false"` is effective in practice, not just declared.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `android/app/src/main/AndroidManifest.xml:14`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-SEC-005 — Screenshot/App-Switcher preview does not expose sensitive fields
- [ ] TC-SEC-005
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: while body-metrics/pregnancy fields are visible, background the app and check the OS app-switcher preview thumbnail.
- **Expected result**: no explicit screenshot-blocking (`FLAG_SECURE` on Android, obscuring overlay on iOS) was found in the codebase during the audit — **this test confirms whether that is actually a gap in practice**. Not previously flagged as a finding since it wasn't checked; if confirmed exposed, file as a new finding.
- **Automation eligibility**: Manual.
- **Related requirement/finding ID**: new coverage — not in `AUDIT_REPORT.md`, flagged here as a genuine gap in the audit itself.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 21. Low Storage, Low Memory, and Low Battery Conditions

### TC-RES-001 — SharedPreferences write failure under simulated low storage
- [ ] TC-RES-001
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: fill device storage to near-capacity (test device only).
- **Steps**: attempt to log hydration/join a challenge.
- **Expected result**: this is the concrete trigger condition for **HYD-CORR-002** (persist failure racing a concurrent mutation) — use this test to attempt reproduction of that race, and separately confirm a single persist failure alone surfaces a clear error rather than silently losing data.
- **Automation eligibility**: Auto-Device (storage-fill tooling).
- **Related requirement/finding ID**: **HYD-CORR-002**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-RES-002 — Low-memory warning while all four tabs are mounted
- [ ] TC-RES-002
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: trigger a simulated memory-pressure warning (Xcode "Simulate Memory Warning"; Android `adb shell am send-trim-memory`) while on the Social/Challenges tab.
- **Expected result**: app does not crash; measure whether Flutter's image cache or the `IndexedStack`'s always-mounted tabs respond to the pressure signal at all (the audit found no explicit low-memory handling code — this test confirms whether that's actually needed in practice).
- **Automation eligibility**: Auto-Device.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-RES-003 — Battery impact of a multi-hour foreground session
- [ ] TC-RES-003
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: run the app in foreground for 2+ hours with typical interaction; measure battery drain via OS battery-usage tooling.
- **Expected result**: no outlier battery consumption; cross-check against the audit's finding that location/weather polling is well-behaved (pull-based, cached) — this test confirms that holds under real, extended use.
- **Automation eligibility**: Manual (OS battery tools) / Auto-Device (Android Battery Historian, Xcode Energy Log).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 22. Upgrade, Downgrade, and Migration Behavior

### TC-MIG-001 — Upgrade across a version that changes a repository's stored schema
- [ ] TC-MIG-001
- **Platforms**: Android, iOS
- **Priority**: P1
- **Preconditions**: identify any storage key with a version suffix (e.g. `hydrion.body_metrics.v1`, `hydrion.user_settings.v1`, `hydrion.hydration_logs.v1`) — these suffixes imply a migration plan exists or will be needed.
- **Steps**: when a future release introduces a `v2` of any of these keys, test that `v1` data migrates or degrades gracefully rather than being silently dropped.
- **Expected result**: TBD per the specific migration's design — this case is a placeholder to be filled in at the time such a migration is actually shipped; flagged now so it isn't forgotten later.
- **Automation eligibility**: Auto-CI (to be written alongside the migration itself).
- **Related feature/source evidence**: versioned storage keys across all `lib/repositories/*`.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-MIG-002 — Downgrade (reinstall older version over newer data) does not corrupt state
- [ ] TC-MIG-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: install a newer build, create data, then sideload an older build over it.
- **Expected result**: at minimum, does not crash; older code encountering unexpected newer-schema data should fail safely (this exercises the same `storage_recovery.dart` fallback path as TC-INST-003).
- **Automation eligibility**: Manual.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 23. Logout, Account Deletion, and Data Removal

*(No "logout" exists — no account to log out of. "Data removal" maps to local-profile reset, already covered in §3 TC-ACCT-001. This section exists to explicitly confirm that gap rather than skip it silently.)*

### TC-WIPE-001 — Local profile reset actually removes all sensitive fields (paired with HYD-SEC-001)
- [ ] TC-WIPE-001
- **Platforms**: Android, iOS
- **Priority**: P0
- **Steps**: populate body metrics (including pregnancy fields) and a profile photo; run local profile reset; then repeat TC-SEC-001's extraction technique.
- **Expected result**: no trace of the previously-entered sensitive data remains in the underlying storage after reset — confirm reset is a real delete, not just a UI-level "hide."
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `lib/services/local_profile_reset_service.dart`.
- **Related requirement/finding ID**: cross-cutting with **HYD-SEC-001**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 24. Long-Session and Repeated-Action Endurance

### TC-ENDUR-001 — 500+ repeated hydration-log taps in one session
- [ ] TC-ENDUR-001
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: script 500 sequential log-water taps (via `integration_test` or a device automation tool) in one continuous session.
- **Expected result**: no crash, no memory growth beyond expected bounds (cross-check against **HYD-PERF-001/002**'s predicted cost growth), UI remains responsive throughout.
- **Automation eligibility**: Auto-Device.
- **Related requirement/finding ID**: **HYD-PERF-001, HYD-PERF-002**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-ENDUR-002 — Repeated login/logout-equivalent cycling (onboarding reset loop)
- [ ] TC-ENDUR-002
- **Platforms**: Android, iOS
- **Priority**: P2
- **Steps**: repeat "reset local profile → redo onboarding" 20+ times in one session.
- **Expected result**: no cumulative memory growth or state corruption across cycles.
- **Automation eligibility**: Auto-Device.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-ENDUR-003 — Multi-day simulated usage (seeded history) opened repeatedly
- [ ] TC-ENDUR-003
- **Platforms**: Android, iOS
- **Priority**: P1
- **Steps**: seed a year's worth of realistic hydration/challenge history (per TC-PERSIST-003's fixture approach); open and close the app 50 times.
- **Expected result**: startup time and interaction latency do not degrade materially compared to a fresh-install baseline.
- **Automation eligibility**: Auto-Device.
- **Related requirement/finding ID**: **HYD-PERF-001**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 25. Device and OS Compatibility

*(See `DEVICE_OS_MATRIX.md` for the full target matrix. Summary cases below.)*

### TC-COMPAT-001 — Minimum supported OS version smoke test
- [ ] TC-COMPAT-001
- **Platforms**: Android (min SDK per `android/app/build.gradle.kts`), iOS (min deployment target per `ios/Runner.xcodeproj`)
- **Priority**: P0
- **Steps**: run the full smoke suite (§28) on the minimum supported OS version.
- **Automation eligibility**: Auto-Device (real device or emulator/simulator pinned to min OS).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-COMPAT-002 — Latest OS version smoke test
- [ ] TC-COMPAT-002
- **Platforms**: Android (latest stable), iOS (latest stable — confirmed iOS 18.3 available in this audit's environment)
- **Priority**: P0
- **Automation eligibility**: Auto-Device.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 26. Android-Specific Behavior

### TC-AND-001 — Exact-alarm scheduling permission (Android 12+)
- [ ] TC-AND-001
- **Platforms**: Android 12+
- **Priority**: P1
- **Steps**: on Android 12+, verify the app correctly requests/handles `SCHEDULE_EXACT_ALARM` for reminder precision.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `android/app/src/main/AndroidManifest.xml`, `lib/services/notifications.dart` (`ReminderSchedulePrecision`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-AND-002 — Three home-screen widgets install/resize/remove correctly
- [ ] TC-AND-002
- **Platforms**: Android
- **Priority**: P1
- **Steps**: add, resize, and remove each of `HydrionDailyProgressWidget`, `HydrionQuickLogWidget`, `HydrionActiveChallengeWidget`.
- **Automation eligibility**: Manual/Auto-Device.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-AND-003 — Release build minification risk (post-HYD-SEC-004 fix)
- [ ] TC-AND-003
- **Platforms**: Android
- **Priority**: P1
- **Steps**: once R8 minification is enabled (remediation for **HYD-SEC-004**), smoke-test the full app on a release build for reflection-related crashes.
- **Automation eligibility**: Auto-Device.
- **Related requirement/finding ID**: **HYD-SEC-004**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 27. iOS-Specific Behavior

### TC-IOS-001 — Widget extension app-group data sharing
- [ ] TC-IOS-001
- **Platforms**: iOS
- **Priority**: P1
- **Steps**: verify `HydrionWidgets` extension correctly reads shared data via `UserDefaults(suiteName: "group.com.the1807.hydrion")`.
- **Automation eligibility**: Auto-Device.
- **Related feature/source evidence**: `ios/HydrionWidgets/HydrionWidgets.swift:35`.
- **Related requirement/finding ID**: **HYD-SEC-002** (privacy-manifest gap for this exact API).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-IOS-002 — App Store privacy-manifest validation (post-HYD-SEC-002 fix)
- [ ] TC-IOS-002
- **Platforms**: iOS
- **Priority**: P0 (release-blocking for App Store submission)
- **Steps**: run Apple's privacy-manifest validation tooling against an archive build after the `PrivacyInfo.xcprivacy` fix.
- **Automation eligibility**: Auto-Device/CI (Xcode Cloud or local `xcodebuild` archive + validation).
- **Related requirement/finding ID**: **HYD-SEC-002**.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-IOS-003 — ATS/TLS enforcement confirmed on-device
- [ ] TC-IOS-003
- **Platforms**: iOS
- **Priority**: P1
- **Steps**: attempt to force an HTTP (non-HTTPS) request via a debug build modification; confirm ATS blocks it given no `NSAppTransportSecurity` exceptions exist.
- **Automation eligibility**: Manual.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## 28. Regression Testing

### TC-REGR-001 — Full existing automated suite remains green
- [ ] TC-REGR-001
- **Platforms**: CI (macOS runner)
- **Priority**: P0
- **Steps**: `flutter analyze && dart format --output=none --set-exit-if-changed . && flutter test`.
- **Expected result (baseline, established in this audit)**: `flutter analyze` clean, `dart format` clean, `flutter test` 600 passed / 2 skipped (Windows-only tests, correctly skipped on macOS) / 0 failed.
- **Automation eligibility**: Auto-CI (already wired in `.github/workflows/flutter-ci.yml`).
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-REGR-002 — Every new regression test named in this audit's findings is added and green
- [ ] TC-REGR-002
- **Platforms**: CI
- **Priority**: P0
- **Steps**: confirm a regression test exists and passes for each of: HYD-CORR-001, HYD-CORR-002, HYD-SEC-001, HYD-SEC-002, HYD-PERF-001, HYD-PERF-002, HYD-PERF-003, HYD-BLOCK-004 (once root-caused).
- **Automation eligibility**: Auto-CI.
- **Related requirement/finding ID**: see `REMEDIATION_LEDGER.md` for live tracking.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

### TC-REGR-003 — Custom tooling suite remains clean after any change
- [ ] TC-REGR-003
- **Platforms**: CI
- **Priority**: P1
- **Steps**: `dart run tool/secret_scan.dart`, `tool/production_string_audit.dart`, `tool/localization_audit.dart`, `tool/mixed_language_audit.dart`, `tool/artwork_audit.dart` — all must remain at their current clean baseline.
- **Automation eligibility**: Auto-CI.
- **Result**: ☐ Pass ☐ Fail ☐ Blocked
- **Defect ID**:
- **Tester / Device / OS / Build**:

---

## Hydration PDF Reports

Reports are opened from Analytics > Hydration reports. Generation is local and
export requires an explicit user action. Record platform results independently.

### Acceptance Scenarios

- [ ] Weekly selection immediately shows today and the previous six local dates.
- [ ] Monthly selection immediately shows the rolling calendar-month boundary.
- [ ] Quarterly selection immediately shows the rolling three-month boundary.
- [ ] Yearly selection immediately shows the rolling twelve-month boundary.
- [ ] March 31 and leap-year dates follow the clamp-then-next-day rule.
- [ ] Rapid switching leaves dates, metrics, graph and PDF on the last selection.
- [ ] Exact inclusive boundaries match in the preview and exported PDF.
- [ ] Missing dates use the missing marker and are not displayed as zero intake.
- [ ] Known target changes appear only from their effective dates.
- [ ] Unavailable historical targets are labeled unavailable, never backfilled.
- [ ] Daily, weekly and monthly graph aggregates reconcile with report totals.
- [ ] Graph bars, target markers, missing markers, axes, unit and legend remain understandable without color.
- [ ] EN, ES and FR graph labels remain readable without clipping.
- [ ] Light and dark preview themes keep adequate graph contrast.
- [ ] Maximum yearly history generates without freezing or excessive memory use.
- [ ] Editing, moving or deleting entries updates both preview and PDF.
- [ ] Milliliter and fluid-ounce display values remain consistent.
- [ ] Empty and in-progress periods are clearly identified.
- [ ] Navigating away during generation produces no late update or success message.
- [ ] Dismissing sharing produces no success message and permits another attempt.
- [ ] Export failure shows a recoverable error and preserves hydration records.
- [ ] Repeated attempts leave no duplicate or abandoned temporary report files.
- [ ] Android can open, save and share the PDF through system targets.
- [ ] iOS can open, save and share the PDF through system targets.
- [ ] PDF pages have readable tables, headers, footers and page numbers.

### Platform Gates

Android and iOS opening, saving and sharing are physical acceptance gates. A
passing Dart/widget suite or web build does not certify a system share target.

---

*End of tester bible. See `AUTOMATION_CANDIDATES.md`, `DEVICE_OS_MATRIX.md`, `SECURITY_TEST_MATRIX.md`, `TEST_COVERAGE_GAPS.md`, and `REMEDIATION_LEDGER.md` for the companion artifacts referenced throughout. No checkbox above has been executed or marked complete by the audit itself — all Result fields are left blank for the testing team.*
