# Hydrion Phase 2 Runtime and Feature Integrity Audit

## Executive Summary

- Current compile status: recovered for the root Flutter project. Fresh local checks pass for `flutter analyze`, `flutter test`, and `flutter build web --release`.
- Current runtime readiness: bootable as a Flutter shell, but not product-ready. Most feature services are in-memory deterministic fallbacks created during Phase 1 to restore compile health.
- Real features: app boot, route table, basic Material UI shell, local route navigation, in-session manual hydration log storage, in-session eco total, deterministic coach text, simple reminder policy calculation, and partial hardcoded localization helpers.
- Compile-safe fallback features: AI bridge, LLM service, voice input, permissions, notifications, BLE, wearable/health sync, AR, social challenges, achievements, settings persistence, and platform integrations.
- Top 5 remaining blockers:
  1. No persistence layer exists for hydration logs, reminders, settings, chat, challenges, achievements, or eco totals.
  2. Hydration summary and analytics do not use logged hydration data. `AIBridge` returns fixed values.
  3. Notifications, voice, permissions, wearable/health, BLE, and AR are not real platform integrations.
  4. UI still depends directly on concrete fallback services instead of domain interfaces/view models.
  5. Product/platform metadata and docs still describe a default `hydrion_app` Flutter starter app.

Fresh command evidence:

```text
flutter analyze
Analyzing hydrion_app...
No issues found! (ran in 65.4s)

flutter test
00:02 +1: All tests passed!

flutter build web --release
Built build\web
Wasm dry run findings:
package:geolocator_web/src/html_geolocation_manager.dart 1:1 - dart:html unsupported
package:geolocator_web/src/html_permissions_manager.dart 1:1 - dart:html unsupported
package:geolocator_web/src/utils.dart 2:1 - dart:html unsupported

flutter build apk --release
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.

flutter --version
Flutter 3.35.6 stable, Dart 3.9.2
```

## Resolved Since Phase 1

| Previous Issue | Previous Path | Current Status | Evidence |
|---|---|---|---|
| Flutter project root confusion between `app/` and repository root. | `.github/workflows/flutter-ci.yml`, repo root | Resolved for Flutter CI and local commands. | Workflow defaults use `working-directory: .`; root `pubspec.yaml`, `lib/`, and `test/` are used. |
| Misspelled service folder blocked imports. | `lib/sevices/` | Resolved in active source. | Active imports now target `lib/services/*`; `rg "sevices" lib test` returns no active source matches. |
| Entrypoint did not compile or expose a public app widget. | `lib/main.dart` | Resolved for compile and basic boot. | `HydrionApp` is public and `main()` calls `runApp(HydrionApp())`. |
| Broken route imports and duplicate/missing screen names. | `lib/main.dart`, `lib/ui/screens/*` | Resolved syntactically. | Routes point to real classes: `HomeScreen`, `AnalyticsScreen`, `ChatCoachScreen`, `LogScreen`, `SettingsScreen`, `SocialChallengesScreen`, `ArVisualizationScreen`. |
| Empty or missing runtime service APIs. | `lib/sevices/core_bridge.dart`, `lib/utils/logging.dart`, service files | Partially resolved. | Compile-safe local implementations exist under `lib/services/` and `lib/utils/`, but most are fallback/in-memory services. |
| `llm_service.dart` syntax error and missing pack clients. | `lib/sevices/llm_service.dart` | Partially resolved. | Syntax is fixed and pack imports were removed; current `LLMService` is deterministic local fallback, not provider-backed AI. |
| Widget test imported `package:hydrion_app` and tested counter app. | `test/widget_test.dart` | Resolved. | Test imports `package:hydrion/main.dart` and pumps `HydrionApp()`. |
| Web build failed on Dart compilation. | `lib/`, `pubspec.yaml` | Resolved for normal web release build. | `flutter build web --release` succeeds and writes `build\web`. |
| Direct broken imports to old `app/` paths. | `lib/**/*`, `test/**/*` | Resolved in active source. | `rg "package:hydrion_app|app/lib|../../../hydrion|sevices" lib test` returns no stale active source imports. |
| Android build could not be validated locally. | Local environment | Still open. | `flutter build apk --release` still fails before Gradle because no Android SDK is configured. |

