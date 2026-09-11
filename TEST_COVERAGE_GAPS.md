# Hydrion — Test Coverage Gaps

Consolidated from `AUDIT_REPORT.md` §8 and the deeper detail surfaced by the Stage 3/5 sub-agent passes. Organized as: **Feature/behavior → current coverage → gap → proposed test**.

| # | Feature/behavior | Current coverage | Gap | Proposed test (tester_bible ID) |
|---|---|---|---|---|
| 1 | Full app boot to `/home` on a real engine | None — only widget-test-harness coverage (fake clock, mocked channels) | This exact gap is why HYD-BLOCK-004 was never caught by CI | TC-INST-001, TC-PERF-001 |
| 2 | Activity-challenge timer dispose under rapid navigation | None (only the Pomodoro variant is tested) | HYD-CORR-001 crash risk has zero regression coverage | TC-CTRL-004 |
| 3 | Concurrent repository mutation + persist failure | None | HYD-CORR-002's rollback-scope bug is untested | TC-RES-001 |
| 4 | Real native `MethodChannel` path for timed-session notifications | Only a fake adapter is tested (`test/timed_session_notification_test.dart`) | HYD-PERF-003's native-lifecycle gap (no timeout backstop on paused state) has zero coverage of the real Kotlin path | TC-KILL-001, TC-KILL-002 |
| 5 | Large-scale hydration/challenge history performance | None | HYD-PERF-001/002's real-world magnitude is UNVERIFIED without a seeded large-history test | TC-PERSIST-003, TC-PERF-003, TC-ENDUR-001/003 |
| 6 | `android_widget_service.dart` sync frequency/debounce | None | Could silently drop a widget update under rapid successive logs (dropped, not queued) | TC-PERSIST-002 |
| 7 | `life_stage_policy.dart` edge/boundary inputs | Happy-path + a few boundaries only | `null`, negative, `>120` ages, and `bodyReferenceStage`'s distinct `<13` branch are all untested | TC-ONB-002 |
| 8 | `challenge_eligibility.dart` with `age: null` | None | Intentional-looking `unresolved`-stage behavior for null age is completely untested | New case, add to `test/challenge_eligibility_test.dart` |
| 9 | `hydration_pacing_engine.dart` | **No test file found exercising this class by name at all**, despite the logic itself being well-written | Well-built logic with, per this audit's search, zero direct unit tests | New file `test/hydration_pacing_engine_test.dart` |
| 10 | `tz.setLocalLocation()` / DST correctness | None directly | HYD-CORR-005 is currently inert but untested; a future recurring-notification feature would silently inherit the bug | TC-NOTIF-003 |
| 11 | "From cache" weather-offline UI indicator | Unknown — audit could not confirm from static reading whether any widget renders `CurrentWeatherContext.fromCache` | UNVERIFIED whether users are ever told they're seeing stale data | TC-NET-002 |
| 12 | Accessibility (screen reader, contrast, touch targets) | Only large-text-scale cases exist in 2 test files | No screen-reader flow test, no contrast check, no touch-target-size check anywhere | TC-A11Y-001 through TC-A11Y-004 |
| 13 | Real device permission dialogs (location, notifications, photos) | None (cannot be exercised in `flutter test`) | Every permission-dependent feature's real-world grant/deny UX is unverified | TC-PERM-001 through TC-PERM-005 |
| 14 | Screenshot/app-switcher preview of sensitive data | Not checked anywhere, including in this audit | Genuinely new gap — `FLAG_SECURE`/obscuring-overlay presence was never investigated | TC-SEC-005 |
| 15 | Rooted/jailbroken-device data extraction | Not checked live (only inferred from the absence of `flutter_secure_storage` in `pubspec.yaml`) | HYD-SEC-001's real-world exploitability was reasoned about, not demonstrated on a rooted device in this pass | TC-SEC-001 |
| 16 | Dependency CVE scanning | `dart pub outdated` only (staleness, not vulnerabilities) | `dart pub audit` does not exist in this SDK — no automated CVE-database check exists at all today | Owner decision: evaluate an external tool (e.g. OSV-Scanner) against the "prove existing stack insufficient" bar before adding |
| 17 | Coverage percentage regression gate | Coverage is generated and uploaded as a CI artifact | Not enforced — a coverage regression would not fail CI (HYD-CI-001) | Add a threshold check to `flutter-ci.yml`'s "Enforce quality gate" step |
| 18 | Web platform runtime behavior | `flutter build web` succeeds | No Chrome available in this audit's environment to test any actual web interaction | Needs an environment with Chrome, or a headless-Chrome CI step |
| 19 | Migration/schema-versioning tests for future `v2` storage keys | None yet (no `v2` key exists today) | Placeholder gap — flagged so it isn't forgotten when the first schema migration ships | TC-MIG-001 |
| 20 | Visual regression (pixel-level UI diffing) | None | No visual-regression tooling exists in this stack today | Evaluate as part of `MOBILE_TEST_PLATFORM_EVALUATION.md`'s supporting-tools section |

## Meta-gap: this audit's own limitations

- No Android SDK/emulator/device was available, so **every Android-specific behavior in this table is doubly unverified** — not just "no automated test exists," but "no execution of any kind, automated or manual, was possible in this environment."
- No live memory/CPU profiler (Instruments, Android Profiler, DevTools) was available, so items 5 and 9 above are backed by static code reading only, not measurement.
- The correctness/concurrency and memory sub-agent passes were thorough but time-boxed; they explicitly flagged several items as "UNVERIFIED beyond the greps performed" (e.g., `social_challenges_screen.dart`'s full lifecycle-safety was not exhaustively line-read). Treat this table as strong but not provably exhaustive.
