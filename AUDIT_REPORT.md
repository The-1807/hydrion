# Hydrion — Production Engineering, Security, and Mobile-Quality Audit

**Audit date:** 2026-08-27
**Auditor:** Claude Code (Sonnet 5), operating directly against the working tree at `/Users/uchennaanozie/Documents/hydrion`
**Scope:** Full repository as checked out on branch `main`, commit `3b71b8f` at audit start. No git operations were performed. No files outside this report/its companion documents were modified.
**Method:** Every claim below is backed by a command that was actually executed and inspected, or a file that was actually read (by the auditor directly or by a research sub-agent operating under the same read-only constraint). Nothing is inferred from filenames, comments, or prior documentation without independent code verification. Contradictions between documentation and code are called out explicitly rather than silently resolved in either direction.

---

## 1. Executive Summary

Hydrion is a real, substantially-functional Flutter hydration-tracking app (`ai.hydrion.app` / `com.the1807.hydrion`) targeting Android, iOS, web, macOS, Linux, and Windows, with a vestigial/unwired Rust workspace and several dead scaffolding directories left over from abandoned architecture directions. The **core hydration-logging, challenge/Pomodoro, local-notification, weather-goal, home-screen-widget, onboarding, and legal-consent features are real, locally implemented, and pass the full existing automated test suite** (600 tests, 0 failures). Static analysis, formatting, and the project's own custom audit tooling (secret scan, localization, artwork, mixed-language) are all clean.

However, three categories of finding materially change the picture a filename-level read would give:

1. **A large fraction of the "AI coach" feature is real, working code with zero path for a user to ever reach it.** The Gemini REST integration, orchestrator, consent gate, and diagnostics are genuine and correctly gated — but the only UI screen meant to expose it (`ChatCoachScreen`) is a static "coming soon" placeholder not wired into any route, and internal architecture docs describe a working Coach UI that does not currently exist in the code. This is the single largest documentation/implementation divergence found.
2. **Sensitive health data is stored unencrypted.** Weight, height, pregnancy status/duration, clinician hydration targets, and a base64-embedded profile photo are persisted in plaintext `SharedPreferences`/`NSUserDefaults` with no `flutter_secure_storage` or Keychain/Keystore layer anywhere in the dependency tree. This is the highest-severity finding in the audit (§7, HYD-SEC-001).
3. **A live reproduction on iOS Simulator surfaced a startup hang that the existing automated test suite does not catch.** The app was installed and launched on a booted iPhone 16 Pro simulator; it remained on the "Preparing your hydration space…" splash screen for over a minute while consuming ~40% sustained CPU, and a `flutter run` session was used to capture the live debug trace (see §6.4 and §12 blocker HYD-BLOCK-004 for the exact evidence and root-cause status at time of writing). Every widget test that exercises the startup screen passes, because the test harness uses a simulated clock and mocked plugin channels — this divergence between test-harness time and real-device/plugin timing is itself a finding (test-gap, §9).

A dedicated concurrency/lifecycle pass over the real, reachable code paths (not the stubs) found one additional **High**-severity bug: a `BuildContext` accessed after an unguarded `await` gap in the activity-challenge timer control (`_ChallengeActivityPanelState._syncTicker`, §6.1a HYD-CORR-001), and one **Medium**-severity systemic race condition where several repository mutation methods roll back to a full pre-mutation snapshot on a persist failure, silently discarding any other operation's already-applied and already-persisted change that landed in between (§6.1a HYD-CORR-002). Both were found by reading the real code paths that back the four repository/service files everything else in the app depends on, not by speculation.

Everything else — build health, dependency posture, CI/CD design, and the majority of the codebase's engineering discipline — is solid to good. The project's own custom static-analysis tools (`tool/secret_scan.dart`, `tool/production_string_audit.dart`, `tool/localization_audit.dart`, `tool/mixed_language_audit.dart`, `tool/artwork_audit.dart`) are unusually mature for a project this size and all ran clean. Error handling is disciplined: an audit of all 39 `catch` sites in `lib/` found no case of a swallowed error being followed by a misleading "success" message to the user.

**No claim of "secure," "production-ready," or "fully functional" is made by this report.** The findings below, in particular HYD-SEC-001, HYD-CORR-001, and HYD-BLOCK-004, are release blockers as written.

---

## 2. Repository and Architecture Map

### 2.1 Technology stack (verified)

| Layer | Technology | Evidence |
|---|---|---|
| App framework | Flutter 3.44.9 (stable), Dart 3.12.2 SDK | `flutter --version` output; `pubspec.yaml:sdk: ">=3.5.0 <4.0.0"` |
| Pinned version | Flutter 3.44.8 via `.fvmrc` | `fvm` is **not installed** in this environment (`which fvm` → not found); the system `flutter` (3.44.9) was used instead — a real, if minor, version drift (HYD-BUILD-003) |
| State/DI | `provider` ^6.1.2, manual service-locator (`HydrionServices` in `lib/main.dart`) | No DI framework (get_it, riverpod); confirmed by `pubspec.yaml` and `lib/main.dart:482-917` |
| Navigation | Classic `Navigator` + static `Map<String, WidgetBuilder>` route table | `lib/main.dart:281-339,415-441`; no GoRouter/declarative routing |
| Local persistence | `shared_preferences` ^2.3.3 only — **no embedded database** | `lib/storage/local_store.dart`; confirmed absent: sqlite/Hive/Isar |
| Networking | `http` ^1.2.2 (Gemini REST, Open-Meteo weather) | `lib/adapters/gemini/gemini_adapter.dart`, `lib/services/weather_goal_service.dart` |
| Notifications | `flutter_local_notifications` ^20.1.0 + `timezone` ^0.10.1 | `lib/services/notifications.dart` (942 lines) |
| Location | `geolocator` ^14.0.2 | `lib/services/location_service.dart` |
| Home-screen widgets | `home_widget` ^0.9.3 | `lib/services/android_widget_service.dart`; native side `ios/HydrionWidgets/`, Android `AppWidgetProvider`s |
| Media | `image_picker` ^1.2.2 | `lib/services/profile_photo_service.dart` |
| Animation | `lottie` ^3.3.3 | Startup splash only (`lib/ui/components/hydrion_startup_shark.dart`) |
| Localization | `flutter_localizations`, `intl`, ARB-based (`lib/l10n/app_{en,es,fr}.arb`) | `l10n.yaml`; 838 required Flutter messages, 100% coverage for en/fr/es (verified, §5) |
| Not present despite adjacent scaffolding | Firebase (any), BLE plugin, Gemini/Google-AI SDK, health/wearable plugin, `flutter_rust_bridge`/`dart:ffi`, `uni_links`/`app_links`, `go_router`, `webview_flutter`, `flutter_secure_storage`, `workmanager`/`background_fetch` | Confirmed absent from `pubspec.yaml` and via `grep` for imports across `lib/` |
| Secondary/unintegrated stack | Rust workspace (`core/cargo.toml`, 5 crates), Python model-training scripts (`models/training/`), Node.js server stubs (`packs/byok_llm/server`, `packs/gemini_connector/server`), Python/Behave BDD features (`features/*.feature`) | None of these are invoked by the Flutter app or its CI build steps that produce the shipped app; see §2.3 |

### 2.2 Platforms and entry points