## Runtime Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `lib/services/wearable_service.dart`, `lib/services/core_bridge.dart`, `lib/services/notifications.dart`, `lib/utils/i18n_resolver.dart` | Core user data is not persisted. | Hydration logs, eco events, scheduled reminders, and locale live only in private fields/lists. | Add a real repository/storage layer before expanding features. Persist hydration events, reminders, settings, challenge state, and chat history. |
| Critical | `lib/services/ai_bridge.dart`, `lib/ui/screens/home_screen.dart` | Logged water does not change the displayed hydration summary. | `AIBridge.getHydrationSummary()` always returns `1500/2200`; `_logWater()` refreshes the same fixed summary. | Make the summary read from the hydration repository or remove the claim that the ring reflects logged intake. |
| High | `lib/services/core_bridge.dart`, `lib/services/wearable_service.dart`, `lib/services/eco_tracker.dart` | Hydration state is split across separate in-memory stores. | `WearableService` stores `HydrationLog`; `CoreBridge` stores only `List<int>` eco events. | Create one hydration event source of truth and derive log, summary, eco, and coach digest from it. |
| High | `lib/services/notifications.dart`, `lib/ui/components/reminder_tile.dart` | Reminder scheduling is not a real notification. | `NotificationService` only appends to `_scheduled`; no `flutter_local_notifications` adapter is used. | Add a notification port plus platform adapter, permission checks, cancellation, persistence, and web fallback. |
| High | `lib/services/voice_client.dart`, `lib/ui/components/voice_input_widget.dart` | Voice input does not listen to a microphone. | `initialize()` always returns `true`; `listenOnce()` returns `''`; button produces `unknown_command`. | Gate the voice button behind a real capability check or add a speech adapter. |
| High | `lib/utils/permissions.dart`, `lib/ui/screens/settings_screen.dart` | Permission flow is simulated. | `requestPermissions()` returns `true` while summary remains `bluetooth: false`, `health: false`; no permission plugin is called. | Implement a permission facade per platform and show real grant state in Settings. |
| High | `lib/utils/i18n_resolver.dart`, `lib/main.dart`, `lib/ui/screens/settings_screen.dart` | Locale changes are not reactive app-wide and are not persisted. | `I18nResolver` is not a `ChangeNotifier`; `MaterialApp.locale` is read once from `services.i18n.locale`; Settings calls `loadLocale()` without rebuilding the app shell. | Make locale state observable, persist selected locale, and rebuild `MaterialApp` when it changes. |
| High | `lib/main.dart`, `lib/ui/screens/*`, `lib/ui/components/*` | UI depends directly on concrete service implementations. | Widgets call `context.read<LLMService>()`, `AIBridge`, `WearableService`, `EcoTracker`, `NotificationService`, and `VoiceService`. | Introduce domain ports/view models and inject implementations behind interfaces. |
| Medium | `lib/main.dart` | Service bootstrap has no startup/error state. | `HydrionServices.local()` is synchronous and assumes all services construct successfully. | Add startup state and failure boundaries before adding real async storage, permissions, or native integrations. |
| Medium | `lib/ui/components/voice_input_widget.dart` | The voice FAB owns a repeating animation controller even when idle. | `_pulse.repeat(reverse: true)` starts in `initState()`; tests require bounded pumps because the app never fully settles. | Start the pulse only during active recording/processing, or replace with a non-repeating idle state. |
| Medium | `pubspec.yaml` | Many native/cloud dependencies remain declared but unused by active source. | Active `lib/` package imports are only Flutter, `provider`, Flutter localizations, and `yaml`; `pubspec.yaml` still lists BLE, notifications, health, OpenAI, AR, HTTP/Dio, etc. | Remove unused direct dependencies or move them into optional adapters when implemented. |
| Medium | `.github/workflows/flutter-ci.yml`, local `flutter --version` | CI Flutter version may not match local validated version. | CI pins `FLUTTER_VERSION: "3.24.x"`; local validation used Flutter `3.35.6`. | Align CI Flutter with the project metadata/local validation version or test both intentionally. |
| Low | `README.md`, `web/*`, platform metadata | Product branding remains default Flutter starter metadata. | README says `# hydrion_app` and "A new Flutter project"; web manifest/title use `hydrion_app`. | Update docs and metadata after runtime behavior is clarified. |

## Feature Readiness Matrix

