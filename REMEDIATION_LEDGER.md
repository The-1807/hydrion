# Hydrion — Remediation Ledger

Live tracking document for every finding in `AUDIT_REPORT.md`. **Nothing in this ledger has been actioned yet** — per the audit's controlled-workflow rule, remediation begins only after the owner reviews the report and confirms priority/scope, especially for HYD-BLOCK-004 (needs real-device reproduction first) and HYD-SEC-001 (needs a storage-migration decision). Update the Status column as work proceeds; do not delete rows, so this remains a full history.

| Finding ID | Severity | Summary | Status | Owner | Fix commit/PR | Regression test added | Verified by | Date closed |
|---|---|---|---|---|---|---|---|---|
| HYD-BLOCK-004 | High (pending confirmation) | App did not progress off startup screen in a live iOS Simulator run; root cause not isolated | **Open — needs real-device reproduction first** | — | — | — | — | — |
| HYD-SEC-001 | High | Health/PII (weight, height, pregnancy, profile photo) stored unencrypted | **Open — needs `flutter_secure_storage` migration decision** | — | — | — | — | — |
| HYD-CORR-001 | High | Unguarded `context` access after `await` in `_ChallengeActivityPanelState._syncTicker()` | **Open — trivial one-line fix identified** | — | — | — | — | — |
| HYD-CORR-002 | Medium | Full-snapshot rollback on persist failure can discard a concurrent change | **Open — fix pattern identified (match `addLog`/`restoreLog`)** | — | — | — | — | — |
| HYD-PERF-003 | Medium | Native timed-session notification has no timeout backstop for paused state | **Open** | — | — | — | — | — |
| HYD-SEC-002 | Medium | iOS privacy manifest missing required-reason API declaration for `UserDefaults(suiteName:)` | **Open — real App Store submission risk** | — | — | — | — | — |
| HYD-SEC-003 | Medium | Gemini API key embedded in compiled binary via `--dart-define` | **Open — server-side key-restriction posture needs owner confirmation (outside repo)** | — | — | — | — | — |
| HYD-PERF-001 | Medium | `HydrationRepository._logs`/`ChallengeRepository._challengeHistory` unbounded | **Open — retention-cap pattern already proven elsewhere in the repo** | — | — | — | — | — |
| HYD-PERF-002 | Medium | Every hydration log triggers full-history recompute cascade across all mounted tabs | **Open — resolves substantially once HYD-PERF-001 lands** | — | — | — | — | — |
| HYD-ARCH-001 | Medium | Gemini AI coach fully implemented, zero reachable UI; docs describe a UI that doesn't exist | **Open — needs product decision: ship or formally shelve** | — | — | — | — | — |
| HYD-SEC-004 | Low | Android release builds ship without minification/obfuscation | **Open** | — | — | — | — | — |
| HYD-SEC-005 | Low | `flutter_local_notifications`/`flutter_lints` multiple major versions behind | **Open** | — | — | — | — | — |
| HYD-SEC-006 | Low | Dead config files (`app.yaml`, `firebase_config.json`, `open_ai_config.yaml`) shipped as compiled assets | **Open** | — | — | — | — | — |
| HYD-SEC-007 | Low | Non-release-guarded `debugPrint` in `android_widget_service.dart:318` | **Open** | — | — | — | — | — |
| HYD-CORR-003 | Low | `TimedSessionNotificationService` never unregisters locale listener | **Open — latent, low priority** | — | — | — | — | — |
| HYD-CORR-005 | Low | `tz.setLocalLocation()` never called | **Open — currently inert, fix before any recurring-notification feature is built** | — | — | — | — | — |
| HYD-PERF-004 | Low | Profile photo re-decoded on every unrelated rebuild | **Open** | — | — | — | — | — |
| HYD-ARCH-002 | Low | `core_bridge.dart` misleadingly named; no real FFI to `core/` Rust workspace | **Open — needs decision: pursue FFI or rename/archive** | — | — | — | — | — |
| HYD-ARCH-003 | Low | Orphaned scaffolding (`packs/byok_llm`, `packs/gemini_connector`, `packs/edge_llm`) | **Open — repo hygiene, low urgency** | — | — | — | — | — |
| HYD-BUILD-003 | Low | `.fvmrc` (3.44.8) drifts from CI-pinned/system Flutter (3.44.9), `fvm` not installed locally | **Open** | — | — | — | — | — |
| HYD-BUILD-005 | Low | Local iOS `pod install` requires `LANG=en_US.UTF-8` workaround | **Open — document in `scripts/dev_setup.sh`** | — | — | — | — | — |
| HYD-CI-001 | Low | No coverage-percentage threshold enforced in CI quality gate | **Open** | — | — | — | — | — |
| HYD-ARCH-004 | Info | Deep-link infrastructure declared but not implemented | **No action required — informational** | — | — | — | — | — |
| HYD-SEC-008 | Info | No root/jailbreak detection | **Owner risk-acceptance decision, not a defect** | — | — | — | — | — |
| HYD-SEC-009 | Info | No certificate pinning | **Optional defense-in-depth backlog item** | — | — | — | — | — |

## Process notes

- **Do not close a row until its `AUDIT_REPORT.md`-specified regression test exists and is green in CI.** A code fix without a regression test is not considered closed by this ledger's own standard, matching the audit's non-negotiable rule against declaring success without inspection.
- **Do not batch unrelated fixes into one commit/PR** — each row should map to its own commit/PR, per the audit's instruction against combining unrelated refactors with fixes.
- When a finding is closed, also update the corresponding row's checkbox context in `tester_bible.md` if a new test case was added there, and update `TEST_COVERAGE_GAPS.md` to remove the now-closed gap.
- Re-run this file's status against `AUDIT_REPORT.md` at every release candidate — do not let this ledger silently drift out of sync with the source report.