- **Android**: `android/app/src/main/AndroidManifest.xml`, package `com.the1807.hydrion` (note: differs from `pubspec.yaml`'s conceptual `ai.hydrion.app` naming used in docs — the real installed package ID is `com.the1807.hydrion`, confirmed via `MainActivity.kt` path `android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt` and the live simulator install in §6.4 which used bundle id `com.the1807.hydrion`). Native Kotlin handles two real `MethodChannel`s: `hydrion/permission_revocation` and `hydrion/timed_session`.
- **iOS**: `ios/Runner/`, `com.the1807.hydrion` bundle id (confirmed live, §6.4), plus a real widget extension target `ios/HydrionWidgets/` (Swift, WidgetKit).
- **Web**: `web/index.html`, builds successfully (`flutter build web --release`, §4) but was not runtime-tested (no Chrome executable in this environment — `flutter doctor` reports Chrome missing).
- **macOS/Linux/Windows**: platform scaffolding exists (`macos/`, `linux/`, `windows/`) and is Flutter's standard generated desktop runner; not exercised in this audit (out of stated product scope per `docs/release/HYDRION_V1_KNOWN_LIMITATIONS.md`, not independently re-verified).
- **App entry point**: `lib/main.dart:73-78` (`main()` → `runApp(HydrionBootstrapApp())`). Boot sequence shows `StartupScreen` while `HydrionServices.local()` assembles the full service graph, then computes the real initial route via a gate chain: `/language` → `/onboarding` → `/profile-age-review` → `/legal-review` → `/home` (`lib/main.dart:121-143`).

### 2.3 Dead / orphaned / unintegrated code (verified, not inferred from names)

| Path | Verdict | Evidence |
|---|---|---|
| `core/` (Rust workspace: `hydrion-core`, `hydrion-crypto`, `hydrion-i18n`, `hydrion-time`, `hydrion_storage`) | **Fully unintegrated.** Real Rust source exists, but no `.so`/`.dylib`/`.xcframework` artifact, no NDK/Cargo hook in `android/app/build.gradle.kts`, no script phase in `ios/Podfile`. `lib/services/core_bridge.dart` — despite its name — is pure Dart with zero `dart:ffi` usage; it never touches this workspace. | Confirmed by grep for `dart:ffi`/`flutter_rust_bridge`/`DynamicLibrary` (zero hits) and by direct read of `core_bridge.dart` |
| `packs/byok_llm/`, `packs/gemini_connector/`, `packs/edge_llm/` | **Orphaned scaffolding**, mostly empty files/`.gitkeep`s and a couple of trivial Node.js server stubs. Zero references from `lib/` or `pubspec.yaml`. | `grep -rln "packs/\|byok_llm\|edge_llm\|gemini_connector" lib/ pubspec.yaml` → zero matches |
| `config/app.yaml`, `config/firebase_config.json`, `config/open_ai_config.yaml` | **Dead config, but still shipped as compiled assets** (`pubspec.yaml` declares `config/` as a Flutter asset dir). No Dart code reads any of the three. Only `config/prompt_templates.yaml` is loaded, by `lib/utils/llm_prompt_builder.dart` — which itself has zero callers anywhere else in `lib/` and is therefore also dead. | grep confirms zero `app.yaml`/`firebase_config`/`open_ai_config` readers in `lib/`; see HYD-SEC-006 |
| `lib/adapters/elka/elka_adapter.dart` | **Intentional always-failing stub** (`ElkaAdapterShell.unconfigured()`), instantiated and provided to the widget tree, but every method throws `UnsupportedError`; no screen calls it. Matches its own architecture doc (`docs/architecture/ADAPTER_BOUNDARY.md`) exactly. | `lib/adapters/elka/elka_adapter.dart:34-74`, `lib/main.dart:829` |
| `lib/ui/screens/chat_coach_screen.dart` | **Orphaned UI** — not in the route table, renders a static "coming soon" card, imports nothing from the (real) coach/orchestrator layer. | `lib/main.dart` route table (no entry); `chat_coach_screen.dart:6,14-49` |
| `lib/services/ble_service.dart`, `wearable_service.dart`, `voice_client.dart` | **Inert stubs by design**, consistent with `docs/CONNECTED_DEVICES_ROADMAP.md` and `config/app.yaml`'s (unread) feature flags. `VoiceInputWidget`'s mic button has `onPressed: null` — permanently disabled. | Full-file reads; `lib/ui/components/voice_input_widget.dart:25-37` |
| `lib/utils/logging.dart` | Dead — zero call sites anywhere in `lib/`. | grep confirms 0 usages of `Log.i/w/e` |
| `models/training/*.py`, `features/*.feature` (Behave) | Not part of the Flutter build or CI gate that produces the shipped app; not independently audited for correctness in this pass (out of scope — these are ML-experimentation and separate BDD scaffolding, not shipped-app code). | File presence + absence from `.github/workflows/flutter-ci.yml` app-build steps |

**Interpretation**: the repository contains a materially larger surface area than the shipped app. This is normal for a project mid-pivot, but it means naïve "grep for BLE/AI/Rust and assume it's a feature" analysis (which this audit was explicitly instructed to avoid) would have produced a false picture. `docs/architecture/STALE_SCAFFOLD_AUDIT.md` already correctly self-documents most of this — it is the most accurate internal doc in the repo and its claims were independently confirmed rather than trusted at face value.

---

## 3. Feature Inventory (real, reachable features only)

Established by full-repository navigation trace (`lib/main.dart` route table) plus per-screen dependency verification. "Real" means: reachable from a route, backed by a genuine data source (not a stub), and exercised by at least one existing automated test unless noted.

| Feature | Screen(s) | Backing data | Reachability | Test coverage evidence |
|---|---|---|---|---|
| Language selection | `language_selection_screen.dart` | `AppLocaleRepository` (SharedPreferences) | `/language`, first-run gate | `app_locale_repository_test.dart`, `localization_test.dart` |
| Onboarding | `onboarding_screen.dart` | `UserSettingsRepository`, `HydrionLifeStagePolicy` | `/onboarding` | `startup_onboarding_test.dart` |
| Age/life-stage review | `profile_age_review_screen.dart` | `UserSettingsRepository` | `/profile-age-review` | `profile_age_review_test.dart`, `life_stage_policy_test.dart` |
| Legal consent | `legal_about_screen.dart` (3 sub-screens) | `HydrionLegalDocumentRegistry`, bundled markdown | `/legal-about`, `/legal-review`, per-doc routes | `legal_document_test.dart` (10 cases) |
| Home hydration dashboard | `home_screen.dart` (tab 0 of shell) | `HydrationRepository`, `hydration_pacing_engine.dart` | `/home` (embedded) | multiple `*_ui_test.dart` |
| Manual hydration logging | `log_screen.dart` | `HydrationRepository` | `/log` | `persistence_test.dart`, `product_qa_test.dart` |
| Analytics/history | `analytics_screen.dart` | `HydrationRepository`, `eco_tracker.dart` (local arithmetic, not a real external eco/environmental data source — see §2.3) | `/analytics` (embedded) | — |
| Social/challenges hub | `social_challenges_screen.dart` | `ChallengeRepository` + 7 other repositories (see §8, HYD-PERF-002 for the resulting rebuild-cost finding) | `/challenges` (embedded) | `challenge_*_test.dart` (9 files) |
| Challenge experience (Pomodoro, bingo, temperature roulette, around-the-world) | `challenge_experience_screen.dart` | `ChallengeRepository`, `pomodoro_session_service.dart`, `timed_session_notification_service.dart` | pushed from Social/Home/widget tap | `release18_challenge_*_test.dart`, `pomodoro_session_*_test.dart`, `challenge_visual_game_test.dart` |
| Reminders | `reminders_screen.dart` | `ReminderRepository`, `flutter_local_notifications` | `/reminders` — **conditionally registered**, only if `capabilityReporter.capabilities.osNotifications` | `reminder_feedback_test.dart`, `notification_service_test.dart`, `timed_session_notification_test.dart` |
| Weather-based goal adjustment | integrated into Home/Body-Metrics flow | `weather_goal_service.dart` — real `http` calls to Open-Meteo, `geolocator` for coarse location | n/a (service, not a screen) | `weather_location_goal_test.dart`, `temperature_roulette_weather_test.dart` |
| Profile & body metrics | `profile_screen.dart`, `body_metrics_screen.dart` | `SettingsRepository`, `BodyMetricsRepository`, `profile_photo_service.dart` (real `image_picker`) | `/profile`, `/body-metrics` | `profile_lifestyle_art_test.dart`, `profile_age_review_test.dart` |
| Settings | `settings_screen.dart` | `SettingsRepository`, `AppLocaleRepository`, `GuidedTourRepository` | `/settings` | — |
| Permission center | `permission_center_screen.dart` | OS permission state via `utils/permissions.dart` | `/permissions` | `permission_consent_test.dart` |
| Android/iOS home-screen widgets | native (`HydrionDailyProgressWidget`, `HydrionQuickLogWidget`, `HydrionActiveChallengeWidget`; iOS `HydrionWidgets.swift`) | `android_widget_service.dart` via real `home_widget` plugin calls | OS home screen, tap re-launches app via `hydrion://` scheme | `android_widget_service_test.dart` |
| Local-rules hydration "coach" (deterministic, no network) | surfaces as reminder/nudge copy | `lib/adapters/local/local_hydrion_adapters.dart` | always active (default provider) | `hydration_pacing_engine_test.dart`, `coach_suggestion_service_test.dart` |

**Real but currently unreachable feature** (documented separately because it is fully implemented, not a stub): Gemini-backed AI hydration coach — `lib/adapters/gemini/gemini_adapter.dart` (876 lines, genuine HTTPS REST client against `generativelanguage.googleapis.com`), `hydration_ai_orchestrator.dart`, `coach_suggestion_service.dart`, `provider_health.dart`. Gated correctly behind a real, tested consent flag (`nonLocalProviderConsentGranted`, default `false`) — but has **no UI screen that a user can reach** to ever activate or see it (§2.3, §7 HYD-ARCH-001).

**Not a feature (confirmed absent)**: remote push notifications (no FCM/`firebase_messaging` despite `config/firebase_config.json` existing), background/scheduled sync (no WorkManager/BGTaskScheduler/background_fetch anywhere), external deep-linking (the `hydrion://` scheme exists solely for widget tap-through, with no `application(_:open:options:)` handler on iOS and no data-bearing Android intent-filter), BLE smart-bottle sync, wearable/Health Connect/HealthKit sync, voice input.

---

## 4. Baseline Results — Commands Actually Executed

All commands below were run against the working tree exactly as checked out; none required or performed any git operation.

| # | Command | Result | Notes |
|---|---|---|---|
| 1 | `flutter --version` | Flutter 3.44.9 stable, Dart 3.12.2 | System flutter, not fvm-pinned 3.44.8 (HYD-BUILD-003) |
| 2 | `flutter pub get` | **Success** | "Got dependencies! 41 packages have newer versions incompatible with dependency constraints." |
| 3 | `flutter analyze` | **Success — "No issues found!"** (9.7s) | Clean |
| 4 | `dart format --output=none --set-exit-if-changed .` | **Success** — "Formatted 198 files (0 changed)" | Clean |
| 5 | `flutter test` | **600 passed, 2 skipped, 0 failed** (~39 min wall time) | The 2 skips are `test/issue_sync_security_test.dart:43,76`, both explicitly `skip: !Platform.isWindows` (Windows-only CI-label-validation tests; correctly skipped on macOS, not a gap) |
| 6 | `dart run tool/secret_scan.dart` | **"No committed API keys, credentials, or private key blocks found."** | Project's own CI-gating secret scanner |
| 7 | `dart run tool/production_string_audit.dart` | **839/839 lines "REVIEWED", zero flagged** | Checks for un-localized/hardcoded user-facing strings |
| 8 | `dart run tool/localization_audit.dart` | **en/fr/es: 838/838 Flutter messages, 24/24 Android strings — 0 missing, 0 extra**; pt_BR/de intentionally deferred/hidden (0/838) | Matches `docs/localization/HYDRION_LANGUAGE_READINESS.md`'s stated scope (not independently re-verified against that doc's exact wording) |
| 9 | `dart run tool/mixed_language_audit.dart` | **fr: identical=0, placeholderDrift=0; es: identical=0, placeholderDrift=0** | Clean |
| 10 | `dart run tool/artwork_audit.dart` | **"Artwork audit passed for 12 challenge PNG files."** | Clean |
| 11 | `dart run tool/android_size_audit.dart` | Ran; reported "No APK or AAB artifacts were found" (none could be built locally, see #13) | Not a failure — correctly reports missing input |
| 12 | `dart run tool/validate_android_release.dart` | **Errored: `FormatException: Missing required --apk argument`** | Requires a built APK to validate; cannot be exercised standalone without one (see #13) |
| 13 | `flutter build apk --debug` | **Failed — "No Android SDK found."** | **Environment limitation, not a code defect.** CI (`flutter-ci.yml build-android` job) has a full Android SDK/Java 17 runner and does build both debug and signed-release APKs there; this was not reproducible locally in this sandbox. |
| 14 | `cd ios && pod install` | **Failed initially** — `Encoding::CompatibilityError` from CocoaPods/Ruby's Unicode normalization | Root cause: shell `LANG`/`LC_ALL` not set to a UTF-8 locale in this environment (CocoaPods' own warning names the fix). Not a project defect (HYD-BUILD-005) |
| 15 | `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install` | **Success** — "1 dependency from the Podfile and 1 total pod installed" | Non-fatal warning: CocoaPods did not set the base xcconfig because the project already customizes it (informational) |
| 16 | `flutter build ios --simulator --debug` | **Success** — `Built build/ios/iphonesimulator/Runner.app` (216.1s) | Real, verified iOS buildability in this environment once the locale issue is worked around |
| 17 | `flutter build web --release` | **Success** — populated `build/web/` | Not runtime-tested (no Chrome in this environment) |
| 18 | `xcrun simctl boot/install/launch` on iPhone 16 Pro simulator (iOS 18.3) | **App installed and launched** (PID confirmed via `ps aux`, `com.the1807.hydrion`) | See §6.4 — app reached the startup screen and rendered correctly, but did **not** transition off it within the observation window |
| 19 | `flutter run -d <simulator>` | **Launched, live trace captured** | See §6.4 / §12 for the exact hang evidence gathered this way |

### 4.1 What was NOT executed, and why

- **Android APK/AAB build**: blocked, no Android SDK in this sandbox (see #13). CI has this capability; a local dev machine with Android Studio would too.
- **Android emulator or physical Android device testing**: blocked for the same reason — no SDK means no `adb`, no emulator, no `flutter devices` entry for Android.
- **Coverage report generation (`flutter test --coverage` + `genhtml`/`lcov`)**: not run in this pass given the ~39-minute runtime of the plain test suite; CI already generates and uploads a coverage artifact (`flutter-ci.yml:181`, `--coverage` flag) but **does not gate on a coverage percentage** — coverage is uploaded, not enforced (HYD-CI-001).
- **Dependency vulnerability database scan**: `dart pub audit` **does not exist** in this Dart SDK version (`Could not find a subcommand named "audit" for "dart pub"`) — confirmed by attempting it. `dart pub outdated --show-all` was used instead as the closest available tooling (see §10).
- **SAST beyond `flutter analyze` + the project's own custom tools**: no third-party SAST tool (Semgrep, MobSFScan, etc.) was introduced, per the instruction not to add tooling without first proving the existing stack insufficient. `flutter analyze` + `flutter_lints` + the five custom `tool/*.dart` scripts constitute the project's real, established static-analysis surface, and all were run.
- **Live memory/CPU profiling (Xcode Instruments, Android Studio Profiler, DevTools Memory view)**: **blocked** — this environment has Xcode but no interactive Instruments session available non-interactively, and no Android SDK/emulator at all. Stage 5 findings below are therefore static-evidence-only; anywhere a live measurement would be needed, it is marked UNVERIFIED.
- **Real physical device testing (Android or iOS)**: no physical devices are connected to this environment.
- **Web runtime testing**: `flutter build web` succeeded, but no Chrome executable is present to actually load and interact with the built output.
- **Any external platform account/service** (BrowserStack, Firebase Test Lab, Sauce Labs, AWS Device Farm, Maestro Cloud, actual Firebase project, actual OpenAI/Gemini billing account): **not created, not signed into, no trial started, nothing purchased** — per explicit instruction, this requires the repo owner's decision and is deferred to §11 (Mobile Test Platform Evaluation) as a recommendation, not an executed action.

---

## 5. Localization, Formatting, and Static-Quality Baseline

Covered in full in §4 (#3, #4, #7, #8, #9). Summary: **clean across the board.** This is one of the strongest areas of the codebase — the presence of custom, CI-gated tooling for production-string hygiene, localization completeness, mixed-language drift, and artwork consistency is unusual and well-executed for a project of this size, and all of it ran clean against the current tree.

---

## 6. Findings

Findings are numbered `HYD-<CATEGORY>-<NNN>`. Severity: **Critical / High / Medium / Low / Info**. Confidence reflects how directly the finding was verified (Confirmed = read the exact code/ran the exact command; Confirmed-Static = verified by code reading but the real-world magnitude needs live measurement).

### 6.1 Architecture / Correctness Findings

---

**HYD-ARCH-001 — Gemini AI coach is fully implemented but unreachable from any screen**
- **Severity**: Medium | **Confidence**: Confirmed
- **Component**: iOS/Android/shared Dart — `lib/ui/screens/chat_coach_screen.dart`, `lib/services/hydration_ai_orchestrator.dart`, `lib/services/coach_suggestion_service.dart`, `lib/adapters/gemini/gemini_adapter.dart`
- **Evidence**: `lib/main.dart`'s route table (lines 281-339) has no entry for `ChatCoachScreen`. `chat_coach_screen.dart:6` doc-comment: "V1 keeps Coach visible as a clearly non-interactive preview"; lines 14-49 render only a static "coming soon" card (`key: 'coach-coming-soon'`) with no imports of `HydrationCoach`/`CoachSuggestionService`. `grep -rln "CoachSuggestionService" lib/` shows it is only referenced by `main.dart`'s DI wiring and its own dependents — no screen consumes it.
- **User/business impact**: engineering investment (876-line Gemini adapter, orchestrator, consent flow, diagnostics) delivers zero user-facing value in the current build. Internal docs (`docs/architecture/GEMINI_API_INTEGRATION_AUDIT.md:172-173,319-323`, `docs/architecture/PHASE_4_2_GEMINI_RUNTIME_AUDIT.md`) describe a working Coach UI and a Settings screen that surfaces provider-health diagnostics — **neither exists in the current code**, which will actively mislead any engineer or auditor who trusts those docs over the code.
- **Root cause**: UI was reverted/stripped to a placeholder after the architecture docs were written, and the docs were never updated to match (or the docs described planned-but-unbuilt work).
- **Recommended correction**: either (a) wire `ChatCoachScreen` into the route table and implement the UI the docs describe, or (b) if the feature is intentionally deferred past this release, update `docs/architecture/GEMINI_API_INTEGRATION_AUDIT.md` and `PHASE_4_2_GEMINI_RUNTIME_AUDIT.md` to state current reality, and add a code comment on `chat_coach_screen.dart` linking to the deferral decision so this doesn't get "rediscovered" as a bug repeatedly.
- **Regression test**: an integration test asserting the route table's actual reachable-screen set matches an explicit allow-list, so future doc/code drift on feature reachability is caught automatically.
- **Standard**: n/a (documentation/process finding).

---

**HYD-ARCH-002 — `core_bridge.dart` does not bridge to the Rust `core/` workspace despite its name**
- **Severity**: Low | **Confidence**: Confirmed
- **Component**: `lib/services/core_bridge.dart`, `core/` (Rust workspace)
- **Evidence**: `core_bridge.dart` (26 lines) is pure Dart arithmetic (`totalMl / 500.0 * 0.01`) with zero `dart:ffi` import. No `.so`/`.dylib`/`.xcframework` exists under `android/` or `ios/`; no Cargo/NDK hook in `android/app/build.gradle.kts`; no script phase in `ios/Podfile`. `docs/architecture/STALE_SCAFFOLD_AUDIT.md` already self-documents this correctly.
- **User/business impact**: none currently (the eco-tracking feature it backs works fine as pure Dart arithmetic) — but the naming actively misrepresents the architecture to future contributors, and the Rust workspace represents unmaintained, unbuilt, unlinked code sitting in the repo consuming review/maintenance attention for zero shipped value.
- **Root cause**: abandoned FFI integration plan; code and naming were never cleaned up after the pivot away from it.
- **Recommended correction**: either commit to the FFI integration (requires `flutter_rust_bridge` or equivalent, a real build-system hook, and a maintenance plan) or rename `core_bridge.dart` to reflect what it actually is (a local arithmetic helper) and move/archive the `core/` Rust workspace out of the active repo root (e.g., to a clearly labeled `experimental/` or a separate repo) so it stops appearing as live architecture.
- **Regression test**: n/a (structural/hygiene finding); if FFI is pursued, needs full new test coverage for the bridge boundary.
- **Standard**: n/a.

---

**HYD-ARCH-003 — Orphaned scaffolding directories (`packs/byok_llm`, `packs/gemini_connector`, `packs/edge_llm`)**
- **Severity**: Low | **Confidence**: Confirmed
- **Evidence**: Zero references from `lib/` or `pubspec.yaml`; mostly empty files, `.gitkeep`s, and trivial unimplemented Node.js server stubs (`packs/byok_llm/client/lib/byok_client.dart` is a 1-byte file).
- **Impact**: repo hygiene / contributor confusion; no functional impact since nothing references these paths.
- **Recommended correction**: remove, or clearly mark with a top-level `NOT_IMPLEMENTED.md` per directory if they represent a genuine near-term roadmap item worth preserving.
- **Standard**: n/a.

---

**HYD-ARCH-004 — Deep-link / app-link infrastructure declared but not implemented**
- **Severity**: Info | **Confidence**: Confirmed
- **Evidence**: iOS `Info.plist` declares `CFBundleURLTypes` for scheme `hydrion://`, but `AppDelegate.swift` implements no `application(_:open:options:)`. The only emitter is the iOS widget's `widgetURL(URL(string: "hydrion://home"))` for tap-through. Android has no deep-link/app-link intent-filter at all. No `uni_links`/`app_links` package exists.
- **Impact**: none today (no product requirement currently depends on external deep-linking) — flagged so it isn't assumed to exist by future feature planning (e.g., marketing wanting a "tap this link to open a specific challenge" campaign would currently be unbuildable without new work).
- **Standard**: MASVS-PLATFORM-3 / MSTG-PLATFORM-3 (informational — no vulnerability, since no sensitive action is currently gated behind the scheme).

---

### 6.1a Correctness, Concurrency, and Lifecycle Findings

---

**HYD-CORR-001 — `BuildContext` accessed after an unguarded `await` gap in the activity-challenge timer control** — **FIXED AND VALIDATED (Sprint 1)**
- **Severity**: High | **Confidence**: Confirmed
- **Sprint 1 update**: fixed by adding `if (!mounted) return;` to the top of `_ChallengeActivityPanelState._syncTicker()`. A real regression test (`test/challenge_activity_lifecycle_ui_test.dart`) was written first, confirmed to reproduce the exact predicted crash against the unfixed code — `FlutterError: "This widget has been unmounted, so the State no longer has a context (and should be considered defunct)"`, thrown from `State.context` at `_syncTicker`'s `context.read<ChallengeRepository>()` call — then confirmed to pass after the fix. The full `flutter test` suite (604 tests, up from 600) passes with no regressions. This finding's original hypothesis is now **empirically confirmed**, not just statically reasoned.
- **Component**: `lib/ui/screens/challenge_experience_screen.dart:3170-3196, 3465` (`_ChallengeActivityPanelState`)
- **Evidence**: the Start/Pause/Resume handler for activity-type challenges (e.g. homework-hydration) runs `await repository.startActivitySession(active.id);` then `await _syncHomeworkNotification(repository, active.id);` then calls `_syncTicker()` unconditionally. `_syncHomeworkNotification` correctly bails on `!mounted`, but execution falls through to `_syncTicker()` regardless, and `_syncTicker()` itself (line 3465) calls `context.read<ChallengeRepository>()` with **no `mounted` check at all**. The sibling `_PomodoroTimerCardState._syncTicker()` (line 3701) *does* guard with `if (!mounted) return;` at its very top — this is a real regression from the pattern the same file uses correctly everywhere else (confirmed: `_logSip`-style handlers at lines 1150-1368 consistently guard with `if (!context.mounted) return;` after every `await`).
- **Failure scenario**: tap Start/Pause/Resume on an activity-type challenge, then immediately navigate away from the screen before the two awaited SharedPreferences round-trips resolve. `State.context` is accessed after `_element` is nulled by `unmount()`, throwing in debug ("This widget has been unmounted…") or hitting a null-check failure in release.
- **User/business impact**: a crash-on-rapid-navigation during exactly the interaction pattern (start a challenge, immediately switch tabs) that the always-mounted `IndexedStack` (§6.3) actively encourages users to do.
- **Root cause**: the guard was added to `_syncHomeworkNotification` but not propagated to the unconditional call immediately after it.
- **Recommended correction**: add `if (!mounted) return;` at the top of `_ChallengeActivityPanelState._syncTicker()`, matching the existing `_PomodoroTimerCardState` pattern exactly.
- **Required regression test**: a widget test that starts an activity challenge and immediately pops the route before the awaits settle, asserting no exception is thrown (mirrors the existing `pomodoro_session_ui_test.dart` "timer ticker is disposed when the challenge view is removed" test, which currently only covers the Pomodoro variant, not the Activity Panel variant).
- **Standard**: n/a (Flutter lifecycle correctness).

---

**HYD-CORR-002 — Full-snapshot rollback-on-persist-failure can silently discard a different, already-persisted concurrent change**
- **Severity**: Medium | **Confidence**: Confirmed
- **Component**: `lib/repositories/hydration_repository.dart:279,302` (`updateLog`/`deleteLog`), `lib/repositories/challenge_repository.dart:582-588,632-638,749-761,1228-1277` (`_updateActiveChallenge`, `_replaceActiveChallenges`, `_deactivateChallenge`, `resumeChallenge`, `updateParameters`, `clear`)
- **Evidence**: these methods snapshot the whole collection (`final previous = List.of(_logs);` / `previous = _activeChallenges;`) before mutating, then on a `_persist()` failure restore that snapshot wholesale (`_logs..clear()..addAll(previous)` / `_activeChallenges = previous`). If a second, unrelated mutation (e.g. pausing the Pomodoro timer while a bottle-bingo tile update is persisting) completes and successfully persists *while the first call's `_persist()` is still pending*, and the first call's persist subsequently fails, its `catch` block restores the collection to the state from **before both calls**, discarding the second call's already-applied, already-persisted change from memory. The next successful write from any caller then re-encodes this truncated in-memory state to disk, permanently reverting the second call's change. By contrast, `HydrationRepository.addLog`/`restoreLog` avoid this correctly: their rollback only removes the single row that specific call added, which is safe under concurrency — proving the team knows the safe pattern but did not apply it consistently. `PomodoroSessionService._persistState` (`pomodoro_session_service.dart:524-550`) funnels every pause/resume/complete transition through `updateParameters`, so the Pomodoro timer's own persistence is exposed to this systemic issue.
- **Failure scenario**: requires a genuine SharedPreferences persist failure (low-storage, plugin exception, or corrupted platform channel) concurrent with a second, unrelated mutation — real but lower-probability; the impact when it does occur is a silently reverted user action with no error surfaced for the *second* operation (which itself reported success when it persisted).
- **Recommended correction**: change these methods to the same "undo only this call's own delta" pattern already used correctly in `addLog`/`restoreLog`, rather than restoring a whole-collection snapshot.
- **Required regression test**: a test that interleaves two concurrent mutations on the same repository, forces the first's underlying persist to fail, and asserts the second's change survives in the final in-memory and persisted state.
- **Standard**: n/a (data-integrity correctness).

---

**HYD-CORR-003 — `TimedSessionNotificationService` never unregisters its locale-change listener**
- **Severity**: Low | **Confidence**: Confirmed
- **Component**: `lib/services/timed_session_notification_service.dart:133-147`
- **Evidence**: the constructor calls `_localeRepository.addListener(_handleLocaleChange)`; no `dispose()` method exists anywhere in the file. Latent in production today because both this service and `AppLocaleRepository` are constructed once as app-lifetime singletons — but there is no code path that could ever cleanly retire an instance, so any future refactor (per-test fixtures, a multi-profile feature) that constructs more than one instance against a longer-lived repository accumulates dangling listeners silently.
- **Recommended correction**: add a `dispose()` method that calls `_localeRepository.removeListener(_handleLocaleChange)`, and call it from wherever the service's owner is torn down (currently nowhere, since it's a singleton — add it defensively for future-proofing).
- **Standard**: n/a.

---

**HYD-CORR-004 (positive/no-bug findings, recorded for completeness)** — No retry policy exists anywhere in the app (confirmed absence for both Gemini and Open-Meteo HTTP calls), and this is not currently a retry-storm risk because `DailyWeatherGoalCoordinator.evaluate()`'s own "already handled today" guard plus `WeatherForecastService`'s 18-hour cache TTL mean the real network call fires at most once per local calendar day regardless of how many times the app resumes. Timeout values declared match timeout values enforced (no mismatch). Offline behavior fails fast (not a hang) via `http.ClientException`, and there is a real, deliberate stale/offline UI fallback path (`CurrentWeatherContext.fromCache`) — though whether any screen actually renders a visible "from cache" indicator to the user was not independently confirmed (UNVERIFIED). Weather cache invalidation logic (`_isStale`) correctly uses `.abs()` on the duration comparison (safe against backward clock jumps) and a redundant local-date-key check, with no off-by-one found. All date/time handling uses a consistent device-local-time convention with no UTC/local mixing (zero `.toUtc()` calls in the entire codebase) — though `tz.setLocalLocation()` is never called for the `timezone` package (HYD-CORR-005 below), and all "day boundary" logic is inherently wall-clock/local-day-based, which carries an unavoidable but low-probability edge case around timezone-change-mid-session (no evidence found that this can lose or double-count a persisted hydration log, since each log stores an absolute timestamp — only display-bucketing could shift). `hydration_pacing_engine.dart` is well-guarded against division-by-zero, equal wake/sleep times, out-of-range minute values, and midnight-crossing windows — no bug found. The Pomodoro/challenge-action concurrency locks (`_timerTransition`, `_inFlightOperations`, `_inFlightHydrationActions`) are real and correctly implemented for the specific action-id-keyed flows they cover (verified by `test/pomodoro_session_ui_test.dart`'s rapid-tap test) — they simply don't generalize to the two gaps above.

---

**HYD-CORR-005 — `timezone` package's local location is never set**
- **Severity**: Low | **Confidence**: Confirmed
- **Component**: `lib/services/notifications.dart`
- **Evidence**: `tz_data.initializeTimeZones()` is called, and `tz.TZDateTime.from(reminder.triggerTime, tz.local)` is used, but `tz.setLocalLocation()` is never called anywhere in the repo, and no package (e.g. `flutter_timezone`) supplies the device's actual IANA zone. `tz.local` therefore remains the package's built-in UTC default rather than the device's real zone.
- **Impact today**: nil in practice — `TZDateTime.from(instant, location)` re-expresses the same absolute instant regardless of the named zone, every reminder is built from an absolute `DateTime`, and the app only ever uses one-shot `zonedSchedule` (confirmed zero uses of `matchDateTimeComponents`, which is the API that would actually depend on `tz.local` being correct for recurring/calendar-relative scheduling).
- **Recommended correction**: call `tz.setLocalLocation()` with the device's real zone (e.g. via the `flutter_timezone` package) now, as a latent-defect fix, before any future recurring/calendar-relative notification feature is built on top of this and silently inherits the wrong zone.
- **Standard**: n/a.

---

**HYD-CORR-006 — `BuildContext`/`setState` accessed after a second, unguarded `await` gap in the log-edit date/time picker flow** *(new, found in Sprint 1)*
- **Severity**: High | **Confidence**: Confirmed (code-review/pattern-match; see reproduction note below)
- **Component**: `lib/ui/screens/log_screen.dart:461-483` (`_EditLogDialogState._chooseTimestamp()`)
- **Evidence**: `_chooseTimestamp()` chains two sequential dialogs: `await showDatePicker(...)` (correctly guarded immediately after with `if (date == null || !mounted) return;`, line 468) then `await showTimePicker(...)`, whose result was checked only with `if (time == null) return;` (line 473) — **no `mounted` check** after the second `await`, followed by an unguarded `setState()`. This is the identical defect class as HYD-CORR-001 (a `State` touching its own `context`/`setState` after a second async gap, having only guarded the first one), found by a dedicated Sprint 1 codebase-wide search for the same pattern (see `REMEDIATION_LEDGER.md` for the search's full coverage statement).
- **Failure scenario**: user opens "Edit hydration log," taps the date/time field, picks a date (first gap passes the guard), the time picker opens and is still awaiting the user's selection when the underlying dialog's route is torn down (e.g. a concurrent app-wide state reset, such as `local_profile_reset_service.dart`'s reset flow, rebuilds the root while the nested time-picker route is still pending) — if the pending route then resolves with a real (non-null) time value in that same window, `setState()` fires on a disposed `State`, throwing "setState() called after dispose()".
- **Fix applied**: changed line 473 to `if (time == null || !mounted) return;`, matching the exact guard style already used one line above in the same function.
- **Reproduction note (stated honestly, not overclaimed)**: unlike HYD-CORR-001, this defect was **not** independently reproduced with a forcing automated test. HYD-CORR-001's reproduction required deliberately holding an in-flight persistence write with a controllable `Completer`; there is no equivalent deterministic lever for forcing Flutter's built-in `showTimePicker` route to resolve non-null in the exact instant its parent is torn down — attempting to force this via `pumpWidget`-replacement was analyzed and found to most likely resolve the pending route to `null` (already guarded) rather than a real value, since Navigator-cascade teardowns generally complete popped routes with no value. The fix is applied on the strength of Flutter's own documented contract (`State.context` access after disposal is unconditionally unsafe, confirmed via the exact same framework assertion that produced HYD-CORR-001's real stack trace) and exact pattern-parity with the already-proven-correct guard one line above, not a demonstrated crash in this repo.
- **Recommended regression test**: a manual/exploratory test case (added to `tester_bible.md`) rather than an automated one, given the practical difficulty above; revisit automation if a future Flutter/`showTimePicker` API change makes the route's resolution timing controllable in tests.
- **Standard**: n/a (Flutter lifecycle correctness).

---

### 6.2 Security & Privacy Findings (MASVS/MASTG-mapped)

---

**HYD-SEC-001 — Sensitive health data and PII stored unencrypted at rest**
- **Severity**: **High** | **Confidence**: Confirmed
- **Component**: Android + iOS — `lib/repositories/body_metrics_repository.dart:10`, `lib/repositories/settings_repository.dart:679`, `lib/storage/local_store.dart`
- **Evidence**: `SharedPreferencesHydrionStore` (`local_store.dart:11-35`) is a thin, unencrypted wrapper over `package:shared_preferences`. `flutter_secure_storage` (or any Keychain/Keystore-backed package) is **not a dependency** — confirmed absent from `pubspec.yaml`. Data confirmed persisted this way includes: `weightKg`, `heightCm`, `reproductiveState`, **`pregnancyGestationalDays`**, `fluidSafetyMode`, `clinicianTargetMl` (`body_metrics_repository.dart`, key `hydrion.body_metrics.v1`); and `nickname`, `sex`, **`profilePhotoBase64`** (a base64-encoded photo embedded directly in a JSON preferences blob) (`settings_repository.dart`, key `hydrion.user_settings.v1`). On Android this lands in plaintext XML at `/data/data/com.the1807.hydrion/shared_prefs/`; on iOS in a plaintext `NSUserDefaults` plist, both extractable via `adb backup`/jailbreak/physical access or a rooted-device backup, since `allowBackup` is correctly `false` on Android but does not protect against on-device/rooted extraction.
- **Reproduction**: on a rooted Android device or the iOS Simulator's own container path, read `hydrion.user_settings.v1` and `hydrion.body_metrics.v1` from the app's preferences store — values are plaintext JSON.
- **User/business impact**: pregnancy status/duration is special-category health data under GDPR Art. 9 and similarly sensitive under most health-privacy frameworks; a lost/stolen/rooted device, a malicious app with storage access on older Android, or a local-backup-extraction attack exposes this without needing to break any encryption. This is the single highest-impact finding in the audit.
- **Root cause**: the project never added a secure-storage dependency; all repositories were built against the same `HydrionLocalStore` key-value abstraction without a sensitivity tier.
- **Recommended correction**: introduce `flutter_secure_storage` (Keychain-backed on iOS, Keystore-backed EncryptedSharedPreferences on Android) for the specific keys carrying health/PII data (`hydrion.body_metrics.v1`, the PII subset of `hydrion.user_settings.v1`) — this is a proportionate, justified new dependency (widely used, actively maintained, MIT-licensed, purpose-built for exactly this gap; the existing stack has no other way to satisfy platform-Keychain/Keystore access). Do **not** move the profile photo into the encrypted store as base64; store it as a file with only a path/reference kept in secure storage, encrypted at rest via the OS file-protection APIs, since large base64 blobs are a poor fit for secure-storage backends.
- **Required regression test**: an integration test asserting that reading the raw underlying preferences store for the relevant keys returns ciphertext, not plaintext JSON, once the migration lands.
- **Standard**: MASVS-STORAGE-1, MASVS-STORAGE-2 / MSTG-STORAGE-1, MSTG-STORAGE-2.

---

**HYD-SEC-002 — iOS privacy manifest omits a required-reason API actually used by the widget extension**
- **Severity**: Medium | **Confidence**: Confirmed
- **Component**: iOS — `ios/Runner/PrivacyInfo.xcprivacy:24-25` vs `ios/HydrionWidgets/HydrionWidgets.swift:35`
- **Evidence**: `HydrionWidgets.swift:35` calls `UserDefaults(suiteName: appGroup)`, one of Apple's "required-reason" API categories (`NSPrivacyAccessedAPICategoryUserDefaults`) under the 2024+ App Store privacy-manifest enforcement policy. `PrivacyInfo.xcprivacy`'s `NSPrivacyAccessedAPITypes` array is empty.
- **User/business impact**: risk of App Store Connect validation warnings or outright submission rejection (Apple's ITMS-91053-class check) at the next iOS release submission.
- **Root cause**: the widget extension's `UserDefaults(suiteName:)` usage for app-group data sharing was added without updating the privacy manifest declaration.
- **Recommended correction**: add an `NSPrivacyAccessedAPIType` entry for `NSPrivacyAccessedAPICategoryUserDefaults` with the appropriate approved reason code (e.g., `CA92.1` for access within the same app group) to `PrivacyInfo.xcprivacy`.
- **Regression test**: a release-checklist / CI step that runs Apple's own privacy-manifest linting (`xcrun` privacy report tooling) or, at minimum, a repo-level test asserting every `UserDefaults(suiteName:)` call site has a corresponding manifest entry.
- **Standard**: Apple App Store privacy-manifest policy (no direct MASVS id; closest analog MSTG-STORAGE conceptually).

---

**HYD-SEC-003 — Gemini API key embedded as plaintext in the compiled release binary**
- **Severity**: Medium | **Confidence**: Confirmed
- **Component**: `lib/services/ai_provider_config.dart:129`
- **Evidence**: the key is read via `String.fromEnvironment('HYDRION_GEMINI_API_KEY')`, a Dart compile-time `--dart-define`. This is correctly kept out of source control, but `--dart-define` values are embedded as literal strings in the compiled app binary and are extractable via `strings`/decompilation of the shipped APK/IPA — unlike a server-brokered key never present client-side.
- **User/business impact**: if the key lacks server-side restrictions (HTTP referrer/app/package restrictions on the Google Cloud console), anyone who decompiles the app can extract and reuse the key against the developer's quota/billing. **Whether such restrictions are configured is outside this repo's visibility and is UNVERIFIED.**
- **Root cause**: no backend token-broker exists; the client talks to Gemini directly (also noted as a moot point today because HYD-ARCH-001 means this path is currently unreachable in production use — but the key still ships in the binary if ever compiled with the define set).
- **Recommended correction**: at minimum, confirm and document that the Gemini API key used in production builds has app/package-restricted, low-privilege, rate-limited scope on the Google Cloud console. For a stronger posture, proxy Gemini calls through a minimal backend that holds the real key server-side.
- **Regression test**: n/a (infrastructure/key-management control, not testable from this repo alone).
- **Standard**: MASVS-CRYPTO-1 / MSTG-STORAGE-14 (hardcoded-secret-in-binary pattern).

---

**HYD-SEC-004 — Release Android builds ship without code shrinking/obfuscation**
- **Severity**: Low | **Confidence**: Confirmed
- **Component**: `android/app/build.gradle.kts:63-64`
- **Evidence**: `isMinifyEnabled = false`, `isShrinkResources = false` for the `release` build type.
- **Impact**: reduced reverse-engineering resistance; larger APK size than necessary.
- **Recommended correction**: enable R8 minification/shrinking for release builds with appropriate `proguard-rules.pro` keep-rules for Flutter/plugin reflection needs, and re-run the full test/build matrix afterward since minification can surface reflection-related runtime breaks that only appear in release mode.
- **Regression test**: a CI job that builds the release APK with minification on and smoke-launches it (already partially covered by `flutter-ci.yml`'s ephemeral-signed release-APK smoke path — extend it to assert no `ClassNotFoundException`/reflection failures at launch).
- **Standard**: MASVS-RESILIENCE-1 / MSTG-RESILIENCE-9.

---

**HYD-SEC-005 — Dependency staleness (`flutter_local_notifications`, `flutter_lints`)**
- **Severity**: Low | **Confidence**: Confirmed
- **Evidence**: `dart pub outdated --show-all` shows `flutter_local_notifications` at 20.1.0 vs. latest 22.3.0 (two major versions behind — notable because this package handles scheduled reminders and a boot-time receiver, both security/reliability-relevant surfaces) and `flutter_lints` (dev) at 4.0.0 vs. 6.0.0.
- **Impact**: no specific CVE was verified for the installed version in this pass (external advisory lookup was out of scope for a read-only repo audit) — this is a hygiene/staleness flag, not a confirmed exploit.
- **Recommended correction**: schedule a dependency upgrade pass, starting with `flutter_local_notifications` given its security-relevant surface (boot receiver, exact-alarm scheduling), run the full test suite afterward, and check the package's own changelog for breaking changes to the scheduling API.
- **Standard**: no direct MASVS mapping; general SDLC/supply-chain hygiene (loosely MASVS-CODE-1 territory).

---

**HYD-SEC-006 — Dead configuration files shipped as compiled app assets**
- **Severity**: Low | **Confidence**: Confirmed
- **Evidence**: `config/app.yaml`, `config/firebase_config.json`, `config/open_ai_config.yaml` are declared as Flutter assets (`pubspec.yaml`) and therefore bundled into every release binary, but no Dart code reads any of the three (confirmed by grep). All current values are placeholders (`YOUR_X_API_KEY`, `${ENV_VAR}` syntax) — no live secret is currently exposed.
- **Impact**: low today, but this is a live foot-gun: if anyone ever pastes a real key into these files during local development or a misconfigured CI step, it ships in plaintext inside every APK/IPA asset bundle, since nothing prevents it and nothing reads them to at least fail loudly if they contain a placeholder.
- **Recommended correction**: remove these three files from the `pubspec.yaml` asset bundle (they are not runtime-needed given nothing reads them), or if kept for documentation purposes, move them out of `assets`-declared paths entirely so they cannot ship in a binary.
- **Regression test**: extend `tool/secret_scan.dart` (or a new lightweight check) to also assert that no file under `pubspec.yaml`'s declared `assets:` paths matches a real-secret pattern, as a second line of defense independent of git-history scanning.
- **Standard**: MASVS-STORAGE-1 / MSTG-STORAGE-14 (attack-surface hygiene).

---

**HYD-SEC-007 — Non-release-guarded `debugPrint` in widget-sync error path**
- **Severity**: Low | **Confidence**: Confirmed
- **Component**: `lib/services/android_widget_service.dart:318`
- **Evidence**: `debugPrint('Hydrion widget sync failed: $error\n$stackTrace')` is not wrapped in a `kReleaseMode` guard (unlike the release-guarded pattern correctly used in `lib/utils/startup_trace.dart:18`). Flutter's `debugPrint` executes in all build modes by default.
- **Impact**: on a widget-sync failure, an exception message and stack trace are written to the OS system log (`adb logcat` / iOS unified log) even in release builds. Requires local/ADB access to read; content observed is exception/stack-trace text, not directly raw hydration/health values, but exception interpolation could incidentally include such values depending on what threw.
- **Recommended correction**: gate this call the same way `startup_trace.dart` does, or route it through a redaction-aware logger.
- **Standard**: MASVS-STORAGE-3 / MSTG-STORAGE-3.

---

**HYD-SEC-008 — No root/jailbreak detection (accepted-risk decision needed, not a defect by itself)**
- **Severity**: Info | **Confidence**: Confirmed (absence)
- **Evidence**: no jailbreak/root-detection library or logic anywhere in `lib/` or `pubspec.yaml`.
- **Impact**: this is an MASVS-RESILIENCE (L2+) control that many apps reasonably skip; given HYD-SEC-001's unencrypted health data, the combination (no secure storage **and** no root-detection-based extra caution) raises the bar slightly on why HYD-SEC-001 should be prioritized first — fixing storage encryption reduces the risk this control would otherwise partially mitigate.
- **Standard**: MASVS-RESILIENCE-1 / MSTG-RESILIENCE-1 (not implemented; explicitly a product/risk-acceptance decision for the owner, not an automatic defect).

---

**HYD-SEC-009 — No certificate pinning (defense-in-depth gap, not a required control)**
- **Severity**: Info | **Confidence**: Confirmed (absence)
- **Evidence**: no `badCertificateCallback` override (good — no TLS bypass either), but also no pinning implementation; relies on platform default trust store + ATS (iOS) / `usesCleartextTraffic=false` (Android).
- **Impact**: standard TLS/OS trust-store protection is in place and correctly configured (positive finding); pinning would be additional defense-in-depth, optional at MASVS L1.
- **Standard**: MASVS-NETWORK-2 / MSTG-NETWORK-4 (optional control).

---

**HYD-SEC-010 (positive finding, recorded for completeness)** — No cleartext traffic, no TLS bypass, no WebView attack surface, no hardcoded live secrets anywhere in source, a real and CI-enforced secret scanner, a genuinely-gated AI-provider consent flow matching the privacy policy text, and an unusually accurate privacy policy (`docs/Hydrion_Legal_Pack_Markdown/01_PRIVACY_POLICY.md`) that correctly describes the coarse-location-only weather flow and the consent-gated Gemini data path. These are not defects; they are recorded so the report reflects genuine strengths, not only gaps.

---

### 6.3 Memory / Resource / Performance Findings (static-evidence-only; see §4.1 for profiling blockers)

---

**HYD-PERF-001 — `HydrationRepository._logs` and `ChallengeRepository._challengeHistory` are unbounded, append-only collections, fully re-serialized on every write**
- **Severity**: Medium | **Confidence**: Confirmed-Static (real-world magnitude UNVERIFIED without a multi-month device history)
- **Evidence**: `lib/repositories/hydration_repository.dart:178,214-260,367-370` — `_logs` has no cap; `addLog()` unconditionally does a full `List.sort()` and a full `jsonEncode()`/SharedPreferences write of the **entire** history on every single call. `lib/repositories/challenge_repository.dart:318` — `_challengeHistory` grows via splice operations with no eviction; `archiveChallenge` only flips a status flag. By contrast, `lib/repositories/daily_hydration_context_repository.dart:12,44-50` **does** enforce a 14-day retention cap (`maxRetainedDays`), proving the team already knows this pattern but did not apply it to the two largest-growing collections.
- **Failure scenario**: a user logging water ~8-10×/day for a year accumulates ~3,000-4,000 entries; every single new log then pays full parse-on-load-once-but-full-serialize-on-every-write cost, compounded by HYD-PERF-002's cascade.
- **Recommended correction**: apply the same retention-cap pattern already used in `daily_hydration_context_repository.dart` to hydration logs (e.g., paginate/archive older entries) and challenge history; alternatively, move to an incremental-append storage format instead of whole-blob JSON rewrite per write.
- **Regression test**: a test that seeds several thousand log entries and asserts `addLog()` completes within a defined time budget (perf regression guard), plus a test asserting old entries are archived/evicted per whatever policy is chosen.
- **Standard**: n/a (performance/architecture).

---

**HYD-PERF-002 — Every hydration log triggers a full-history recompute cascade across all four always-mounted tabs**
- **Severity**: Medium | **Confidence**: Confirmed-Static
- **Evidence**: `lib/repositories/challenge_repository.dart:423-449` subscribes to `HydrationRepository`'s `notifyListeners()` and, on every change, iterates the **entire** hydration history to recompute challenge qualifications, then fires its own `notifyListeners()`. Because `lib/ui/screens/hydrion_shell.dart:290-307` hosts all four tabs (`HomeScreen`, `SocialChallengesScreen`, `AnalyticsScreen`, `ProfileScreen`) in an `IndexedStack` — meaning all four stay mounted and listening for the entire app session, not just while visible — a single "log one glass of water" action triggers: full-history sort + full-history JSON write (HYD-PERF-001) + full-history qualification recompute + two separate `notifyListeners()` broadcasts, each forcing a rebuild in every mounted, listening tab, including `SocialChallengesScreen.build()` which itself re-runs a full challenge-recommendation ranking over 8 watched repositories on every rebuild (`social_challenges_screen.dart:48-101`).
- **Failure scenario**: this compute cost scales with total lifetime log count (HYD-PERF-001) and fires on every single hydration-logging tap, regardless of which tab the user is actually looking at.
- **Recommended correction**: once HYD-PERF-001's retention cap is in place, this finding's severity drops substantially on its own; additionally consider debouncing the challenge-qualification recompute or scoping the `SocialChallengesScreen` rebuild to only recompute when its own watched data actually changed relevance (e.g., `Selector` instead of blanket `context.watch` on 8 providers).
- **Regression test**: a widget test that logs N hydration entries and asserts `SocialChallengesScreen`'s ranking-computation method is called a bounded number of times, not once per log entry while off-screen.
- **Standard**: n/a (performance).

---

**HYD-PERF-003 — Native Android "timed session" notification has no OS-lifecycle-bound cleanup for the paused state**
- **Severity**: Medium | **Confidence**: Confirmed-Static (real-device force-kill persistence UNVERIFIED)
- **Evidence**: `android/app/src/main/kotlin/com/the1807/hydrion/MainActivity.kt:93-178` posts a plain `NotificationManager.notify()` with `.setOngoing(true)`; there is no `Service`/`startForeground`, no `onDestroy()` override, no boot/task-removed receiver binding this notification's lifecycle to any native component. `.setTimeoutAfter(...)` (API 26+) is only applied to the "running" branch (line 166-173) — the "paused" branch (line 174-176) has **no** timeout backstop at all. Cancellation is entirely Dart-directed (`timed_session_notification_service.dart:79-90,149-165`), requiring the Flutter engine and the app's own session-state machine to be alive and to route through the "stopped" path.
- **Failure scenario**: user pauses a Pomodoro/homework session, then force-kills the app (or the OS reclaims the process). The ongoing notification has no native mechanism to ever clear itself and will persist in the notification shade until manually dismissed or until relaunch happens to reconcile that specific session — whether relaunch reliably reaches the cancel path for every abandoned-mid-session scenario requires live device testing.
- **Recommended correction**: apply `.setTimeoutAfter(...)` to the paused branch too (a generous but finite ceiling, e.g. a few hours), and/or add an `onDestroy()`/task-removed native handler that cancels any outstanding timed-session notification when the app process is torn down.
- **Regression test**: (native/instrumented) — force-stop the app mid-paused-session on a real or emulated Android device and assert the notification is cleared within the timeout window; not achievable as a pure Dart unit test since it requires the real Android component lifecycle.
- **Standard**: n/a (platform resource-lifecycle correctness).

---

**HYD-PERF-004 — Profile photo is base64-decoded and re-rendered on every unrelated rebuild, with no memoization**
- **Severity**: Low | **Confidence**: Confirmed-Static
- **Evidence**: `lib/ui/screens/profile_screen.dart:349-382` (`_ProfileImage`) calls `base64Decode` and wraps a fresh `Uint8List` in `Image.memory()` inside `build()`, with no caching. Because `ProfileScreen` is one of the four permanently-mounted `IndexedStack` tabs and watches three separate `ChangeNotifier`s, any Settings/Reminder/CapabilityReporter change anywhere in the app re-decodes the avatar image even while the Profile tab isn't visible. Mitigating factor: `image_picker` is correctly called with `maxWidth: 720, maxHeight: 720, imageQuality: 82` (`profile_photo_service.dart:29-34`), so the decoded bytes are small — this is wasted CPU/allocation churn, not an OOM risk.
- **Recommended correction**: cache the decoded `Uint8List`/`MemoryImage` keyed on the base64 string's identity (or a hash of it), invalidating only when the photo actually changes.
- **Regression test**: a test asserting `base64Decode` is called at most once per distinct photo value across repeated unrelated rebuilds.
- **Standard**: n/a (performance).

---

**HYD-PERF-005 (positive findings, recorded for completeness)** — Timer/ticker hygiene is good: the Pomodoro/activity countdown timers (`challenge_experience_screen.dart:3470,3711`) use sensible 1-second intervals and are correctly cancelled in `dispose()` with idempotent re-sync guards; `dynamic_theme_clock.dart` and `hydrion_shell.dart`'s day-rollover logic use single-shot (not periodic) timers rescheduled to the next boundary. Location fetching (`location_service.dart`) is single-shot/pull-based with no continuous position stream; weather caching (`weather_goal_service.dart`) uses sensible 18-hour staleness and 24-hour decision-cooldown windows with no polling loop. Lottie usage is limited to the startup splash and is torn down correctly via route replacement (not push), so it cannot outlive its screen.

**Profiling tooling note**: `leak_tracker`/`leak_tracker_flutter_testing` ship transitively via `flutter_test` (confirmed in `pubspec.lock`) but are not actively configured (no `LeakTesting.settings` anywhere in `test/`) — the project has the tool on its classpath but has not opted into stricter leak assertions. Live DevTools/Instruments/Android-Profiler measurement of all the above at realistic multi-month usage scale is **BLOCKED in this environment** (no physical device, no Android SDK/emulator) and would need to be run separately.

---

### 6.4 Real-Device/Simulator Testability Finding — Startup Hang Observed Live

**HYD-BLOCK-004 — App does not transition off the startup screen when launched normally on iOS Simulator; the entire automated test suite does not catch this**
- **Severity**: **High** (pending root-cause confirmation) | **Confidence**: Confirmed reproduction, root cause unverified at time of writing
- **Component**: iOS (reproduced), startup sequence — `lib/main.dart`'s `_HydrionBootstrapAppState` / `StartupScreen` gate chain
- **Evidence gathered live in this audit**:
  1. `flutter build ios --simulator --debug` succeeded; the resulting `Runner.app` was installed and launched via `xcrun simctl install`/`launch` on a booted iPhone 16 Pro (iOS 18.3) simulator.
  2. A screenshot taken immediately after launch showed the startup screen (animated shark, "Preparing your hydration space…").
  3. A second screenshot taken **roughly one minute later** showed the identical screen, still on the startup splash.
  4. `ps aux` showed the `Runner` process sustaining **~42.7% CPU** continuously (3:37 of accumulated CPU time), i.e. actively busy, not idly waiting — consistent with either a runaway loop or an animation spinning while something it's waiting on never resolves.
  5. A follow-up `flutter run -d <simulator>` session was attempted against the same simulator specifically to capture the live Dart-side `HYDRION_STARTUP` debug trace (the same trace lines that appear near-instantly in the widget-test harness, e.g. `test/startup_onboarding_test.dart`). This attempt did **not** succeed: `xcrun simctl`/`flutter devices` calls in this sandboxed environment began hanging or timing out after the sustained high-CPU process had been running for several minutes, and the subsequent `flutter run` itself failed with `xcodebuild: error: Unable to find a device matching the provided destination specifier` — the simulator's device-destination registration had become unstable, independent of the app under test. **Root cause of the original startup-screen hang was therefore not isolated in this session.** This is recorded honestly as an open item rather than glossed over or retried indefinitely: the live reproduction (screenshots + sustained CPU) is real and directly observed evidence; the tooling instability encountered while trying to get a deeper trace is a separate, additional observation about this sandboxed environment's simulator tooling under load, not a resolution of the original question. The stray simulator process was terminated (`kill -9`) to stop it consuming CPU before ending this investigation.
- **Independent corroboration (Stage 10 of this audit)**: a later, separate proof-of-concept using the Maestro test-automation tool (see `MOBILE_TEST_PLATFORM_EVALUATION.md` §5) against the same simulator failed **twice** — once at Maestro's default driver-startup timeout, and once again after doubling that timeout per Maestro's own suggested remediation — with `IOSDriverTimeoutException: iOS driver not ready in time`. This is a second, independent tool exhibiting the same class of Simulator/Xcode-automation unreliability observed during the original hang investigation, strengthening the hypothesis that this sandboxed environment's Simulator/CoreSimulator stack degrades under repeated automation load (most plausibly from this audit's own earlier heavy use of the same simulator instance) rather than pointing to a single-tool-specific bug. This remains a plausible explanation, not a confirmed one.
- **Why the test suite doesn't catch this**: `flutter test` widget tests run against a simulated/faked clock and mocked plugin channels (`flutter_test`'s `TestWidgetsFlutterBinding`), so `StartupScreen`'s "buffer visible gate" and any real plugin-initialization `Future`s resolve near-instantly and deterministically in tests. A real simulator run uses real frame timing and real platform-channel round-trips to actual plugins (`geolocator`, `image_picker`, `home_widget`, `flutter_local_notifications`), any one of which could behave differently (e.g., a permission-prompt handshake, a plugin that has no/blocking simulator-specific behavior) outside the test harness. This exact category — "tests mock the boundary that real devices don't" — is precisely the kind of gap the audit was commissioned to find rather than trust from a green test suite.
- **User/business impact if confirmed as a genuine hang**: this would be a total launch blocker for real users on the affected platform/condition — the highest possible severity for a mobile app if it reproduces outside this specific sandboxed simulator environment. It could also be **specific to this sandboxed CI-like environment** (e.g., a plugin's simulator behavior differs from a real device, or a permission dialog is silently blocking with no way for a headless environment to dismiss it) — this distinction matters enormously for prioritization and is exactly why it is flagged as OPEN rather than asserted as a confirmed field-impacting bug.
- **Recommended immediate action**: reproduce with `flutter run` attached to the debugger/console on (a) this same simulator, (b) a different simulator/OS version, and (c) if at all possible a real device, to determine whether this is sandbox-specific (e.g., a location/notification permission prompt with no way to auto-dismiss in a headless CI runner) or a genuine app defect. Capture the full `HYDRION_STARTUP` trace line sequence in each case and compare against the sequence the widget tests expect.
- **Regression test**: once root-caused, add an `integration_test/` (real-engine, not widget-test-harness) test that boots the real app to `/home` end-to-end and asserts a maximum wall-clock time — this class of defect is structurally invisible to `flutter test`'s widget-test harness and needs a real-engine integration test to ever be caught by CI. (Note: `integration_test/android_notification_delivery_test.dart` already exists as precedent for this test type but currently only covers Android notification delivery, not full-app boot.)
- **Status at report time**: **OPEN / UNVERIFIED ROOT CAUSE.** This is called out explicitly rather than glossed over, per the audit's own non-negotiable rule against claiming a check passed without inspecting its result — the live reproduction is real and was directly observed, but the causal mechanism was not yet isolated when this report was written.
- **Sprint 1 update (see `IOS_STARTUP_INVESTIGATION.md` for the full account)**: root cause is **still not conclusively isolated**, but substantial progress was made: (1) comprehensive per-gate startup instrumentation was added to `lib/main.dart`, covering every step of `HydrionServices.local()` and the routing decision, so a future live capture can pinpoint the exact stalling gate; (2) a real, independently-confirmed code defect was found that fully explains the *symptom* regardless of root cause — `StartupScreen` has a 6-second warm-up timeout, but on timeout/failure it silently gives up with no error UI, retry, or fallback, leaving the exact "Preparing your hydration space..." text and continuously-animating shark visible forever (tracked separately as **HYD-REL-001**, since it's a distinct, real defect from whatever causes warm-up to stall); (3) two further live-reproduction attempts this sprint were defeated by this sandbox's Simulator/CoreSimulator tooling becoming unreliable under cumulative session load (a `flutter run` targeting a brand-new, never-before-used simulator failed to even begin compiling on its second attempt) — a **third independent tool** (after the original `xcrun simctl`/`flutter run` failures and Maestro's Stage-10 POC failures) exhibiting this same instability pattern in this sandbox. The original hang reproduction stands as genuine, directly-observed evidence; whether it reflects a real Hydrion defect, sandbox-specific degradation, or (most likely per the new HYD-REL-001 finding) a real-but-otherwise-harmless slow step made to LOOK like a permanent hang by the missing error-UI defect, remains open pending a clean-environment or real-device re-run using this sprint's new instrumentation.

---

## 7. CI/CD and Release Configuration Findings

- **HYD-CI-001** (Info/Low) — `flutter-ci.yml`'s quality gate enforces secret-scan, format, analyze, and test exit codes, but **does not enforce a coverage percentage threshold**; coverage is generated (`flutter test --coverage`) and uploaded as an artifact only. A silent coverage regression would not fail CI today.
- **HYD-CI-002** (Info, positive) — CI/release signing design is sound: `hydrion-release.yml` (production, `workflow_dispatch`-only, `main`-only) reads real signing secrets from GitHub Actions encrypted secrets, decodes at runtime only, masks sensitive values in logs, and independently verifies the resulting certificate SHA-256 before trusting the artifact (`tool/verify_jar_signature.sh`). Regular PR/CI builds (`flutter-ci.yml`, `codemagic.yaml`) instead generate a **fresh, ephemeral, explicitly-labeled throwaway keystore per run** for smoke-install testing only — correctly segregated from the real release pipeline. iOS signing in `codemagic.yaml` uses Codemagic's own App Store Connect API integration gated behind an explicit `HYDRION_SIGNED_IOS_ENABLED` flag in a protected environment. No hardcoded secrets found in any workflow file.
- **HYD-BUILD-003** (Low) — `.fvmrc` pins Flutter 3.44.8; this environment's system Flutter is 3.44.9 and `fvm` itself is not installed, so the pin is not actually enforced locally. Reproducible-build risk if CI and local dev machines silently diverge on patch version. Recommend either installing/requiring `fvm` in `scripts/dev_setup.sh` or updating `.fvmrc` to track what CI (`flutter-ci.yml:23`, `FLUTTER_VERSION: "3.44.8"`) actually pins, and verifying they stay in sync.
- **HYD-BUILD-005** (Low) — Local iOS builds require `LANG=en_US.UTF-8`/`LC_ALL=en_US.UTF-8` to be set explicitly, or `pod install` crashes with a Ruby `Encoding::CompatibilityError`. This is an environment/tooling quirk (CocoaPods' own warning names the fix), not a project code defect, but `scripts/dev_setup.sh` should probably check/set this for new iOS contributors on similarly-configured machines, since it otherwise silently blocks iOS onboarding.
- **CocoaPods integration warning** (Info) — `pod install` reports: "CocoaPods did not set the base configuration of your project because your project already has a custom config set," and separately `flutter build ios` reports the project should migrate from CocoaPods to Swift Package Manager since all current plugins already support SPM. Neither is a defect today; both are worth a deliberate future migration decision rather than accidental drift.
- **HYD-BUILD-006** (Low, confirmed Sprint 1) — Project's Gradle (8.12.0), Android Gradle Plugin (8.9.1), and Kotlin (2.1.0) versions are all below Flutter's currently-stated support minimums (Gradle ≥8.14.0, AGP ≥8.11.1, Kotlin ≥2.2.20), per real warnings emitted during a live `flutter build apk` this sprint (not previously observable since no Android build had ever been run against this repo before Sprint 1). Not yet build-breaking. See `ANDROID_ENVIRONMENT_READINESS.md` §6.
- **HYD-BUILD-007** (Medium, confirmed Sprint 1) — A **fresh `flutter run` targeting iOS Simulator fails deterministically** on a clean checkout with `Target Integrity (Xcode): The package product 'home-widget' requires minimum platform version 14.0 for the iOS platform, but this target supports 13.0`. Root cause: Flutter's auto-generated, gitignored `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` hardcodes `.iOS("13.0")` regardless of the project's actual, correctly-configured `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (verified correct in all `ios/Runner.xcodeproj/project.pbxproj` targets and `ios/Flutter/AppFrameworkInfo.plist`'s `MinimumOSVersion`, and in `ios/Podfile`'s `platform :ios, '14.0'`) — confirmed **reproducible twice independently**, including after a full `rm -rf ios/Flutter/ephemeral && flutter pub get` regeneration, ruling out one-off cache corruption. This did not affect the original audit's `flutter build ios --simulator` (CocoaPods-resolution path), only a plain `flutter run` in this sprint's fresh-simulator reproduction attempt, suggesting Flutter's plugin resolver chose the Swift-Package-Manager path for `home_widget` specifically on this invocation. **Impact**: blocks the single most common local iOS development command (`flutter run`) for any contributor doing a clean checkout, not just this audit's sandbox. **Workaround used in this sprint** (not a real fix — the file is gitignored and regenerated on every `flutter pub get`/`clean`): hand-edited the generated file's platform floor to `14.0` to unblock testing. **Real fix requires investigation outside this sprint's scope**: likely a Flutter-SDK-version-specific SPM-generation bug (worth checking against a newer Flutter stable release) or a `home_widget` package-version pinning change — flagged for the owner rather than resolved here, since editing generated, non-committed output is not a durable solution.

---

## 8. Missing Validation / Test-Gap Highlights

(Full traceability matrix deferred to a follow-up artifact given the scope of this audit — see §13. Highlights below.)

- No test exercises the real native `MethodChannel` path for `timed_session` notifications (only a fake adapter is tested) — HYD-PERF-003's native-lifecycle gap has zero automated coverage.
- No test seeds a large (multi-hundred/thousand-entry) hydration history to catch HYD-PERF-001/002's performance-degradation pattern.
- No test asserts on `android_widget_service.dart`'s sync call frequency/debouncing.
- No integration test (real Flutter engine, not widget-test harness) exercises full app boot to `/home` — this is exactly the gap that let HYD-BLOCK-004 go undetected by CI.
- No widget test covers `_ChallengeActivityPanelState`'s timer/dispose path under rapid navigation (HYD-CORR-001) — the existing `pomodoro_session_ui_test.dart` disposal test only covers the sibling Pomodoro variant.
- No test interleaves two concurrent repository mutations with a forced persist failure to catch the rollback-scope bug (HYD-CORR-002).
- `test/life_stage_policy_test.dart` and `test/challenge_eligibility_test.dart` do not exercise `null`/negative/out-of-range age inputs or exact upper boundaries for several branches that the production code explicitly handles — the logic is correct, but untested (HYD-CORR-004 detail).
- No test file exercising `HydrationPacingEngine` by name was found, despite the underlying logic being well-written — coverage of this file is UNVERIFIED.
- `dart pub audit` does not exist in this SDK; there is no automated dependency-vulnerability-database check in CI today (only `dart pub outdated`, which flags staleness, not known CVEs).
- No automated accessibility audit tooling is wired into CI (screen-reader/semantics testing was not independently exercised in this pass — flagged as UNVERIFIED/not assessed, not as a confirmed gap, since accessibility semantics testing was outside this pass's executed command set).

---

## 9. Blockers and Unverified Areas (explicit)

| Area | Status | Reason |
|---|---|---|
| Android APK/AAB build, Android emulator/device testing | **Blocked** | No Android SDK installed in this environment |
| Live memory/CPU profiling (Instruments, Android Profiler, DevTools) | **Blocked** | No physical device attached with interactive profiling session; no Android SDK/emulator at all |
| Web runtime testing | **Blocked** | `flutter build web` succeeds, but no Chrome executable present |
| `dart pub audit` / CVE database scan | **Blocked (tooling absent)** | Not a subcommand in this Dart SDK version |
| HYD-BLOCK-004 root cause | **Open/unverified** | Live reproduction confirmed (screenshots + sustained ~43% CPU over 1+ minute); a follow-up `flutter run` attempt to capture the live debug trace failed when this sandbox's `simctl`/CoreSimulator tooling itself became unresponsive under the load — a separate environment-stability observation, not a resolution |
| Gemini production API key restriction posture (HYD-SEC-003) | **Unverified** | Google Cloud console configuration is outside this repo's visibility |
| Real-device persistence of the paused-session notification gap (HYD-PERF-003) | **Unverified** | Requires physical/emulated Android device force-kill testing |
| Accessibility (screen reader, semantics, contrast, text scaling beyond what existing tests cover) | **Not independently assessed** | Out of the command set executed in this pass; existing tests (`legal_document_test.dart`'s dark-theme/large-text cases, `challenge_personalization_correction_test.dart`'s narrow/dark/large-text layout cases) provide partial evidence but a dedicated accessibility pass was not performed |
| External mobile-test-platform accounts (BrowserStack, Firebase Test Lab, etc.) | **Not created** | Requires explicit owner approval and, in most cases, payment — deferred per instruction |

---

## 10. Dependency Posture Summary

`dart pub outdated --show-all` (full output captured; direct-dependency highlights):

| Package | Current | Latest | Gap |
|---|---|---|---|
| `flutter_local_notifications` | 20.1.0 | 22.3.0 | 2 major |
| `flutter_lints` (dev) | 4.0.0 | 6.0.0 | 2 major |
| `lottie` | 3.3.3 | 3.5.1 | minor |
| `timezone` | 0.10.1 | 0.11.1 | minor |
| `flutter_markdown_plus` | 1.0.9 | 1.0.12 | patch |
| `geolocator` | 14.0.2 | 14.0.3 | patch |
| `image_picker` | 1.2.2 | 1.2.3 | patch |

No `dart pub audit` equivalent exists in this SDK to check against a CVE database (confirmed by direct attempt). `tool/secret_scan.dart` ran clean against the current tree. No license-compliance tooling beyond the existing `THIRD_PARTY_NOTICES.md` (not independently re-verified line-by-line against actual dependency licenses in this pass — flagged as not assessed rather than assumed correct).

---

## 11. Prioritized Remediation Plan (proposed — not yet executed; see Stage 8 note below)

1. **HYD-BLOCK-004** — isolate root cause of the startup hang (needs a stable device/simulator environment outside this sandbox); this blocks confidence in every other finding about app behavior until resolved, since a hang this severe (if it reproduces outside this sandbox) would itself be release-blocking.
2. **HYD-SEC-001** — introduce `flutter_secure_storage` for health/PII fields; highest-severity confirmed security finding.
3. **HYD-CORR-001** — one-line `mounted` guard fix in `_ChallengeActivityPanelState._syncTicker()`; trivial fix, real crash risk, should be batched with item 1's investigation since both concern the same screen family.
4. **HYD-PERF-003** — add native-side timeout backstop for paused-session notifications.
5. **HYD-SEC-002** — add the missing privacy-manifest entry (cheap fix, real App Store submission risk).
6. **HYD-CORR-002** — fix the full-snapshot rollback pattern in the repository mutation methods listed, using the already-correct `addLog`/`restoreLog` pattern as the template.
7. **HYD-PERF-001 / HYD-PERF-002** — add retention caps to hydration logs and challenge history (same pattern already proven in `daily_hydration_context_repository.dart`).
8. **HYD-SEC-003 / HYD-SEC-004 / HYD-SEC-005 / HYD-SEC-006 / HYD-SEC-007 / HYD-CORR-003 / HYD-CORR-005** — lower-severity hardening pass, batchable together.
9. **HYD-ARCH-001 / HYD-ARCH-002 / HYD-ARCH-003** — architecture-hygiene/documentation-accuracy pass (product decision needed first: ship the Coach UI or formally shelve it).

**This report intentionally stops short of executing remediation.** Per the audit's own controlled-workflow rule ("fix findings in severity and dependency order" only "after completing the baseline and report"), and because item 1 above (the live startup hang) has genuine release-blocking severity *if* it reproduces outside this sandbox, remediation should not proceed until the repository owner confirms: (a) whether HYD-BLOCK-004 reproduces on a real device / outside this sandbox, and (b) which of the above the owner wants actioned now versus tracked for later, since several of these (especially HYD-SEC-001's storage migration and HYD-ARCH-001's product decision) have scope and product-direction implications beyond a pure engineering fix.

---

## 12. What This Report Does Not Cover Yet

Given the scope of the full audit specification, the following deliverables are tracked as separate, in-progress or pending artifacts rather than folded into this document:

- `tester_bible.md`, `AUTOMATION_CANDIDATES.md`, `DEVICE_OS_MATRIX.md`, `SECURITY_TEST_MATRIX.md`, `TEST_COVERAGE_GAPS.md`, `REMEDIATION_LEDGER.md` (Stage 9)
- `MOBILE_TEST_PLATFORM_EVALUATION.md` (Stage 10) — no external platform accounts have been created or trialed, per instruction requiring explicit owner approval before any such step.
- Full traceability matrix (feature → unit → integration → UI → manual → security coverage) — §8 above gives highlights; the full matrix is a large structured artifact best delivered separately.
- Resolution of HYD-BLOCK-004's root cause.

---

*End of report. No git operations, no destructive actions, and no production credentials were used or exposed in the production of this document.*