| Feature | Status | Current Implementation | Missing Work | Priority |
|---|---|---|---|---|
| App shell and navigation | Basic real | `HydrionApp` registers routes and providers; route buttons navigate. | Route-level tests, startup error UI, product nav structure. | High |
| Manual hydration log | Partial/in-session | Home logs `250 ml` into `WearableService` and `EcoTracker`. | Persistence, variable amounts, validation UX, summary update, editing/deleting logs. | Critical |
| Hydration summary/ring | Fake deterministic | `AIBridge` returns constant `1500/2200` and 30 activity minutes. | Derive from persisted intake, target rules, activity, time of day. | Critical |
| Hydration log screen | Partial/in-session | Reads `WearableService` logs for the current process. | Empty-state actions, persistence, date grouping, add/edit/delete, real sources. | High |
| Analytics | Mostly shell | Uses fixed `AIBridge` summary, hardcoded achievements, in-memory eco total. | Real metrics, trends, achievement rules, repository-backed data. | High |
| Eco impact | Partial/in-session | Converts logged ml into estimated plastic saved via `CoreBridge`. | Persist events, define formula, show units/rationale, reconcile with actual intake. | Medium |
| Reminders | Compile-safe fallback | `ReminderPolicy` computes time/message; `NotificationService` stores in memory. | OS notifications, permissions, scheduling/cancel/repeat, persistence, web fallback. | Critical |
| Chat coach | Deterministic fallback | `LLMService.getCoachingAdvice()` returns local string with logged ml from `CoreBridge`. | Chat persistence, real provider adapters, prompt validation, privacy controls. | High |
| LLM advice card | Deterministic fallback | Uses `LLMService.getHydrationCoachResponse()` with rule-based text. | Real domain input, adapter boundary, loading/error telemetry. | Medium |
| Voice input | Fake/simulated | Button initializes successfully but parses empty transcript. | Speech capture, permissions, transcript UI, platform gating, failure states. | High |
| Social challenges | Shell | `AIBridge.createChallenge()` returns one deterministic challenge; Join shows snack only. | Join state, challenge repository, progress, social backend/local mode. | Medium |
| Achievements | Fake/static | Analytics displays fixed locked/unlocked badges. | Achievement rules, persistence, unlock flow, accessibility states. | Medium |
| AR hydration view | Disabled shell | Route shows disabled message. | Hide/gate route, add real assets/permissions/platform adapter if kept. | Low |
| Localization | Partial/fallback-only | Hardcoded map for English plus partial Spanish/French; Material delegates registered. | Real localization files, reactive locale, persistence, full string coverage. | High |
| Permissions | Simulated | Returns success without platform permission requests. | Real permission plugin integration and platform-specific copy. | High |
| BLE/smart bottle | Disabled fallback | `BLEService.scanForBottles()` returns empty and is not registered in providers. | Real BLE adapter, permissions, UI flow, web/desktop gating. | Medium |
| Wearable/health sync | Disabled fallback | `WearableService` is local in-memory logging only. | HealthKit/Google Fit adapters, permissions, conflict resolution, privacy docs. | Medium |
| Storage | Missing | No app source imports a storage package. | Repository interfaces, schemas, migrations, encryption/privacy decisions. | Critical |
| Web release | Compile-ready | `flutter build web --release` passes. | Wasm dependency cleanup, web feature gating, PWA branding. | Medium |
| Android release | Not locally validated | Build stops before Gradle because Android SDK is missing locally. | SDK setup, CI APK validation, app ID, signing, permissions. | High |

## Service Layer Findings

