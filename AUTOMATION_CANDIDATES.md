# Hydrion — Automation Candidates

Derived from `tester_bible.md`. Purpose: rank which test cases to automate first, in which framework, and which are better left manual given current environment constraints (see `AUDIT_REPORT.md` §4.1 and §9 for what this environment could/could not execute).

## Tier 1 — Automate immediately in `flutter test` (widget/unit level, no device needed)

These require no plugin/device boundary and slot directly into the existing `test/` suite pattern.

| Test case | Why Tier 1 | Notes |
|---|---|---|
| TC-CTRL-004 (activity-panel navigate-away crash, HYD-CORR-001) | Pure widget lifecycle; mirrors existing `pomodoro_session_ui_test.dart` pattern exactly | Write as a new case in that same file |
| TC-CTRL-003 (challenge join double-tap) | In-memory repository logic, no plugin | New test in `challenge_recommendation_test.dart` or a new file |
| TC-VAL-001/002/003/004 (input validation) | Pure Dart validation logic | Extend existing domain tests |
| TC-ONB-002's untested age boundaries (null/-1/121/120) | Existing `life_stage_policy_test.dart` just needs more parameterized cases | Cheapest fix in this entire document |
| TC-A11Y-002 pattern extension (large text on every screen) | Existing pattern in `legal_document_test.dart`/`challenge_personalization_correction_test.dart` just needs broader application | Low effort, meaningfully closes a real gap |
| TC-PERSIST-003 / TC-PERF-003 (seeded large-history perf) | Can seed `MemoryHydrionStore` with thousands of synthetic entries entirely in-process | High value — this is the only practical way to get HYD-PERF-001's real-world magnitude without months of field data |
| TC-REGR-002 (regression test existence for each finding) | Meta-test asserting the other new tests exist and pass | Write last, once the above land |

## Tier 2 — Automate via `integration_test` (real Flutter engine, real plugin channels; runs on simulator/emulator or real device)

These need the real engine because the defect class is specifically about the boundary `flutter test`'s fake clock/mocked channels paper over — this is the single most important structural gap this audit found (see `AUDIT_REPORT.md` HYD-BLOCK-004's "why the test suite doesn't catch this" explanation).

| Test case | Why Tier 2 | Priority |
|---|---|---|
| TC-INST-001 / TC-PERF-001 (full boot-to-home timing) | **Highest priority new automated test in this entire audit.** Existing `integration_test/android_notification_delivery_test.dart` is the only precedent; extend the pattern to a full-boot assertion | P0 |
| TC-NOTIF-001/002/004 (real notification delivery/actions) | Needs real OS notification tray, already has one precedent file | P0/P1 |
| TC-PERM-001/002/003/004 (real OS permission dialogs) | `flutter test` cannot drive real permission dialogs | P0/P1 |
| TC-KILL-001/002/003 (force-kill/process-death) | Needs real process lifecycle | P0/P1 |
| TC-CORE-005/006 (home-screen widget taps) | Needs real OS widget surface | P1 |
| TC-LC-001/002/003 (background/foreground, day rollover) | Needs real app lifecycle + wall-clock time | P1 |
| TC-NAV-001 (full route-table smoke) | Best run as one real-engine pass across every route rather than 15 separate widget tests, to also catch any real-plugin-initialization interaction between screens | P0 |

## Tier 3 — Device-farm or real-hardware only (cannot be fully automated in any CI runner without one)

| Test case | Why Tier 3 |
|---|---|
| TC-SEC-001 (rooted-device extraction) | Requires a rooted/jailbroken device or equivalent container-inspection access |
| TC-NOTIF-002 (reboot survival) | Requires a real reboot cycle |
| TC-RES-001/002/003 (low storage/memory/battery) | Requires real resource-pressure simulation tooling per-platform |
| TC-COMPAT-001/002 (OS version matrix) | Requires a real device/OS matrix — see `DEVICE_OS_MATRIX.md` |
| TC-IOS-002 (App Store privacy-manifest validation) | Requires an Xcode archive + Apple's own validation step |
| TC-ENDUR-001/003 (endurance/large-scale) | Best run on real hardware to get real memory/battery signal, though the seeded-fixture *correctness* portion (Tier 1) can run in CI |

## Tier 4 — Manual only (human judgement required, at least for now)

| Test case | Why manual |
|---|---|
| TC-A11Y-001 (screen reader flow) | Screen-reader UX quality needs a human; can add basic `Semantics` tree assertions as a Tier-1 supplement, but full VoiceOver/TalkBack flow validation is human work |
| TC-A11Y-003 (contrast) | No contrast-checking tool is currently in the CI pipeline; introduce one (justify against the "prove existing stack insufficient" rule first — `flutter_lints`/`flutter analyze` do not check contrast) before promoting this to Tier 1 |
| TC-VIS-001/002/003 (visual quality) | Subjective/visual judgement; candidate for future visual-regression tooling (see `MOBILE_TEST_PLATFORM_EVALUATION.md`) |
| TC-NET-002 "from cache" badge visibility | Needs a human to confirm the UI actually communicates the cached state, since this was UNVERIFIED from static code alone |
| TC-SEC-005 (screenshot/app-switcher exposure) | Visual confirmation of OS-level behavior |

## What NOT to automate yet

Per the audit's own instruction ("do not automate unstable journeys until deterministic test data, account isolation, and environment reset mechanisms exist"): the Gemini/AI-coach path (currently unreachable, HYD-ARCH-001) should not be automated until a product decision is made to ship it — automating a dead UI wastes maintenance effort. Similarly, do not automate anything against a live Gemini/Open-Meteo endpoint in CI without a dedicated test API key and rate-limit budget; use recorded/mocked responses for CI and reserve live-network cases (TC-CORE-002, TC-NET-001–004) for a scheduled, lower-frequency device-farm run.