| Severity | Service | Current Behavior | Risk | Recommended Fix |
|---|---|---|---|---|
| Critical | `AIBridge` (`lib/services/ai_bridge.dart`) | Returns fixed `HydrationSummary` and one deterministic challenge. | UI appears data-driven but does not reflect user behavior. | Replace with domain services backed by hydration repository and optional AI adapters. |
| Critical | `WearableService` (`lib/services/wearable_service.dart`) | Stores manual hydration logs in a private list with source `local`. | Data loss on restart; name implies wearable/health integration that does not exist. | Rename/split into `HydrationLogRepository` and later add optional health/wearable adapters. |
| High | `CoreBridge` (`lib/services/core_bridge.dart`) | In-memory pseudo-core for eco events, digest JSON, and response validation. | Can be mistaken for Rust/FFI core; state diverges from logs. | Define a clear app-core port; wire Rust FFI only when real and tested. |
| High | `LLMService` (`lib/services/llm_service.dart`) | Deterministic rule-based responses; `LlmMode` values are not used for provider selection. | Product may imply AI/cloud/local models while no provider exists. | Introduce `AiProvider` interface and mark local fallback explicitly in UI/config. |
| High | `NotificationService` (`lib/services/notifications.dart`) | Keeps scheduled reminders in memory only. | Users will not receive reminders after leaving the screen/app. | Implement platform notification adapter plus persistence and cancellation. |
| High | `VoiceService` (`lib/services/voice_client.dart`) | Initializes to true, listens to nothing, parses empty transcript. | Voice UI is misleading and always returns unknown intent. | Gate or disable voice until a real speech adapter exists. |
| High | `Permissions` (`lib/utils/permissions.dart`) | Simulates permission request outcome. | Settings reports success without user/device permissions. | Use platform adapters and return accurate grant state. |
| Medium | `VoiceLLMBridge` (`lib/services/voice_llm_bridge.dart`) | Normalizes parser output from `LLMService`. | Reasonable fallback boundary, but it has no actual transcript source. | Keep as a parser boundary, but feed it real speech/text commands. |
| Medium | `ReminderPolicy` (`lib/services/policy_service.dart`) | Computes reminder urgency and delay from shortfall, hours, percent, active time. | Policy is usable but detached from user preferences, quiet hours, and sent counts. | Add tests and wire to persisted preferences/history. |
| Medium | `EcoTracker` (`lib/services/eco_tracker.dart`) | Delegates hydration volume to `CoreBridge`. | Depends on separate in-memory event stream. | Derive eco metrics from persisted hydration events. |
| Medium | `BLEService` (`lib/services/ble_service.dart`) | Scan returns empty list; read water level returns null. | Feature is disabled but not surfaced as unavailable. | Keep as no-op adapter only behind explicit capability state. |
| Medium | `I18nResolver` (`lib/utils/i18n_resolver.dart`) | Hardcoded lookup map with partial translations. | Missing keys fall back to English or widget fallback; app locale is not reactive. | Move to real localization assets/generation or make resolver observable and complete. |
| Low | `LLMPromptBuilder` (`lib/utils/llm_prompt_builder.dart`) | Loads prompt templates from assets but is unused by `LLMService`. | Dead/latent code can drift; prompt YAML contains mojibake characters such as `Â°C`. | Either integrate into the local/provider AI flow or remove from runtime until adapter work begins. |

## UI and Routing Findings

| Severity | Screen or Component | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| High | `lib/main.dart` route table | Every route points to a real screen, but several route targets are feature shells. | `/`, `/analytics`, `/chat`, `/log`, `/settings`, `/challenges`, and `/ar` compile and are reachable. | Add route tests and feature availability guards. |
| Critical | `lib/ui/screens/home_screen.dart` | Main hydration UI does not update the ring after logging water. | `_logWater()` logs to services, then refreshes fixed `AIBridge.getHydrationSummary()`. | Bind home summary to real hydration event state. |
| High | `lib/ui/screens/home_screen.dart` | Home exposes AR, voice, reminders, and challenges even though they are disabled/fallbacks. | Route chips include `AR`; FAB uses fake `VoiceService`; reminder tile schedules in memory. | Hide/gate unavailable features and label local fallback behavior honestly. |
| High | `lib/ui/components/voice_input_widget.dart` | Voice button produces duplicate/stacked snack feedback and no real command. | Widget shows `Command: ...`; home callback also shows `Voice intent: ...`. | Centralize command handling and remove duplicate snackbars. |
| High | `lib/ui/components/reminder_tile.dart` | Reminder UI confirms scheduling even though no notification will fire. | `NotificationService` returns a `ScheduledReminder` object only in memory. | Show local-only state or wire real platform scheduling first. |
| Medium | `lib/ui/screens/analytics_screen.dart` | Analytics mixes static and in-session data. | Achievements are hardcoded; eco comes from current `CoreBridge`; hydration score is fixed. | Add a view model with explicit data freshness/loading/error states. |
| Medium | `lib/ui/screens/log_screen.dart` | Log screen can display current-session logs but cannot add/edit/delete entries. | It only fetches from `WearableService`; manual add exists only on Home. | Add log management UI and persist events. |
| Medium | `lib/ui/screens/settings_screen.dart` | Settings controls do not have lasting effect. | Language and permissions are not persisted; locale is not app-reactive. | Persist settings and rebuild app shell on locale/theme changes. |
| Medium | `lib/ui/screens/chat_coach_screen.dart` | Chat history is session-only and coach is deterministic. | `_messages` is a local list; `LLMService` returns local fallback text. | Persist chat sessions or make chat explicitly ephemeral; add provider adapter later. |
| Medium | `lib/ui/screens/social_challenges_screen.dart` | Join action does not join anything. | Button only shows `Challenge joined` snackbar. | Store joined challenge state and show progress/cancel/completion. |
| Low | `lib/ui/screens/ar_visualization_screen.dart` | AR route is a disabled placeholder but is still reachable. | Screen text says AR is disabled. | Keep disabled screen for transparency or remove route chip until assets/permissions exist. |
| Low | `lib/ui/components/intake_ring.dart` | Ring is visually functional but displays stale domain data. | Consumes props correctly; upstream summary is fixed. | No component fix needed until data source is repaired. |

## Storage and Persistence Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| Critical | `lib/services/wearable_service.dart` | Hydration logs are volatile. | `_logs` is a private `List<HydrationLog>` created per app service instance. | Add persisted hydration event repository with date/source/volume schema. |
| Critical | `lib/services/notifications.dart` | Reminder schedules are volatile and not delivered by OS. | `_scheduled` is a private list; no platform plugin calls. | Persist reminder definitions and schedule via platform notification adapter. |
| High | `lib/utils/i18n_resolver.dart`, `lib/ui/screens/settings_screen.dart` | Locale selection is volatile. | `_locale` is an instance field and Settings `_selected` is widget state. | Persist selected locale and expose observable app settings. |
| High | `lib/ui/screens/chat_coach_screen.dart` | Chat history is volatile. | `_messages` is a widget-local list. | Store conversations only if product needs history; otherwise label chat as ephemeral. |
| High | `lib/ui/screens/social_challenges_screen.dart` | Challenge participation is not persisted. | Join button shows a snackbar only. | Add challenge state repository before social/challenge UX expands. |
| Medium | `pubspec.yaml` | Storage-capable dependencies are declared but unused. | `path_provider` exists in dependencies; active `lib/` code imports no storage packages. | Remove unused dependency or implement storage deliberately behind a repository. |
| Medium | `config/`, `i18n/`, `assets/` | Declared asset/config folders do not drive runtime behavior. | `assets/` and `i18n/` contain no files; `config/app.yaml` feature flags are not read. | Either wire config/assets intentionally or stop declaring unused runtime assets. |
| Medium | `models/` | Training scripts are declared as Flutter assets. | `models/training/*.py` are under `pubspec.yaml` asset path `models/`. | Separate runtime model assets from training source. |

## AI and ELKA Preparation Findings

| Severity | Path | Issue | Evidence | Recommended Fix |
|---|---|---|---|---|
| High | `lib/services/llm_service.dart` | Current AI behavior is deterministic fallback, not AI inference. | Responses are switch/if generated strings; no `dart_openai`, local model, or pack client import is active. | Keep fallback, but expose provider interfaces before adding any real AI. |
| High | `lib/services/ai_bridge.dart` | `AIBridge` is a mock-like local facade, not an ELKA or AI bridge. | It returns constants and one challenge by user level. | Rename or replace with app-domain use cases so future ELKA does not leak into UI. |
| High | `lib/ui/screens/chat_coach_screen.dart`, `lib/ui/components/llm_advice_card.dart` | UI directly depends on `LLMService`. | Widgets call `context.read<LLMService>()`. | Depend on `HydrationCoach` or view model interface instead. |
| High | `lib/ui/screens/home_screen.dart`, `lib/ui/screens/analytics_screen.dart`, `lib/ui/screens/social_challenges_screen.dart` | UI directly depends on `AIBridge`. | Widgets call `context.read<AIBridge>()`. | Replace with domain services such as `HydrationSummaryService` and `ChallengeService`. |
| Medium | `config/open_ai_config.yaml`, `pubspec.yaml` | OpenAI config/dependency exist but are not used. | `dart_openai` is declared; active imports do not include it. | Keep provider config outside runtime until adapter is implemented and opt-in. |
| Medium | `packs/` | AI provider packs are empty shells. | Pack files are 0 bytes; `packs/gemini_connector/client/lib/` has no files. | Do not wire packs until they are real packages/adapters with tests. |
| Medium | `lib/utils/llm_prompt_builder.dart`, `config/prompt_templates.yaml` | Prompt builder is present but unused by local LLM fallback. | `LLMPromptBuilder` is not imported by active services. | Decide whether prompts belong in provider adapters or delete from app runtime after tracing. |
| Low | Whole repo | No ELKA runtime coupling was found. | `rg "ELKA|elka" lib config packs README.md pubspec.yaml` finds no active ELKA code. | Preserve this: Hydrion should remain standalone and ELKA should be optional through an adapter. |

## Platform Readiness Update

| Platform | Current Status | Remaining Blockers | Required Fixes |
|---|---|---|---|
| Android | Not locally validated; code-level build likely reaches Gradle only when SDK exists. | Local `flutter build apk --release` fails because Android SDK/`ANDROID_HOME` is missing. Platform metadata still uses `com.example.hydrion_app`, label `hydrion_app`, and debug release signing. No production permissions are declared for intended BLE/health/notifications/voice features. | Configure Android SDK locally/CI, verify APK, set real app ID/namespace/label, add release signing, add permissions only when real adapters exist. |
| iOS | Not validated. Scaffold is default. | Bundle ID remains `com.example.hydrionApp`; `Info.plist` lacks usage descriptions for intended health/BLE/speech/camera/notification features. | Validate on macOS, set bundle ID/team, add usage strings only for enabled adapters. |
| Web | Normal web release build passes. | Wasm dry run warns that transitive `geolocator_web` uses unsupported `dart:html`; web metadata still says `hydrion_app`; fake voice/permissions/reminders are shown on web. | Remove unused native dependencies or gate them; update PWA metadata; hide unsupported features. |
| macOS | Not validated. Scaffold exists. | Default product/bundle metadata; generated plugin registrant includes unused native plugins due dependencies. | Validate build, update identity, gate unsupported features, remove unused plugins. |
| Windows | Not validated. Scaffold exists. | Default `hydrion_app`/`com.example` metadata; generated plugins include connectivity/geolocator/permission due dependency graph. | Validate build, update metadata, remove or isolate unused native plugins. |
| Linux | Not declared in `pubspec.yaml` platforms but folder exists. | `pubspec.yaml` lists android/ios/web/macos/windows only; Linux scaffold has default `com.example.hydrion_app`. | Decide whether Linux is supported. Either declare/test it or archive/remove scaffold in a cleanup phase. |

## Recommended Phase 2 Repair Plan

### Runtime boot hardening

1. Add a small app bootstrap state that can show loading and fatal startup errors before `MaterialApp` routes are used.
2. Convert `HydrionServices` from concrete service bag to domain-facing interfaces.
3. Add route smoke tests for every named route.
4. Align CI Flutter version with the locally validated Flutter version or document/test the version matrix.

### Feature wiring

1. Create a single hydration event repository as the source of truth.
2. Make Home, Log, Analytics, Eco, Reminder, and Coach read from the same hydration state.
3. Rename misleading fallback services or mark them explicitly as local-only.
4. Gate AR, BLE, voice, health, and notifications behind capability state.

### Persistence repair

1. Persist hydration events first.
2. Persist settings/locale second.
3. Persist reminders only when platform scheduling is real.
4. Persist challenge/chat state only after product requirements are clear.
5. Add migration/schema tests before committing to storage format.

### UI behavior repair

1. Make `Log 250 ml` immediately update the ring, score, log, eco impact, and coach digest.
2. Replace fake Join, Voice, Permission, and Reminder confirmations with honest states.
3. Remove duplicate snackbars from voice handling.
4. Start voice animation only while active.
5. Add empty-state actions and user-visible unavailable states.

### Platform gating

1. Remove unused native/cloud dependencies from the app until adapters are real, or move them behind optional packages.
2. Use `kIsWeb` and platform capability services for feature availability, not UI guesses.
3. Add Android/iOS permission strings only for enabled features.
4. Keep web build green and decide whether wasm support is required.

### Documentation update

1. Replace default README content with actual root-project setup instructions.
2. Document Phase 1 fallback behavior so contributors do not mistake it for production integrations.
3. Document which features are local-only, disabled, or future adapter work.
4. Update stale `hydrion.txt`, `p1.txt`, and `overview` references to the old `app/` architecture or move them into an archive.
5. Add a short architecture note: Hydrion runs standalone; ELKA is optional; AI providers live behind adapters; UI does not import ELKA/provider SDKs.
